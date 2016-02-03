//
//  Message.swift
//  FireChat-Swift
//
//  Created by Katherine Fang on 8/20/14.
//  Copyright (c) 2014 Firebase. All rights reserved.
//

import Foundation
import JSQMessagesViewController

class Message : NSObject, JSQMessageData {
    var text_: String
    var sender_: String
    var date_: NSDate
    var imageUrl_: String?
    
    convenience init(text: String?, sender: String?) {
        self.init(text: text, sender: sender, imageUrl: nil)
    }
    
    init(text: String?, sender: String?, imageUrl: String?) {
        self.text_ = text!
        self.sender_ = sender!
        self.date_ = NSDate()
        self.imageUrl_ = imageUrl
    }
    
    func senderId() -> String! {
        return sender_;
    }
    
    func senderDisplayName() -> String! {
        return sender_;
    }
    
    func date() -> NSDate! {
        return date_;
    }
    
    func isMediaMessage() -> Bool {
        return false
    }
    
    func messageHash() -> UInt {
        return 100
    }
    
    func imageUrl() -> String? {
        return imageUrl_;
    }

    func text() -> String! {
        return text_;
    }
    
    func media() -> JSQMessageMediaData! {
        return nil
    }
}