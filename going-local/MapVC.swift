//
//  MapVC.swift
//  going-local
//
//  Created by Dide van Berkel on 06-05-16.
//  Copyright © 2016 Gary Grape Productions. All rights reserved.
//

import UIKit
import GoogleMaps

class MapVC: UIViewController {
    
    var markerTitle: String!
    var markerSnippet: String!
    var markerLat: Double!
    var markerLong: Double!
    var markerPosition: CLLocationCoordinate2D!

    override func viewDidLoad() {
        super.viewDidLoad()
        let markerTitleDefault = NSUserDefaults.standardUserDefaults().valueForKey("markerTitle")
        let markerSnippetDefault = NSUserDefaults.standardUserDefaults().valueForKey("markerSnippet")
        let markerLatDefault = NSUserDefaults.standardUserDefaults().doubleForKey("markerLat")
        let markerLongDefault = NSUserDefaults.standardUserDefaults().doubleForKey("markerLong")
        
        let camera = GMSCameraPosition.cameraWithLatitude(markerLatDefault,longitude: markerLongDefault, zoom: 15)
        let mapView = GMSMapView.mapWithFrame(CGRectZero, camera: camera)
        mapView.myLocationEnabled = true
        self.view = mapView
        
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2DMake(markerLatDefault, markerLongDefault)
        marker.title = String(markerTitleDefault!)
        marker.snippet = String(markerSnippetDefault!)
        marker.map = mapView
        
        //OWN POSITION
        mapView.settings.myLocationButton = true
        
        //COMPASS
        mapView.settings.compassButton = true
        
        //SCROLL AND ZOOM
        mapView.settings.scrollGestures = true
        mapView.settings.zoomGestures = true
        self.view = mapView
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func mapTapped() {
        NSUserDefaults.standardUserDefaults().setValue(markerTitle, forKey: "markerTitle")
        NSUserDefaults.standardUserDefaults().setValue(markerSnippet, forKey: "markerSnippet")
        NSUserDefaults.standardUserDefaults().setDouble(markerLat, forKey: "markerLat")
        NSUserDefaults.standardUserDefaults().setDouble(markerLong, forKey: "markerLong")
    }
}
