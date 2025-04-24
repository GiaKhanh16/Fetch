//
//  swifttesting.swift
//  FetchTakeHome_Final
//
//  Created by Khanh Nguyen on 4/23/25.
//

import Testing
import Foundation
@testable import Fetch_TakeHome
import UIKit

final class LocalFileManagerTestings {


	 var manager: LocalFileManager!

	 init() {
			manager = LocalFileManager.instance

	 }
	 deinit {
			manager = nil
	 }
	 
	 @Test("Inject a URl that isn't an image to download")
	 func invalidURL() async throws {
			let invalidURLString: String? = "https://www.example.com"
			let uuid = UUID().uuidString

			do {
				 try await manager.saveImage(from: invalidURLString, for: uuid)
				 let image = manager.retrieveImages(for: uuid)
				 #expect(image == nil)
			} catch let error as CachingErrors {
				 #expect(error == .urlDoesNotContainImage)
			} catch {
				 #expect(Bool(false), "Unexpected error type: \(error)")
			}
	 }

	 @Test("Saving Existed Image")
	 func alreadyExistedImage() async throws {
			let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
			let uuid = UUID().uuidString

			let dummyImage = UIImage(systemName: "photo")!
			guard let imageData = dummyImage.jpegData(compressionQuality: 1.0) else {
				 #expect(Bool(false), "Failed to create JPEG data from dummy image")
				 return
			}

			let fileURL = cacheDirectory.appendingPathComponent("\(uuid).jpg")
			try imageData.write(to: fileURL)

			let validImageURL = "https://www.apple.com"

			do {
				 try await manager.saveImage(from: validImageURL, for: uuid)
			} catch let error as CachingErrors {
				 #expect(error == .imageAlreadyExists)
			} catch {
				 #expect(Bool(false), "Unexpected error type: \(error)")
			}

				 // Clean up
			try? FileManager.default.removeItem(at: fileURL)
	 }

	 @Test("Retrieve Non Existing Images")
	 func retreivingNonExistImage() async {
			let nonExistentUUID = UUID().uuidString
			let result = manager.retrieveImages(for: nonExistentUUID)
			#expect(result == nil)
	 }
}
