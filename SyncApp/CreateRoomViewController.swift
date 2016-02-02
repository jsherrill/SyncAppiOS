//
//  CreateRoomViewController.swift
//  GroupApp
//
//  Created by Jim Sherrill on 2/1/16.
//  Copyright © 2016 Jim Sherrill. All rights reserved.
//

import UIKit
import Firebase

class CreateRoomViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var roomNameTextField: UITextField!
    @IBOutlet var errorLabel: UILabel!
    var firebaseManager:FirebaseManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        errorLabel.text = ""
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func createButtonPressed(sender: AnyObject) {
        var roomName:String = roomNameTextField.text!
        
        if roomName.characters.count > 0 {
            let room = firebaseManager.roomsRoot?.childByAutoId()
            var roomDetails:[String:AnyObject] = [ "roomName":roomName, "members":[firebaseManager.localUser.username:true]]
            room?.setValue(roomDetails)
            
            self.performSegueWithIdentifier("idCreatedRoomSegue", sender: self.firebaseManager)
        }
        else {
            errorLabel.text = "Error: Please enter a room name"
        }
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
        if segue.identifier == "idCreatedRoomSegue" {
            (segue.destinationViewController as! RoomListViewController).firebaseManager = self.firebaseManager
        }
    }

}
