//
//  Model.swift
//  PhotoCloudkit
//
//  Created by Nathan on 3/8/24.
//

import Foundation
import CloudKit
import SwiftUI
import PhotosUI
import Photos

@MainActor
class Model: ObservableObject {
    @Published private var photosDictionary: [CKRecord.ID: Photo] = [:]
    
    private var db = CKContainer.default().publicCloudDatabase
    
    var photos: [Photo] {
        photosDictionary.values.compactMap { $0 }
    }
    
    func addPhoto(photo: Photo) async throws {
        let record = try await db.save(photo.record)
        guard let photo = Photo(record: record) else { return }
        photosDictionary[photo.recordId!] = photo
    }
    
    func populatePhotos() async throws {
        let query = CKQuery(recordType: "Photo", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        let result = try await db.records(matching: query)
        let records = result.matchResults.compactMap { try? $0.1.get() }
        
        records.forEach { record in
            print(record)
            photosDictionary[record.recordID] = Photo(record: record)
        }
    }
    

    
//    func getImageMetadata(for asset: PHAsset) {
//        let options = PHContentEditingInputRequestOptions()
//        options.canHandleAdjustmentData = {(adjustmentData: PHAdjustmentData) -> Bool in
//            return adjustmentData.formatIdentifier == "nchuluda.PhotoCloudkit"
//        }
//        asset.requestContentEditingInput(with: options) { (input, _) in
//            guard let input = input else { return }
//            guard let url = input.fullSizeImageURL else { return }
//            let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil)
//            let metadata = CGImageSourceCopyPropertiesAtIndex(imageSource!, 0, nil) as? [CFString: Any]
//            // Now you can access individual metadata attributes from the 'metadata' dictionary
//            
////            if let exifData = metadata?[kCGImagePropertyExifDictionary] as? [CFString: Any] {
////                // Access EXIF metadata
////                
////                let aperture = exifData[kCGImagePropertyExifFNumber] as? Float ?? 0.0
////                let shutterSpeed = exifData[kCGImagePropertyExifExposureTime] as? Float ?? 0.0
////                let iso = exifData[kCGImagePropertyExifISOSpeedRatings] as? Int ?? 0
////                // ... access other EXIF attributes
////            }
//            
//            if let gpsData = metadata?[kCGImagePropertyGPSDictionary] as? [CFString: Any] {
//                let latitude = gpsData[kCGImagePropertyGPSLatitude] as? Double ?? 0.0
//                let longitude = gpsData[kCGImagePropertyGPSLongitude] as? Double ?? 0.0
//                
//            }
//        }
//    }
    
    func upload(selectedPhoto photosPickerItem: PhotosPickerItem?) async throws {
        if let photosPickerItem {
            let savedURL = try await save(photosPickerItem: photosPickerItem)
            let asset = CKAsset(fileURL: savedURL)
            try await add(asset: asset)
            metaData(for: photosPickerItem)
        }
    }
    
    func save(photosPickerItem: PhotosPickerItem) async throws -> URL {
        guard let data = try? await photosPickerItem.loadTransferable(type: Data.self) else {
            throw NSError(domain: "Error", code: 1)
        }
        
        let contentType = photosPickerItem.supportedContentTypes.first
        
        guard let url =  FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("\(UUID().uuidString).\(contentType?.preferredFilenameExtension ?? "")") else {
            throw NSError(domain: "Error", code: 1)
        }
        
        try data.write(to: url)
        return url
        
    }
    
    func add(asset: CKAsset) async throws {
        let photo = Photo(image: asset, date: Date())
        try await addPhoto(photo: photo)
        print("Photo added")
    }
    
    
    func metaData(for photosPickerItem: PhotosPickerItem) {
        if let id = photosPickerItem.itemIdentifier {
            let result = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
            let phAsset = result.firstObject
            print(phAsset?.location?.coordinate ?? "no location")
        }
    }
}
