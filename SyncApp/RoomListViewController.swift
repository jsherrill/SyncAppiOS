//
//  RoomListViewController.swift
//  GroupApp
//
//  Created by Jim Sherrill on 2/1/16.
//  Copyright © 2016 Jim Sherrill. All rights reserved.
//

import UIKit
import Firebase
import Kingfisher
import YouTubePlayer

class RoomListViewController: UIViewController, UITableViewDelegate {
    var firebaseManager:FirebaseManager!
    
    @IBOutlet var roomsTable: UITableView!
    @IBOutlet var invitesBarButton: UIBarButtonItem!
    var roomCount = 1
    var rooms:NSMutableArray = NSMutableArray()
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        if firebaseManager == nil {
            firebaseManager = FirebaseManager()
            firebaseManager.initFirebaseURLsFromPListKey("Info", plistURLKey: "FirebaseURL", checkForUserAuth: true)
        }
        
        let invites = firebaseManager.userRoot.childByAppendingPath("\(firebaseManager.localUser.username)/invites")
        invites.observeEventType(.Value, withBlock: { entry in
            if (entry.value is NSNull) == false {
                if entry.childrenCount > 0 {
                    self.invitesBarButton.title = "Invites (\(entry.childrenCount))"
                    self.invitesBarButton.enabled = true
                }
                else {
                    self.invitesBarButton.enabled = false
                    self.invitesBarButton.title = ""
                }
            }
            else {
                self.invitesBarButton.enabled = false
                self.invitesBarButton.title = ""
            }
        })
        
        firebaseManager.roomsRoot.observeEventType(.Value, withBlock: { entry in
            if entry.value is NSNull {
                print ("no rooms")
            }
            else {
                let roomEnumerator = entry.children
                self.rooms.removeAllObjects()
                while let room = roomEnumerator.nextObject() as? FDataSnapshot {
                    var roomDescription = NSMutableDictionary()
                    roomDescription["roomName"] = room.childSnapshotForPath("roomName").value
                    
                    var roomMembers = room.childSnapshotForPath("members")
                    roomDescription["userCount"] = roomMembers.childrenCount
                    
                    roomDescription["youTubeUrl"] = room.childSnapshotForPath("youTubeUrl").value
                    roomDescription["roomId"] = room.key
                    
                    self.rooms.addObject(roomDescription)
                }
                self.roomsTable.reloadData()
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return rooms.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("idRoomCellWithImage", forIndexPath: indexPath) as! RoomListViewTableViewCell
        
        let roomEntry = rooms[indexPath.row]
        let roomName = roomEntry["roomName"] as? String
        let youTubeUrl = roomEntry["youTubeUrl"] as? String
        var youTubeImageUrl = "https://img.youtube.com/vi/<insert-youtube-video-id-here>/mqdefault.jpg"
        
        if let url = NSURL(string: youTubeUrl!) {
            if let youTubeId = videoIDFromYouTubeURL(url) {
                youTubeImageUrl = youTubeImageUrl.stringByReplacingOccurrencesOfString("<insert-youtube-video-id-here>", withString: youTubeId)
                if let youTubeImageUrl = NSURL(string: youTubeImageUrl) {
                    cell.roomImageView.kf_setImageWithURL(youTubeImageUrl)
                }
            }
        }
        
        cell.roomTitleLabel?.text = roomName
        
//        let cell = tableView.dequeueReusableCellWithIdentifier("idRoomCell", forIndexPath: indexPath)
//
//        let roomEntry = rooms[indexPath.row]
//        let userCount = roomEntry["userCount"] as? Int
//        
//        //var roomDescription = roomEntry.valueForKey(key: roomEntry.key)
//        
//        // Configure the cell...
//        cell.textLabel?.text = roomEntry["roomName"] as? String
//        cell.detailTextLabel?.text = "\(userCount!) User(s)"
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 90
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "idShowCreateRoom" {
            (segue.destinationViewController as! CreateRoomViewController).firebaseManager = self.firebaseManager
        } else if segue.identifier == "idEnterRoom" {
            if let room = segue.destinationViewController as? ViewController {
                if let index = roomsTable.indexPathForSelectedRow?.row {
                    room.firebaseManager = self.firebaseManager
                    room.youTubeUrl = rooms[index]["youTubeUrl"] as? String
                    room.roomId = rooms[index]["roomId"] as? String
                    enterRoom(room.roomId)
                }
            }
        }
    }
    
    func enterRoom(roomId:String!) {
        let uniqueRoomInMembers = firebaseManager.membersRoot.childByAppendingPath(roomId)
        let memberInRoom = uniqueRoomInMembers.childByAppendingPath(firebaseManager.localUser.username)
        memberInRoom.setValue([firebaseManager.localUser.username:["isReady":false, "playerState":"Unstarted"]])
    }
    
    @IBAction func logoutPressed(sender: AnyObject) {
        firebaseManager.root.unauth()
        self.performSegueWithIdentifier("idLogoutSegue", sender: self)
    }
    
    @IBAction func createdRoom(segue:UIStoryboardSegue) {
        
    }
}
