//
//  FunkyRadishTests.swift
//  FunkyRadishTests
//
//  Created by Ryn Goodwin on 8/12/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import XCTest
@testable import funky_radish
@testable import RealmSwift

//@testable import funky_radish

class FunkyRadishTests: XCTestCase {

    let realmManager = RealmManager()

    override class func setUp() {
        super.setUp()
    }

    func testClearRealm() {
        realmManager.clearAll()

        let recipes = realmManager.read(Recipe.self)

        XCTAssertEqual(recipes.count, 0)
    }

    func testCreateRecipe() {
        let recipe = Recipe()

        recipe.title = "cookies"

        realmManager.create(recipe)
        let recipes = realmManager.read(Recipe.self)

        XCTAssertEqual(recipes.count, 1)
        XCTAssertEqual(recipes[0].title, "cookies")
    }

    func testEditRecipe() {
        let recipes = realmManager.read(Recipe.self)

        realmManager.update(recipes[0], with: [
            "title": "Chocolate Chip Cookies"
            ])

        XCTAssertEqual(recipes.count, 1)
        XCTAssertEqual(recipes[0].title, "Chocolate Chip Cookies")
    }

    func testDeleteRecipe() {
        let recipes = realmManager.read(Recipe.self)

        realmManager.delete(recipes[0])

        XCTAssertEqual(recipes.count, 0)
    }

    func testRecipeSerializer() {

        let resultsString: String = """
        [
        {
        "ingredients": [
            "3 oz Chipotle powder",
            "6 oz chili powder",
            "6 oz garlic powder",
            "3 oz ground cumin",
            "6 oz ground coriander",
            "9 oz salt"
        ],
        "directions": [
            "Combine and use on ground beef. Fry the beef."
        ],
        "_id": "5c06efd80620840014e01b95",
        "realmID": "f7562dc9-4364-4158-8fc4-54c6a2f277cb",
        "title": "Taco Seasoning",
        "updatedAt": "2018-12-27T16:13:29.113Z",
        "author": {
            "recipes": [],
            "_id": "5c05a9e9aff0fc001437f3bc",
            "name": "scolobey",
            "email": "scolobey@gmail.com",
            "password": "$2b$12$b3nXTAch.vbmTbH5CkBmM.uI.6R6tNVUsHSbtAe6UT43FaRb7JRlW",
            "admin": false,
            "createdAt": "2018-12-03T22:10:49.906Z",
            "updatedAt": "2018-12-03T22:10:49.906Z",
            "__v": 0
        },
        "__v": 0,
        "createdAt": "2018-12-04T21:21:28.961Z"
        },
        {
        "ingredients": [
            "4 cups sea salt",
            "2 cups onion powder",
            "2 cups granulated garlic",
            "1 cup Chipotle powder",
            "1 cup chili powder",
            "1 cup ground black pepper",
            "1 cup poultry seasoning",
            "2 cup smoked paprika"
        ],
        "directions": [
            "Combine and use on breakfast potatoes or poultry. X"
        ],
        "_id": "5c06f07e0620840014e01b96",
        "realmID": "a69ca6cf-616a-45d9-b44e-48b53c92a6b5",
        "title": "Breakfast Potato Seasoning",
        "updatedAt": "2018-12-27T00:13:44.502Z",
        "author": {
            "recipes": [],
            "_id": "5c05a9e9aff0fc001437f3bc",
            "name": "scolobey",
            "email": "scolobey@gmail.com",
            "password": "$2b$12$b3nXTAch.vbmTbH5CkBmM.uI.6R6tNVUsHSbtAe6UT43FaRb7JRlW",
            "admin": false,
            "createdAt": "2018-12-03T22:10:49.906Z",
            "updatedAt": "2018-12-03T22:10:49.906Z",
            "__v": 0
        },
        "__v": 0,
        "createdAt": "2018-12-04T21:24:14.023Z"
        }
        ]
        """

        var mockAPIResults: Data
        mockAPIResults = resultsString.data(using: .utf8)!

        do {
            try JSONSerializer().serialize(input: mockAPIResults)
        }
        catch serializerError.formattingError {
            print("data formatting issue")
        }
        catch serializerError.failedSerialization {
            print("serialization failed")
        }
        catch {
            print("other issue")
        }

        let recipes = realmManager.read(Recipe.self)

        XCTAssertEqual(recipes.count, 2)

        XCTAssertEqual(recipes[0].title, "Taco Seasoning")
        XCTAssertEqual(recipes[0].ingredients.count, 6)
        XCTAssertEqual(recipes[0].directions[0].text, "Combine and use on ground beef. Fry the beef.")
        XCTAssertEqual(recipes[0].ingredients[0].name, "3 oz Chipotle powder")
    }

}
