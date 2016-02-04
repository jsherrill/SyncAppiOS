//
//  CreateAccountViewController.swift
//  GroupApp
//
//  Created by Jim Sherrill on 1/31/16.
//  Copyright © 2016 Jim Sherrill. All rights reserved.
//

import UIKit
import Firebase

class CreateAccountViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var firstNameTextField: UITextField!
    @IBOutlet var lastNameTextField: UITextField!
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var verifyPasswordTextField: UITextField!
    @IBOutlet var errorLabel: UILabel!
    @IBOutlet var usernameTextField: UITextField!
    
    let maxFirstNameLength = 35
    let maxLastNameLength = 50
    let minPasswordLength = 8
    let maxPasswordLength = 25
    let maxUsernameLength = 25
    
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
        firstNameTextField.delegate = self
        lastNameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        verifyPasswordTextField.delegate = self
        usernameTextField.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func createAccountPressed(sender: AnyObject) {
        let firstName:String = firstNameTextField.text!
        let lastName:String = lastNameTextField.text!
        let email:String = emailTextField.text!
        let username:String = usernameTextField.text!
        let password:String = passwordTextField.text!
        let verifyPassword:String = verifyPasswordTextField.text!
        
        var error:Bool = false
        var errorMessage:String = "Error: "
        
        //  First Name error handling
        if firstName.characters.count == 0 {
            errorMessage += "Missing First Name;\n"
            error = true
        }
        else if firstName.characters.count > maxFirstNameLength {
            errorMessage += "First Name exceeds character limit of \(maxFirstNameLength);\n"
            error = true
        }
        else {
            // TODO: make sure we only accept valid symbols
        }
        
        // Last Name error handling
        if lastName.characters.count == 0 {
            errorMessage += "Missing Last Name;\n"
            error = true
        }
        else if lastName.characters.count > maxLastNameLength {
            errorMessage += "Last Name exceeds character limit of \(maxLastNameLength);\n"
            error = true
        }
        
        // Email Address error handling
        if email.characters.count == 0 {
            errorMessage += "Missing Email Address;\n"
            error = true
        }
        else {
            // process email to make sure no spaces
        }
        
        // Password error handling
        if password.characters.count == 0 || verifyPassword.characters.count == 0 {
            error = true
            if password.characters.count == 0 {
                errorMessage += "Password not set;\n"
            }
            if verifyPassword.characters.count == 0 {
                errorMessage += "Verify password not set;\n"
            }
        }
        else {
            if password.characters.count < minPasswordLength {
                error = true
                errorMessage += "Password does not meet minimum character limit of \(minPasswordLength);\n"
            }
            else if password.characters.count > maxPasswordLength {
                error = true
                errorMessage += "Password exceeds maximum character limit of \(maxPasswordLength);\n"
            }
            
            if password != verifyPassword {
                error = true
                errorMessage += "Verify password does not match;\n"
            }
        }
        
        // Username error handling
        if username.characters.count == 0 {
            error = true
            errorMessage += "Username is not set;\n"
        }
        else if username.characters.count > maxUsernameLength {
            error = true
            errorMessage += "Username exceeds maximum character limit of \(maxUsernameLength);\n"
        }
        
        if error == false {
            // All is good so far.. let's make sure this username isn't taken first
            let newUser = [ "firstName":firstName,
                            "lastName":lastName,
                            "email":email ]
            
            firebaseManager.createUser(username, password: password, email: email, userProperties: newUser, withValueCompletionBlock: { didError, result in
                if didError == nil {
                    // go ahead and login now that we've successfully created the account
                    self.firebaseManager.authUser(username, password: password, withCompletionBlock: { error, authData in
                        if error != nil {
                            self.errorLabel.text = "Could not log in at this time."
                        }
                        else {
                            NSUserDefaults.standardUserDefaults().setObject(self.firebaseManager.localUser.serialize(), forKey: "FirebaseUser")
                            self.performSegueWithIdentifier("idLoginSegue", sender: self.firebaseManager)
                        }
                    })
                }
            })
        }

        if error == true {
            errorLabel.text = errorMessage
        }
        else {
            errorLabel.text = ""
        }
        
        self.view.endEditing(true)
    }

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
        if segue.identifier == "idLoginSegue" {
            var controller = segue.destinationViewController as! UITabBarController
            
            var navController = controller.customizableViewControllers?[0] as! UINavigationController
            (navController.viewControllers[0] as! RoomListViewController).firebaseManager = self.firebaseManager
        }
    }

}
