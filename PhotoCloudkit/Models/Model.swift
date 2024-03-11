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
}
