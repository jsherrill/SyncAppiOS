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
    @IBOutlet weak var youTubeUrlTextField: UITextField!
    @IBOutlet var errorLabel: UILabel!
    var firebaseManager:FirebaseManager!
    var roomId: String!
    
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
        var youTubeUrl: String = youTubeUrlTextField.text!
        
        if roomName.characters.count > 0 && youTubeUrl.characters.count > 0 {
            let room = firebaseManager.roomsRoot?.childByAutoId()
            self.roomId = room!.key
            var roomDetails:[String:AnyObject] = [ "roomName":roomName, "youTubeUrl" : youTubeUrl,  "members":[firebaseManager.localUser.username:true], "roomId":room!.key]
            room?.setValue(roomDetails)
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
            //(segue.destinationViewController as! RoomListViewController).firebaseManager = self.firebaseManager
            
            if let room = segue.destinationViewController as? ViewController {
                    room.firebaseManager = self.firebaseManager
                    room.youTubeUrl = self.youTubeUrlTextField.text
                    room.roomId = self.roomId!
                    enterRoom(self.roomId)
            }
        }
    }
    
    func enterRoom(roomId:String!) {
        let uniqueRoomInMembers = firebaseManager.membersRoot.childByAppendingPath(roomId)
        let memberInRoom = uniqueRoomInMembers.childByAppendingPath(firebaseManager.localUser.username)
        memberInRoom.setValue(0)
    }

}
