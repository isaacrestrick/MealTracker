//
//  MealService.swift
//  MealTracker
//
//  Created by Isaac Restrick on 4/6/23.
//

import CoreData
import Foundation

enum MealCallingError: Error {
    case problemGeneratingURL
    case problemGettingDataFromAPI
    case problemDecodingData
    case problemFetchingDataFromCoreData
}

class MealService {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func getMeals(sortDescriptor: NSSortDescriptor, completion: @escaping ([Meal]?, Error?) -> ()) {
        let fetchRequest = NSFetchRequest<MealEntity>(entityName: "MealEntity")
        fetchRequest.sortDescriptors = [sortDescriptor]

        do {
            let mealEntities = try context.fetch(fetchRequest)
            let meals = mealEntities.compactMap { mealEntity -> Meal? in
                guard let name = mealEntity.name,
                      let date = mealEntity.date,
                      let foodDescription = mealEntity.foodDescription,
                      let imageUrl = mealEntity.imageUrl else {
                    return nil
                }
                return Meal(named: name, date: date, foodDescription: foodDescription, imageUrl: imageUrl, confirmedEaten: mealEntity.confirmedEaten)
            }

            completion(meals, nil)
        } catch {
            completion(nil, MealCallingError.problemFetchingDataFromCoreData)
        }
    }
}
