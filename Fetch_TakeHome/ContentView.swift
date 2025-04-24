import SwiftUI

struct ContentView: View {
	 @State private var viewModel = ViewModel()
	 @State private var searchText = ""
	 @State private var showAlert = false
	 @State private var selectedURL: URL?
	 @State private var sortOrder: SortOrder = .nameAscending
	 @State private var isLoading = false
	 var fileManager = LocalFileManager.instance

			// Image cache
	 @State private var imageCache: [String: UIImage] = [:]

	 var body: some View {
			NavigationStack {
				 Group {
						if isLoading {
							 ProgressView("Loading recipes...")
									.frame(maxWidth: .infinity, maxHeight: .infinity)
						} else if viewModel.recipes.isEmpty && searchText.isEmpty {
							 VStack {
									Image(systemName: "tray.fill")
										 .resizable()
										 .scaledToFit()
										 .frame(width: 100, height: 100)
										 .foregroundColor(.gray)
										 .padding(.bottom, 20)
									Text("Error Loading Recipes")
										 .font(.title2)
										 .fontWeight(.bold)
										 .foregroundColor(.gray)
									Text("It looks like there are no recipes to display at the moment.")
										 .font(.subheadline)
										 .foregroundColor(.gray)
										 .multilineTextAlignment(.center)
										 .padding(.horizontal)
							 }
							 .frame(maxWidth: .infinity, maxHeight: .infinity)
							 .offset(y: -100)
						} else {
							 List {
									ForEach(groupedRecipes.keys.sorted(), id: \.self) { cuisine in
										 Section(header: Text(cuisine).font(.title2).fontWeight(.bold)) {
												ForEach(groupedRecipes[cuisine]!) { recipe in
													 HStack {
															if let image = imageCache[recipe.uuid] {
																 Image(uiImage: image)
																		.resizable()
																		.scaledToFill()
																		.frame(width: 60, height: 60)
																		.clipShape(RoundedRectangle(cornerRadius: 8))
															} else {
																 Rectangle()
																		.fill(Color.gray.opacity(0.2))
																		.frame(width: 60, height: 60)
																		.clipShape(RoundedRectangle(cornerRadius: 8))
																		.overlay {
																			 ProgressView()
																		}
															}

															VStack(alignment: .leading) {
																 Text(recipe.name)
																		.font(.headline)
																 Text(recipe.cuisine)
																		.font(.subheadline)
																		.foregroundColor(.secondary)
															}
													 }
													 .onAppear {
															if imageCache[recipe.uuid] == nil {
																 Task {
																		if let cached = fileManager.retrieveImages(for: recipe.uuid) {
																			 imageCache[recipe.uuid] = cached
																		} else {
																			 do {
																					try await fileManager.saveImage(from: recipe.photoUrlSmall, for: recipe.uuid)
																					if let image = fileManager.retrieveImages(for: recipe.uuid) {
																						 imageCache[recipe.uuid] = image
																					}
																			 } catch {
																					print("Image load error: \(error)")
																			 }
																		}
																 }
															}
													 }
													 .onTapGesture {
															if let urlString = recipe.youtubeUrl, let url = URL(string: urlString) {
																 selectedURL = url
																 showAlert = true
															}
													 }
												}
										 }
									}
							 }
							 .background {
									if filteredRecipes.isEmpty && !searchText.isEmpty {
										 VStack {
												Image(systemName: "fork.knife")
													 .resizable()
													 .scaledToFit()
													 .frame(width: 100, height: 100)
													 .foregroundColor(.gray)
													 .padding(.bottom, 20)
												Text("No Recipes Found")
													 .font(.title2)
													 .foregroundColor(.gray)
										 }
										 .frame(maxWidth: .infinity, maxHeight: .infinity)
									}
							 }
						}
				 }
				 .refreshable {
						do {
							 try await viewModel.fetchData(urlString: "https://d3jbb8n5wk0qxi.cloudfront.net/recipes.json")
						} catch {
							 print("Error refreshing data: \(error)")
						}
				 }
				 .navigationTitle("Cuisine")
				 .listStyle(.plain)
				 .searchable(text: $searchText, prompt: "Search recipes")
				 .toolbar {
						ToolbarItem(placement: .topBarTrailing) {
							 Menu {
									Picker("Sort", selection: $sortOrder) {
										 ForEach(SortOrder.allCases) { option in
												Text(option.rawValue).tag(option)
										 }
									}
									.pickerStyle(.inline)
							 } label: {
									Label("Sort", systemImage: "arrow.up.arrow.down")
							 }
						}
				 }
				 .task {
						isLoading = true
						do {
							 try await viewModel.fetchData(urlString: "https://d3jbb8n5wk0qxi.cloudfront.net/recipes.json")
//							 try fileManager.clearAllImages()
						} catch {
							 print("Error Fetching from UI: \(error)")
						}
						isLoading = false
				 }
				 .alert("Open YouTube", isPresented: $showAlert) {
						Button("Cancel", role: .cancel) {
							 selectedURL = nil
						}
						Button("Open") {
							 if let url = selectedURL {
									UIApplication.shared.open(url)
							 }
						}
				 } message: {
						Text("This will take you to YouTube to view the recipe video.")
				 }
			}
	 }

	 private var groupedRecipes: [String: [Recipe]] {
			let filtered = filteredRecipes
			return Dictionary(grouping: filtered, by: { $0.cuisine })
	 }

	 private var filteredRecipes: [Recipe] {
			var recipes = viewModel.recipes

			if !searchText.isEmpty {
				 recipes = recipes.filter { recipe in
						recipe.name.lowercased().contains(searchText.lowercased()) ||
						recipe.cuisine.lowercased().contains(searchText.lowercased())
				 }
			}

			switch sortOrder {
				 case .nameAscending:
						recipes.sort { $0.name.lowercased() < $1.name.lowercased() }
				 case .nameDescending:
						recipes.sort { $0.name.lowercased() > $1.name.lowercased() }
			}

			return recipes
	 }

	 enum SortOrder: String, CaseIterable, Identifiable {
			case nameAscending = "Name (A-Z)"
			case nameDescending = "Name (Z-A)"
			var id: String { rawValue }
	 }
}
