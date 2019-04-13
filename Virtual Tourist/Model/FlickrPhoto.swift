//
//  FlickrPhoto.swift
//  Virtual Tourist
//
//  Created by Razan on 05/04/2019.
//  Copyright © 2019 Udacity. All rights reserved.
//

import Foundation
class FlickrPhoto {
    
    let id:String
    let secret:String
    let server:String
    let farm:Int
    
    init(id: String, secret: String, server: String, farm: Int) {
        
        self.id = id
        self.secret = secret
        self.server = server
        self.farm = farm
    }
    
    func imageURLString() -> String {
        
        return "https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret)_q.jpg"
    }
    
}
