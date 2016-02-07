//
//  ProfileViewController.swift
//  SyncApp
//
//  Created by Jim Sherrill on 2/5/16.
//  Copyright © 2016 Matthew Ferri. All rights reserved.
//

import UIKit
import Firebase

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var profileImageView: UIImageView!
    @IBOutlet var addFriendTextfield: UITextField!
    @IBOutlet var friendsTable: UITableView!
    @IBOutlet var errorLabel: UILabel!
    
    var friendsList:[String:Bool]!
    var pendingFriends:[String:Bool]!
    
    
    var firebaseManager:FirebaseManager!
    
    var acceptAction:UITableViewRowAction!
    var rejectAction:UITableViewRowAction!
    var removeAction:UITableViewRowAction!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        errorLabel.text = ""
        
        if firebaseManager == nil {
            firebaseManager = FirebaseManager()
            firebaseManager.initFirebaseURLsFromPListKey("Info", plistURLKey: "FirebaseURL")
            
            let localUser = NSUserDefaults.standardUserDefaults().valueForKey("FirebaseUser")
            if localUser != nil {
                firebaseManager.localUser.deserialize((localUser as? [String:AnyObject])!)
            }
        }
        
        configureProfileLabels()
        configureTableActions()
        
        let userFriends = firebaseManager.friendsRoot.childByAppendingPath(firebaseManager.localUser.username)
        
        friendsList = [String:Bool]()
        pendingFriends = [String:Bool]()
        
        // watch our friends in Firebase
        userFriends.observeEventType(.Value, withBlock: { entry in
            if entry.value is NSNull {
                // we don't have any friends :(
            }
            else {
                let friendEnumerator = entry.children
                self.friendsList.removeAll()
                
                while let friend = friendEnumerator.nextObject() as? FDataSnapshot {
                    let friendName = friend.key
                    let friendRef = self.firebaseManager.friendsRoot.childByAppendingPath("\(friendName)/\(self.firebaseManager.localUser.username)")
                    let localFriendRef = self.firebaseManager.friendsRoot.childByAppendingPath("\(self.firebaseManager.localUser.username)/\(friendName)")
                    
                    var theyAccepted = false
                    var weAccepted = false
                    var areAccepted = false
                    
                    // check if this user has accepted us
                    friendRef.observeSingleEventOfType(.Value, withBlock: { entry in
                        if (entry.value is NSNull) == false {
                            theyAccepted = entry.value as! Bool
                            
                            localFriendRef.observeSingleEventOfType(.Value, withBlock: { entry in
                                if (entry.value is NSNull) == false {
                                    weAccepted = entry.value as! Bool
                                    
                                    areAccepted = weAccepted && theyAccepted
                                    
                                    if areAccepted == true {
                                        self.friendsList[friendName] = areAccepted
                                        self.friendsTable.reloadData()
                                    }
                                    else {
                                        self.pendingFriends[friendName] = weAccepted
                                        self.friendsTable.reloadData()
                                    }
                                }
                            })
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
    
    func configureTableActions() {
        acceptAction = UITableViewRowAction(style: .Normal, title: "Accept", handler: { (rowAction:UITableViewRowAction, indexPath:NSIndexPath) -> Void in
            self.acceptFriendAtIndexPath(indexPath)
        })
        acceptAction.backgroundColor = UIColor.greenColor()
        
        rejectAction = UITableViewRowAction(style: .Normal, title: "Reject", handler: { (rowAction:UITableViewRowAction, indexPath:NSIndexPath) -> Void in
            self.removeFriendAtIndexPath(indexPath)
        })
        rejectAction.backgroundColor = UIColor.redColor()
        
        removeAction = UITableViewRowAction(style: .Normal, title: "Remove", handler: { (rowAction:UITableViewRowAction, indexPath:NSIndexPath) -> Void in
            self.removeFriendAtIndexPath(indexPath)
        })
    }
    
    // MARK: - Add Friend Methods
    @IBAction func addFriendPressed(sender: AnyObject) {
        if addFriendTextfield.text?.characters.count == 0 {
            errorLabel.text = "Please enter a username."
        }
        else {
            sendFriendInvite(addFriendTextfield.text!)
        }
    }
    
    func sendFriendInvite(username:String) {
        if firebaseManager == nil {
            return
        }
        
        if firebaseManager.membersRoot == nil {
            return
        }
        
        if username.characters.count == 0 {
            errorLabel.text = "Please enter a username."
            return
        }
        
        if username == firebaseManager.localUser.username {
            errorLabel.text = "Please enter a different person's username."
            return
        }
        
        let userNoSpace = username.stringByReplacingOccurrencesOfString(" ", withString: "-")
        var invitedFriend = firebaseManager.userRoot.childByAppendingPath(userNoSpace)
        let localUserName:String = firebaseManager.localUser.username
        let localUserFriendEntry = firebaseManager.friendsRoot.childByAppendingPath(localUserName)
        
        // check to make sure this user exists first
        invitedFriend.observeSingleEventOfType(.Value, withBlock: { entry in
            if entry.value is NSNull {
                self.errorLabel.text = "Error: User does not exist."
            }
            else {
                // get this user's entry in the /friends/ section of firebase
                invitedFriend = self.firebaseManager.friendsRoot.childByAppendingPath(entry.key)
                
                invitedFriend.observeSingleEventOfType(.Value, withBlock: { entry in
                    if entry.value is NSNull {
                        invitedFriend.setValue(["\(localUserName)":false])
                        
                        // update our local user entry
                        localUserFriendEntry.observeSingleEventOfType(.Value, withBlock: { entry in
                            if entry.value is NSNull {
                                localUserFriendEntry.setValue(["\(userNoSpace)":true])
                            }
                            else {
                                localUserFriendEntry.updateChildValues(["\(userNoSpace)":true])
                            }
                        })
                        self.addFriendTextfield.text = ""
                        self.errorLabel.text = ""
                    }
                    else {
                        let alreadyExists = invitedFriend.childByAppendingPath(localUserName)
                        alreadyExists.observeSingleEventOfType(.Value, withBlock: { entry in
                            if entry.value is NSNull {
                                invitedFriend.updateChildValues(["\(localUserName)":false])
                                
                                // update the local user entry
                                localUserFriendEntry.observeSingleEventOfType(.Value, withBlock: { entry in
                                    if entry.value is NSNull {
                                        localUserFriendEntry.setValue(["\(userNoSpace)":true])
                                    }
                                    else {
                                        localUserFriendEntry.updateChildValues(["\(userNoSpace)":true])
                                    }
                                })
                                self.addFriendTextfield.text = ""
                                self.errorLabel.text = ""
                            }
                            else {
                                if (entry.value as! FDataSnapshot).value as! Bool == true {
                                    self.errorLabel.text = "You're already friends with this user."
                                }
                                else {
                                    self.errorLabel.text = "You've already invited this user."
                                }
                                self.addFriendTextfield.text = ""
                            }
                        })
                    }
                })
            }
        })
    }
    
    // MARK: - Private Accept/Remove Friend Methods
    private func acceptFriendAtIndexPath(indexPath:NSIndexPath) {
        let acceptIndex = self.pendingFriends.startIndex.advancedBy(indexPath.row)
        let acceptUsername = self.pendingFriends.keys[acceptIndex]
        
        let localUserFriendEntry = self.firebaseManager.friendsRoot.childByAppendingPath(self.firebaseManager.localUser.username)
        
        localUserFriendEntry.updateChildValues([acceptUsername:true])
        self.pendingFriends.removeAtIndex(acceptIndex)
        self.friendsTable.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
    }
    
    private func removeFriendAtIndexPath(indexPath:NSIndexPath) {
        var localUserFriendEntry:Firebase!
        var removingFriendEntry:Firebase!
        var removingUsername:String!
        
        if indexPath.section == 0 {
            let removeIndex = self.friendsList.startIndex.advancedBy(indexPath.row)
            removingUsername = self.friendsList.keys[removeIndex]
        }
        else if indexPath.section == 1 {
            let removeIndex = self.pendingFriends.startIndex.advancedBy(indexPath.row)
            removingUsername = self.pendingFriends.keys[removeIndex]
        }
        
        localUserFriendEntry = self.firebaseManager.friendsRoot.childByAppendingPath(self.firebaseManager.localUser.username)
        removingFriendEntry = self.firebaseManager.friendsRoot.childByAppendingPath(removingUsername)
        
        localUserFriendEntry.observeSingleEventOfType(.Value, withBlock: { entry in
            if (entry.value is NSNull) == false {
                removingFriendEntry.observeSingleEventOfType(.Value, withBlock: { entry in
                    if (entry.value is NSNull) == false {
                        removingFriendEntry.childByAppendingPath(self.firebaseManager.localUser.username).removeValue()
                        localUserFriendEntry.childByAppendingPath(removingUsername).removeValue()
                        
                        if indexPath.section == 0 {
                            let removeIndex = self.friendsList.startIndex.advancedBy(indexPath.row)
                            self.friendsList.removeAtIndex(removeIndex)
                            self.friendsTable.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
                        }
                        else if indexPath.section == 1 {
                            let removeIndex = self.pendingFriends.startIndex.advancedBy(indexPath.row)
                            self.pendingFriends.removeAtIndex(removeIndex)
                            self.friendsTable.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
                        }
                        
                    }
                })
            }
        })
    }
    
    // MARK: - Configuration
    private func configureProfileLabels()
    {
        if firebaseManager != nil {
            usernameLabel.text = firebaseManager.localUser.username
            emailLabel.text = firebaseManager.localUser.email
        }
    }
    
    // MARK: - UITextFieldDelegate Methods
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: - UITableviewDelegate Methods
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return friendsList.count
        case 1:
            return pendingFriends.count
        default :
            return 0
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Friends"
        case 1:
            return "Pending Invites"
        default:
            return ""
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("idFriendCell", forIndexPath: indexPath)
        
        if indexPath.section == 0 {
            let friendIndex = friendsList.startIndex.advancedBy(indexPath.row)
            let friendName = friendsList.keys[friendIndex]
            
            cell.textLabel?.text = friendName
            cell.detailTextLabel?.text = ""
        }
        else if indexPath.section == 1 {
            let friendIndex = pendingFriends.startIndex.advancedBy(indexPath.row)
            let friendName = pendingFriends.keys[friendIndex]
            
            cell.textLabel?.text = friendName
            cell.detailTextLabel?.text = "Pending"
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {

    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        if indexPath.section == 0 { // Friends section
            return [removeAction]
        }
        else if indexPath.section == 1 { // Pending invites section
            let friendIndex = pendingFriends.startIndex.advancedBy(indexPath.row)
            let friendName = pendingFriends.keys[friendIndex]
            let accepted = pendingFriends.values[friendIndex]
            
            if accepted {
                return [removeAction]
            }
            else {
                return [rejectAction, acceptAction]
            }
        }
        
        return []
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
