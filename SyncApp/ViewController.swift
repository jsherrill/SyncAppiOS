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

    //var firebaseRef : Firebase!
    @IBOutlet var videoPlayer: YouTubePlayerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let firebaseRef = Firebase(url: "https://popping-fire-2047.firebaseio.com")
        // Do any additional setup after loading the view, typically from a nib.
        
        firebaseRef.authUser("mattferri@gmail.com", password:"password") {
            error, authData in
            if error != nil {
                // Something went wrong. :(
            } else {
                // Authentication just completed successfully :)
                // The logged in user's unique identifier
                print(authData.uid)
                // Create a new user dictionary accessing the user's info
                // provided by the authData parameter
                let newUser = [
                    "provider": authData.provider,
                    "displayName": authData.providerData["email"] as? NSString as? String
                ]
                
                print(authData)
                print(authData.providerData)
                // Create a child path with a key set to the uid underneath the "users" node
                // This creates a URL path like the following:
                //  - https://<YOUR-FIREBASE-APP>.firebaseio.com/users/<uid>
                firebaseRef.childByAppendingPath("users")
                    .childByAppendingPath(authData.uid).setValue(newUser)
            }
        }
        
        var roomRef = firebaseRef.childByAppendingPath("rooms")
        
        // room:
        //      id
        //      url
        //      users
        //          name
        //          ready
        var room = ["url" : "test"]
        var rooms = [ "1" : room ]
        roomRef.setValue(rooms)
        
        videoPlayer.loadVideoID("ayg9qnIPDVk");
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func playerReady(videoPlayer: YouTubePlayerView) {
        videoPlayer.play()
    }
    
    func playerStateChanged(videoPlayer: YouTubePlayerView, playerState: YouTubePlayerState) {
        
    }
    
    func playerQualityChanged(videoPlayer: YouTubePlayerView, playbackQuality: YouTubePlaybackQuality) {
        
    }

}

