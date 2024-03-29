//
//  Photo.swift
//  PhotoCloudkit
//
//  Created by Nathan on 3/8/24.
//

import Foundation
import CloudKit

struct Photo {
    var recordId: CKRecord.ID?
    var image: CKAsset?
    var compressedImage: CKAsset?
    let date: Date
    var imageURL: URL?
    var compressedImageURL: URL?
    
    var latitude: Double?
    var longitude: Double?
}

extension Photo {
    init?(record: CKRecord) {
        guard let date = record["date"] as? Date else { return nil }
        let image = record["image"] as? CKAsset
        let imageURL = image?.fileURL as? URL
        let compressedImage = record["compressedImage"] as? CKAsset
        let compressedImageURL = compressedImage?.fileURL as? URL
        let location = record["location"] as? CLLocation
        
        self.init(recordId: record.recordID, image: image, compressedImage: compressedImage, date: date, imageURL: imageURL, compressedImageURL: compressedImageURL, latitude: location?.coordinate.latitude, longitude: location?.coordinate.longitude)
    }
}

extension Photo {
    var record: CKRecord {
        let record = CKRecord(recordType: "Photo")
        // use lat and long to create a cllocation. sotre the cllocation in your record
        record["date"] = date
        record["image"] = image
        record["compressedImage"] = compressedImage
        
        if let latitude,
           let longitude {
            record["location"] = CLLocation(latitude: latitude, longitude: longitude)
        }
        
        return record
     }
}
