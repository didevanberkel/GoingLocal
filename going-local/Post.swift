//
//  Post.swift
//  going-local
//
//  Created by Dide van Berkel on 05-04-16.
//  Copyright © 2016 Gary Grape Productions. All rights reserved.
//

import Foundation
import Firebase

class Post {
    
    private var _postDescription: String!
    private var _postTitle: String!
    private var _postLocation: String!
    private var _postImgUrl: String?
    private var _likes: Int!
    private var _postKey: String!
    private var _postRef: Firebase!
    private var _username: String!
    private var _userImgUrl: String?
    private var _postUid: String!
    private var _timestamp: Double!
    private var _key: String!
    private var _lat: Double!
    private var _long: Double!

    var postDescription: String {
        return _postDescription
    }
    
    var postTitle: String {
        return _postTitle
    }
    
    var postLocation: String {
        return _postLocation
    }
    
    var postImgUrl: String? {
        return _postImgUrl
    }
    
    var userImgUrl: String? {
        return _userImgUrl
    }
    
    var likes: Int {
        return _likes
    }
    
    var postKey: String {
        return _postKey
    }
    
    var postUid: String {
        return _postUid
    }
    
    var timeStamp: Double {
        return _timestamp
    }
    
    var username: String {
        if _username == nil {
            _username = "Anonymous"
        }
        return _username
    }
    
    var key: String {
        return _key
    }
    
    var lat: Double {
        return _lat
    }
    
    var long: Double {
        return _long
    }
    
    init(description: String, imageUrl: String?, userUrl: String?, title: String, location: String, username: String, postUid: String, timeStamp: Double, key: String, lat: Double, long: Double) {
        self._postDescription = description
        self._postImgUrl = imageUrl
        self._postTitle = title
        self._postLocation = location
        self._username = username
        self._postUid = postUid
        self._userImgUrl = userUrl
        self._timestamp = timeStamp
        self._key = key
        self._lat = lat
        self._long = long
    }
    
    init(postKey: String, dictionary: Dictionary<String, AnyObject>) {
        self._postKey = postKey
        if let likes = dictionary["likes"] as? Int {
            self._likes = likes
        }
        if let imgUrl = dictionary["imageUrl"] as? String {
            self._postImgUrl = imgUrl
        }
        if let loc = dictionary["location"] as? String {
            self._postLocation = loc
        }
        if let title = dictionary["title"] as? String {
            self._postTitle = title
        }
        if let desc = dictionary["description"] as? String {
            self._postDescription = desc
        }
        
        if let users = dictionary["username"] as? String {
            self._username = users
        }
        
        if let postUid = dictionary["uid"] as? String {
            self._postUid = postUid
        }
        
        if let userImgUrl = dictionary["img"] as? String {
            self._userImgUrl = userImgUrl
        }
        
        if let time = dictionary["timestamp"] as? Double {
            self._timestamp = time
        }
        
        if let key = dictionary["postKey"] as? String {
            self._key = key
        }
        
        if let lat = dictionary["lat"] as? Double {
            self._lat = lat
        }
        
        if let long = dictionary["long"] as? Double {
            self._long = long
        }
        
        self._postRef = DataService.ds.REF_POSTS.childByAppendingPath(self._postKey)
    }
    
    func adjustLikes(addLike: Bool) {
        if addLike {
            _likes = _likes + 1
        } else {
            _likes = _likes - 1
        }
        _postRef.childByAppendingPath("likes").setValue(_likes)
    }
}
