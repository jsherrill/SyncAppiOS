//
//  ViewController.swift
//  SyncApp
//
//  Created by Matthew Ferri on 2/1/16.
//  Copyright © 2016 Matthew Ferri. All rights reserved.
//

import UIKit
import Firebase
import YouTubePlayer

class ViewController: UIViewController, YouTubePlayerDelegate {

    var firebaseManager : FirebaseManager!
    @IBOutlet var videoPlayer: YouTubePlayerView!
    var members:NSMutableArray = NSMutableArray()
    var roomId: String!
    var youTubeUrl: String!
    @IBOutlet weak var userTable: UITableView!
    @IBOutlet var roomNavItem: UINavigationItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.hidesBarsOnTap = true
        
        let roomName = firebaseManager.roomsRoot.childByAppendingPath("\(roomId)/roomName")
        roomName.observeSingleEventOfType(.Value, withBlock: { entry in
            if !(entry.value is NSNull) {
                self.roomNavItem.title = entry.value as? String
            }
        })
        
        print("Entered Room")
        //print(youTubeUrl)
        //print(roomId)
        
        videoPlayer.delegate = self
        videoPlayer.playerVars = [
            "playsinline" : "1"
        ]
        
        if let url = youTubeUrl {
            if let url = NSURL(string: url) {
                videoPlayer.loadVideoURL(url)
            }
        }
        
        if let roomId = roomId {
        
        let membersForRoomRoot = firebaseManager.membersRoot.childByAppendingPath(roomId)
        //let membersForRoomRoot = firebaseManager.root.childByAppendingPath("members/\(roomId)")
        membersForRoomRoot.observeEventType(.Value, withBlock: { entry in
            if entry.value is NSNull {
                print ("no members")
            }
            else {
                let memberEnumerator = entry.children
                self.members.removeAllObjects()
                
                var isEveryoneReady = true
                var myState: String!
                while let member = memberEnumerator.nextObject() as? FDataSnapshot {
                    print (member)
                    let memberDescription = NSMutableDictionary()
                    memberDescription["name"] = member.key
                    memberDescription["state"] = member.childSnapshotForPath("\(member.key)/playerState").value as? String
                    memberDescription["isReady"] = member.childSnapshotForPath("\(member.key)/isReady").value as? Bool
                    
                    var user = member.key as? String
                    var state:String = memberDescription["state"] as! String
                    var isReady:Bool = memberDescription["isReady"] as! Bool
                    
                    if user != self.firebaseManager.localUser.username {
                        if isReady == false {
                            isEveryoneReady = false
                        }
                        
                        if state != "Playing" {
                            isEveryoneReady = false
                        }
                    }
                    else {
                        myState = state
                        if memberDescription["isReady"] as? Bool == false {
                            isEveryoneReady = false
                        }
                    }
                    
                    // Do stuff here JIM!!!!!!
                    
                    self.members.addObject(memberDescription)
                }
                
                if isEveryoneReady == true {
                    self.videoPlayer.play()
                }
                else {
                    if myState == "Playing" {
                        self.videoPlayer.pause()
                    }
                }
                
                
                self.userTable.reloadData()
            }
        })
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return navigationController?.navigationBarHidden == true
    }
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return .Slide
    }
    
    func updateMemberPlayerStatus(status: String!) {
        let uniqueRoomInMembers = firebaseManager.membersRoot.childByAppendingPath(roomId)
        let memberInRoom = uniqueRoomInMembers.childByAppendingPath(firebaseManager.localUser.username)
        memberInRoom.updateChildValues(["\(firebaseManager.localUser.username)/playerState":status])
    }

    func updateMemberReadyStatus(status: Bool!) {
        let uniqueRoomInMembers = firebaseManager.membersRoot.childByAppendingPath(roomId)
        let memberInRoom = uniqueRoomInMembers.childByAppendingPath(firebaseManager.localUser.username)
        memberInRoom.updateChildValues(["\(firebaseManager.localUser.username)/isReady":status])
    }
    
    func playerReady(videoPlayer: YouTubePlayerView) {
        //videoPlayer.play()
        self.updateMemberPlayerStatus("Player loaded")
    }
    
    func playerStateChanged(videoPlayer: YouTubePlayerView, playerState: YouTubePlayerState) {
        print(playerState)
        //self.updateMemberStatus(playerState.rawValue)
        switch playerState {
        case .Buffering:
            self.updateMemberPlayerStatus("Buffering")
        case .Ended:
            self.updateMemberPlayerStatus("Ended")
        case .Paused:
            self.updateMemberPlayerStatus("Paused")
        case .Playing:
            self.updateMemberPlayerStatus("Playing")
        case .Queued:
            self.updateMemberPlayerStatus("Queued")
        case .Unstarted:
            self.updateMemberPlayerStatus("Unstarted")
        default:
            break;
        }
    }
    
    @IBAction func imReadyPressed(sender: AnyObject) {
        firebaseManager.localUser.isReady = !firebaseManager.localUser.isReady
        updateMemberReadyStatus(firebaseManager.localUser.isReady)
    }
    
    func playerQualityChanged(videoPlayer: YouTubePlayerView, playbackQuality: YouTubePlaybackQuality) {
        
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return members.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("idUserCell", forIndexPath: indexPath)
        
        let member = members[indexPath.row]
        
        //var roomDescription = roomEntry.valueForKey(key: roomEntry.key)
        
        // Configure the cell...
        cell.textLabel?.text = member["name"] as? String
        //cell.detailTextLabel?.text = member["state"] as? Int == 0 ? "Not Ready" : "Ready"
        cell.detailTextLabel?.text = member["isReady"] as? Bool == true ? "Ready" : "Not Ready"
        
        return cell
    }

}

