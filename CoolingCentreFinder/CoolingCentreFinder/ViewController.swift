//
//  ViewController.swift
//  CoolingCentreFinder
//
//  Created by Russell Gordon on 2016-05-14.
//  Copyright © 2016 Royal St. George's College. All rights reserved.
//

import UIKit
import CoreLocation     // Required to obtain user's location
import Foundation

// Allow for degrees <--> radians conversions
extension Double {
    var degreesToRadians: Double { return self * M_PI / 180 }
    var radiansToDegrees: Double { return self * 180 / M_PI }
}

class ViewController : UIViewController, CLLocationManagerDelegate {
    
    // Views that need to be accessible to all methods
    let jsonResult = UILabel()
    var phoneNumber = UITextView(frame: CGRectMake(0, 0, 300.0, 300.0))
    
    // Required object to obtain user's location
    var locationManager : CLLocationManager = CLLocationManager()
    
    // Will store the user's current location, once it is obtained
    var latitude : String = ""          // Required by CLLocationManagerDelegate
    var longitude : String = ""         // Required by CLLocationManagerDelegate
    var latitudeAsDouble : Double = 0.0
    var longitudeAsDouble : Double = 0.0
    
    // Average radius of Earth
    let averageEarthRadius : Double = 6373
    
    // Shortest distance from my current location (start at "really far away")
    var shortestCoolingCentreDistance : Double = Double.infinity
    
    // Information for the cooling centre closest to me
    var closestCoolingCentre : [String : String] = [:]
    
    // Determine the distance between two positions by latitude and longitude
    func currentLocationDistanceTo(otherLatitude otherLatitude : Double, otherLongitude : Double) -> Double {
        
        // An implementation of the Haversine formula for finding distances between two co-ordinates
        // See: http://andrew.hedges.name/experiments/haversine/
        let longitudeDifference = otherLongitude - longitudeAsDouble
        let latitudeDifference = otherLatitude - latitudeAsDouble
        let a : Double = pow(sin( latitudeDifference.degreesToRadians / 2), 2) + cos(latitudeAsDouble.degreesToRadians) * cos(otherLatitude.degreesToRadians) * pow(sin(longitudeDifference.degreesToRadians / 2), 2)
        let c : Double = 2 * atan2( sqrt(a), sqrt(1 - a) )
        let d : Double = averageEarthRadius * c
        
        return d
        
    }
    
