//
//  ContentView.swift
//  PhotoCloudkit
//
//  Created by Nathan on 3/8/24.
//

import SwiftUI
import PhotosUI
import CloudKit

struct ContentView: View {
    @EnvironmentObject private var model: Model
    @State private var photosPickerItem: PhotosPickerItem?
    
    var body: some View {
        VStack {
            ScrollView {
                ForEach(model.photos, id: \.recordId) { photo in
                    if let url = photo.imageURL,
                       let data = try? Data(contentsOf: url),
                       let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                }
            }
            
            HStack(spacing: 20) {
                Spacer()
                PhotosPicker(selection: $photosPickerItem, matching: .images, photoLibrary: .shared()) {
                    Text("Add Photo")
                        .font(.title2)
                }
                Text("Refresh")
                    .onTapGesture {
                        Task {
                            do {
                                try await model.populatePhotos()
                            } catch {
                                print(error)
                            }
                        }
                    }
                
            }
        }
        .padding(30)
        .task {
            do {
                try await model.populatePhotos()
            } catch {
                print(error)
            }
        }
        .onChange(of: photosPickerItem) { _, _ in
            Task {
                try await model.upload(selectedPhoto: photosPickerItem)
            }
            
            //            Task {
            //                if let photosPickerItem,
            //                   let data = try? await photosPickerItem.loadTransferable(type: Data.self),
            //                   let contentType = photosPickerItem.supportedContentTypes.first,
            //                   let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("\(UUID().uuidString).\(contentType.preferredFilenameExtension ?? "")") {
            //                    do {
            //
            //                        try data.write(to: url)
            //
            //                        // METADATA
            //                        let options = [kCGImageSourceShouldCache as String:  kCFBooleanFalse]
            //                        let nsdata = NSData(contentsOf: url)
            //                        let imgSrc = CGImageSourceCreateWithData(nsdata!, options as CFDictionary)
            ////                        let metadata = CGImageSourceCopyPropertiesAtIndex(imgSrc!, 0, options as CFDictionary)
            //                        let metadata = CGImageSourceCopyPropertiesAtIndex(imgSrc!, 0, nil) as? [CFString: Any]
            //
            //                        if let gpsData = metadata?[kCGImagePropertyGPSDictionary] as? [CFString: Any] {
            //                            let latitude = gpsData[kCGImagePropertyGPSLatitude] as? Double ?? 0.0
            //                            var longitude = gpsData[kCGImagePropertyGPSLongitude] as? Double ?? 0.0
            //                            let longitudeRef = gpsData[kCGImagePropertyGPSLongitudeRef] as? String ?? ""
            //
            //                            if longitudeRef == "W" {
            //                                longitude *= -1
            //                            }
            //                            print("longitudeRef: \(longitudeRef)")
            //                            print("gpsdata: \(gpsData)")
            //                            print("lat: \(latitude) long: \(longitude)")
            //                        }
            //
            //
            //                        // SAVE PHOTO TO CLOUDKIT
            //                        let asset = CKAsset(fileURL: url)
            //                        let photo = Photo(image: asset, date: Date())
            //                        try await model.addPhoto(photo: photo)
            //                        print("Photo added")
            //
            //
            //                    }
            //                }
            //            }
            

            

            
            //            Task {
            //                if let photosPickerItem,
            //                   let data = try? await photosPickerItem.loadTransferable(type: Data.self),
            //                   let contentType = photosPickerItem.supportedContentTypes.first,
            //                   let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("\(UUID().uuidString).\(contentType.preferredFilenameExtension ?? "")") {
            //                    do {
            //                        try data.write(to: url)
            //                        let asset = CKAsset(fileURL: url)
            //
            //                        if let id = photosPickerItem.itemIdentifier {
            //                            let result = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
            //                            let phAsset = result.firstObject
            //                            print(phAsset?.location?.coordinate ?? "no location")
            //                        }
            //
            ////                        print("\(phAsset?.location ?? CLLocation(latitude: 180.0, longitude: 180.0))")
            //
            //                        let photo = Photo(image: asset, date: Date())
            //                        try await model.addPhoto(photo: photo)
            //                        print("Photo added")
            //
            //                    }
            //                }
            //            }
        }
    }
}

#Preview {
    ContentView()
}
