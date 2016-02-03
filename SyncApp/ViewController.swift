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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.hidesBarsOnTap = true
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
                
                while let member = memberEnumerator.nextObject() as? FDataSnapshot {
                    
                    let memberDescription = NSMutableDictionary()
                    memberDescription["name"] = member.key
                    memberDescription["state"] = member.value
                    
                    self.members.addObject(memberDescription)
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
    
    func updateMemberStatus(status: String!) {
        let uniqueRoomInMembers = firebaseManager.membersRoot.childByAppendingPath(roomId)
        let memberInRoom = uniqueRoomInMembers.childByAppendingPath(firebaseManager.localUser.username)
        memberInRoom.setValue(status)
    }

    func playerReady(videoPlayer: YouTubePlayerView) {
        //videoPlayer.play()
        self.updateMemberStatus("Player loaded")
    }
    
    func playerStateChanged(videoPlayer: YouTubePlayerView, playerState: YouTubePlayerState) {
        print(playerState)
        //self.updateMemberStatus(playerState.rawValue)
        switch playerState {
        case .Buffering:
            self.updateMemberStatus("Buffering")
        case .Ended:
            self.updateMemberStatus("Ended")
        case .Paused:
            self.updateMemberStatus("Paused")
        case .Playing:
            self.updateMemberStatus("Playing")
        case .Queued:
            self.updateMemberStatus("Queued")
        case .Unstarted:
            self.updateMemberStatus("Unstarted")
        default:
            break;
        }
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
        cell.detailTextLabel?.text = member["state"] as? String
        
        return cell
    }

}