    // If data is successfully retrieved from the server, we can parse it here
    func parseMyJSON(theData : NSData) {
        
        // Print the provided data
        print("")
        print("====== the data provided to parseMyJSON is as follows ======")
        print(theData)
        
        // De-serializing JSON can throw errors, so should be inside a do-catch structure
        do {
            
            // Do the initial de-serialization
            // Source JSON is here:
            // http://www.learnswiftonline.com/Samples/subway.json
            //
            let allCoolingCentres = try NSJSONSerialization.JSONObjectWithData(theData, options: NSJSONReadingOptions.AllowFragments) as! [AnyObject]
            
            // Print all the JSON
            print(allCoolingCentres)
            
            // Iterate over each object in the JSON
            // Cast it to a dictionary
            // Find what cooling centre is closest to my current location
            for eachCoolingCentre in allCoolingCentres {
                
                // Try to cast the current anyObject in the array of AnyObjects to a dictionary
                if let thisCentre = eachCoolingCentre as? [String : AnyObject] {
                    
                    // A successful cast...
                    //
                    // Now try casting key values to see if this cooling centre is closest
                    // to the current location
                    guard let centreLongitude : Double = thisCentre["lon"] as? Double,
                        let centreLatitude : Double = thisCentre["lat"]  as? Double,
                        var centreName : String = thisCentre["locationName"] as? String,
                        let centreDescription : String = thisCentre["locationDesc"] as? String
                        else {
                            print("Problem getting details for a centre")
                            return
                    }
                    
                    // Fix up the centre's name
                    if centreDescription == "Library" {
                        centreName += " "
                        centreName += centreDescription
                    }
                    
                    
                    // Get the distance of this centre from my current location
                    let distanceFromMe : Double = currentLocationDistanceTo(otherLatitude: centreLatitude, otherLongitude: centreLongitude)
                    
                    // See if this is the closest
                    if distanceFromMe < shortestCoolingCentreDistance {
                        
                        // Save the closest centre
                        shortestCoolingCentreDistance = distanceFromMe
                        
                        // Save closest centre basic details
                        closestCoolingCentre["name"] = centreName
                        closestCoolingCentre["latitude"] = String(centreLatitude)
                        closestCoolingCentre["longitude"] = String(centreLongitude)

                        // Debug output
                        print("==== ***** NEW CLOSEST LOCATION ***** ====")
                        for (key, value) in closestCoolingCentre {
                            print("\(key): \(value)")
                        }
                        print("==== ******************************** ====")

                        // Get further details for the closest centre
                        guard let centreAddress : String = thisCentre["address"] as? String,
                        //let centreNotes : String = thisCentre["notes"] as? String,
                        var centrePhone : String = thisCentre["phone"] as? String
                            else {
                                print("Problem getting further details for the closest centre")
                                return
                        }
                        
                        // Fix up the centre's phone number
                        if centrePhone == "<null>" {
                            centrePhone = ""
                        }
                        
                        // Save in a global variable (dictionary) that tracks the details of the closest centre
                        //closestCoolingCentre["notes"] = centreNotes
                        closestCoolingCentre["phone"] = centrePhone
                        closestCoolingCentre["address"] = centreAddress
                        
                    }

                    // Now we have the current longitude and latitude of this centre as double values
                    print("==== information for \(centreName) ==== ")
                    print("Longitude: \(centreLongitude)")
                    print("Latitude: \(centreLatitude)")
                    print("Distance from me: \(distanceFromMe)")
                    print("====")
                    
                }
                
            }
            
            // Print out the closest cooling centre details
            print("==== ***** THE CLOSEST LOCATION IS... ***** ====")
            for (key, value) in closestCoolingCentre {
                print("\(key): \(value)")
            }
            print("==== ************************************** ====")
            
            // Now we can update the UI
            // (must be done asynchronously)
            dispatch_async(dispatch_get_main_queue()) {
                
                var infoToShow : String = "==== ***** THE CLOSEST LOCATION IS... ***** ====\n"
                for (key, value) in self.closestCoolingCentre {
                    infoToShow += "\(key): \(value)\n"
                }
                infoToShow += "==== ************************************** ====\n"
                self.jsonResult.text = infoToShow
                self.phoneNumber.text = self.closestCoolingCentre["phone"]
                
            }
            
        } catch let error as NSError {
            
            print ("Failed to load: \(error.localizedDescription)")
            
        }
        
    }
    
    // Set up and begin an asynchronous request for JSON data
    func getMyJSON() {
        
        // Define a completion handler
        // The completion handler is what gets called when this **asynchronous** network request is completed.
        // This is where we'd process the JSON retrieved
        let myCompletionHandler : (NSData?, NSURLResponse?, NSError?) -> Void = {
            
            (data, response, error) in
            
            // Cast the NSURLResponse object into an NSHTTPURLResponse objecct
            if let r = response as? NSHTTPURLResponse {
                
                // If the request was successful, parse the given data
                if r.statusCode == 200 {
                    
                    if let d = data {
                        
                        // Parse the retrieved data
                        self.parseMyJSON(d)
                        
                    }
                    
                }
                
            }
            
        }
        
        // Define a URL to retrieve a JSON file from
        let address : String = "http://app.toronto.ca/opendata//ac_locations/locations.json?v=1.00"
        
        // Try to make a URL request object
        if let url = NSURL(string: address) {
            
            // We have an valid URL to work with
            print(url)
            
            // Now we create a URL request object
            let urlRequest = NSURLRequest(URL: url)
            
            // Now we need to create an NSURLSession object to send the request to the server
            let config = NSURLSessionConfiguration.defaultSessionConfiguration()
            let session = NSURLSession(configuration: config)
            
            // Now we create the data task and specify the completion handler
            let task = session.dataTaskWithRequest(urlRequest, completionHandler: myCompletionHandler)
            
            // Finally, we tell the task to start (despite the fact that the method is named "resume")
            task.resume()
            
        } else {
            
            // The NSURL object could not be created
            print("Error: Cannot create the NSURL object.")
            
        }
        
    }
    
