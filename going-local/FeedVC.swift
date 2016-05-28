//
//  FeedVC.swift
//  going-local
//
//  Created by Dide van Berkel on 05-04-16.
//  Copyright © 2016 Gary Grape Productions. All rights reserved.
//

import UIKit
import Firebase
import Alamofire
import GoogleMaps

class FeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate, UIPopoverControllerDelegate, GMSAutocompleteViewControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleTextField: MaterialTextField!
    @IBOutlet weak var descriptionTextField: MaterialTextField!
    @IBOutlet weak var locationTextField: MaterialTextField!
    @IBOutlet weak var imageField: UIImageView!
    @IBOutlet weak var usernameDisplay: UILabel!
    @IBOutlet weak var userImageDisplay: UIImageView!
    @IBOutlet weak var sortDateBtn: UIButton!
    @IBOutlet weak var sortLikeBtn: UIButton!
    
    @IBOutlet weak var enterText: UILabel!
    
    var posts = [Post]()
    var imgChanged: Bool!
    
    var imageSelected = false
    static var imageCache = NSCache()
    var imagePicker: UIImagePickerController!

    var searchController: UISearchController!
    var searchResult: [Post] = []
    
    var profileImage: Firebase!
    var customUsername: Firebase!
    
    var coordinates: CLLocationCoordinate2D!
    var lat: Double!
    var long: Double!
    var popover: UIPopoverPresentationController? = nil
    
    var markerTitle: String!
    var markerSnippet: String!
    var markerPosition: CLLocationCoordinate2D!
    
    override func viewDidAppear(animated: Bool) {
        checkforUsername()
        profileImage = DataService.ds.REF_USER_CURRENT.childByAppendingPath("img")
        profileImage.observeEventType(.Value, withBlock: { snapshot in
            if snapshot.value is NSNull {
                self.userImageDisplay.image = UIImage(named: "2")
                NSUserDefaults.standardUserDefaults().setValue("http://imageshack.com/a/img922/2122/C5vION.png", forKey: "profileImage")
            } else {
                NSUserDefaults.standardUserDefaults().setValue(snapshot.value, forKey: "profileImage")
                let img = String(snapshot.value)
                Alamofire.request(.GET, img).response { (request, response, data, error) in
                    self.userImageDisplay.image = UIImage(data: data!, scale: 1)
                }
            }
        })
    }
    
    override func viewWillDisappear(animated: Bool) {
        searchController.active = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchController = UISearchController(searchResultsController: nil)
        tableView.tableHeaderView = searchController.searchBar
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search location"
        searchController.searchBar.sizeToFit()
        searchController.hidesNavigationBarDuringPresentation = false
        
        tableView.delegate = self
        tableView.dataSource = self
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        tableView.estimatedRowHeight = 375
        
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "sortByDate")

        DataService.ds.REF_POSTS.observeEventType(.Value, withBlock:  { snapshot in
            let sortByDate = NSUserDefaults.standardUserDefaults().boolForKey("sortByDate")
            if sortByDate == true {
                self.performSelector(#selector(self.sortingByDate), withObject: nil, afterDelay: 1)
            } else {
                self.performSelector(#selector(self.sortingByLikes), withObject: nil, afterDelay: 1)
            }
        })
    }
    
    func sortingByDate() {
        self.posts.removeAll()
        sortDateBtn.setTitleColor(UIColor(red: 255/255, green: 102/255, blue: 102/355, alpha: 1.0), forState: .Normal)
        sortLikeBtn.setTitleColor(UIColor(red: 76/255, green: 76/255, blue: 76/355, alpha: 1.0), forState: .Normal)
        
        DataService.ds.REF_POSTS.queryOrderedByChild("timestamp").observeEventType(.ChildAdded, withBlock: { snapshot in
            if let postDict = snapshot.value as? Dictionary<String, AnyObject> {
                let key = snapshot.key
                let post = Post(postKey: key, dictionary: postDict)
                self.posts.insert(post, atIndex: 0)
            }
            
            if (self.searchController.active) {
                if let searchText = self.searchController.searchBar.text {
                    self.filterContent(searchText)
                    self.tableView.reloadData()
                }
            } else {
                self.tableView.reloadData()
            }
        })
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "sortByDate")
    }
    
    func sortingByLikes() {
        self.posts.removeAll()
        sortLikeBtn.setTitleColor(UIColor(red: 255/255, green: 102/255, blue: 102/355, alpha: 1.0), forState: .Normal)
        sortDateBtn.setTitleColor(UIColor(red: 76/255, green: 76/255, blue: 76/355, alpha: 1.0), forState: .Normal)
        
        DataService.ds.REF_POSTS.queryOrderedByChild("likes").observeEventType(.ChildAdded, withBlock: { snapshot in
            if let postDict = snapshot.value as? Dictionary<String, AnyObject> {
                let key = snapshot.key
                let post = Post(postKey: key, dictionary: postDict)
                self.posts.insert(post, atIndex: 0)
            }
            
            if (self.searchController.active) {
                if let searchText = self.searchController.searchBar.text {
                    self.filterContent(searchText)
                    self.tableView.reloadData()
                }
            } else {
                self.tableView.reloadData()
            }
            
        })
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: "sortByDate")
    }
    
    @IBAction func locationTextFieldChanged(sender: AnyObject) {
        searchController.active = false
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        self.presentViewController(autocompleteController, animated: true, completion: nil)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.active {
            return searchResult.count
        } else {
            return posts.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCellWithIdentifier("PostCell") as? PostCell {
            let postList = searchController.active ? searchResult[indexPath.row] : posts[indexPath.row]
            let post = postList
            cell.request?.cancel()
            
            var image: UIImage?
            if let url = post.postImgUrl {
                image = FeedVC.imageCache.objectForKey(url) as? UIImage
            }
            
            var image2: UIImage?
            if let url2 = post.userImgUrl {
                image2 = FeedVC.imageCache.objectForKey(url2) as? UIImage
            }
            
            cell.configureCell(post, img: image, img2: image2)
            
            return cell
        } else {
            return PostCell()
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let post = posts[indexPath.row]
        if post.postImgUrl == nil {
            return 230
        } else {
            return tableView.estimatedRowHeight
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
        imageField.image = image
        imageSelected = true
    }
    
    @IBAction func selectImage(sender: UITapGestureRecognizer) {
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
        alertController.popoverPresentationController?.sourceRect = self.imageField.frame
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
    
    @IBAction func makePost(sender: AnyObject) {
        searchController.active = false
        if descriptionTextField.text != "" && titleTextField.text != "" && locationTextField.text != "" {
            if let img = imageField.image where imageSelected == true {
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
                                    //if let links = results["images"]?[0] as? Dictionary<String, AnyObject> {
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
        } else {
            enterText.hidden = false
            NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: #selector(FeedVC.changeLbl), userInfo: nil, repeats: false)
        }
        checkforUsername()
    }
    
    func changeLbl() {
        enterText.hidden = true
    }
    
    func postToFirebase(imgUrl: String?) {
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "sortByDate")
        let imageForProfile = NSUserDefaults.standardUserDefaults().valueForKey("profileImage")
        var post: Dictionary<String, AnyObject> = [
            "title": titleTextField.text!,
            "description": descriptionTextField.text!,
            "likes": 0,
            "location": locationTextField.text!,
            "username": usernameDisplay.text!,
            "uid": NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID)!,
            "img": String(imageForProfile!),
            "timestamp": NSDate.timeIntervalSinceReferenceDate(),
            "lat": lat,
            "long": long,
            ]
            
            if imgUrl != nil {
                post["imageUrl"] = imgUrl
            }
        
    let firebasePost = DataService.ds.REF_POSTS.childByAutoId()
    let url = NSURL(fileURLWithPath: "\(firebasePost)")
    let lastComponent = url.lastPathComponent
        
        if lastComponent != nil {
            post["postKey"] = lastComponent!
        }
        
    firebasePost.setValue(post)
        
    titleTextField.text = ""
    descriptionTextField.text = ""
    locationTextField.text = ""
    imageField.image = UIImage(named: "camera")
    imageSelected = false
    }
    
    func viewController(viewController: GMSAutocompleteViewController, didAutocompleteWithPlace place: GMSPlace) {
        locationTextField.text = place.formattedAddress!
        coordinates = place.coordinate
        lat = coordinates.latitude
        long = coordinates.longitude
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func viewController(viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: NSError) {
        print("Error: ", error.description)
    }
    
    func wasCancelled(viewController: GMSAutocompleteViewController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func didRequestAutocompletePredictions(viewController: GMSAutocompleteViewController) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(viewController: GMSAutocompleteViewController) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        let sortByDate = NSUserDefaults.standardUserDefaults().boolForKey("sortByDate")
        if sortByDate == true {
            sortingByDate()
        } else if sortByDate == false {
            sortingByLikes()
        } else {
            if let searchText = searchController.searchBar.text {
                filterContent(searchText)
                self.tableView.reloadData()
            }
        }
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchController.active = false
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchController.active = false
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }
    
    func filterContent(searchText: String) {
        searchResult = posts.filter({ (post: Post) -> Bool in
            let titleMatch = post.postTitle.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch)
            let locationMatch = post.postLocation.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch)
            let nameMatch = post.username.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch)
            return titleMatch != nil || locationMatch != nil || nameMatch != nil
        })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "UserVC") {
            let uvc = segue.destinationViewController as! UserVC;
            uvc.username = self.usernameDisplay.text
            uvc.image = self.userImageDisplay
        }
    }
    
    func checkforUsername(){
        customUsername = DataService.ds.REF_USER_CURRENT.childByAppendingPath("username")
        customUsername.observeEventType(.Value, withBlock: { snapshot in
            if snapshot.value is NSNull {
                self.usernameDisplay.text = "Anonymous"
                NSUserDefaults.standardUserDefaults().setValue("Anonymous", forKey: "username")
            } else {
                self.usernameDisplay.text = ("\(snapshot.value)")
                NSUserDefaults.standardUserDefaults().setValue(self.usernameDisplay.text!, forKey: "username")
            }
        })
    }
    
    @IBAction func sortDateBtnPressed(sender: AnyObject) {
        sortingByDate()
    }
    
    @IBAction func sortLikeBtnPressed(sender: AnyObject) {
        sortingByLikes()
    }
}


