//
//  GameViewController.swift
//  FirstSceneKit
//
//  Created by Yuchi on 2/13/17.
//  Copyright © 2017 Yuchi. All rights reserved.
//

import UIKit
import SceneKit
import MapKit
import CoreLocation
import GooglePlaces



class GameViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var scnView: SCNView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var latLon: UILabel!
    
    @IBOutlet weak var pName: UILabel!
    @IBOutlet weak var pAddress: UILabel!
    @IBOutlet weak var pType: UILabel!
    
    let locationManager = CLLocationManager()
    var placesClient: GMSPlacesClient!
    var placeID: String!

    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        placesClient = GMSPlacesClient.shared()
    
        if (CLLocationManager.locationServicesEnabled()){
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.requestAlwaysAuthorization()
            self.locationManager.startUpdatingLocation()
        }
        

  
    }
    
    
    func sceneSetup(){
        
        // create a new scene
        let scene = SCNScene()
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        
        // careate a box
        let geo = SCNNode(geometry: SCNBox(width: 4, height: 4, length: 4, chamferRadius: 1))
        geo.position = SCNVector3(x: 0, y:0, z:0)
        scene.rootNode.addChildNode(geo)
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
        // retrieve the ship node
//        let ship = scene.rootNode.childNode(withName: "ship", recursively: true)!
        
        // animate the 3d object
//        ship.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 1)))
        
        // retrieve the SCNView
        // let scnView = self.view as! SCNView
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
        
        // configure the view
        scnView.backgroundColor = UIColor.black
        
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
        
        
    }
    
    
    @IBAction func getCurrentPlace(_ sender: UIButton){
        
        placesClient.currentPlace { (placeLikelihoodList, error) -> Void in
            if let error = error {
                print("pick place error: \(error.localizedDescription)")
                return
            }
            
            self.pName.text = "No current place"
            self.pAddress.text = ""
            
            if let placeLikelihoodList =  placeLikelihoodList{
                let place = placeLikelihoodList.likelihoods.first?.place
                if let place = place {
                    self.pName.text = place.name
                    self.pAddress.text = place.formattedAddress!.components(separatedBy: ", ").joined(separator: "\n")
                    self.placeID = place.placeID
                }
            }
        }
        
    }

    
    @IBAction func lookupPlaceID(_ sender: UIButton){
        
        placesClient.lookUpPlaceID(placeID, callback: {(place, error) -> Void in
            
            if let error = error {
                print("lookup place id query error: \(error.localizedDescription)")
                return
            }
            
            guard let place = place else {
                print("No place details for \(self.placeID)")
                return
            }
            
            self.pType.text = "\(place.types)"

            print (place.types)
            let i: String! = "establishment"
            
            if place.types.contains(i){
                print("hr")
                
                self.sceneSetup()
                
            }

        })
        

        
        
    }

    
    
    func locationManager (_ manager: CLLocationManager, didUpdateLocations locations:[CLLocation] ){
        let location = locations.last
        let center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta:1, longitudeDelta:1))
        self.mapView.setRegion(region, animated:true)
        self.latLon.text = "lat: \(location!.coordinate.latitude), lon: \(location!.coordinate.longitude)"
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error" + error.localizedDescription)
    }
    
    
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        // retrieve the SCNView
//        let scnView = self.view as! SCNView
        
        // check what nodes are tapped
        let p = gestureRecognize.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result: AnyObject = hitResults[0]
            
            // get its material
            let material = result.node!.geometry!.firstMaterial!
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                
                material.emission.contents = UIColor.black
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = UIColor.red
            
            SCNTransaction.commit()
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

}
