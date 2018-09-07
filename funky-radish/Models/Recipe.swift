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

@objcMembers class Recipe: Object, Decodable {
    dynamic var _id : String? = ""
    dynamic var title : String? = ""
    dynamic var updatedAt : String? = ""

    var ingredients = List<Ingredient>()
    var directions = List<Direction>()

    private enum RecipeCodingKeys: String, CodingKey {
        case _id
        case title
        case updatedAt
        case ingredients
        case directions
    }

    convenience init(_id: String, title: String, updatedAt: String, ingredients: List<Ingredient>, directions: List<Direction>) {
        self.init()
        self._id = _id
        self.title = title
        self.updatedAt = updatedAt
        self.ingredients = ingredients
        self.directions = directions
    }

    convenience required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: RecipeCodingKeys.self)
        let _id = try container.decode(String.self, forKey: ._id)
        let title = try container.decode(String.self, forKey: .title)
        let updatedAt = try container.decode(String.self, forKey: .updatedAt)

        let ingredientsArray = try container.decode([String].self, forKey: .ingredients)

        let secondaryIngredientsArray = ingredientsArray.map({
            (name: String) -> Ingredient in
            let ingToAdd = Ingredient()
            ingToAdd.name = name
            return ingToAdd
        })

        let ingredientsList = List<Ingredient>()
        ingredientsList.append(objectsIn: secondaryIngredientsArray)

        let directionsArray = try container.decode([String].self, forKey: .directions)

        let secondaryDirectionsArray = directionsArray.map({
            (text: String) -> Direction in
            let dirToAdd = Direction()
            dirToAdd.text = text
            return dirToAdd
        })

        let directionsList = List<Direction>()
        directionsList.append(objectsIn: secondaryDirectionsArray)

        self.init(_id: _id, title: title, updatedAt: updatedAt, ingredients: ingredientsList, directions: directionsList)
    }

    required init() {
        super.init()
    }

    required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }

    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
}


