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

    func serializeUser(input data: Data) throws {
        let jsonDecoder = JSONDecoder()

        do {
            let response = try jsonDecoder.decode(APIResponse.self, from: data)

            let msg = response.message
            let user = response.data

            print(msg!)

            let recs = Array(user.recipes)

            synchRecipes(recipes: recs)

            let userObject = ["username": user.name, "id": user._id, "email": user.email]

            defaults.set(userObject, forKey: "fr_user")

            //TODO: Handle multiple users. Probably store id of current user in userDefaults.
            //TODO: When you sign in or log in, reconcile the user's recipe list with the API. These todo's conflict.
            //TODO: Should I just eliminate the user object and only store user data under UserDefaults?
            let realm = try! Realm()

            try! realm.write {
                realm.add(user)
            }
        } catch {
            throw serializerError.failedSerialization
        }
    }

    func synchRecipes(recipes: [Recipe]) {
        // Accepts array of recipes from APi
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
                // Check for a local recipe with each id occurring in your downloaded recipes.
                let localInstance = localRecipes.index(where: {$0._id == recipe._id})

                if ( localInstance != nil) {
                    // If the local recipe was edited more recently, add it to the post list.
                    let webDate = stringToDate(date: recipe.updatedAt!)
                    let locDate = stringToDate(date: localRecipes[localInstance!].updatedAt!)

                    if (webDate == locDate) {
                        print("identical recipe")
                    }
                    else if (webDate > locDate) {
                        // update the local recipe
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

        // Post recipes to the API.
        do {
            try APIManager().bulkInsertRecipes(recipes: upload,
                onSuccess: { print("Bulk insert successful.") },
                onFailure: { error in print(error)}
            )
        }
        catch {
            print("Error posting recipes")
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
