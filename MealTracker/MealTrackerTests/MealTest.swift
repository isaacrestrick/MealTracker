//
//  MealTest.swift
//  MealTrackerTests
//
//  Created by Isaac Restrick on 4/21/23.
//

import XCTest
@testable import MealTracker

final class MealTest: XCTestCase {

    func testMealDebugDescription() {
        let subjectUnderTest = Meal(named: "Breakfast", date: Date(timeIntervalSince1970:1670985600), foodItems: ["eggs","bacon","toast"], imageUrl: "https://th.bing.com/th/id/OIG.Plm7ePJhxY._oD6AFssd?pid=ImgGn")

        let actualValue = subjectUnderTest.debugDescription

        let expectedValue = "Meal(name: Breakfast, date: 2022-12-14 02:40:00 +0000, foodItems: [\"eggs\", \"bacon\", \"toast\"], confirmedEaten: false)"
        XCTAssertEqual(actualValue, expectedValue)
    }

}
