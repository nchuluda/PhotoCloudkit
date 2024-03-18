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
    @State private var showingRejectedPhotoAlert: Bool = false
    
    var body: some View {
        VStack {
            List {
                ForEach(model.photos, id: \.recordId) { photo in
                    if let url = photo.imageURL,
                       let data = try? Data(contentsOf: url),
                       let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                }
                .onDelete { indexSet in
                    guard let index = indexSet.map({ $0 }).last else {
                        return
                    }
                    
                    let photo = model.photos[index]
                    Task {
                        do {
                            try await model.deletePhoto(photoToBeDeleted: photo)
                        } catch {
                            print(error)
                        }
                    }
                }
            }
            .listStyle(.plain)
            
            HStack(spacing: 20) {
                Spacer()
                PhotosPicker(selection: $photosPickerItem, matching: .images, photoLibrary: .shared()) {
                    Text("Add Photo")
                        .font(.title2)
                }
//                Text("Refresh")
//                    .onTapGesture {
//                        Task {
//                            do {
//                                try await model.populatePhotos()
//                            } catch {
//                                print(error)
//                            }
//                        }
//                    }
            }
        }
        .padding(30)
        .alert("Only photos taken in Campus Martius park are permitted. Please select a different photo.", isPresented: $showingRejectedPhotoAlert) {
            Button("OK", role: .cancel) { }
        }
        .task {
            do {
                try await model.populatePhotos()
            } catch {
                print(error)
            }
        }
        .onChange(of: photosPickerItem) { _, _ in
            Task {
                do {
                    try await model.upload(selectedPhoto: photosPickerItem)
                } catch {
                    showingRejectedPhotoAlert = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
