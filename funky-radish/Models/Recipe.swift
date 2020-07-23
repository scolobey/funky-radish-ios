//
//  Recipe.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 7/31/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

@objcMembers class Recipe: Object {
    @objc dynamic var realmID: ObjectId? = ObjectId.generate()
    @objc dynamic var _id: ObjectId? = ObjectId.generate()
    @objc dynamic var title: String? = nil
    @objc dynamic var updatedAt: String? = nil
    @objc dynamic var _partition: String = "PUBLIC"
    let __v = RealmOptional<Int>()
    @objc dynamic var author: User?
    @objc dynamic var clientID: String? = nil
    @objc dynamic var createdAt: Date? = nil
    @objc dynamic var user: ObjectId = ObjectId.generate()

    var directions = RealmSwift.List<Direction>()
    var ingredients = RealmSwift.List<Ingredient>()
    
    override static func primaryKey() -> String? {
        return "_id"
    }

//    override static func primaryKey() -> String? {
//        return "realmID"
//    }

//    private enum RecipeCodingKeys: String, CodingKey {
//        case _id
//        case realmID
//        case title
//        case updatedAt
//        case ingredients
//        case directions
//    }

    convenience init(title: String, ingredients: List<Ingredient>, directions: List<Direction>) {
        self.init()
        self.title = title
        self.ingredients = ingredients
        self.directions = directions
    }

//    convenience required init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: RecipeCodingKeys.self)
//        let _id = try container.decode(String.self, forKey: ._id)
//        let realmID = try container.decode(String.self, forKey: .realmID)
//        let title = try container.decode(String.self, forKey: .title)
//        let updatedAt = try container.decode(String.self, forKey: .updatedAt)
//
//        let ingredientsArray = try container.decode([String].self, forKey: .ingredients)
//
//        let secondaryIngredientsArray = ingredientsArray.map({
//            (name: String) -> Ingredient in
//            let ingToAdd = Ingredient()
//            ingToAdd.name = name
//            return ingToAdd
//        })
//
//        let ingredientsList = List<Ingredient>()
//        ingredientsList.append(objectsIn: secondaryIngredientsArray)
//
//        let directionsArray = try container.decode([String].self, forKey: .directions)
//
//        let secondaryDirectionsArray = directionsArray.map({
//            (text: String) -> Direction in
//            let dirToAdd = Direction()
//            dirToAdd.text = text
//            return dirToAdd
//        })
//
//        let directionsList = List<Direction>()
//        directionsList.append(objectsIn: secondaryDirectionsArray)
//
//        self.init(_id: _id, realmID: realmID, title: title, updatedAt: updatedAt, ingredients: ingredientsList, directions: directionsList)
//    }
//
//    required init() {
//        super.init()
//    }
}

//TODO: Probably ditch this stuff.

//extension Object {
//    func toDictionary() -> [String:AnyObject] {
//        let properties = self.objectSchema.properties.map { $0.name }
//        var dicProps = [String:AnyObject]()
//        for (key, value) in self.dictionaryWithValues(forKeys: properties) {
//            //key = key.uppercased()
//            if let value = value as? ListBase {
//                dicProps[key] = value.toArray1() as AnyObject
//            } else if let value = value as? Object {
//                dicProps[key] = value.toDictionary() as AnyObject
//            } else {
//                dicProps[key] = value as AnyObject
//            }
//        }
//        return dicProps
//    }
//}
//
//extension ListBase {
//    func toArray1() -> [AnyObject] {
//        var _toArray = [AnyObject]()
//        for i in 0..<self._rlmArray.count {
//            let obj = unsafeBitCast(self._rlmArray[i], to: Object.self)
//            _toArray.append(obj.toDictionary() as AnyObject)
//        }
//        return _toArray
//    }
//}
