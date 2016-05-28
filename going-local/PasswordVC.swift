//
//  PasswordVC.swift
//  going-local
//
//  Created by Dide van Berkel on 29-04-16.
//  Copyright © 2016 Gary Grape Productions. All rights reserved.
//

import UIKit

class PasswordVC: UIViewController {
    
    @IBOutlet weak var emailField: UITextField!
    
    @IBAction func backBtnPressed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func resetPasswordBtnPressed(sender: AnyObject) {
        if emailField.text != "" {
            let email = emailField.text!
            let ref = DataService.ds.REF_BASE
            ref.resetPasswordForUser(email, withCompletionBlock: { error in
            if error != nil {
                self.showErrorAlert("Error", msg: "The specified email address is invalid")
                } else {
                print("Password reset sent successfully")
                }
            })
        } else {
            self.showErrorAlert("Error", msg: "Please enter your email address")
        }
    }
    
    func showErrorAlert(title: String, msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .Alert)
        let action = UIAlertAction(title: "Ok", style: .Default, handler: nil)
        alert.addAction(action)
        presentViewController(alert, animated: true, completion: nil)
    }
}
