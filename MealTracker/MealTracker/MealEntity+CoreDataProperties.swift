//
//  MealEntity+CoreDataProperties.swift
//  MealTracker
//
//  Created by Isaac Restrick on 5/15/23.
//
//

import Foundation
import CoreData


extension MealEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MealEntity> {
        return NSFetchRequest<MealEntity>(entityName: "MealEntity")
    }

    @NSManaged public var name: String?
    @NSManaged public var date: Date?
    @NSManaged public var foodDescription: String?
    @NSManaged public var confirmedEaten: Bool
    @NSManaged public var imageUrl: String?

}

extension MealEntity : Identifiable {

}
