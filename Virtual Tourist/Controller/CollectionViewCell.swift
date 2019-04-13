//
//  CollectionViewCell.swift
//  Virtual Tourist
//
//  Created by Razan on 05/04/2019.
//  Copyright © 2019 Udacity. All rights reserved.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    func initPhoto(_ photo: Photo) {
        
        if photo.imageData != nil {
            DispatchQueue.main.async {
                self.imageView.image = UIImage(data: photo.imageData! as Data)
                self.activityIndicator.stopAnimating() 
            }
            
        } else {
            downloadImage(photo)
        }
    }
    
    func downloadImage(_ photo: Photo) {
        URLSession.shared.dataTask(with: URL(string: photo.imageURL!)!) { (data, response, error) in
            if error == nil {
                DispatchQueue.main.async {
                    self.imageView.image = UIImage(data: data! as Data)
                    self.activityIndicator.stopAnimating()
                    self.saveImage(photo: photo, imageData: data! as NSData)
                }
            }
            }
            
            .resume()
    }
    
    func saveImage(photo: Photo, imageData: NSData) {
        do {
            print("Saving Photo imageData Success")
            photo.imageData = imageData as Data
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let dataController = delegate.dataController
            try dataController.saveContext()
        } catch {
            print("Saving Photo imageData Failed")
        }
    }
    
}

