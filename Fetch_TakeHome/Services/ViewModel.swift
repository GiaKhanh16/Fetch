//
//  ViewModel.swift
//  Fetch_TakeHome
//
//  Created by Khanh Nguyen on 4/24/25.
//



import Observation
import SwiftUI


@Observable
class ViewModel {
	 var recipes: [Recipe] = []
	 let networking: NetWorking = NetWorking()


	 func fetchData(urlString: String) async throws {
			try await Task.sleep(nanoseconds: 1_000_000_000)
			self.recipes = try await networking.downloadData(urlString: urlString)
	 }
}


struct Recipe: Identifiable, Codable {
	 let cuisine: String
	 let name: String
	 let photoUrlLarge: String?
	 let photoUrlSmall: String?
	 let uuid: String
	 let sourceUrl: String?
	 let youtubeUrl: String?

	 var id: String { uuid }
}

struct RecipeResponse: Codable {
	 let recipes: [Recipe]
}


