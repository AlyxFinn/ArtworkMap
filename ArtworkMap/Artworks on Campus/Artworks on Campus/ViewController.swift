//
//  ViewController.swift
//  Artworks on Campus
//
//  Created by Alex Finnigan on 12/12/2018.
//  Copyright © 2018 Alex Finnigan. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

// First structure to decode individual art data.
struct artwork: Decodable {
    let id: String
    let title: String
    let artist: String
    let yearOfWork: String?
    let Information: String
    let lat: String
    let long: String
    let location: String
    let locationNotes: String
    let fileName: String
    let lastModified: String
    let enabled: String
}

// Second structure to store the first struct in an array.
struct artworks: Decodable {
    let artworks2: [artwork]
}

/*
 * This is the main class that will decode the art from the JSON file and present it using a table and map.
 * It will also enable a search bar to filter the table of artwork.
 */
class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate, CLLocationManagerDelegate {
    
    // Map variable
    @IBOutlet weak var mapView: MKMapView!
    
    // TableView variable
    @IBOutlet weak var table: UITableView!
    
    // Arrays used to for storing and sorting the artwork.
    var arts = [artwork]()
    var orderedArtwork = [artwork]()
    var sectionedArtwork = [(location: String, artwork: [artwork])]()
    
    // Arrays used to fill the tables
    var artTitle = [String]()
    var artist = [String]()
    var location = [String]()
    
    // Stores information of the user's location
    let initialLocation = CLLocation(latitude: 53.406566, longitude: -2.966531)
    var locationManager = CLLocationManager() //create an instance to manage our the user’s location.
    
    // Stores artwork when filtering
    var filteredArt = [artwork]()
    
    // These variable will be used for fetching and storing the art's image in the Core Data.
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var context: NSManagedObjectContext?
    var entity: NSEntityDescription?
    var newImage: NSManagedObject?
    
    // Initial method called at start
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialise variables used for persistent storage.
        context = appDelegate.persistentContainer.viewContext
        entity = NSEntityDescription.entity(forEntityName: "ArtImage", in: context!)!
        newImage = NSManagedObject(entity: entity!, insertInto: context)
        
        // Initialise locational features
        locationManager.delegate = self as CLLocationManagerDelegate //we want messages about location
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.requestWhenInUseAuthorization() //ask the user for permission to get their location
        locationManager.startUpdatingLocation() //and start receiving those messages (if we’re allowed to)
        
