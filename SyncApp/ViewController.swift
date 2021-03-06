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
import SnapKit

class ViewController: UIViewController, YouTubePlayerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var videoPlayer: YouTubePlayerView!
    @IBOutlet weak var userTable: UITableView!
    @IBOutlet var roomNavItem: UINavigationItem!
    
    var firebaseManager : FirebaseManager!
    var messagesViewController:MessagesViewController!
    
    var members:NSMutableArray = NSMutableArray()
    var invitedMembers:[String] = [String]()
    var roomId: String!
    var youTubeUrl: String!
    
    var userTableHidden: Bool = false
    var hasStarted: Bool = false
    
    // MARK: Creation Methods
    
    func createMessagesViewController() {
        messagesViewController = MessagesViewController()
        messagesViewController.roomId = roomId
        messagesViewController.firebaseManager = firebaseManager
        
        self.addChildViewController(messagesViewController)
        self.view.addSubview(messagesViewController.view)
        
        messagesViewController.view!.snp_remakeConstraints { (make) -> Void in
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view.snp_bottom).offset(self.view.frame.height)
            make.top.equalTo(self.view.snp_bottom)
        }
    }
    
    func createYouTubePlayer() {
        videoPlayer.delegate = self
        videoPlayer.playerVars = [
            "playsinline" : "1"
        ]
        
        if let url = youTubeUrl {
            if let url = NSURL(string: url) {
                videoPlayer.loadVideoURL(url)
            }
        }
    }
    
    func createCloseButton() {
        let button: UIButton = UIButton(frame: CGRectMake(0, 0, 25, 25))
        button.setTitle("X", forState: .Normal)
        
        button.titleLabel?.textColor = UIColor.whiteColor()
        button.backgroundColor = UIColor.redColor()
        button.addTarget(self, action: "closeButtonTapped:", forControlEvents: .TouchUpInside)
        
        self.view.addSubview(button)
        
        button.snp_makeConstraints { (make) -> Void in
            make.top.left.equalTo(self.view).offset(5)
            make.width.height.equalTo(25)
        }
    }
    
    func closeButtonTapped(sender: UIButton!) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: View Cycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //self.view.backgroundColor = UIColor.blueColor()
        
        var gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.view.bounds
        gradientLayer.colors = [UIColor(red: 1, green: 1, blue: 1, alpha: 0).CGColor, UIColor(red: 1, green: 1, blue: 1, alpha: 1).CGColor, UIColor(red: 1, green: 1, blue: 1, alpha: 1).CGColor]
        gradientLayer.locations = [0, 0.8, 1]
        //gradientLayer.startPoint = CGPointMake(0.0, 1.0)
        //gradientLayer.endPoint = CGPointMake(0.0, 0.0)
        
        //self.userTable.layer.addSublayer(gradientLayer)
        
        self.createMessagesViewController()
        self.createCloseButton()
        
       // self.messagesViewController.collectionView?.layer.mask = gradientLayer
        self.messagesViewController.view.layer.mask = gradientLayer
        //self.showUserTable()
        
        //self.navigationController?.hidesBarsOnTap = true
        
        let roomName = firebaseManager.roomsRoot.childByAppendingPath("\(roomId)/roomName")
        roomName.observeSingleEventOfType(.Value, withBlock: { entry in
            if !(entry.value is NSNull) {
                self.roomNavItem.title = entry.value as? String
            }
        })
        
        self.createYouTubePlayer()
        
        if let roomId = roomId {
            let invitedUsersRef = firebaseManager.root.childByAppendingPath("invites/\(roomId)")
            invitedUsersRef.observeEventType(.Value, withBlock: { entry in
                if (entry.value is NSNull) == false {
                    let invitedEnum = entry.children
                    self.invitedMembers.removeAll()
                    
                    while let invitedUser = invitedEnum.nextObject() as? FDataSnapshot {
                        self.invitedMembers.append(invitedUser.key)
                    }
                    self.userTable.reloadData()
                }
                else {
                    self.invitedMembers.removeAll()
                    self.userTable.reloadData()
                }
            })
            
            let membersForRoomRoot = firebaseManager.membersRoot.childByAppendingPath(roomId)
            membersForRoomRoot.observeEventType(.Value, withBlock: { entry in
            if entry.value is NSNull {
                print ("no members")
            }
            else {
                let memberEnumerator = entry.children
                self.members.removeAllObjects()
                
                var isEveryoneReady = true
                var isEveryonePlaying = true
                
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
                    
                    if user == self.firebaseManager.localUser.username {
                        myState = state
                    }
                    
                    if isReady == false {
                        isEveryoneReady = false
                    }
                    
                    if self.hasStarted {
                        if user == self.firebaseManager.localUser.username {
                            if myState != "Playing" && isReady == true {
                                self.updateMemberReadyStatus(false)
                                isEveryoneReady = false
                            }
                            else if myState == "Playing" && isReady == false {
                                self.updateMemberReadyStatus(true)
                            }
                        }
                    }
                    
                    self.members.addObject(memberDescription)
                }
                
                if isEveryoneReady == true && self.hasStarted == false {
                    self.videoPlayer.play()
                    self.userTableHidden = true
                    self.view.setNeedsUpdateConstraints()
                    self.hasStarted = true
                    //self.showMessagesViewController()
                }
                
                if self.hasStarted {
                    if isEveryoneReady {

                    }
                    
                }
                
                self.userTable.reloadData()
            }
        })
            
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.view.setNeedsUpdateConstraints()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Update view constraints
    
    override func updateViewConstraints() {
        
        if self.userTableHidden {
            self.hideUserTable()
            self.showMessagesViewController()
        } else {
            self.showUserTable()
        }
        
        super.updateViewConstraints()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
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
    
    // MARK: YouTube Delegate Methods
    
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
    
    // MARK: TableView Delegate Methods
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if invitedMembers.count == 0 {
            return 1
        }
        else {
            return 2
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return ""
        case 1:
            return "Invited Users"
        default:
            return ""
        }
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return members.count
        case 1:
            return invitedMembers.count
        default:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("idUserCell", forIndexPath: indexPath)
        
        if indexPath.section == 0 {
            let member = members[indexPath.row]
            
            cell.textLabel?.text = member["name"] as? String
            cell.detailTextLabel?.text = member["state"] as? String
            
            if member["isReady"] as? Bool == true {
                cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            }
            else {
                cell.accessoryType = UITableViewCellAccessoryType.None
            }
        }
        else if indexPath.section == 1 {
            let member = invitedMembers[indexPath.row]
            cell.textLabel?.text = member
            cell.detailTextLabel?.text = ""
        }

        return cell
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            let frame = tableView.frame
            
            let button: UIButton = UIButton(frame: CGRectMake(0, 0, frame.width, 44))
            button.setTitle("Not Ready", forState: .Normal)
            button.setTitle("Ready", forState: .Selected)
            button.setTitle("Ready", forState: [.Selected, .Highlighted])
            
            button.titleLabel?.textColor = UIColor.whiteColor()
            button.backgroundColor = UIColor.redColor()
            button.addTarget(self, action: "readyButtonTapped:", forControlEvents: .TouchUpInside)
            
            button.setBackgroundColor(UIColor.redColor(), forUIControlState: .Normal)
            button.setBackgroundColor(UIColor.greenColor(), forUIControlState: .Selected)
            button.setBackgroundColor(UIColor.greenColor(), forUIControlState: [.Selected, .Highlighted])
            
            let headerView: UIView = UIView(frame: CGRectMake(0, 0, frame.width, 44))
            headerView.addSubview(button);
            
            return headerView
        }
        else {
            return tableView.tableHeaderView
        }
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    func readyButtonTapped(sender: UIButton!) {
        sender.selected = !sender.selected
        firebaseManager.localUser.isReady = !firebaseManager.localUser.isReady
        updateMemberReadyStatus(firebaseManager.localUser.isReady)
    }
    
    // MARK: Hide / Show Views
    
    func showMessagesViewController() {
        
        UIView.animateWithDuration(0.5) {
            self.messagesViewController.view!.snp_remakeConstraints { (make) -> Void in
                make.left.equalTo(self.view.snp_left)
                make.right.equalTo(self.view.snp_right)
                make.bottom.equalTo(self.view.snp_bottom)
                make.top.equalTo(self.view.snp_top)
            }
        }
    }
    
    func showUserTable() {
        
        UIView.animateWithDuration(0.5) {
            self.userTable.snp_remakeConstraints { (make) -> Void in
                make.left.equalTo(self.view.snp_left)
                make.top.equalTo(self.videoPlayer.snp_bottom)
                make.right.equalTo(self.view.snp_right)
                make.bottom.equalTo(self.view.snp_bottom)
            }
        }
    }
    
    func hideUserTable() {
        
        UIView.animateWithDuration(0.5) {
            self.userTable.snp_remakeConstraints { (make) -> Void in
                make.left.equalTo(self.view.snp_left)
                make.top.equalTo(self.view.snp_bottom)
                make.right.equalTo(self.view.snp_right)
                make.bottom.equalTo(self.view.snp_bottom).offset(self.view.frame.height)
            }
        }
    }
    
}

extension UIButton {
    private func imageWithColor(color: UIColor) -> UIImage {
        let rect = CGRectMake(0.0, 0.0, 1.0, 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    func setBackgroundColor(color: UIColor, forUIControlState state: UIControlState) {
        self.setBackgroundImage(imageWithColor(color), forState: state)
    }
}


