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

    var ingredients = List<Ingredient>()
    var directions = List<Direction>()

    override static func primaryKey() -> String? {
        return "_id"
    }

    private enum RecipeCodingKeys: String, CodingKey {
        case _id
        case title
        case ingredients
        case directions
    }

    convenience init(_id: String, title: String, ingredients: List<Ingredient>, directions: List<Direction>) {
        self.init()
        self._id = _id
        self.title = title
        self.ingredients = ingredients
        self.directions = directions
    }

    convenience required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: RecipeCodingKeys.self)
        let _id = try container.decode(String.self, forKey: ._id)
        let title = try container.decode(String.self, forKey: .title)

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


        self.init(_id: _id, title: title, ingredients: ingredientsList, directions: directionsList)
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

extension Recipe {
    func writeToRealm() {
        try! uiRealm.write {
            uiRealm.add(self, update: true)
        }
    }

    func writeIngredientsFromArray(ingredients: [String]) {
        //convert to Realm list and save
        let ingredientArray = ingredients.map({
            (name: String) -> Ingredient in
            let ingToAdd = Ingredient()
            ingToAdd.name = name
            return ingToAdd
        })

        let ingredientRealmList = List<Ingredient>()
        ingredientRealmList.append(objectsIn: ingredientArray)

        try! uiRealm.write {
            localRecipes[selectedRecipe].ingredients = ingredientRealmList
        }

        print(ingredientRealmList.description)
        print(localRecipes[selectedRecipe].ingredients.description)
    }
}