        // Begin JSON decoder
        if let url = URL(string: "https://cgi.csc.liv.ac.uk/~phil/Teaching/COMP327/artworksOnCampus/data.php?class=artworks2&lastUpdate=2017-11-01"){
            let session = URLSession.shared
            session.dataTask(with: url) { (data, response, err) in
                guard let jsonData = data else { return }
                do {
                    let decoder = JSONDecoder()
                    let artList = try decoder.decode(artworks.self, from: jsonData)
                    
                    // Store decoded file into array
                    self.arts = artList.artworks2
                    
                    // Sort array by location
                    self.orderedArtwork = self.arts.sorted{
                        let distance0 = CLLocation(latitude: Double($0.lat)!, longitude: Double($0.long)!)
                        let distance1 = CLLocation(latitude: Double($1.lat)!, longitude: Double($1.long)!)
                        if (self.initialLocation.distance(from: distance0)) != (self.initialLocation.distance(from: distance1)){
                            return self.initialLocation.distance(from: distance0) < self.initialLocation.distance(from: distance1)
                        } else {
                            return self.initialLocation.distance(from: distance0) > self.initialLocation.distance(from: distance1)
                        }
                    }
                    
                    // Populate the table contents
                    self.populateData()
                    
                    // Finds every unique location sorted by distance
                    var encountered = Set<String>()
                    var locations: [String] = []
                    for value in self.orderedArtwork {
                        if encountered.contains(value.location) {
                            // Do not add a duplicate element.
                        }
                        else {
                            // Add value to the set.
                            encountered.insert(value.location)
                            // ... Append the value.
                            locations.append(value.location)
                        }
                    }
                    
                    // Splits artwork up between location
                    for i in 0..<locations.count {
                        var artArray = [artwork]()
                        for j in 0..<self.orderedArtwork.count {
                            if locations[i] == self.orderedArtwork[j].location {
                                artArray.append(self.orderedArtwork[j])
                            }
                        }
                        self.sectionedArtwork.append((location: locations[i], artwork: artArray))
                    }
                    
                    print("sorted artwork")
                    
                    // Creates annotations to be plotted on the map.
                    var annotations = [MKPointAnnotation]()
                    for i in 0..<locations.count {
                        print("----------------------------------")
                        var multipleArt = false
                        let annotation = MKPointAnnotation()
                        let diffAnnotation = MKPointAnnotation()
                        let lastAnnotation = MKPointAnnotation()
                        let multiArtAnnotation = MKPointAnnotation()
                        var subtitle = String()
                        for j in 0..<self.sectionedArtwork[i].artwork.count {
                            let art = self.sectionedArtwork[i].artwork[j]
                            if self.sectionedArtwork[i].artwork.count > 1 {
                                let checker = self.sectionedArtwork[i].artwork[j+1]
                                if ((Double(art.lat)!) == (Double(checker.lat)!)) && ((Double(art.long)!) == (Double(checker.long)!)) {
                                    print("same coords")
                                    multiArtAnnotation.coordinate = CLLocationCoordinate2D(latitude: Double(art.lat)!, longitude: Double(art.long)!)
                                    multiArtAnnotation.title = "Multiple art at: "+art.location
                                    subtitle = subtitle + "● " + art.title+"\n"
                                    multipleArt = true
                                    if checker.title == self.sectionedArtwork[i].artwork.last?.title {
                                        print("adding last similar loc element")
                                        subtitle = subtitle + "● " + checker.title
                                        break
                                    }
                                } else {
                                    print("different coords, same loc")
                                    diffAnnotation.coordinate = CLLocationCoordinate2D(latitude: Double(art.lat)!, longitude: Double(art.long)!)
                                    diffAnnotation.title = art.title
                                    print(diffAnnotation.title!)
                                    diffAnnotation.subtitle = art.artist
                                    annotations.append(diffAnnotation)
                                    if checker.title == self.sectionedArtwork[i].artwork.last?.title {
                                        print("adding last element")
                                        lastAnnotation.coordinate = CLLocationCoordinate2D(latitude: Double(checker.lat)!, longitude: Double(checker.long)!)
                                        lastAnnotation.title = checker.title
                                        print(lastAnnotation.title!)
                                        lastAnnotation.subtitle = checker.artist
                                        annotations.append(lastAnnotation)
                                        break
                                    }
                                }
                            } else {
                                print("only 1 entry")
                                annotation.coordinate = CLLocationCoordinate2D(latitude: Double(art.lat)!, longitude: Double(art.long)!)
                                annotation.title = art.title
                                print(annotation.title!)
                                annotation.subtitle = art.artist
                                annotations.append(annotation)
                            }
                        }
                        if multipleArt == true {
                            print("adding multiPoints")
                            multiArtAnnotation.subtitle = subtitle
                            print(subtitle)
                            annotations.append(multiArtAnnotation)
                        }
                    }
                    // Adds annotations to the map.
                    self.mapView.addAnnotations(annotations)
                    
                    print("added annotations")
                    
                    // Runs table and map refresh on the main thread.
                    DispatchQueue.main.async {
                        self.table.delegate = self
                        self.table.dataSource = self
                        self.table.reloadData()
                        self.mapView.delegate = self as MKMapViewDelegate
                        self.mapView.showAnnotations(annotations, animated: true)
                    }
                    
                } catch let jsonErr {
                    print("Error decoding JSON", jsonErr)
                }
                }.resume()
        }
        
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Filter artwork results"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
    }
    
    // Centers the map view on the current location
    let regionRadius: CLLocationDistance = 125
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
        print("completed center func")
    }
    
    // Sets up the number of sections depending on how many unique years there are.
    func numberOfSections(in tableView: UITableView) -> Int {
        if isFiltering(){
            return 1
        }
        return sectionedArtwork.count
    }
    
    // Adds the location titles for each header in the table.
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if isFiltering() {
            return "Filtered Results"
        }
        return sectionedArtwork[section].location
    }
    
    // Sets up the number of rows inside each section.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() {
            return filteredArt.count
        }
        return sectionedArtwork[section].artwork.count
    }
    
    // Populates each individual cell inside a section. It will also check if the table is being filtered
    // and will recreate the table accordingly.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Create reusable variable for a cell.
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "cell")
        
        if isFiltering() {
            cell.textLabel?.text = filteredArt[indexPath.row].title
            cell.detailTextLabel?.text = filteredArt[indexPath.row].artist
        } else {
            cell.textLabel?.text = sectionedArtwork[indexPath.section].artwork[indexPath.row].title
            cell.detailTextLabel?.text = sectionedArtwork[indexPath.section].artwork[indexPath.row].artist
        }
        // Add title of the report and the authors name to the cell.
