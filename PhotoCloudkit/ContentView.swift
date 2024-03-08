//
//  ContentView.swift
//  PhotoCloudkit
//
//  Created by Nathan on 3/8/24.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @EnvironmentObject private var model: Model
    @State private var avatarImage: UIImage?
    @State private var photosPickerItem: PhotosPickerItem?
    
    
    var body: some View {
        VStack {
            HStack(spacing: 20) {
                PhotosPicker(selection: $photosPickerItem, matching: .images) {
                    Image(uiImage: avatarImage ?? UIImage(resource: .avatar))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(.circle)
                }
                VStack(alignment: .leading) {
                    Text("My Profile")
                        .font(.largeTitle.bold())
                    Text("iOS Developer")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            Spacer()
        }
        .padding(30)
        .onChange(of: photosPickerItem) { _, _ in
            Task {
                if let photo = photosPickerItem {
                    await model.uploadPhoto(photo: photo)
                }
                
//                if let photosPickerItem,
//                   let data = try? await photosPickerItem.loadTransferable(type: Data.self) {
//                    if let image = UIImage(data: data) {
//                        if let contentType = photosPickerItem.supportedContentTypes.first {
//                            let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("\(UUID().uuidString).\(contentType.preferredFilenameExtension ?? "")")
//                            
////                            do {
////                                try data.write(to: url)
////                                let asset = CKAsset(fileURL: url)
////                            }
//                            avatarImage = image
//                        }
//                    }
//                }
//                photosPickerItem = nil
            }
        }
    }
}

#Preview {
    ContentView()
}
