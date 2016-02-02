//
//  LoginViewController.swift
//  GroupApp
//
//  Created by Jim Sherrill on 1/31/16.
//  Copyright © 2016 Jim Sherrill. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var usernameTextfield: UITextField!
    @IBOutlet var passwordTextfield: UITextField!
    @IBOutlet var errorLabel: UILabel!
    
    var firebaseManager:FirebaseManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        errorLabel.text = ""
        setDelegates()
        
        firebaseManager = FirebaseManager()
        firebaseManager.initFirebaseURLsFromPListKey("Info", plistURLKey: "FirebaseURL")
    }

    func setDelegates() {
        usernameTextfield.delegate = self
        passwordTextfield.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func loginButtonPressed(sender: AnyObject) {
        let username:String = usernameTextfield.text!
        let password:String = passwordTextfield.text!
        
        firebaseManager.authUser(username, password: password, withCompletionBlock: { error, authData in
            if error == nil {
                self.performSegueWithIdentifier("idLoginSegue", sender: self.firebaseManager)
            }
            else {
                if self.firebaseManager.userAuthError == FAuthenticationError.InvalidCredentials {
                    self.errorLabel.text = "Failed to log in. Incorrect username or password."
                }
                else if self.firebaseManager.userAuthError == FAuthenticationError.UserDoesNotExist {
                    self.errorLabel.text = "Failed to log in. User does not exist."
                }
            }
        })
        
        
    }
    
    // MARK: - UITextFieldDelegate Methods
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        print(segue.identifier)
        if segue.identifier == "idLoginSegue" {
            var controller = segue.destinationViewController as! UITabBarController

            var navController = controller.customizableViewControllers?[0] as! UINavigationController
            (navController.viewControllers[0] as! RoomListViewController).firebaseManager = self.firebaseManager
        }
    }
}
