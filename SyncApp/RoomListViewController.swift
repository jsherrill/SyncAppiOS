//
//  RoomListViewController.swift
//  GroupApp
//
//  Created by Jim Sherrill on 2/1/16.
//  Copyright © 2016 Jim Sherrill. All rights reserved.
//

import UIKit
import Firebase

class RoomListViewController: UIViewController, UITableViewDelegate {
    var firebaseManager:FirebaseManager!
    
    @IBOutlet var roomsTable: UITableView!
    var roomCount = 1
    var rooms:NSMutableArray = NSMutableArray()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
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
        let cell = tableView.dequeueReusableCellWithIdentifier("idRoomCell", forIndexPath: indexPath)

        let roomEntry = rooms[indexPath.row]
        let userCount = roomEntry["userCount"] as? Int
        
        //var roomDescription = roomEntry.valueForKey(key: roomEntry.key)
        
        // Configure the cell...
        cell.textLabel?.text = roomEntry["roomName"] as? String
        cell.detailTextLabel?.text = "\(userCount!) User(s)"
        
        return cell
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
        memberInRoom.setValue(0)
    }
    
    @IBAction func createdRoom(segue:UIStoryboardSegue) {
        
    }
}