//        cell.textLabel?.text = sectionedArtwork[indexPath.section].artwork[indexPath.row].title
//        cell.detailTextLabel?.text = sectionedArtwork[indexPath.section].artwork[indexPath.row].artist
        
        // Display the cell with the given information.
        return cell
    }
    
    // Creates variables that will allow the specific artwork to be sent to the detail page.
    var selectedSec: Int?
    var selectedRow: Int?
    
    // Sets variables and performs the segue.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedSec = indexPath.section
        selectedRow = indexPath.row
        performSegue(withIdentifier: "toDetailedView", sender: nil)
    }
    
    // Sends information to the next view for use.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("setting instances")
        if segue.identifier == "toDetailedView" {
            if sender == nil {
                print("set from cell")
                // Create new instance to send to.
                let DetailedViewController = segue.destination as! DetailedViewController

                // Send variables to overwrite ones currently initialised inside that view.
                DetailedViewController.art = sectionedArtwork[selectedSec!].artwork[selectedRow!]
                DetailedViewController.newImage = newImage
                DetailedViewController.context = context
            }
        }
        print("begin segue")
    }
    
    // When the user returns to the main view, it will refresh the table data.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        centerMapOnLocation(location: initialLocation)
        table.reloadData()
    }
    
    // Populates the content for the table on startup
    func populateData(){
        // Populate titles
        if artTitle.count == 0 {
            for i in 0..<orderedArtwork.count {
                artTitle.append(orderedArtwork[i].title)
            }
            print("populated titles")
        }
        
        // Populate artists
        if artist.count == 0 {
            for i in 0..<orderedArtwork.count {
                artist.append(orderedArtwork[i].artist)
            }
            print("populated artists")
        }
        
        // Populate locations
        if location.count == 0 {
            for i in 0..<orderedArtwork.count {
                location.append(orderedArtwork[i].location)
            }
            print("populated locations")
        }
    }
    
    // Sets up the map for the user's position
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locationOfUser = locations[0] //get the first location (ignore any others)
        let latitude = locationOfUser.coordinate.latitude
        let longitude = locationOfUser.coordinate.longitude
        let latDelta: CLLocationDegrees = 0.002
        let lonDelta: CLLocationDegrees = 0.002
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(center: location, span: span)
        self.mapView.setRegion(region, animated: true)
        print("completed loc manageer")
    }
    
    // Initialises the search bar for use.
    let searchController = UISearchController(searchResultsController: nil)
    
    // Check the searchbar is empty
    func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    // Filters table based on text inside the searchbar.
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        filteredArt = orderedArtwork.filter({( art : artwork) -> Bool in
            return art.title.lowercased().contains(searchText.lowercased())
        })
        
        table.reloadData()
    }
    
    // Checks if the searchbar is filtering the table.
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
}

// Extension to allow use of the searchbar.
extension ViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}
