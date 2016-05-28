//
//  ViewController.swift
//  going-local
//
//  Created by Dide van Berkel on 04-04-16.
//  Copyright © 2016 Gary Grape Productions. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit

class ViewController: UIViewController {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    override func viewDidAppear(animated: Bool) {
        if NSUserDefaults.standardUserDefaults().boolForKey("automaticallyLogin") == true {
        if NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID) != nil {
            self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
        }
        }
    }
    
    @IBAction func fbButtonPressed(sender: UIButton!) {
        let facebookLogin = FBSDKLoginManager()
        facebookLogin.logInWithReadPermissions(["email"], fromViewController: self) { (facebookResult: FBSDKLoginManagerLoginResult!, facebookError: NSError!) in
            if facebookError != nil {
                print("Facebook login failed. Error \(facebookError)")
            } else if facebookResult.isCancelled {
                print("Facebook login was cancelled")
            } else {
                let accessToken = FBSDKAccessToken.currentAccessToken().tokenString
                print("Successfully logged in with Facebook \(accessToken)")
                
                DataService.ds.REF_BASE.authWithOAuthProvider("facebook", token: accessToken, withCompletionBlock: { error, authData in
                    
                    if error != nil {
                        print("Login failed")
                    } else {
                        print("Logged in! \(authData)")
                        
                        DataService.ds.REF_USER_CURRENT.observeEventType(.Value, withBlock: { snapshot in
                            if snapshot.value is NSNull {
                                print("this fb account is new")
                                let user = ["provider": authData.provider!]
                                DataService.ds.createFirebaseUser(authData.uid, user: user)
                            } else {
                                print("This fb account exists")
                            }
                        })
                        
                        NSUserDefaults.standardUserDefaults().setValue(String(authData.uid!), forKey: KEY_UID)
                        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "automaticallyLogin")
                        self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                    }
                })
            }
        }
    }
    
    @IBAction func attemptLogin(sender: UIButton!) {
        if let email = emailField.text where email != "", let pwd = passwordField.text where pwd != "" {
            DataService.ds.REF_BASE.authUser(email, password: pwd, withCompletionBlock: { error, authData in
                if error != nil {
                    print(error.code)
                    if error.code == STATUS_ACCOUNT_NONEXIST {
                        self.showErrorAlert("Could not login", msg: "Email address doesn't exist")
                    } else if error.code == STATUS_EMAIL_NONEXIST {
                        self.showErrorAlert("Could not login", msg: "The specified email address is invalid")
                    } else if error.code == STATUS_PASSWORD_INVALID {
                        self.showErrorAlert("Could not login", msg: "The specified password is incorrect")
                    } else {
                        self.showErrorAlert("Could not login", msg: "An unknown error occurred")
                    }
                } else {
                    NSUserDefaults.standardUserDefaults().setValue(String(authData.uid!), forKey: KEY_UID)
                    NSUserDefaults.standardUserDefaults().setBool(true, forKey: "automaticallyLogin")
                    self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                }
            })
        } else {
            showErrorAlert("Email and Password required", msg: "You must enter an email and a password")
        }
    }
    
    @IBAction func attemptSignup(sender: UIButton!) {
        if let email = emailField.text where email != "", let pwd = passwordField.text where pwd != "" {
            DataService.ds.REF_BASE.createUser(email, password: pwd, withValueCompletionBlock: { error, result in
                if error != nil {
                    if error.code == STATUS_EMAIL_NONEXIST {
                        self.showErrorAlert("Could not create account", msg: "The specified email address is invalid")
                    } else if error.code == STATUS_EMAIL_USED {
                        self.showErrorAlert("Could not create account", msg: "The specified email address is already in use")
                    } else {
                        self.showErrorAlert("Could not create account", msg: "An unknown error occurred")
                    }
                } else {
                    NSUserDefaults.standardUserDefaults().setValue(result[KEY_UID], forKey: KEY_UID)
                    NSUserDefaults.standardUserDefaults().setBool(true, forKey: "automaticallyLogin")
                    DataService.ds.REF_BASE.authUser(email, password: pwd, withCompletionBlock: { err, authData in
                        let user = ["provider": authData.provider!]
                        DataService.ds.createFirebaseUser(authData.uid, user: user)
                    })
                    
                    self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                }
            })
            
        } else {
            showErrorAlert("Email and Password required", msg: "You must enter an email and a password")
        }
    }
    
    func showErrorAlert(title: String, msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .Alert)
        let action = UIAlertAction(title: "Ok", style: .Default, handler: nil)
        alert.addAction(action)
        presentViewController(alert, animated: true, completion: nil)
    }
}

