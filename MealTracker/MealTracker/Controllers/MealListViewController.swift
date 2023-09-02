//
//  ViewController.swift
//  MealTracker
//
//  Created by Isaac Restrick on 3/30/23.
//

import UIKit
import CoreData
import MobileCoreServices

struct RecipeResponse: Codable {
    let name: String
    let description: String
    
}

class MealListViewController: UIViewController, UINavigationControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var context: NSManagedObjectContext?

    var api_spinner: UIActivityIndicatorView!
    
    var meals: [Meal] = []
    var mealEntities: [MealEntity] = []
    var sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
    
    var filteredMeals: [Meal] = []
    var filteredMealEntities: [MealEntity] = []

    var mealService: MealService!
    var openAIService = OpenAIService(apiKey: Bundle.main.infoDictionary?["OPENAI_API_KEY"] as? String ?? "")
    var selectedImageURL = "/"
    var mealDescription = ""
    var mealName = ""
    var selectedDate = Date()
    
    var searchController: UISearchController!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        context = appDelegate.persistentContainer.viewContext
        navigationItem.largeTitleDisplayMode = .always

        api_spinner = UIActivityIndicatorView(style: .large)
        api_spinner.transform = CGAffineTransform(scaleX: 2, y: 2)
        api_spinner.center = view.center
        view.addSubview(api_spinner)

        
        self.mealService = MealService(context:context!)
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(fetchMeals), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        let aiButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addMealButtonPressedAI))
        let photoButton = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(addMealButtonPressed))
        let sortButton = UIBarButtonItem(barButtonSystemItem: .organize, target: self, action:
            #selector(selectSortDescriptor))
        navigationItem.rightBarButtonItems = [aiButton, photoButton, sortButton]
        
        self.searchController = UISearchController(searchResultsController: nil)
        self.searchController.searchResultsUpdater = self
        self.searchController.obscuresBackgroundDuringPresentation = false
        self.searchController.searchBar.placeholder = "Search Meals"
        self.searchController.searchBar.delegate = self
        self.navigationItem.searchController = searchController
        self.definesPresentationContext = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchMeals()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard
            let destination = segue.destination as? DetailViewController,
            let selectedIndexPath = self.tableView.indexPathForSelectedRow,
            let confirmedCell = self.tableView.cellForRow(at: selectedIndexPath) as? MealCell
            else { return }
        
        let confirmedMeal = confirmedCell.meal
        let mealEntity = getMealEntity(at: selectedIndexPath)
        print(confirmedMeal!.name)
        print(mealEntity!.name)

        destination.meal = confirmedMeal
        destination.mealEntity = mealEntity!
        
    }

    func getMealEntity(at indexPath: IndexPath) -> MealEntity? {
        return filteredMealEntities[indexPath.row]
    }

    
    func saveMeal(_ meal: Meal) {
        let mealEntity = NSEntityDescription.insertNewObject(forEntityName: "MealEntity", into: context!) as! MealEntity
        mealEntity.name = meal.name
        mealEntity.date = meal.date
        mealEntity.foodDescription = meal.foodDescription
        mealEntity.imageUrl = meal.imageUrl
        mealEntity.confirmedEaten = meal.confirmedEaten

        do {
            try context!.save()
            fetchMeals()
        } catch {
            print("Failed saving")
        }
    }
    
    func updateMeal(_ meal: Meal, at indexPath: IndexPath) {
        do {
            let mealEntity = self.filteredMealEntities[indexPath.row]
            mealEntity.confirmedEaten = meal.confirmedEaten
            
            try context?.save()
        } catch {
            print("Failed updating")
        }
    }

    @objc func fetchMeals() {
        
        guard let confirmedService = self.mealService else { return }
        
        confirmedService.getMeals(sortDescriptor: self.sortDescriptor, completion: { meals, error in
            DispatchQueue.main.async {
                if let meals = meals, error == nil {
                    self.meals = meals
                    self.filteredMeals = meals
                    
                    let fetchRequest = NSFetchRequest<MealEntity>(entityName: "MealEntity")
                    fetchRequest.sortDescriptors = [self.sortDescriptor]
                    guard let mealEntities = try? self.context?.fetch(fetchRequest) else {
                        print("Failed fetching meal entities")
                        return
                    }
                    self.mealEntities = mealEntities
                    self.filteredMeals = meals
                    self.filteredMealEntities = mealEntities
                    // Change the navigation bar title to indicate if the list is empty.
                    self.navigationItem.title = self.meals.isEmpty ? "Happy Meals (Empty)" : "Happy Meals"
                } else {
                    self.navigationItem.title = self.meals.isEmpty ? "Happy Meals (Empty)" : "Happy Meals"
                    self.showAlertWithError(error)
                }
                self.tableView.refreshControl?.endRefreshing()
                self.tableView.reloadData()
            }
        })
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    @objc func addMealButtonPressedAI() {
            let alertController = UIAlertController(title: "Add Meal", message: "Enter a description for your meal:", preferredStyle: .alert)

            alertController.addTextField { textField in
                textField.placeholder = "Meal Description"
            }

        let submitAction = UIAlertAction(title: "Submit", style: .default) { [weak self] _ in
            if let mealDescription = alertController.textFields?.first?.text {
                self?.api_spinner.startAnimating()
                self?.openAIService.generateRecipe(description: mealDescription) { result in
                    switch result {
                        case .success(let response):
                            print("Successfully received recipe response: \(response)")
                            if let responseJson = response.data(using: .utf8),
                               let responseObject = try? JSONDecoder().decode(RecipeResponse.self, from: responseJson) {
                                
                                let name = responseObject.name
                                let description = responseObject.description
                                
                                print("description: \(description)")
                                print("Parsed name: \(name)")
                                
                                self?.openAIService.generateImage(prompt: description, n: 1, size: "512x512") { imageResult in
                                    switch imageResult {
                                        case .success(let imageData):
                                            print("Successfully received image data: \(imageData)")
                                            if let firstImage = imageData.first,
                                               let imageUrlString = firstImage["url"],
                                               let imageUrl = URL(string: imageUrlString) {
                                                // Download image data
                                                DispatchQueue.global().async {
                                                    if let data = try? Data(contentsOf: imageUrl),
                                                       let image = UIImage(data: data) {
                                                        // Save image locally and get local URL
                                                        DispatchQueue.main.async {
                                                            if let savedImageUrl = self?.saveImageAndGetURL(image: image) {
                                                                print("Saved image URL: \(savedImageUrl)")
                                                                let meal = Meal(named: name, date: Date(), foodDescription: description, imageUrl: savedImageUrl, confirmedEaten: false)
                                                                print("Created meal: \(meal)")
                                                                self?.saveMeal(meal)
                                                                self?.api_spinner.stopAnimating()
                                                            } else {
                                                                print("Error saving image locally.")
                                                                self?.api_spinner.stopAnimating()
                                                            }
                                                        }
                                                    } else {
                                                        print("Error downloading image.")
                                                        self?.api_spinner.stopAnimating()
                                                    }
                                                }
                                            }
                                        case .failure(let error):
                                            print("Error generating image: \(error)")
                                            self?.api_spinner.stopAnimating()
                                    }
                                }

                            }
                        case .failure(let error):
                            self?.api_spinner.stopAnimating()
                            print("Error generating recipe: \(error)")
                    }
                }
            }
        }


            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

            alertController.addAction(submitAction)
            alertController.addAction(cancelAction)

            self.present(alertController, animated: true, completion: nil)
        }

    @objc func addMealButtonPressed() {
        let alertController = UIAlertController(title: "Add Meal", message: "Enter a description for your meal:", preferredStyle: .alert)

        alertController.addTextField { textField in
            textField.placeholder = "Meal Name"
            textField.text = self.mealName
        }

        alertController.addTextField { textField in
            textField.placeholder = "Meal Description"
            textField.text = self.mealDescription
        }


        let photoAction = UIAlertAction(title: "Add Photo", style: .default) { [weak self] _ in
            self?.selectPhoto()
            self?.mealName = (alertController.textFields?[0].text!)!
            self?.mealDescription = (alertController.textFields?[1].text!)!
        }

        let submitAction = UIAlertAction(title: "Submit", style: .default) { [weak self] _ in
            if let mealName = alertController.textFields?[0].text,
                let mealDescription = alertController.textFields?[1].text {
                self?.mealName = mealName
                self?.mealDescription = mealDescription
                
                if let imageUrl = self?.selectedImageURL {
                    let meal = Meal(named: mealName, date: Date(), foodDescription: mealDescription, imageUrl: imageUrl, confirmedEaten: false)
                    print("Created meal: \(meal)")
                    self?.saveMeal(meal)
                    self?.mealName = ""
                    self?.mealDescription = ""
                    self?.selectedImageURL = ""
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)


        alertController.addAction(photoAction)
        alertController.addAction(submitAction)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true)
    }
    
    @objc func selectSortDescriptor() {
        let alertController = UIAlertController(title: "Sort by...", message: "Select how to sort your meals", preferredStyle: .alert)
        let nameAscending = UIAlertAction(title: "Name Ascending (Alphabetical)", style: .default) { [weak self] _ in
            self?.sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
            self?.fetchMeals()
        }
        let nameDescending = UIAlertAction(title: "Name Descending (Reverse Alphabetical)", style: .default) { [weak self] _ in
            self?.sortDescriptor = NSSortDescriptor(key: "name", ascending: false)
            self?.fetchMeals()
        }
        let dateAscending = UIAlertAction(title: "Date Ascending (Oldest First)", style: .default) { [weak self] _ in
            self?.sortDescriptor = NSSortDescriptor(key: "date", ascending: true)
            self?.fetchMeals()
        }
        let dateDescending = UIAlertAction(title: "Date Descending (Newest First)", style: .default) { [weak self] _ in
            self?.sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
            self?.fetchMeals()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(nameAscending)
        alertController.addAction(nameDescending)
        alertController.addAction(dateAscending)
        alertController.addAction(dateDescending)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true)
    }

    func selectPhoto() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.mediaTypes = [kUTTypeImage as String]

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let photoLibraryAction = UIAlertAction(title: "Select from Photo Library", style: .default) { _ in
            imagePickerController.sourceType = .photoLibrary
            self.present(imagePickerController, animated: true)
        }

        let cameraAction = UIAlertAction(title: "Take a Photo", style: .default) { _ in
            imagePickerController.sourceType = .camera
            self.present(imagePickerController, animated: true)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        alertController.addAction(photoLibraryAction)
        alertController.addAction(cameraAction)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true)
    }

    func saveImageAndGetURL(image: UIImage) -> String? {
        guard let data = image.pngData() else {
            return nil
        }
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = UUID().uuidString + ".png"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileName
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    func getImageWithFileName(fileName: String) -> UIImage? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            let imageData = try Data(contentsOf: fileURL)
            return UIImage(data: imageData)
        } catch {
            print("Error loading image : \(error)")
            return nil
        }
    }

    
    func showAlertWithError(_ error: Error?) {
        let errorMessage: String

        if let error = error as? MealCallingError {
            switch error {
            case .problemGeneratingURL:
                errorMessage = "There was a problem generating the request URL. Please try again later."
            case .problemGettingDataFromAPI:
                errorMessage = "We're having trouble connecting to the server. Please check your internet connection and try again."
            case .problemDecodingData:
                errorMessage = "There was a problem decoding the data. Please try again later."
            case .problemFetchingDataFromCoreData:
                errorMessage = "There was a problem fetching the data from core data."
            }
        } else {
            errorMessage = "An unknown error occurred. Please try again later."
        }

        let alertController = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
            
        let retryAction = UIAlertAction(title: "Retry", style: .default) { _ in
            self.fetchMeals()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(retryAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            var newFilteredMeals: [Meal] = []
            var newFilteredMealEntities: [MealEntity] = []
            for (index, meal) in meals.enumerated() {
                if meal.name.lowercased().contains(searchText.lowercased()) {
                    newFilteredMeals.append(meal)
                    newFilteredMealEntities.append(mealEntities[index])
                }
            }
            filteredMeals = newFilteredMeals
            filteredMealEntities = newFilteredMealEntities
        } else {
            filteredMeals = meals
            filteredMealEntities = mealEntities
        }
        
        tableView.reloadData()
    }
}

extension MealListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredMeals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "mealCell") as! MealCell
        let meal = self.filteredMeals[indexPath.row]
                
        cell.meal = meal
        cell.accessoryType = meal.confirmedEaten ? .checkmark : .none
        
        return cell
    }
}

extension MealListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let meal = self.filteredMeals[indexPath.row]
        let confirmAction = UIContextualAction(style: .normal, title: meal.confirmedEaten ? "Unconfirm Eaten" : "Confirm Eaten") { (action, view, completionHandler) in
            meal.confirmedEaten.toggle()
            if let cell = tableView.cellForRow(at: indexPath) as? MealCell {
                cell.accessoryType = meal.confirmedEaten ? .checkmark : .none
            }
            self.updateMeal(meal, at: indexPath)
            completionHandler(true)
        }
        
        confirmAction.backgroundColor = meal.confirmedEaten ? .orange : .systemGreen
        let swipeActionsConfiguration = UISwipeActionsConfiguration(actions: [confirmAction])
        return swipeActionsConfiguration
    }
    
}

extension MealListViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.selectedImageURL = saveImageAndGetURL(image: image)!
        }
        picker.dismiss(animated: true)
        
        self.addMealButtonPressed()
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
