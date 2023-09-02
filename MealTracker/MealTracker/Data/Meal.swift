//
//  Meal.swift
//  MealTracker
//
//  Created by Isaac Restrick on 4/6/23.
//

import Foundation

class Meal: CustomDebugStringConvertible, Codable {
    var debugDescription: String {
        return "Meal(name: \(self.name), date: \(self.date), foodDescription: \(self.foodDescription), confirmedEaten: \(self.confirmedEaten))"
    }
    
    var name: String
    var date: Date
    var foodDescription: String
    var confirmedEaten: Bool = false
    var imageUrl: String
    
    private enum CodingKeys: String, CodingKey {
        case name, date, foodDescription, imageUrl
    }
    
    init(named name: String, date: Date, foodDescription: String, imageUrl: String, confirmedEaten: Bool) {
        self.name = name
        self.date = date
        self.foodDescription = foodDescription
        self.imageUrl = imageUrl
        self.confirmedEaten = confirmedEaten
    }
    
}

struct MealResult: Codable {
    let meals: [Meal]
}
