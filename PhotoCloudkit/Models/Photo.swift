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
    let date: Date
    var imageURL: URL?
}

extension Photo {
    init?(record: CKRecord) {
        guard let date = record["date"] as? Date else { return nil }
        let image = record["image"] as? CKAsset
        let imageURL = image?.fileURL as? URL
        self.init(recordId: record.recordID, image: image, date: date, imageURL: imageURL)
    }
}

extension Photo {
    var record: CKRecord {
        let record = CKRecord(recordType: "Photo")
        record["date"] = date
        record["image"] = image
        return record
     }
}
