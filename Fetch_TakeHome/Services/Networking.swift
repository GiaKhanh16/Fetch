//
//  Networking.swift
//  Fetch_TakeHome
//
//  Created by Khanh Nguyen on 4/24/25.
//

import Foundation

protocol URLSessionProtocol {
	 func data(from url: URL) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

class NetWorking {
	 private let urlSession: URLSessionProtocol

	 init(urlSession: URLSessionProtocol = URLSession.shared) {
			self.urlSession = urlSession
	 }

	 func downloadData(urlString: String) async throws -> [Recipe] {
			guard let url = URL(string: urlString), url.scheme != nil, url.host != nil else {
				 throw NetworkError.invalidURL
			}

			do {
				 let (data, response) = try await urlSession.data(from: url)

				 if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
						throw NetworkError.httpError(statusCode: httpResponse.statusCode)
				 }

				 let decodedRecipes = try decodeAndValidateRecipes(from: data)
				 return decodedRecipes
			} catch let error as URLError where error.code == .timedOut {
				 print(error.localizedDescription)
				 throw NetworkError.timeout
			} catch let error as URLError where error.code == .notConnectedToInternet {
				 print(error.localizedDescription)
				 throw NetworkError.notConnectedToInternet
			} catch {
				 print("\(error.localizedDescription)")
				 throw error
			}
	 }

	 private func decodeAndValidateRecipes(from data: Data) throws -> [Recipe] {
			let decoder = JSONDecoder()
			decoder.keyDecodingStrategy = .convertFromSnakeCase

			let decodedResponse = try decoder.decode(RecipeResponse.self, from: data)

			guard !decodedResponse.recipes.isEmpty else {
				 throw NetworkError.emptyData
			}

			for recipe in decodedResponse.recipes {
				 if recipe.cuisine.isEmpty || recipe.name.isEmpty || recipe.uuid.isEmpty {
						throw NetworkError.decodingError
				 }
			}

			return decodedResponse.recipes
	 }
}

enum NetworkError: Error, LocalizedError, Equatable {
	 case invalidURL
	 case httpError(statusCode: Int)
	 case decodingError
	 case emptyData
	 case timeout
	 case notConnectedToInternet

	 var errorDescription: String? {
			switch self {
				 case .invalidURL:
						return "Invalid URL. Please try again later."
				 case .httpError(let statusCode):
						return "Server error with status code: \(statusCode). Please try again later."
				 case .decodingError:
						return "Malformed recipe detected. The data couldn’t瞄准 be decoded because it was missing a required key."
				 case .emptyData:
						return "No recipes found. The list is currently empty."
				 case .timeout:
						return "The request timed out. Please try again later."
				 case .notConnectedToInternet:
						return "A network connection was lost."
			}
	 }
}
