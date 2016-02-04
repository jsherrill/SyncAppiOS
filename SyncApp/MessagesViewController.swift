//
//  MessagesViewController.swift
//  SyncApp
//
//  Created by Matthew Ferri on 2/3/16.
//  Copyright © 2016 Matthew Ferri. All rights reserved.
//

import UIKit
import Foundation
import JSQMessagesViewController
import Firebase

class MessagesViewController: JSQMessagesViewController {
    
//    let incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(UIColor(red: 10/255, green: 180/255, blue: 230/255, alpha: 1.0))
//    let outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImageWithColor(UIColor.lightGrayColor())
//    var messages = [JSQMessage]()
    
    var messages = [Message]()
    var avatars = Dictionary<String, UIImage>()
    var outgoingBubbleImageView = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
    var incomingBubbleImageView = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleGreenColor())
    var senderImageUrl: String!
    var batchMessages = true
    
    var roomId: String!
    var firebaseManager: FirebaseManager!
    //var ref: Firebase!

    override func viewDidLoad() {
        super.viewDidLoad()

//        firebaseManager = FirebaseManager()
//        firebaseManager.initFirebaseURLsFromPListKey("Info", plistURLKey: "FirebaseURL")
//        roomId = "-K9_ocER7aCHWKhwodwl"
        senderImageUrl = "http://orig04.deviantart.net/3b00/f/2010/249/d/3/free_50x50_white_kitty_icon_by_zeldakinz-d2y6vrp.png"
        automaticallyScrollsToMostRecentMessage = true
        senderId = firebaseManager.localUser.username
        senderDisplayName = senderId
        
        // Do any additional setup after loading the view.
        
        let messagesRootForRoom = firebaseManager.messagesRoot.childByAppendingPath(roomId)
        messagesRootForRoom.queryLimitedToLast(25).observeEventType(FEventType.ChildAdded, withBlock: { (snapshot) in
              let text = snapshot.value["text"] as? String
              let sender = snapshot.value["sender"] as? String
              let imageUrl = "http://orig04.deviantart.net/3b00/f/2010/249/d/3/free_50x50_white_kitty_icon_by_zeldakinz-d2y6vrp.png" //snapshot.value["imageUrl"] as? String

            let message = Message(text: text, sender: sender, imageUrl: imageUrl)
            self.messages.append(message)
            self.finishReceivingMessage()
        })
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        //collectionView?.collectionViewLayout.springinessEnabled = true
    }
    
    func sendMessage(text: String!, sender: String!) {
        // *** STEP 3: ADD A MESSAGE TO FIREBASE
        let messagesRootForRoom = firebaseManager.messagesRoot.childByAppendingPath(roomId)
        messagesRootForRoom.childByAutoId().setValue([
            "text":text,
            "sender":sender,
            "imgUrl":senderImageUrl
            ])
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func reloadMessagesView() {
        self.collectionView?.reloadData()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func receivedMessagePressed(sender: UIBarButtonItem) {
        // Simulate reciving message
        showTypingIndicator = !showTypingIndicator
        scrollToBottomAnimated(true)
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        sendMessage(text, sender: senderId)
        
        finishSendingMessage()
    }
    
    override func didPressAccessoryButton(sender: UIButton!) {
        print("Camera pressed!")
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        
        let message = messages[indexPath.item]
        
        if message.senderId() == senderId {
            return outgoingBubbleImageView
        }
        
        return incomingBubbleImageView
        
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
                let message = messages[indexPath.item]
                let image = UIImage(named: "free_50x50_white_kitty_icon_by_zeldakinz-d2y6vrp.png")
                //if let avatar = avatars[message.senderId()] {
                    return JSQMessagesAvatarImage(avatarImage: image, highlightedImage: image, placeholderImage: image)
                //} else {
                    //setupAvatarImage(message.sender(), imageUrl: message.imageUrl(), incoming: true)
                    return JSQMessagesAvatarImage(avatarImage: image, highlightedImage: image, placeholderImage: image)
                //}
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        
        let message = messages[indexPath.item]
        if message.senderId() == senderId {
            cell.textView?.textColor = UIColor.blackColor()
        } else {
            cell.textView?.textColor = UIColor.whiteColor()
        }
        
        // TODO: See if this line crashes
        let attributes = [NSForegroundColorAttributeName:cell.textView?.textColor as! AnyObject, NSUnderlineStyleAttributeName: 1]
        cell.textView?.linkTextAttributes = attributes
        
        //        cell.textView.linkTextAttributes = [NSForegroundColorAttributeName: cell.textView.textColor,
        //            NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle]
        self.collectionView?.collectionViewLayout.invalidateLayout()
        return cell
    }
    
    // View  usernames above bubbles
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.item];
        
        // Sent by me, skip
        if message.senderId() == senderId {
            return nil;
        }
        
        // Same as previous sender, skip
        if indexPath.item > 0 {
            let previousMessage = messages[indexPath.item - 1];
            if previousMessage.senderId() == message.senderId() {
                return nil;
            }
        }
        
        return NSAttributedString(string:message.senderId())
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        let message = messages[indexPath.item]
        
        // Sent by me, skip
        if message.senderId() == senderId {
            return CGFloat(0.0);
        }
        
        // Same as previous sender, skip
        if indexPath.item > 0 {
            let previousMessage = messages[indexPath.item - 1];
            if previousMessage.senderId() == message.senderId() {
                return CGFloat(0.0);
            }
        }
        
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }

}


