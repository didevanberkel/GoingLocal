//
//  UserVC.swift
//  going-local
//
//  Created by Dide van Berkel on 19-04-16.
//  Copyright © 2016 Gary Grape Productions. All rights reserved.
//

import UIKit
import Firebase
import Alamofire

class UserVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var username: String!
    var image: UIImageView!
    var post: Post!
    var imagePicker: UIImagePickerController!
    var userImage: Firebase!
    var postUid: String!
    
    @IBOutlet weak var userTextfield: UITextField!
    @IBOutlet weak var oldPasswordTextField: UITextField!
    @IBOutlet weak var newPassword1TextField: UITextField!
    @IBOutlet weak var newPassword2TextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var imageDisplay: UIImageView!
    @IBOutlet weak var usernameSaveLbl: UILabel!
    @IBOutlet weak var passwordSaveLbl: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        userTextfield.text = username
        
        userImage = DataService.ds.REF_USER_CURRENT.childByAppendingPath("img")
        userImage.observeEventType(.Value, withBlock: { snapshot in
            if snapshot.value is NSNull {
                self.imageDisplay.image = UIImage(named: "2")
            } else {
                NSUserDefaults.standardUserDefaults().setValue(snapshot.value, forKey: "profileImage")
                let img = String(snapshot.value)
                Alamofire.request(.GET, img).response { (request, response, data, error) in
                    self.imageDisplay.image = UIImage(data: data!, scale: 1)
                }
            }
        })
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }
    
    @IBAction func changePassword(sender: AnyObject) {
        if newPassword1TextField.text == newPassword2TextField.text {
        DataService.ds.REF_BASE.changePasswordForUser(emailTextField.text, fromOld: oldPasswordTextField.text, toNew: newPassword1TextField.text, withCompletionBlock: { error in
                if error != nil {
                    self.passwordSaveLbl.hidden = false
                    self.passwordSaveLbl.text = "Email address or password is incorrect."
                } else {
                    self.passwordSaveLbl.hidden = false
                    self.passwordSaveLbl.text = "Password's changed!"
            }
        })
        } else {
            self.passwordSaveLbl.hidden = false
            self.passwordSaveLbl.text = "New passwords do not match."
            usernameSaveLbl.hidden = false
        }
        NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: #selector(UserVC.changeBtnPassword), userInfo: nil, repeats: false)
    }
    
    @IBAction func changeUsername(sender: AnyObject) {
        userTextfield.resignFirstResponder()
        usernameSaveLbl.hidden = false
        NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: #selector(UserVC.changeBtnName), userInfo: nil, repeats: false)
        
        if let img = imageDisplay.image {
            let urlString = "http://api.imageshack.com/v3/images"
            let url = NSURL(string: urlString)!
            let imageData = UIImageJPEGRepresentation(img, 0.3)!
            let keyData = "49DENOQRb81dc017f583754848c2dd5c6d127074".dataUsingEncoding(NSUTF8StringEncoding)!
            let keyJSON = "json".dataUsingEncoding(NSUTF8StringEncoding)!
            
            Alamofire.upload(.POST, url, multipartFormData: { multipartFormData in
                multipartFormData.appendBodyPart(data: imageData, name: "fileupload", fileName: "image", mimeType: "image/jpg")
                multipartFormData.appendBodyPart(data: keyData, name: "key")
                multipartFormData.appendBodyPart(data: keyJSON, name: "json")
                
            }) { encodingResult in
                switch encodingResult {
                case .Success(let upload, _, _):
                    upload.responseJSON(completionHandler: { response in
                        let result = response.result
                        if let info = result.value as? Dictionary<String, AnyObject> {
                            if let results = info["result"] as? Dictionary<String, AnyObject> {
                                if let links = (results["images"] as? Array)![0] as? Dictionary<String, AnyObject> {
                                    if let imgLink = links["direct_link"] as? String {
                                        self.postToFirebase("http://\(imgLink)")
                                    }
                                }
                            }
                        }
                    })
                case .Failure(let error):
                    print(error)
                }
            }
            
        } else {
            self.postToFirebase(nil)
        }
    }
    
    @IBAction func changePhoto(sender: AnyObject) {
        let alertController = UIAlertController(title: "Choose Image", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: UIAlertActionStyle.Destructive, handler: {(alert :UIAlertAction!) in
                self.openCamera()
            })
            alertController.addAction(cameraAction)
            
        let galleryAction = UIAlertAction(title: "Gallery", style: UIAlertActionStyle.Default, handler: {(alert :UIAlertAction!) in
                self.openGallery()
            })
            alertController.addAction(galleryAction)
            
            alertController.popoverPresentationController?.sourceView = view
            alertController.popoverPresentationController?.sourceRect = self.image.frame
            alertController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.Any
            
            presentViewController(alertController, animated: true, completion: nil)
    }
    
    func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            imagePicker.sourceType = UIImagePickerControllerSourceType.Camera
            imagePicker.allowsEditing = false
            self.presentViewController(imagePicker, animated: true, completion: nil)
        } else {
            imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            imagePicker.allowsEditing = true
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
    }
    
    func openGallery() {
        imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        imagePicker.allowsEditing = true
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage imageSelected: UIImage, editingInfo: [String : AnyObject]?) {
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
        imageDisplay.image = imageSelected
    }
    
    func postToFirebase(imgUrl: String?) {
        if imgUrl != nil {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "imgIsChanged")
            let firebaseImg = DataService.ds.REF_USER_CURRENT.childByAppendingPath("img")
            firebaseImg.setValue(imgUrl)
        }
        
        if (userTextfield.text! != "") {
            let firebaseUser = DataService.ds.REF_USER_CURRENT.childByAppendingPath("username")
            firebaseUser.setValue(userTextfield.text!)
        }
    }
    
    func changeBtnName() {
        usernameSaveLbl.hidden = true
    }
    
    func changeBtnPassword() {
        self.passwordSaveLbl.hidden = true
    }
    
    @IBAction func logout(sender: UIButton!) {
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: "automaticallyLogin")
        self.dismissViewControllerAnimated(true, completion: nil)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
