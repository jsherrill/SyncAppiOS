//
//  User.swift
//  GroupApp
//
//  Created by Jim Sherrill on 2/2/16.
//  Copyright © 2016 Jim Sherrill. All rights reserved.
//

import Foundation
import Firebase

class User : NSObject {
    var firebaseAuthData:FAuthData!
    var username:String!
    var password:String!
    var email:String!
    var userProperties:[String:AnyObject] = [String:AnyObject]()
    var isReady:Bool!
    
    func serialize() -> [String:AnyObject] {
        return [ "userName":username, "password":password, "email":email, "userProperties":userProperties, "isReady":isReady]
    }
    
    func deserialize(userParams:[String:AnyObject]) {
        username = userParams["userName"] as? String
        password = userParams["password"] as? String
        email = userParams["email"] as? String
        userProperties = (userParams["userProperties"] as? [String:AnyObject])!
        isReady = userParams["isReady"] as? Bool
    }
}