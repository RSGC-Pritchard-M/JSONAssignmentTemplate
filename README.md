# JSONAssignmentTemplate

Use this as the starting point for your unit 4 summative assignment.

For your own application, add sections below like I have, to describe the purpose of your app that makes use of a JSON data source.

*– Mr. Gordon*

## Cooling Centre Finder a.k.a. "Stay Cool TO"

The purpose of this application is to tell the user where the closest cooling centre is in Toronto, relative to their current location.

The application obtains a list of cooling centres available to the public when it is very hot outside. Overall description available here:

http://www1.toronto.ca/wps/portal/contentonly?vgnextoid=e7356d1900531510VgnVCM10000071d60f89RCRD

Quoting from the page:

"Toronto Public Health monitors the Heat Health Alert System every day from May 15 to September 30 each year, to alert those people most at risk of heat-related illness that hot weather conditions presently exist and to take appropriate precautions. One such precaution is the availability of buildings that are open to the general public that offer an air-conditioned space for temporary relief from the extreme heat."

The direct JSON data source being utilized is available here:

http://app.toronto.ca/opendata//ac_locations/locations.json

## Assets used in this project

For the app icon, I obtained the [sun image](https://pixabay.com/static/uploads/photo/2014/04/02/10/19/star-303454_960_720.png) from [Pixabay](https://pixabay.com).

I obtained the [CN Tower image](http://www.flaticon.com/free-icon/cn-tower_1162#term=cN%20tower&page=1&position=2) from FlatIcon. Specifically, the icon was made by author [Freepik](http://www.freepik.com/) from [FlatIcon](https://www.flaticon.com ).

## Obtaining JSON from an insecure (HTTP) source

When you run an application in a full-fledged iOS application, default security settings disallow connections to insecure web hosts (HTTP vs. HTTPS).

If your JSON data source is being provided from an address that begins with *HTTP*, you will need to edit the *Info.plist* file like so:

![Edit info.plist as source code](/edit-info-plist.png)

Then add the following XML to the file:

	<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSExceptionDomains</key>
		<dict>
			<key>app.toronto.ca</key>
			<dict>
				<key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
				<true/>
			</dict>
		</dict>
	</dict>
	
Replace **app.toronto.ca** in the XML given above with the domain of the source of your JSON data file.

So for example, my JSON data source is:

http://app.toronto.ca/opendata//ac_locations/locations.json

I added **app.toronto.ca** to the XML above. You would replace this value with the domain of your own JSON data source.

## Obtaining the user's location

There are several steps required to be able to request a user's location in an app.

### Testing with Location Services

Whether running in debug mode on an actual device, or whether testing in the iOS Simulator, location services on iOS needs a "pretend" set of location(s) to return any values.

First, visit [Google Maps](https://maps.google.com/) and search for a location that you want to test with.  Then right-click on the map. Select **What's here**:

![Find what's here at a location](/google-maps-whats-here.png)

Then take note of the longtiude and latitude values given:

![Get longitude and latitude](/longitude-latitude.png)

Next, visit the [GPX POI File Generator website](http://gpx-poi.com).  This will help you create the necessary XML file required by Xcode to simulate a location.  Enter some longitude and latitude values:

![Set longitude and latitude](/enter-long-lat-values.png)

Then download the file with the correct format:

![Get GPX file](/download-file.png)

After the file has downloaded, you may need to rename the file to ensure it's extension is **.gpx** (sometimes a web browser will download the file with a .txt extension).

Now, you can add as many test location(s) as you like to your project in Xcode by editing the scheme for your product:

![Edit application scheme](/edit-scheme.png)

Once inside the product scheme dialog, click on **Run**, then **Options**, then under **Default location** select *Add GPX File to Project...* 

![Add a location](/add-location.png)

Then select the GPX file you just created.

### Getting permission to find a user's location

Your app will need to request a user's location. Permission is required.

In order to show the prompt to ask for permission to find a user's location, you must define custom messages that will be shown by your app in the **Info.plist** file.

Edit the *Info.plist* file like so:

![Edit info.plist as source code](/edit-info-plist.png)

Then add the following XML to the bottom of the file (change the messages as appropriate for your application):

	<key>NSLocationWhenInUseUsageDescription</key>
	<string>The application uses this information to find the cooling centre nearest you.</string>
	<key>NSLocationAlwaysUsageDescription</key>
	<string>The application uses this information to find the cooling centre nearest you.</string>

### Code changes required

To obtain a user's location, the view controller [must implement the **CLLocationManagerDelegate** protocol](https://github.com/rgordonatrsgc/JSONAssignmentTemplate/blob/59dd56282a16773e76f447538cc194c09ecd9bce/CoolingCentreFinder/CoolingCentreFinder/ViewController.swift#L12).  This just means that your view controller "promises" to provide certain methods that will be called by iOS when it attempts to find the user's location.

Next, you must [create an object that will be used to get the user's location](https://github.com/rgordonatrsgc/JSONAssignmentTemplate/blob/59dd56282a16773e76f447538cc194c09ecd9bce/CoolingCentreFinder/CoolingCentreFinder/ViewController.swift#L17-L18).

After this, it is convenient to [declare some global variables inside the view controller](https://github.com/rgordonatrsgc/JSONAssignmentTemplate/blob/59dd56282a16773e76f447538cc194c09ecd9bce/CoolingCentreFinder/CoolingCentreFinder/ViewController.swift#L20-L22) that will store the latitude and longitude the you retrieve.

At the start of **viewDidLoad** in the view controller, you [set some options for finding the user's location](https://github.com/rgordonatrsgc/JSONAssignmentTemplate/blob/59dd56282a16773e76f447538cc194c09ecd9bce/CoolingCentreFinder/CoolingCentreFinder/ViewController.swift#L154-L167), and then try to do so.

[If the user's location can be determined, this method will run](https://github.com/rgordonatrsgc/JSONAssignmentTemplate/blob/59dd56282a16773e76f447538cc194c09ecd9bce/CoolingCentreFinder/CoolingCentreFinder/ViewController.swift#L249-L268).

[If something goes wrong, this method will run](https://github.com/rgordonatrsgc/JSONAssignmentTemplate/blob/59dd56282a16773e76f447538cc194c09ecd9bce/CoolingCentreFinder/CoolingCentreFinder/ViewController.swift#L270-L277).

Finally, [this is where the UI is updated in the application](https://github.com/rgordonatrsgc/JSONAssignmentTemplate/blob/59dd56282a16773e76f447538cc194c09ecd9bce/CoolingCentreFinder/CoolingCentreFinder/ViewController.swift#L50-L60) – this is simply printing out the contents of the global variables we created before, and sticking them in a label.
