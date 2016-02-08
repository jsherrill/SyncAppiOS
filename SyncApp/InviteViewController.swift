//
//  InviteViewController.swift
//  SyncApp
//
//  Created by Jim Sherrill on 2/7/16.
//  Copyright © 2016 Matthew Ferri. All rights reserved.
//

import UIKit
import Firebase
import YouTubePlayer

class InviteViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var inviteTable: UITableView!
    var firebaseManager:FirebaseManager!
    var inviteRooms:NSMutableArray!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        inviteRooms = NSMutableArray()
        
        firebaseManager = FirebaseManager()
        firebaseManager.initFirebaseURLsFromPListKey("Info", plistURLKey: "FirebaseURL", checkForUserAuth: true)
        
        let invites = firebaseManager.userRoot.childByAppendingPath("\(firebaseManager.localUser.username)/invites")
        
        invites.observeEventType(.Value, withBlock: { entry in
            if (entry.value is NSNull) == false {
                if entry.childrenCount > 0 {
                    let invitesEnum = entry.children
                    
                    while let invite = invitesEnum.nextObject() {
                        let roomName = invite.key
                        let room = self.firebaseManager.roomsRoot.childByAppendingPath(roomName)
                        room.observeEventType(.Value, withBlock: { entry in
                            if (entry.value is NSNull) == false {
                                let roomName = entry.childSnapshotForPath("roomName").value as! String
                                let url = entry.childSnapshotForPath("youTubeUrl").value as! String
                                self.inviteRooms.addObject(["roomName":roomName, "roomID":entry.key, "url":url])
                                self.inviteTable.reloadData()
                            }
                        })
                    }
                }

            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return inviteRooms.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("idRoomCellWithImage", forIndexPath: indexPath) as! RoomListViewTableViewCell
        
        let inviteEntry = inviteRooms[indexPath.row]
        let roomName = inviteEntry["roomName"] as? String
        let youtubeURL = inviteEntry["url"] as? String
        var youTubeImageUrl = "https://img.youtube.com/vi/<insert-youtube-video-id-here>/mqdefault.jpg"
        
        if let url = NSURL(string: youtubeURL!) {
            if let youTubeId = videoIDFromYouTubeURL(url) {
                youTubeImageUrl = youTubeImageUrl.stringByReplacingOccurrencesOfString("<insert-youtube-video-id-here>", withString: youTubeId)
                if let youTubeImageUrl = NSURL(string: youTubeImageUrl) {
                    cell.roomImageView.kf_setImageWithURL(youTubeImageUrl)
                }
            }
        }
        
        cell.roomTitleLabel?.text = roomName
        cell.detailTextLabel?.text = ""
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 90
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "idEnterRoom" {
            if let room = segue.destinationViewController as? ViewController {
                if let index = inviteTable.indexPathForSelectedRow?.row {
                    room.firebaseManager = self.firebaseManager
                    
                    let inviteEntry = inviteRooms[index]
                    let url = inviteEntry["url"] as? String
                    room.youTubeUrl = url
                    room.roomId = inviteEntry["roomID"] as? String
                    
                    inviteRooms.removeObjectAtIndex(index)
                    inviteTable.deleteRowsAtIndexPaths([inviteTable.indexPathForSelectedRow!], withRowAnimation: UITableViewRowAnimation.Fade)
                    
                    enterRoom(room.roomId)
                }
            }
        }
    }
    
    func enterRoom(roomId:String) {
        let uniqueRoomInMembers = firebaseManager.membersRoot.childByAppendingPath(roomId)
        let memberInRoom = uniqueRoomInMembers.childByAppendingPath(firebaseManager.localUser.username)
        memberInRoom.setValue([firebaseManager.localUser.username:["isReady":false, "playerState":"Unstarted"]])
        
        let inviteRef = firebaseManager.root.childByAppendingPath("invites/\(roomId)/\(firebaseManager.localUser.username)")
        inviteRef.setValue([])
        
        let userInviteRef = firebaseManager.userRoot.childByAppendingPath("\(firebaseManager.localUser.username)/invites/\(roomId)")
        userInviteRef.setValue([])
    }

}
