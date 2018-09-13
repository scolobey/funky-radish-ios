//
//  JSONSerializer.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 7/29/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import Foundation
import RealmSwift

enum serializerError: Error {
    case formattingError
    case failedSerialization
}

class JSONSerializer {
    func serialize(input data: Data) throws {
        let jsonDecoder = JSONDecoder()

        do {
            // Make sure the response is properly formatted json
            let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
            guard json is [AnyObject] else {
                throw serializerError.formattingError
            }

            let recipes = try jsonDecoder.decode([Recipe].self, from: data)

            synchRecipes(recipes: recipes)

        } catch {
            throw serializerError.failedSerialization
        }
    }

    func serializeUser(input data: Data) throws -> String {
        let jsonDecoder = JSONDecoder()

        do {
            let response = try jsonDecoder.decode(UserResponse.self, from: data)
            let msg = response.message
            let user = response.data

            let userObject = ["username": user.name, "id": user._id, "email": user.email]
            defaults.set(userObject, forKey: "fr_user")

            let recs = Array(user.recipes)
            if (recs.count > 0) {
                synchRecipes(recipes: recs)
            }

            return msg!
        } catch {
            throw serializerError.failedSerialization
        }
    }

    func synchRecipes(recipes: [Recipe]) {
        // Accepts array of recipes from API
        //TODO: make this print a formatted array of recipes to upload
        //TODO: maintain a Realm on the server and synch with Mongo at the controller level.
        let realm = try! Realm()
        let localRecs = realm.objects(Recipe.self)

        //TODO: Pretty sure recipes is already an array.
        // Check diff between localRecs and recipes
        // upload recipes without id's.
        // Store unrecorded recipes to Realm
        let cloudRecipes = Array(recipes)
        var localRecipes = Array(localRecs)
     
        // Collect recipes without id's for upload.
        var upload = Array<Recipe>()

        for (index, recipe) in localRecipes.enumerated().reversed() {
            if(recipe._id == "") {
                upload.append(recipe)
                localRecipes.remove(at: index)
            }
        }

        if(recipes.count > 0) {
            for recipe in cloudRecipes {
                // Check for a local version of the recipe.
                let localInstance = localRecipes.index(where: {$0._id == recipe._id})

                if ( localInstance != nil) {
                    // Compare recipe.updatedAt to select the most recent version
                    let webDate = stringToDate(date: recipe.updatedAt!)
                    let locDate = stringToDate(date: localRecipes[localInstance!].updatedAt!)

                    if (webDate == locDate) {
                        print("identical recipe")
                    }
                    else if (webDate > locDate) {
                        // update local recipe
                        try! realm.write {
                            localRecipes[localInstance!].setValue(recipe._id, forKey: "_id")
                            localRecipes[localInstance!].setValue(recipe.updatedAt, forKey: "updatedAt")
                            localRecipes[localInstance!].setValue(recipe.title, forKey: "title")
                            localRecipes[localInstance!].setValue(recipe.directions, forKey: "directions")
                            localRecipes[localInstance!].setValue(recipe.ingredients, forKey: "ingredients")
                        }
                    }
                    else {
                        // queue the local recipe to update via API
                        upload.append(recipe)
                    }

                }
                else {
                    // If there is no local recipe with a matching id, save recipe to Realm
                    try! realm.write {
                        realm.add(recipe)
                    }
                }
            }
        }

        if (upload.count > 0) {
            // Post update recipes.
            do {
                try APIManager().bulkInsertRecipes(recipes: upload,
                onSuccess: {
                    print("Bulk insert successful.")
                },
                onFailure: { error in
                    print("Error: " + error.localizedDescription)
                })
            }
            catch RecipeError.noInternetConnection {
                print("No internet connection")
            }
            catch RecipeError.noToken {
                print("No token")
            }
            catch {
                print("Error posting recipes")
            }
        }
    }

    func stringToDate(date: String) -> Date {
        let formatter = DateFormatter()

        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let parsedDate = formatter.date(from: date) {
            return parsedDate
        }

        return Date()
    }
}
