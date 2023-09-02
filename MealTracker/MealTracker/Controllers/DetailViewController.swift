//
//  DetailViewController.swift
//  MealTracker
//
//  Created by Isaac Restrick on 4/13/23.
//

import UIKit
import CoreData
import MobileCoreServices


class DetailViewController: UIViewController, UINavigationControllerDelegate {
    
    var meal: Meal!
    var mealEntity: MealEntity!
    var selectedImageURL = "/"
    
    @IBOutlet weak var foodItemsLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var mealImageView: UIImageView!

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var context: NSManagedObjectContext?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(meal!)
        print(mealEntity!)
        context = appDelegate.persistentContainer.viewContext
        navigationItem.largeTitleDisplayMode = .always

        nameLabel.text = meal.name
        print(meal.debugDescription)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateLabel.text = dateFormatter.string(from: meal.date)
        
        foodItemsLabel.text = meal.foodDescription
        
        
        DispatchQueue.global(qos: .userInitiated).async {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsDirectory.appendingPathComponent(self.meal!.imageUrl)
            let mealImageData = NSData(contentsOf: fileURL)
            DispatchQueue.main.async {
                if mealImageData != nil {
                    self.mealImageView.image = UIImage(data: mealImageData as! Data)
                }
                else {
                    self.mealImageView.image = UIImage(named: "placeholder")
                }
            }
        }
        
        nameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(nameTapped)))
        nameLabel.isUserInteractionEnabled = true

        mealImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(imageTapped)))
        mealImageView.isUserInteractionEnabled = true

        foodItemsLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(descriptionTapped)))
        foodItemsLabel.isUserInteractionEnabled = true

        dateLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dateTapped)))
        dateLabel.isUserInteractionEnabled = true
        
        let deleteButton = UIButton(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
        deleteButton.layer.cornerRadius = 25
        deleteButton.backgroundColor = UIColor.red.withAlphaComponent(0.5)

        deleteButton.setTitle("Delete Meal", for: .normal)
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped(_:)), for: .touchUpInside)
        
        view.addSubview(deleteButton)
        
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            deleteButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            deleteButton.topAnchor.constraint(equalTo: foodItemsLabel.bottomAnchor, constant: 20),
            deleteButton.widthAnchor.constraint(equalToConstant: 200),
            deleteButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
    }
    
    func updateMealEntity() {
        do {
            try self.context?.save()
        } catch {
            print("Failed updating meal entity")
        }
    }
    
    func deleteMealEntity() {
        self.context!.delete(mealEntity!)

        do {
            try self.context?.save()
        } catch {
            print("Failed deleting")
        }
    }


    @objc func nameTapped() {
        let alertController = UIAlertController(title: "Update Meal Name", message: "Enter a new name for your meal:", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Meal Name"
            textField.text = self.mealEntity.name
        }

        let submitAction = UIAlertAction(title: "Submit", style: .default) { [weak self] _ in
            if let newName = alertController.textFields?.first?.text {
                self?.mealEntity.name = newName
                self?.nameLabel.text = newName
                self?.updateMealEntity()
            }
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        alertController.addAction(submitAction)
        self.present(alertController, animated: true)
    }

    @objc func imageTapped() {
        print("hi!")
        let alertController = UIAlertController(title: "Update Meal Image", message: "Add a new photo for your meal:", preferredStyle: .alert)

        let photoAction = UIAlertAction(title: "Add Photo", style: .default) { [weak self] _ in
            self?.selectPhoto()
        }
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { [weak self] _ in
                if let imageUrl = self?.selectedImageURL {
                    self?.mealEntity.imageUrl = imageUrl
                    DispatchQueue.global(qos: .userInitiated).async {
                        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                        let fileURL = documentsDirectory.appendingPathComponent(imageUrl)
                        let mealImageData = NSData(contentsOf: fileURL)
                        DispatchQueue.main.async {
                            if mealImageData != nil {
                                self!.mealImageView.image = UIImage(data: mealImageData as! Data)
                            }
                            else {
                                self!.mealImageView.image = UIImage(named: "placeholder")
                            }
                        }
                    }
                    self?.selectedImageURL = ""
                }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(photoAction)
        alertController.addAction(submitAction)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true)
    }

    @objc func descriptionTapped() {
        let alertController = UIAlertController(title: "Update Meal Description", message: "Enter a new description for your meal:", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Meal Description"
            textField.text = self.mealEntity.foodDescription
        }

        let submitAction = UIAlertAction(title: "Submit", style: .default) { [weak self] _ in
            if let newDescription = alertController.textFields?.first?.text {
                self?.mealEntity.foodDescription = newDescription
                self?.foodItemsLabel.text = newDescription
                self?.updateMealEntity()
            }
        }
        

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        alertController.addAction(submitAction)
        self.present(alertController, animated: true)
    }

    @objc func dateTapped() {
        let alert = UIAlertController(title: nil, message: "You can't change the past", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }

    @IBAction func deleteButtonTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Delete Meal", message: "Are you sure you want to delete this meal?", preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
            self!.deleteMealEntity()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
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

}
extension DetailViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.selectedImageURL = saveImageAndGetURL(image: image)!
        }
        picker.dismiss(animated: true)
        
        self.imageTapped()
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
