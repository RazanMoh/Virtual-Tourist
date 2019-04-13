//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Razan on 05/04/2019.
//  Copyright © 2019 Udacity. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate  {
    
    @IBOutlet weak var mapView: MKMapView!
    var gesture:Bool!
    var pins:[Pin] = []
    var dataController:DataController!
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setGesture(bool: true)
       
        dataController = getDataController()
        
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(
            key: "creationDate",
            ascending: false
        )
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: dataController.viewContext,
            sectionNameKeyPath: nil,
            cacheName: "Pins")
        
        let savedPins = loadSavedPin()
        
        addPinsOnMap(savedPins)
    }
    
    func setGesture(bool: Bool) {
        self.gesture = bool
    }
    
    @IBAction func responseLongTapAction(_ sender: Any) {
        
        if gesture {
            let gestureRecognizer = sender as! UILongPressGestureRecognizer
            let gestureTouchLocation = gestureRecognizer.location(in: mapView)
            addAnnotationToMap(fromPoint: gestureTouchLocation)
           setGesture(bool: false)
        }
    }
    
    func addAnnotationToMap(fromPoint: CGPoint) {
        
        let coordToAdd = mapView.convert(fromPoint, toCoordinateFrom: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordToAdd
        
        mapView.addAnnotation(annotation)
        
        var savePin = Pin(context: dataController.viewContext)
        savePin.latitude = annotation.coordinate.latitude
        savePin.longitude = annotation.coordinate.longitude
        try? dataController.saveContext()
    
        pins.append(savePin)
    }
    
    func addAnnotationToMap(fromCoord: CLLocationCoordinate2D) {
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = fromCoord
        mapView.addAnnotation(annotation)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        performSegue(withIdentifier: "pin", sender: view.annotation?.coordinate)
        mapView.deselectAnnotation(view.annotation, animated: false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "pin" {
            let destination = segue.destination as! PhotoAlbumViewController
            let coord = sender as! CLLocationCoordinate2D
            for pin in pins {
                if pin.latitude == coord.latitude && pin.longitude == coord.longitude {
                    destination.coordinate = coord
                    destination.pin = pin
                    break
                }
            }
        }
    }
    
    func loadSavedPin() -> [Pin]? {
        
        do {
            var pinArray:[Pin] = []
            try fetchedResultsController.performFetch()
            let pinCount = try fetchedResultsController.managedObjectContext.count(for: fetchedResultsController.fetchRequest)
            for index in 0..<pinCount {
                pinArray.append(fetchedResultsController.object(at: IndexPath(row: index, section: 0)) as! Pin)
            }
            return pinArray
            
        } catch {
            return nil
        }
    }
    
    func addPinsOnMap(_ savedPins: [Pin]?) {
        if savedPins != nil {
            pins = savedPins!
            for pin in pins {
                let coord = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
                addAnnotationToMap(fromCoord: coord)
            }
        }
    }
    
    func getDataController() -> DataController {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        return delegate.dataController
    }
}
