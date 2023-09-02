//
//  MealCellTableViewCell.swift
//  MealTracker
//
//  Created by Isaac Restrick on 3/31/23.
//

import UIKit

class MealCell: UITableViewCell {

    @IBOutlet weak var mealImageView: UIImageView!
    @IBOutlet weak var mealNameLabel: UILabel!
    @IBOutlet weak var mealDescriptionLabel: UILabel!
    var meal: Meal? {
        didSet {
            self.mealNameLabel.text = meal?.name
            self.accessoryType = meal!.confirmedEaten ? .checkmark : .none
            if let foodDescription = meal?.foodDescription as? String, let date = meal?.date as? Date {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .none
                let formattedDate = dateFormatter.string(from: date)
                self.mealDescriptionLabel.text = formattedDate + " - " + foodDescription
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let fileURL = documentsDirectory.appendingPathComponent(self.meal!.imageUrl)
                let mealImageData = NSData(contentsOf: fileURL)
                DispatchQueue.main.async {
                    if mealImageData != nil {
                        self.mealImageView.image = UIImage(data: mealImageData as! Data)
                        self.mealImageView.layer.cornerRadius = self.mealImageView.frame.width / 2
                    }
                    else {
                        self.mealImageView.image = UIImage(named: "placeholder")
                        self.mealImageView.layer.cornerRadius = self.mealImageView.frame.width / 2
                    }
                }
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
