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
}

extension Photo {
    init?(record: CKRecord) {
        guard let date = record["date"] as? Date else {
            return nil
        }
        self.init(recordId: record.recordID, date: date)
    }
}

extension Photo {
    var record: CKRecord {
        let record = CKRecord(recordType: "Photo")
        record["date"] = date
        return record
     }
}
