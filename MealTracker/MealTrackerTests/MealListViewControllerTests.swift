//
//  MealListViewControllerTests.swift
//  MealTrackerTests
//
//  Created by Isaac Restrick on 4/21/23.
//

import XCTest
@testable import MealTracker

final class MealListViewControllerTests: XCTestCase {
    var systemUnderTest: MealListViewController!
    
    override func setUp() {
        super.setUp()
        
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let navigationController = storyboard.instantiateInitialViewController() as! UINavigationController
        self.systemUnderTest = navigationController.topViewController as? MealListViewController
        
        UIApplication.shared.windows
            .filter { $0.isKeyWindow}
            .first!
            .rootViewController = self.systemUnderTest
        
        XCTAssertNotNil(navigationController.view)
        XCTAssertNotNil(self.systemUnderTest.view)
        
        
    }

    func testTableView_loadsMeals() {
        //given
        let mockMealService = MockMealService()
        let mockMeals = [
            Meal(named: "Breakfast", date: Date(timeIntervalSince1970:1670985600), foodItems: ["eggs","bacon","toast"], imageUrl: "https://th.bing.com/th/id/OIG.Plm7ePJhxY._oD6AFssd?pid=ImgGn"),
            Meal(named: "Lunch", date: Date(timeIntervalSince1970:1671007200), foodItems:["sandwich", "salad", "apple"], imageUrl:"https://th.bing.com/th/id/OIG.gnuGrXaxbpeNINVY0jqP?pid=ImgGn"),
            Meal(named: "Dinner", date: Date(timeIntervalSince1970:1671028800), foodItems: ["grilled chicken", "rice", "steamed vegetables"], imageUrl: "https://th.bing.com/th/id/OIG.dU3erKtOYAVTqbAotSos?pid=ImgGn")
        ]
        mockMealService.mockMeals = mockMeals
        
        self.systemUnderTest.viewDidLoad()
        self.systemUnderTest.mealService = mockMealService
        
        
        XCTAssertEqual(0, self.systemUnderTest.tableView.numberOfRows(inSection: 0))
        //when
        self.systemUnderTest.viewWillAppear(false)
        
        // While implementing the refresh button, I made a change to refactor my viewWillAppear function
        // to call an asynchronous fetchMeals() function.
        // The fetchMeals() function updates the view asynchronously,
        // so there's a chance that the test assertions will be executed before
        // the completion handler has a chance to run.
        // To mitigate this issue, I added a short delay before the test assertions to give the completion handler enough time to process the fetched data and update the view.
        // This is not optimal but the code is different enough that I believe it warranted the change.
        let expectation = XCTestExpectation(description: "Wait for a short time")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    
        
        //then
        XCTAssertEqual(mockMeals.count, systemUnderTest.meals.count)
        XCTAssertEqual(mockMeals.count,
                       self.systemUnderTest.tableView.numberOfRows(inSection: 0))
    }

    
    class MockMealService: MealService {
        var mockMeals: [Meal]?
        var mockError: Error?
        
        override func getMeals(completion: @escaping ([Meal]?,Error?) -> ()) {
            completion(mockMeals, mockError)
        }
    }
}