    // This is the method that will run as soon as the view controller is created
    override func viewDidLoad() {
        
        // Sub-classes of UIViewController must invoke the superclass method viewDidLoad in their
        // own version of viewDidLoad()
        super.viewDidLoad()
        
        /*
         * Location services setup
         */
        // What class is the delegate for CLLocationManager? (By passing "self" we are saying it is this view controller)
        locationManager.delegate = self
        // Set the level of location accuracy desired
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        // Prompt the user for permission to obtain their location when the app is running
        // NOTE: Must add these values to the Info.plist file in the project
        // 	  <key>NSLocationWhenInUseUsageDescription</key>
        //    <string>The application uses this information to find the cooling centre nearest you.</string>
        locationManager.requestWhenInUseAuthorization()
        // Now try to obtain the user's location (this runs aychronously)
        locationManager.startUpdatingLocation()
        
        /*
         * Define overall visual appearance of the application
         */
        // Make the view's background be white
        // Trying to match colours expected on iOS
        // http://iosdesign.ivomynttinen.com/#color-palette
        view.backgroundColor = UIColor.whiteColor()
        
        /*
         * Add a button
         */
        let getData = UIButton(frame: CGRect(x: 0, y: 0, width: 150, height: 30))
        
        // Make the button, when touched, run the calculate method
        getData.addTarget(self, action: #selector(ViewController.getMyJSON), forControlEvents: UIControlEvents.TouchUpInside)
        
        // Set the button's title
        getData.setTitle("Get my JSON!", forState: UIControlState.Normal)
        
        // Set the button's color
        getData.setTitleColor(UIColor.init(red: 0.329, green: 0.78, blue: 0.988, alpha: 1), forState: UIControlState.Normal)
        
        // Required to auto layout this button
        getData.translatesAutoresizingMaskIntoConstraints = false
        
        // Add the button into the super view
        view.addSubview(getData)
        
        /*
         * Further define textview that will show phone number for closest cooling station
         */
        phoneNumber.text = "Not yet"
        phoneNumber.font = UIFont.systemFontOfSize(12)
        phoneNumber.backgroundColor = UIColor.whiteColor()
        phoneNumber.textAlignment = NSTextAlignment.Left
        phoneNumber.editable = false
        phoneNumber.selectable = true
        phoneNumber.scrollEnabled = false
        phoneNumber.dataDetectorTypes = UIDataDetectorTypes.PhoneNumber
        
        // Required to autolayout this label
        phoneNumber.translatesAutoresizingMaskIntoConstraints = false
        
        // Add the label to the superview
        view.addSubview(phoneNumber)
        
        /*
         * Further define label that will show JSON data
         */
        
        // Set the label text and appearance
        jsonResult.text = "..."
        jsonResult.font = UIFont.systemFontOfSize(12)
        jsonResult.numberOfLines = 0   // makes number of lines dynamic
        // e.g.: multiple lines will show up
        jsonResult.textAlignment = NSTextAlignment.Left
        
        // Required to autolayout this label
        jsonResult.translatesAutoresizingMaskIntoConstraints = false
        
        // Add the label to the superview
        view.addSubview(jsonResult)
        
        /*
         * Layout all the interface elements
         */
        
        // This is required to lay out the interface elements
        view.translatesAutoresizingMaskIntoConstraints = false
        
        // Create an empty list of constraints
        var allConstraints = [NSLayoutConstraint]()
        
        // Create a dictionary of views that will be used in the layout constraints defined below
        let viewsDictionary : [String : AnyObject] = [
            "getData": getData,
            "title": jsonResult,
            "phone": phoneNumber
            ]
        
        // Define the vertical constraints
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
            "V:|-50-[getData]-20-[phone]-20-[title]",
            options: [],
            metrics: nil,
            views: viewsDictionary)
        
        // Add the vertical constraints to the list of constraints
        allConstraints += verticalConstraints
        
        // Activate all defined constraints
        NSLayoutConstraint.activateConstraints(allConstraints)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Required method for CLLocationManagerDelegate
    // This method runs when the location of the user has been updated.
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        // We now have the user's location, so stop finding their location.
        // (Looking for current location is a battery drain)
        self.locationManager.stopUpdatingLocation()
        
        // Set the most recent location found
        let latestLocation = locations.last
        
        // Format the current location as strings with four decimal places of accuracy
        latitude = String(format: "%.4f", latestLocation!.coordinate.latitude)
        longitude = String(format: "%.4f", latestLocation!.coordinate.longitude)
        
        // Save the current location as a Double
        latitudeAsDouble = Double(latestLocation!.coordinate.latitude)
        longitudeAsDouble = Double(latestLocation!.coordinate.longitude)
        
        // Report the location
        print("Location obtained at startup...")
        print("Latitude: \(latitudeAsDouble)")
        print("Longitude: \(longitudeAsDouble)")
    }
    
    // Required method for CLLocationManagerDelegate
    // This method will be run when there is an error determing the user's location
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        
        // Report the error
        print("didFailWithError \(error)")
        
    }
    

}