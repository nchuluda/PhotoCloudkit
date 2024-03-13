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
    
    func upload(selectedPhoto photosPickerItem: PhotosPickerItem?) async throws {
        if let photosPickerItem {
            let savedURL = try await save(photosPickerItem: photosPickerItem)
            let asset = CKAsset(fileURL: savedURL)
            
//            try await add(asset: asset)
            
            guard let coordinates = getCoordinates(for: photosPickerItem) else { throw NSError(domain: "Couldn't get coordinates", code: 1) }
            
            let photo = Photo(image: asset, date: Date(), latitude: coordinates.latitude, longitude: coordinates.longitude)
            
            try await addPhoto(photo: photo)
            print("Photo added")
            
//            metaData(for: photosPickerItem)
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
    
//    func add(asset: CKAsset) async throws {
//        let photo = Photo(image: asset, date: Date())
//        try await addPhoto(photo: photo)
//        print("Photo added")
//    }
    
    func addPhoto(photo: Photo) async throws {
        let record = try await db.save(photo.record)
        guard let photo = Photo(record: record) else { return }
        photosDictionary[photo.recordId!] = photo
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
