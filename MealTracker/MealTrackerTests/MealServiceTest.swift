//
//  MealServiceTest.swift
//  MealTrackerTests
//
//  Created by Isaac Restrick on 4/21/23.
//

import XCTest
@testable import MealTracker

final class MealServiceTest: XCTestCase {

    var systemUnderTest: MealService!
    
    override func setUpWithError() throws {
        self.systemUnderTest = MealService()
    }

    override func tearDownWithError() throws {
        self.systemUnderTest = nil
    }

    func testAPI_returnsSuccessfulResult() throws {
        // Given
        var meals: [Meal]!
        var error: Error?
        
        let promise = expectation(description: "Completion handler is invoked")
        
        // When
        self.systemUnderTest.getMeals(completion: { data, shouldntHappen in
            meals = data
            error = shouldntHappen
            promise.fulfill()
        })
        wait(for: [promise], timeout: 5)
        // Then
        XCTAssertNotNil(meals)
        XCTAssertNil(error)
        
    }

}
