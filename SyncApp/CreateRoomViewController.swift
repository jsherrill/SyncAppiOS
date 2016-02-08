//
//  CreateRoomViewController.swift
//  GroupApp
//
//  Created by Jim Sherrill on 2/1/16.
//  Copyright © 2016 Jim Sherrill. All rights reserved.
//

import UIKit
import Firebase
import YouTubePlayer

class CreateRoomViewController: UIViewController, UITextFieldDelegate, YouTubePlayerDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var roomNameTextField: UITextField!
    @IBOutlet weak var youTubeUrlTextField: UITextField!
    @IBOutlet var errorLabel: UILabel!
    @IBOutlet var friendsTable: UITableView!
    var firebaseManager:FirebaseManager!
    var roomId: String!
    var roomDetails:[String:AnyObject]!
    var youtubePlayer:YouTubePlayerView!
    
    var friendsList:[String:Bool]!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        errorLabel.text = ""
        youtubePlayer = YouTubePlayerView()
        youtubePlayer.delegate = self
        
        var pasteboardString:String? = UIPasteboard.generalPasteboard().string
        if let url = pasteboardString {
            if let url = NSURL(string: url) {
                youTubeUrlTextField.text = url.absoluteString
            }
        }
        
        loadFriendsList()
    }

    func loadFriendsList() {
        if firebaseManager == nil || firebaseManager.friendsRoot == nil {
            return
        }
        
        friendsList = [String:Bool]()
        
        let localUserFriendEntry = firebaseManager.friendsRoot.childByAppendingPath(firebaseManager.localUser.username)
        localUserFriendEntry.observeEventType(.Value, withBlock: { entry in
            if (entry.value is NSNull) == false {
                // make sure we have some friends
                let friendEnum = entry.children
                self.friendsList.removeAll()
                
                while let friend = friendEnum.nextObject() as? FDataSnapshot {
                    let friendName = friend.key
                    let weAccepted = friend.value as! Bool
                    var areAccepted = false
                    
                    // need to do a lookup for both these users to make sure we're both accepted
                    let acceptedRef = self.firebaseManager.friendsRoot.childByAppendingPath("\(friendName)/\(self.firebaseManager.localUser.username)")
                    var theyAccepted = false
                    
                    acceptedRef.observeSingleEventOfType(.Value, withBlock: { entry in
                        if (entry.value is NSNull) == false {
                            theyAccepted = entry.value as! Bool
                            areAccepted = theyAccepted && weAccepted
                            
                            if areAccepted {
                                self.friendsList[friendName] = false
                                self.friendsTable.reloadData()
                            }
                        }
                    })
                }
            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func createButtonPressed(sender: AnyObject) {
        var roomName:String = roomNameTextField.text!
        var youTubeUrl: String = youTubeUrlTextField.text!
        
        if roomName.characters.count > 0 && youTubeUrl.characters.count > 0 {
            var url = NSURL(string: youTubeUrl)
            if url == nil {
                errorLabel.text = "Error: Please enter a valid Youtube URL"
            }
            else {
                youtubePlayer.loadVideoURL(url!)
                self.roomDetails = [ "roomName":roomName, "youTubeUrl" : youTubeUrl]
            }
        }
        else {
            var errorText = "Error: "
            if roomName.characters.count == 0 && youTubeUrl.characters.count == 0 {
                errorText += "Please enter a room name and Youtube URL"
            }
            errorLabel.text = "Error: Please enter a room name"
        }
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    private func sendInvites(roomID:String) {
        if roomID.characters.count == 0 {
            return
        }
        
        if friendsList.count == 0 {
            return
        }
        
        // update our invites/roomID/ firebase path
        let inviteRef = firebaseManager.root.childByAppendingPath("invites/\(roomID)")
        inviteRef.observeSingleEventOfType(.Value, withBlock: { entry in
            var invitedFriends:[String:Bool] = [String:Bool]()
            for var i = self.friendsList.startIndex; i != self.friendsList.endIndex; i = i.advancedBy(1) {
                if self.friendsList.values[i] == true {
                    invitedFriends[self.friendsList.keys[i]] = true
                }
            }
            
            if entry.value is NSNull {
                inviteRef.setValue(invitedFriends)
            }
        })
        
        // update our invited user's user/username/invites/ path
        for var i = self.friendsList.startIndex; i != self.friendsList.endIndex; i = i.advancedBy(1) {
            let friendName = self.friendsList.keys[i]
            let invited = self.friendsList.values[i]
            
            if invited {
                let userRef = firebaseManager.userRoot.childByAppendingPath(friendName)
                userRef.observeEventType(.Value, withBlock: { entry in
                    if (entry.value is NSNull) == false {
                        userRef.childByAppendingPath("invites").updateChildValues([roomID:true])
                    }
                })
            }
        }
    }
    // MARK: - Youtube Validation
    func playerReady(videoPlayer: YouTubePlayerView) {
        if videoPlayer.ready {
            errorLabel.text = ""
            let room = firebaseManager.roomsRoot?.childByAutoId()
            self.roomId = room!.key
            self.roomDetails["roomId"] = self.roomId
            
            room?.setValue(roomDetails)
            
            sendInvites(self.roomId)
            
            self.performSegueWithIdentifier("idCreatedRoomSegue", sender: self)
        }
        else {
            errorLabel.text = "Error: Please enter a valid Youtube video."
        }
    }
    
    func playerStateChanged(videoPlayer: YouTubePlayerView, playerState: YouTubePlayerState) {
        print(playerState)
    }
    
    func playerQualityChanged(videoPlayer: YouTubePlayerView, playbackQuality: YouTubePlaybackQuality) {
        
    }
    
    // MARK: - UITableviewDelegate Methods
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return friendsList.count
        default:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Invite Friends"
        default:
            return ""
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("idFriendCell", forIndexPath: indexPath)
        
        if indexPath.section == 0 {
            let friendIndex = friendsList.startIndex.advancedBy(indexPath.row)
            let friendName = friendsList.keys[friendIndex]
            let invited = friendsList.values[friendIndex]
            
            cell.textLabel?.text = friendName
            
            if invited {
                cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            }
            else {
                cell.accessoryType = UITableViewCellAccessoryType.None
            }
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            let friendIndex = friendsList.startIndex.advancedBy(indexPath.row)
            let friendName = friendsList.keys[friendIndex]
            var invited = friendsList.values[friendIndex]
            
            invited = !invited
            friendsList.updateValue(invited, forKey: friendName)
            
            let cell = friendsTable.cellForRowAtIndexPath(indexPath)!
            
            if invited {
                cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            }
            else {
                cell.accessoryType = UITableViewCellAccessoryType.None
            }
            
            cell.selected = false
        }
    }
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "idCreatedRoomSegue" {
            //(segue.destinationViewController as! RoomListViewController).firebaseManager = self.firebaseManager
            
            if let room = segue.destinationViewController as? ViewController {
                    room.firebaseManager = self.firebaseManager
                    room.youTubeUrl = self.youTubeUrlTextField.text
                    room.roomId = self.roomId!
                    enterRoom(self.roomId)
            }
        }
    }
    
    func enterRoom(roomId:String!) {
        let uniqueRoomInMembers = firebaseManager.membersRoot.childByAppendingPath(roomId)
        let memberInRoom = uniqueRoomInMembers.childByAppendingPath(firebaseManager.localUser.username)
        memberInRoom.setValue([firebaseManager.localUser.username:["isReady":false, "playerState":"Unstarted"]])
    }

}
