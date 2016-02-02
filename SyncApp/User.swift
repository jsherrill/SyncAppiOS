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
    var userProperties = []
}