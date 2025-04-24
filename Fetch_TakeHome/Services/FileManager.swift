//
//  FileManager.swift
//  Fetch_TakeHome
//
//  Created by Khanh Nguyen on 4/24/25.
//

import SwiftUI
import Foundation

class LocalFileManager {
	 static let instance = LocalFileManager()
	 private let fileManager = FileManager.default
	 private let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]

	 private init() {}

	 func saveImage(from urlString: String?, for uuid: String) async throws {
			guard let urlString = urlString, let url = URL(string: urlString) else {
				 throw CachingErrors.invalidURL
			}

			let fileURL = cacheDirectory.appendingPathComponent("\(uuid).jpg")

			if FileManager.default.fileExists(atPath: fileURL.path) {
				 throw CachingErrors.imageAlreadyExists
			}

			let (data, _) = try await URLSession.shared.data(from: url)


			guard let _ = UIImage(data: data) else {
				 throw CachingErrors.urlDoesNotContainImage
			}

			print("Downloading and caching image id: \(uuid)")
			try data.write(to: fileURL)
	 }

	 func retrieveImages(for uuid: String) -> UIImage? {
			let fileURL = cacheDirectory.appendingPathComponent("\(uuid).jpg")
			guard FileManager.default.fileExists(atPath: fileURL.path),
						let image = UIImage(contentsOfFile: fileURL.path) else {
				 return nil
				 
			}
			print("Retrieving image from cache id: \(uuid)")
			return image
	 }

	 func clearAllImages() throws {
			let files = try fileManager.contentsOfDirectory(atPath: cacheDirectory.path())
			for file in files where file.hasSuffix(".jpg") {
				 let fileURL = cacheDirectory.appendingPathComponent(file)
				 try fileManager.removeItem(at: fileURL)
				 print("Deleted image: \(file)")
			}
	 }
}

enum CachingErrors: Error, LocalizedError {
	 case invalidURL
	 case imageAlreadyExists
	 case urlDoesNotContainImage
	 case retrieveError

	 var errorDescription: String? {
			switch self {
				 case .invalidURL:
						return "The provided URL is invalid."
				 case .imageAlreadyExists:
						return "The image already exists in the cache."
				 case .urlDoesNotContainImage:
						return "The URL does not point to valid image data."
				 case .retrieveError:
						return "Error Retrieving Image"

			}
	 }
}
