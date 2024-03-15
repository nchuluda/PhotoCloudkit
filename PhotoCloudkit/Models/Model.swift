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
    @Published  var showingRejectedPhotoAlert: Bool = false
    
    private var db = CKContainer.default().publicCloudDatabase
    
    var photos: [Photo] {
        photosDictionary.values.compactMap { $0 }
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
    
    func photoWithinCircle(photoCoordinates: CLLocationCoordinate2D, centerCoordinates: CLLocationCoordinate2D, radius: Double) -> Bool {
        let g = centerCoordinates.latitude
        let f = centerCoordinates.longitude
        
        let x = photoCoordinates.latitude
        let y = photoCoordinates.longitude
        
        let distanceFromCenter = sqrt( (pow((x - g), 2) + pow((y - f), 2)) )
        
        return distanceFromCenter < radius ? true : false
    }
    
    func checkCoordinates(coordinates: CLLocationCoordinate2D) -> Bool {
        let latitudeAccepted = (42.331011118311146 ... 42.332134578207956).contains(coordinates.latitude)
        let longitudeAccepted = (-83.04710234437916 ... -83.0461048163645).contains(coordinates.longitude)
        
        return latitudeAccepted && longitudeAccepted ? true : false
    }
    
    func upload(selectedPhoto photosPickerItem: PhotosPickerItem?) async throws {
        if let photosPickerItem {
            let savedURL = try await save(photosPickerItem: photosPickerItem)
            let asset = CKAsset(fileURL: savedURL)
                        
            guard let coordinates = getCoordinates(for: photosPickerItem) else { throw NSError(domain: "Couldn't get coordinates", code: 1) }
            
            // CHECK IF PHOTO IS WITHIN CIRCLE
            // CENTER OF CAMPUS MARITUS PARK - RADIUS SHOULD BE 0.0006
            let centerCampusMartius = CLLocationCoordinate2D(latitude: 42.33160449450324, longitude: -83.04668146008768)
            
            if photoWithinCircle(photoCoordinates: coordinates, centerCoordinates: centerCampusMartius, radius: 0.0006) {
                let photo = Photo(image: asset, date: Date(), latitude: coordinates.latitude, longitude: coordinates.longitude)
                try await addPhoto(photo: photo)
                print("Photo added")
            } else {
                throw NSError(domain: "Not within the circle", code: 1)
            }
            
            
            // CHECK IF PHOTO IS IN RECTANGLE GEOFENCE
//            if checkCoordinates(coordinates: coordinates) {
//                let photo = Photo(image: asset, date: Date(), latitude: coordinates.latitude, longitude: coordinates.longitude)
//                try await addPhoto(photo: photo)
//                print("Photo added")
//            } else {
//                throw NSError(domain: "Not within GPS range", code: 1)
//            }
        }
    }
    
    func save(photosPickerItem: PhotosPickerItem) async throws -> URL {
        guard let data = try? await photosPickerItem.loadTransferable(type: Data.self) else {
            throw NSError(domain: "Error loading data from photo", code: 1)
        }
        
        let contentType = photosPickerItem.supportedContentTypes.first
        
        guard let url =  FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("\(UUID().uuidString).\(contentType?.preferredFilenameExtension ?? "")") else {
            throw NSError(domain: "Error writing photo to cache directory", code: 1)
        }
        
        try data.write(to: url)
        return url
    }
    
    func addPhoto(photo: Photo) async throws {
        let record = try await db.save(photo.record)
        guard let photo = Photo(record: record) else { return }
        photosDictionary[photo.recordId!] = photo
    }
    
    func deletePhoto(photoToBeDeleted: Photo) async throws {
            photosDictionary.removeValue(forKey: photoToBeDeleted.recordId!)
            
            do {
                let _ = try await db.deleteRecord(withID: photoToBeDeleted.recordId!)
            } catch {
                photosDictionary[photoToBeDeleted.recordId!] = photoToBeDeleted
                print(error)
            }
        }
    
//    func metaData(for photosPickerItem: PhotosPickerItem) {
//        if let id = photosPickerItem.itemIdentifier {
//            let result = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
//            let phAsset = result.firstObject
//            print(phAsset?.location?.coordinate ?? "no location")
//        }
//    }
    
    func getCoordinates(for photosPickerItem: PhotosPickerItem) -> CLLocationCoordinate2D? {
        if let id = photosPickerItem.itemIdentifier {
            let result = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
            let phAsset = result.firstObject
            guard let coordinates = phAsset?.location?.coordinate else { return nil }
            print(phAsset?.location?.coordinate ?? "no location")
            return coordinates
        } else {
            return nil
        }
    }
}
