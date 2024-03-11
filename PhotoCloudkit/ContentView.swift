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
                
//                model.photosDictionary.values.forEach { photo in
//                    if let url = photo.image?.fileURL,
//                       let data = try? Data(contentsOf: url),
//                       let image = UIImage(data: data) {
//                        Image(uiImage: image)
//                            .resizable()
//                            .aspectRatio(contentMode: .fit)
//                    }
//                }
                
//                ForEach(model.photos, id: \.recordId) { photo in
//                    Text("\((photo.image?.fileURL ?? URL(string: "nothing"))!)")
//                    
//                }
                
//                ForEach(model.photos, id: \.recordId) { photo in
//                    Text("\((String(photo.imageURL?.path) ?? URL(string: "nothing2")))")
//                }
                
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
                PhotosPicker(selection: $photosPickerItem, matching: .images) {
                    Text("Add Photo")
                        .font(.title2)
//                    Button {
//                        
//                    } label: {
//                        Label("Add Photo", systemImage: "plus")
//                    }
//                    .buttonStyle(.borderedProminent)
//                    Image(uiImage: avatarImage ?? UIImage(resource: .avatar))
//                        .resizable()
//                        .aspectRatio(contentMode: .fill)
//                        .frame(width: 100, height: 100)
//                        .clipShape(.circle)
                }
                Text("Refresh")
                    .onTapGesture {
                        Task {
                            do {
                                try await model.populatePhotos()
                                print("calling model.populatePhotos()")
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
                if let photosPickerItem,
                   let data = try? await photosPickerItem.loadTransferable(type: Data.self),
                   let contentType = photosPickerItem.supportedContentTypes.first,
                   let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("\(UUID().uuidString).\(contentType.preferredFilenameExtension ?? "")") {
                    do {
                        try data.write(to: url)
                        let asset = CKAsset(fileURL: url)
                        let photo = Photo(image: asset, date: Date())
                        try await model.addPhoto(photo: photo)
                        print("Photo added")
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
