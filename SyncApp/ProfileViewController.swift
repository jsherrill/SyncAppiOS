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
    var firebaseManager:FirebaseManager!
    
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
        
        let userFriends = firebaseManager.friendsRoot.childByAppendingPath(firebaseManager.localUser.username)
        
        friendsList = [String:Bool]()

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
                    let accepted = friend.value as! Bool
                    
                    self.friendsList[friendName] = accepted
                }
                self.friendsTable.reloadData()
            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
                                localUserFriendEntry.setValue(["\(userNoSpace)":false])
                            }
                            else {
                                localUserFriendEntry.updateChildValues(["\(userNoSpace)":false])
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
                                        localUserFriendEntry.setValue(["\(userNoSpace)":false])
                                    }
                                    else {
                                        localUserFriendEntry.updateChildValues(["\(userNoSpace)":false])
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
        return friendsList.count
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Friends"
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("idFriendCell", forIndexPath: indexPath)
        
        let friendIndex = friendsList.startIndex.advancedBy(indexPath.row)
        let friendName = friendsList.keys[friendIndex]
        let accepted = friendsList.values[friendIndex]
        
        cell.textLabel?.text = friendName
        
        if accepted == true {
            cell.detailTextLabel?.text = ""
        }
        else {
            cell.detailTextLabel?.text = "Pending"
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            let removeIndex = friendsList.startIndex.advancedBy(indexPath.row)
            let removingUsername = friendsList.keys[removeIndex]
            
            let localUserFriendEntry = firebaseManager.friendsRoot.childByAppendingPath(firebaseManager.localUser.username)
            let removingFriendEntry = firebaseManager.friendsRoot.childByAppendingPath(removingUsername)
            
            localUserFriendEntry.observeSingleEventOfType(.Value, withBlock: { entry in
                if (entry.value is NSNull) == false {
                    removingFriendEntry.observeSingleEventOfType(.Value, withBlock: { entry in
                        if (entry.value is NSNull) == false {
                            removingFriendEntry.childByAppendingPath(self.firebaseManager.localUser.username).removeValue()
                            localUserFriendEntry.childByAppendingPath(removingUsername).removeValue()
                            self.friendsList.removeAtIndex(removeIndex)
                            self.friendsTable.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
                        }
                    })
                }
            })
        }
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
