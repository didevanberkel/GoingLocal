//
//  PostCell.swift
//  going-local
//
//  Created by Dide van Berkel on 05-04-16.
//  Copyright © 2016 Gary Grape Productions. All rights reserved.
//

import UIKit
import Alamofire
import Firebase

class PostCell: UITableViewCell {
    
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var showcaseImg: UIImageView!
    @IBOutlet weak var descriptionText: UITextView!
    @IBOutlet weak var likesLbl: UITextView!
    @IBOutlet weak var postTitle: UITextView!
    @IBOutlet weak var postLocation: UITextView!
    @IBOutlet weak var likesImg: UIImageView!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var editBtn: UIButton!
    @IBOutlet weak var delBtn: UIButton!
    @IBOutlet weak var postKeyLbl: UILabel!
    @IBOutlet weak var mapBtn: UIButton!
    
    var post: Post!
    var feedVC = FeedVC()
    var mapVC = MapVC()
    var request: Request?
    var likeRef: Firebase!
    var postKey: Firebase!
    var inEditMode: Bool = false
    var keyArray = [String]()
    
    var isEditable: Bool = false
    var lat: Double!
    var long: Double!
    var likes: Int!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let tap = UITapGestureRecognizer(target: self, action: #selector(PostCell.likeTapped(_:)))
        tap.numberOfTapsRequired = 1
        likesImg.addGestureRecognizer(tap)
        likesImg.userInteractionEnabled = true
        postTitle.text = nil
    }
    
    override func drawRect(rect: CGRect) {
        showcaseImg.layer.cornerRadius = 3.0
        showcaseImg.clipsToBounds = true
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }
    
    func configureCell(post: Post, img: UIImage?, img2: UIImage?) {
        self.post = post
        likeRef = DataService.ds.REF_USER_CURRENT.childByAppendingPath("likes").childByAppendingPath(post.postKey)
        
        self.descriptionText.text = post.postDescription
        self.descriptionText.scrollRangeToVisible(NSMakeRange(0, 0))
        self.likes = post.likes
        self.likesLbl.text = "\(post.likes) likes"
        self.postTitle.text = post.postTitle
        self.postLocation.text = post.postLocation
        self.username.text = post.username
        self.postKeyLbl.text = post.key
        self.lat = post.lat
        self.long = post.long
        
        if post.postImgUrl != nil {
            if img != nil {
                self.showcaseImg.image = img
            } else {
                request = Alamofire.request(.GET, post.postImgUrl!).validate(contentType: ["image/*"]).response(completionHandler: { request, response, data, err in
                    if err == nil {
                        let _img = UIImage(data: data!)!
                        self.showcaseImg.image = img
                        FeedVC.imageCache.setObject(_img, forKey: self.post.postImgUrl!)
                    } else {
                        print(err.debugDescription)
                    }
                })
            }
        } else {
            self.showcaseImg.hidden = true
        }
        
        if post.userImgUrl != nil {
            if img2 != nil {
                self.profileImg.image = img2
            } else {
                request = Alamofire.request(.GET, post.userImgUrl!).validate(contentType: ["image/*"]).response(completionHandler: { request, response, data, err in
                    if err == nil {
                        let _img2 = UIImage(data: data!)!
                        self.profileImg.image = img2
                        FeedVC.imageCache.setObject(_img2, forKey: self.post.userImgUrl!)
                    } else {
                        print(err.debugDescription)
                    }
                })
            }
        } else {
            print("no image")
        }

        likeRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            if snapshot.value is NSNull {
                self.likesImg.image = UIImage(named: "heart")
            } else {
                self.likesImg.image = UIImage(named: "heart-filled")
            }
        })
        
        let getUid = NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID)
        if String(getUid!) == (self.post.postUid) {
            editBtn.hidden = false
            delBtn.hidden = false
            
            let usernameDefaults = NSUserDefaults.standardUserDefaults().valueForKey("username")
            if usernameDefaults != nil {
                username.text = String(usernameDefaults!)
            }
            
            let checkIfImageChanged = NSUserDefaults.standardUserDefaults().boolForKey("imgIsChanged")
            if checkIfImageChanged == true {
                self.changePost()
                NSUserDefaults.standardUserDefaults().setBool(false, forKey: "imgIsChanged")
            }
        } else {
            editBtn.hidden = true
            delBtn.hidden = true
        }
        
        mapVC.markerTitle = postTitle.text
        mapVC.markerSnippet = postLocation.text
        mapVC.markerLat = lat
        mapVC.markerLong = long
    }
    
    func changePost() {
        let imageForProfile = NSUserDefaults.standardUserDefaults().valueForKey("profileImage")
        let username = NSUserDefaults.standardUserDefaults().valueForKey("username")
        var post: Dictionary<String, AnyObject> = [
            "title": postTitle.text,
            "description": descriptionText.text,
            "likes": likes,
            "location": postLocation.text,
            "username": String(username!),
            "uid": NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID)!,
            "img": String(imageForProfile!),
            "timestamp": NSDate.timeIntervalSinceReferenceDate(),
            "postKey": postKeyLbl.text!,
            "lat": lat,
            "long": long
        ]
        
        if self.post.postImgUrl != nil {
            post["imageUrl"] = self.post.postImgUrl
        }

        let urlForChangedPost = DataService.ds.REF_POSTS.childByAppendingPath(postKeyLbl.text!)
        urlForChangedPost.setValue(post)
    }

    @IBAction func editTapped(sender: AnyObject) {
        if inEditMode {
            inEditMode = false
            editBtn.setTitle("Edit", forState: .Normal)
            postTitle.editable = false
            postLocation.editable = false
            descriptionText.editable = false
            changePost()
        } else {
            inEditMode = true
            editBtn.setTitle("Done", forState: .Normal)
            postTitle.editable = true
            postLocation.editable = true
            descriptionText.editable = true
        }
    }
    
    @IBAction func mapTapped(sender: AnyObject) {
        mapVC.mapTapped()
    }
    
    @IBAction func deleteTapped(sender: AnyObject) {
        let deletePostUrl = DataService.ds.REF_POSTS.childByAppendingPath(postKeyLbl.text!)
        deletePostUrl.removeValue()
    }

    func likeTapped(sender: UITapGestureRecognizer) {
        NSNotificationCenter.defaultCenter().postNotificationName("load", object: nil)
        likeRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            if snapshot.value is NSNull {
                self.likesImg.image = UIImage(named: "heart-filled")
                self.post.adjustLikes(true)
                self.likeRef.setValue(true)
            } else {
                self.likesImg.image = UIImage(named: "heart")
                self.post.adjustLikes(false)
                self.likeRef.removeValue()
            }
        })
    }
}








