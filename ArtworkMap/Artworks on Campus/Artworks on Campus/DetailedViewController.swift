//
//  DetailedViewController.swift
//  Artworks on Campus
//
//  Created by Alex Finnigan on 17/12/2018.
//  Copyright © 2018 Alex Finnigan. All rights reserved.
//

import UIKit
import CoreData

/*
 * This class will show a detailed view of all the information concerning the selected artwork from the table.
 */
class DetailedViewController: UIViewController {
    
    // varibale to contain artwork info.
    var art: artwork?
    
    // Label variable
    @IBOutlet weak var artistName: UILabel!
    
    // ImageView variable
    @IBOutlet weak var artImage: UIImageView!
    
    // Title variable
    @IBOutlet weak var artTitle: UILabel!
    
    // Year variable
    @IBOutlet weak var yearOfWork: UILabel!
    
    // Info variable
    @IBOutlet weak var artInfo: UILabel!
    
    // Initialise variables for persistence storage use.
    var newImage: NSManagedObject?
    var context: NSManagedObjectContext?
    
    // Inital method
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set artist name
        artistName.text = art?.artist
        
        // Check if the image for the art has been previously saved to Core Data. If not, download it.
        if !fetchImage() {
            let fixedPath = (art?.fileName)!.replacingOccurrences(of: " ", with: "%20", options: .regularExpression)
            let url = URL(string: "https://cgi.csc.liv.ac.uk/~phil/Teaching/COMP327/artwork_images/"+fixedPath)
            artImage.load(url: url!)
            artImage.contentMode = .scaleAspectFit
            
            // Save to Core Data
//            let newPic = NSEntityDescription.insertNewObject(forEntityName: "ArtImage", into: context!) as! ArtImage
//            newPic.title = art?.title
//            let imageData: NSData = artImage.image!.pngData()! as NSData
//            newPic.picture = imageData as Data
//            saved()
//            print("done array add")
        }
        
        // Set title
        artTitle.text = art?.title
        
        // Set year
        yearOfWork.text = art?.yearOfWork
        
        // Set info
        artInfo.text = art?.Information
        
    }
    
    // Searches through Core Data for the report the user is viewing and returns true if it was found,
    // or false if it was not found.
    func fetchImage() -> Bool {
        var check = false
        let artName = art?.title
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ArtImage")
        
        request.predicate = NSPredicate(format: "title == %@", artName!)
        
        request.returnsObjectsAsFaults = false
        do {
            let results = try context?.fetch(request)
            for i in results! {
                // Found it.
                check = true
                artImage.image = i as? UIImage
                artImage.contentMode = .scaleAspectFit
                break
            }
        } catch {
            print("couldn't fetch results")
        }
        return check
    }
    
    // Saves the current state of the Core Data. This will be called after any inserts or deletes.
    func saved(){
        do {
            try context?.save()
            
            print("Saved")
        } catch {
            print("there was an error")
        }
    }

}

// Extension allows use of the load feature so the downloaded image can be uploaded to the imageView.
extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}
