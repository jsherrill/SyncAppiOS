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
    var youTubeUrl: String!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Entered Room")
        print(youTubeUrl)
        
        videoPlayer.playerVars = [
            "playsinline" : "1"
        ]
        
        //videoPlayer.loadVideoID("ayg9qnIPDVk");
        if let url = youTubeUrl {
            if let url = NSURL(string: url) {
            videoPlayer.loadVideoURL(url)
            }
        }
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

