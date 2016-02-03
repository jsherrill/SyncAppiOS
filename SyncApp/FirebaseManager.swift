//
//  FirebaseManager.swift
//  GroupApp
//
//  Created by Jim Sherrill on 2/1/16.
//  Copyright © 2016 Jim Sherrill. All rights reserved.
//

import Foundation
import Firebase

class FirebaseManager {
    private var _isInitialized:Bool = false
    private var _firebaseURL:String!
    
    var root:Firebase!
    var userRoot:Firebase!
    var roomsRoot:Firebase!
    var membersRoot:Firebase!
    var localUser:User = User()
    var userAuthError:FAuthenticationError!
    
    func initFirebaseURLsFromPListKey(plistName:String, plistURLKey:String) {
        if let info = NSBundle.mainBundle().pathForResource(plistName, ofType: "plist") {
            let properties = NSDictionary(contentsOfFile: info)
            _firebaseURL = properties?.valueForKey(plistURLKey) as! String
            _initFirebaseURLs()
            _isInitialized = true
        }
    }
    
    private func _initFirebaseURLs() {
        if _firebaseURL.characters.count != 0 {
            root = Firebase(url: _firebaseURL)
            userRoot = root.childByAppendingPath("users")
            roomsRoot = root.childByAppendingPath("rooms")
            membersRoot = root.childByAppendingPath("members")
        }
    }
    
    func authUser(username:String, password:String, withCompletionBlock block: ((NSError!, FAuthData!) -> Void)!) -> Bool {
        userAuthError = FAuthenticationError.Unknown
        var authSuccess = true
        if _isInitialized == true {
            let userRef = userRoot.childByAppendingPath(username)

            // check if the user entry exists
            userRef.observeSingleEventOfType(.Value, withBlock: { entry in
                if entry.value is NSNull {
                    self.userAuthError = FAuthenticationError.UserDoesNotExist
                    authSuccess = false
                }
                else {
                    let email:String = entry.value.valueForKey("email") as! String
                    
                    self.root.authUser(email, password: password, withCompletionBlock: { error, authData in
                        if error == nil {
                            self.localUser.firebaseAuthData = authData
                            self.localUser.username = username
                            self.localUser.password = password
                            self.localUser.email = email
                        }
                        else {
                            self.userAuthError = FAuthenticationError.InvalidCredentials
                            authSuccess = false
                        }
                        
                        block(error, authData)
                    })
                }
            })
        }
        
        return authSuccess
    }
    
    func createUser(username:String, password:String, email:String, userProperties:[String:String], withValueCompletionBlock block: ((NSError!, [NSObject : AnyObject]!) -> Void)!) {
        let userRef = userRoot.childByAppendingPath(username)
        
        userRef.observeSingleEventOfType(.Value, withBlock: { userEntry in
            if userEntry.value is NSNull {
                
                self.root.createUser(email, password: password,
                    withValueCompletionBlock: { didError, result in
                        
                        if didError == nil {
                            self.root.childByAppendingPath("users/\(username)").setValue(userProperties)
                        }
                        block(didError, result)
                })
            }
        })
    }
}