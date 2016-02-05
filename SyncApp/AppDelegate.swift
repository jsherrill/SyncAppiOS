//
//  AppDelegate.swift
//  SyncApp
//
//  Created by Matthew Ferri on 2/1/16.
//  Copyright © 2016 Matthew Ferri. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var firebaseManager: FirebaseManager?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: false)
        let darkness : CGFloat = 40.0 / 255.0
        UINavigationBar.appearance().barTintColor = UIColor(red: darkness, green: darkness, blue: darkness, alpha: 1)
        UINavigationBar.appearance().tintColor = UIColor.whiteColor()
        UINavigationBar.appearance().translucent = false
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()]
        UITabBar.appearance().translucent = false
        UITabBar.appearance().barTintColor = UIColor(red: darkness, green: darkness, blue: darkness, alpha: 1)
        
        firebaseManager = FirebaseManager()
        firebaseManager?.initFirebaseURLsFromPListKey("Info", plistURLKey: "FirebaseURL")
        
        if firebaseManager?.root.authData != nil {
            // we have an authorized session already so bypass the login screen
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let tabController = storyboard.instantiateViewControllerWithIdentifier("idTabController")
            
            self.window?.rootViewController = tabController
        }
        else {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let loginScreen = storyboard.instantiateViewControllerWithIdentifier("idLoginScreen")
            self.window?.rootViewController = loginScreen
        }
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        //firebaseManager?.root.unauth()
    }

}

