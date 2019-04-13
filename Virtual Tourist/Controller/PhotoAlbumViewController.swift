//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Razan on 05/04/2019.
//  Copyright © 2019 Udacity. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class PhotoAlbumViewController: UIViewController,UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout{
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var coordinate:CLLocationCoordinate2D!
    var pin: Pin!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    let spacingBetweenItems:CGFloat = 5
    let totalCellCount:Int = 25
    var flickrPhotos:[FlickrPhoto] = []
    var savedPhotos:[Photo] = []
    var dataController:DataController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataController = getDataController()
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin == %@", argumentArray: [pin])
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: dataController.viewContext,
            sectionNameKeyPath: nil,
            cacheName: "Photos")
        
        addAnnotationToMap()

        savedPhotos = loadSavedPhoto()!
        if self.loadSavedPhoto() != nil && savedPhotos.count != 0 {
            savedPhotos = self.loadSavedPhoto()!
            showSavedData()
            
        } else {
            loadFromNetwork()
      }
    }
    
    func addAnnotationToMap() {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        mapView.showAnnotations([annotation], animated: true)
    }
    
    func loadFromNetwork() {
        print("loadFromNetwork")
        setnewCollectionButton(bool: false)
        
        deletePhoto()
        savedPhotos.removeAll()
        collectionView.reloadData()
        
        getFlickrPhotos { (flickrPhotos) in
            
            if flickrPhotos != nil {
                DispatchQueue.main.async {
                    
                    self.addCoreData(flickrPhotos: flickrPhotos!, pin: self.pin)
                    self.savedPhotos = self.loadSavedPhoto()!
                    self.showSavedData()
                    self.setnewCollectionButton(bool: true)
                }
            }
        }
    }
    
    func getFlickrPhotos(completion: @escaping (_ result:[FlickrPhoto]?) -> Void) {
        
        var result:[FlickrPhoto] = []
        FlickrNetwork.getFlickrImages(lat: coordinate.latitude, lng: coordinate.longitude) { (success, flickrImages) in
            if success {
                
                if flickrImages!.count > self.totalCellCount {
                    var randomArray:[Int] = []
                    
                    while randomArray.count < self.totalCellCount {
                        
                        let random = arc4random_uniform(UInt32(flickrImages!.count))
                        if !randomArray.contains(Int(random)) { randomArray.append(Int(random)) }
                    }
                    
                    for random in randomArray {
                        
                        result.append(flickrImages![random])
                    }
                    
                    completion(result)
                    
                } else {
                    
                    completion(flickrImages!)
                }
                
            } else {
                completion(nil)
            }
        }
    }
    
    func setnewCollectionButton(bool: Bool) {
        newCollectionButton.isEnabled = bool
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.savedPhotos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionCell", for: indexPath) as! CollectionViewCell
        cell.activityIndicator.startAnimating()
        if( self.savedPhotos[(indexPath as NSIndexPath).row].imageData != nil){
        cell.imageView.image = UIImage(data: self.savedPhotos[(indexPath as NSIndexPath).row].imageData!)
        cell.activityIndicator.isHidden = true
        }
            
        else{
            cell.initPhoto(savedPhotos[indexPath.row])
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,didSelectItemAt indexPath: IndexPath){
        let alert = UIAlertController(title: "Alert", message: "Are you sure you want to remove it", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Remove", style: UIAlertAction.Style.default, handler: { action in
            let photoToDelete = self.fetchedResultsController.object(at: indexPath)
            self.dataController.viewContext.delete(photoToDelete)
            try? self.dataController.viewContext.save()
            if self.loadSavedPhoto() != nil && self.savedPhotos.count != 0 {
                self.savedPhotos = self.loadSavedPhoto()!
                self.showSavedData()
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }
    
    func getDataController() -> DataController {
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        return delegate.dataController
    }
    
    func addCoreData(flickrPhotos:[FlickrPhoto], pin:Pin) {
        
        for image in flickrPhotos {
            do {
                let photo = Photo(context: dataController.viewContext)
                photo.pin = pin
                photo.imageURL = image.imageURLString()
                photo.imageData = nil
                photo.index = Int16(flickrPhotos.index{$0 === image}!)
                try dataController.saveContext()
                
            } catch {
                print("Add Core Data Failed")
            }
        }
    }
    
    func loadSavedPhoto() -> [Photo]? {
        
        do {
            
            var photoArray:[Photo] = []
            try fetchedResultsController.performFetch()
            let photoCount = try fetchedResultsController.managedObjectContext.count(for: fetchedResultsController.fetchRequest)
            
            for index in 0..<photoCount {
                photoArray.append(fetchedResultsController.object(at: IndexPath(row: index, section: 0)) )
            }
            return photoArray.sorted(by: {$0.index < $1.index})
            
        } catch {
            
            return nil
        }
    }
    
    func showSavedData() {
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    func deletePhoto() {
        for image in savedPhotos {
            self.dataController.viewContext.delete(image)
        }
    }
    @IBAction func onButtonClick(_ sender: Any) {
       
            self.loadFromNetwork()
    }
    @IBAction func onCancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
