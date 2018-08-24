//
//  FunkyRadishTests.swift
//  FunkyRadishTests
//
//  Created by Ryn Goodwin on 8/12/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import XCTest
import RealmSwift

@testable import funky_radish

class FunkyRadishTests: XCTestCase {

    override class func setUp() {
        super.setUp()

        let realm = try! Realm()

        try! realm.write {
            realm.deleteAll()
        }
    }
    
    func testRecipeSerializer() {

        let resultsString: String = """
            [{
                "ingredients": [
                    "cheese",
                    "milk"
                ],
                "directions": [
                    "happy days",
                    "fonzie"
                ],
                "_id": "5b3e5fff9882680014a44542",
                "title": "Milk Cheese",
                "createdAt": "2018-07-05T18:14:23.778Z",
                "updatedAt": "2018-07-05T18:14:23.778Z",
                "__v": 0
            }]
        """

        var mockAPIResults: Data
        mockAPIResults = resultsString.data(using: .utf8)!
    
        let serializer = JSONSerializer()
        serializer.serialize(input: mockAPIResults)

        let recipes = realm.objects(Recipe.self)

        XCTAssertEqual(recipes[0].title, "Milk Cheese")
        XCTAssertEqual(recipes[0]._id, "5b3e5fff9882680014a44542")
        XCTAssertEqual(recipes[0].directions[0].text, "happy days")
        XCTAssertEqual(recipes[0].ingredients[0].name, "cheese")
    }
    
}
