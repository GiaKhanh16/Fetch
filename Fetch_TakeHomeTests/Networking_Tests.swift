//
//  NetWorking_Tests.swift
//  FetchTakeHome_Final
//
//  Created by Khanh Nguyen on 4/23/25.
//


import Testing
import Foundation
@testable import Fetch_TakeHome
import UIKit

class NetWorkingTests {
	 var sut: NetWorking!

	 init() {
			sut = NetWorking()
	 }
	 deinit {
			sut = nil
	 }

	 @Test("Successful Request",
			.disabled("Issue with try catch "))
	 func test_FetchDataSuccess() async throws {
			let validJSON = """
		{
				"recipes": [
						{
								"uuid": "12345",
								"name": "Test Recipe",
								"cuisine": "Italian",
								"photoUrlSmall": "https://d3jbb8n5wk0qxi.cloudfront.net/photos/535dfe4e-5d61-4db6-ba8f-7a27b1214f5d/small.jpg"
						}
				]
		}
		""".data(using: .utf8)!


			let response = HTTPURLResponse(
				 url: URL(string: "https://api.example.com")!,
				 statusCode: 200,
				 httpVersion: nil,
				 headerFields: nil
			)!

			let mockSession = MockURLSession(data: validJSON, response: response)
			sut = NetWorking(urlSession: mockSession)

			let recipes = try await sut.downloadData(urlString: "https://api.example.com")

			#expect(recipes.count == 1)

			let recipe = recipes.first!
			#expect(recipe.uuid == "12345", "UUID does not match expected value")
			#expect(recipe.name == "Test Recipe", "Recipe name does not match expected value")
			#expect(recipe.cuisine == "Italian", "Cuisine does not match expected value")
			#expect(recipe.photoUrlSmall == "https://example.com/photo.jpg", "Photo URL does not match expected value")
	 }

	 @Test("Inject an Invalid URL")
	 func test_FetchDataWithInvalidURL() async {
			let invalidURL = "invalid-url"

			do {
				 _ = try await sut.downloadData(urlString: invalidURL)
				 #expect(Bool(false), "Expected invalidURL error, but no error was thrown")
			} catch let error as NetworkError {
				 #expect(error == .invalidURL, "Expected NetworkError.invalidURL")
				 #expect(error.localizedDescription == "Invalid URL. Please try again later.", "Error message does not match")
			} catch {
				 #expect(Bool(false), "Unexpected error: \(error)")
			}
	 }



			@Test("Test for malformed API")
			func test_MalformedAPI() async throws {
				 let malformedJSON = """
						{
								"recipes": [
										{
												"uuid": "",
												"cuisine": "",
												"name": "Test Recipe",
												"photoUrlSmall": "https://example.com/image.jpg"
										}
								]
						}
						""".data(using: .utf8)!

				 let response = HTTPURLResponse(
						url: URL(string: "https://api.example.com")!,
						statusCode: 200,
						httpVersion: nil,
						headerFields: nil
				 )!

				 let mockSession = MockURLSession(data: malformedJSON, response: response)
				 sut = NetWorking(urlSession: mockSession)

				 do {
						_ = try await sut.downloadData(urlString: "https://api.example.com")
						#expect(Bool(false), "Expected NetworkError.decodingError")
				 } catch let error as NetworkError {
						#expect(error == .decodingError, "Expected NetworkError.decodingError")
						#expect(error.localizedDescription == "Malformed recipe detected. The data couldn’t瞄准 be decoded because it was missing a required key.")
				 } catch {
						#expect(Bool(false), "Unexpected error type: \(error)")
				 }
			}

			@Test("Test for Empty API")
			func test_EmptyAPI() async {
				 let emptyJSON = """
						{
								"recipes": []
						}
						""".data(using: .utf8)!

				 let response = HTTPURLResponse(
						url: URL(string: "https://api.example.com")!,
						statusCode: 200,
						httpVersion: nil,
						headerFields: nil
				 )!

				 let mockSession = MockURLSession(data: emptyJSON, response: response)
				 sut = NetWorking(urlSession: mockSession)

				 do {
						_ = try await sut.downloadData(urlString: "https://api.example.com")
				 } catch let error as NetworkError {
						#expect(error == .emptyData, "Expected NetworkError.emptyData")
						#expect(error.localizedDescription == "No recipes found. The list is currently empty.", "Error message does not match")
				 } catch {
						#expect(Bool(false), "Unexpected error type: \(error)")
				 }
			}

	 @Test("No internet connection")
	 func test_NoInternetConnection() async {
			let urlString = "https://example.com"

			let mockSession = MockURLSession(data: nil, response: nil, error: URLError(.notConnectedToInternet))
			sut = NetWorking(urlSession: mockSession)

			do {
				 _ = try await sut.downloadData(urlString: urlString)
			} catch let error as NetworkError {
				 #expect(error == .notConnectedToInternet, "Expected notConnectedToInternet error")
				 #expect(error.localizedDescription == "A network connection was lost.", "Unexpected error message")
			} catch {
				 #expect(Bool(false), "Unexpected error type: \(error)")
			}
	 }



	 @Test("Server Error 404")
	 func test_FetchDataWithServerError() async {
			let validJSON = """
		{
			"recipes": []
		}
		""".data(using: .utf8)!

			let response = HTTPURLResponse(
				 url: URL(string: "https://api.example.com")!,
				 statusCode: 404,
				 httpVersion: nil,
				 headerFields: nil
			)!

			let mockSession = MockURLSession(data: validJSON, response: response)
			sut = NetWorking(urlSession: mockSession)

			do {
				 _ = try await sut.downloadData(urlString: "https://api.example.com")
			} catch let error as NetworkError {
				 if case .httpError(let statusCode) = error {
						#expect(statusCode == 404, "Expected status code 404")
						#expect(
							 error.localizedDescription == "Server error with status code: 404. Please try again later.","Error message does not match")
				 } else {
						#expect(Bool(false), "Expected NetworkError.httpError, but got \(error)")
				 }
			} catch {
				 #expect(Bool(false), "Unexpected error type: \(error)")
			}
	 }

	 func testFetchDataWithTimeoutError() async {
			let mockSession = MockURLSession(data: nil, response: nil, error: URLError(.timedOut))
			sut = NetWorking(urlSession: mockSession)

			do {
				 _ = try await sut.downloadData(urlString: "https://api.example.com")
			} catch let error as NetworkError {
				 #expect(error == .timeout, "Expected timedOut error")
				 #expect(error.localizedDescription == "The request timed out. Please try again later.", "Unexpected error message")
			} catch {
				 #expect(Bool(false), "Unexpected error type: \(error)")
			}
	 }
}

class MockURLSession: URLSessionProtocol {
	 let data: Data?
	 let response: URLResponse?
	 let error: Error?

	 init(data: Data?, response: URLResponse?, error: Error? = nil) {
			self.data = data
			self.response = response
			self.error = error
	 }

	 func data(from url: URL) async throws -> (Data, URLResponse) {
			if let error = error {
				 throw error
			}
			guard let data = data, let response = response else {
				 throw URLError(.badServerResponse)
			}
			return (data, response)
	 }
}
