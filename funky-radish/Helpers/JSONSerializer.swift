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

    func serializeUploadedRecipes(input data: Data) throws -> [Recipe]{
        let jsonDecoder = JSONDecoder()

        do {
            // Make sure the response is properly formatted json
            let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
            guard json is [AnyObject] else {
                throw serializerError.formattingError
            }

            let recipes = try jsonDecoder.decode([Recipe].self, from: data)
            return recipes
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
        print("synchronizing recipes")
        // Accepts an array of online recipes in the format returned from bulk recipe creation.
        // Compares to locally stored recipes.
        // local recipes, uploading any offline recipes that are not present online,

        let realm = try! Realm()

        let offlineRecipes = realm.objects(Recipe.self)

        let cloudRecipes = recipes
        var localRecipes = Array(offlineRecipes)

        var upload = Array<Recipe>()
        var update = Array<Recipe>()

        // Any local recipes without ._id?
        for (index, recipe) in localRecipes.enumerated().reversed() {
            if(recipe._id == "") {
                print("queueing \(recipe.title) for upload")
                print(recipe.realmID)

                upload.append(recipe)
                localRecipes.remove(at: index)
            }
        }

        // Any online recipes?
        if(cloudRecipes.count > 0) {
            for recipe in cloudRecipes {

                let localInstance = localRecipes.index(where: {$0._id == recipe._id})

                // Is there an existing local version of this online recipe?
                if ( localInstance != nil) {
                    // Compare recipe.updatedAt to select the most recent version
                    let webDate = stringToDate(date: recipe.updatedAt!)
                    let locDate = stringToDate(date: localRecipes[localInstance!].updatedAt!)

                    if (NSCalendar.current.isDate(webDate, equalTo: locDate, toGranularity: .second)) {
                        print("identical recipe")

                        return
                    }
                    else if (webDate > locDate) {
                        print("online recipe is more recent, update realm recipe.")
                        // this probab
                        // update local recipe
                        try! realm.write {
                            localRecipes[localInstance!].setValue(recipe._id, forKey: "_id")
                            localRecipes[localInstance!].setValue(recipe.updatedAt, forKey: "updatedAt")
                            localRecipes[localInstance!].setValue(recipe.title, forKey: "title")
                            localRecipes[localInstance!].setValue(recipe.directions, forKey: "directions")
                            localRecipes[localInstance!].setValue(recipe.ingredients, forKey: "ingredients")
                        }
                        return
                    }

                    else {
                        // The local recipe was updated and we need to update the one online.
                        // Queue the local recipe to update via API
                        update.append(recipe)
                        return
                    }
                }
                // If there isn't already an offline version, add one.
                else {
                    print("Adding \(recipe.title) to Realm")

                    let realm = try! Realm()
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
                print("uploading recipes")
                try APIManager().bulkInsertRecipes(recipes: upload,
                onSuccess: {
                    print("success")
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

        if (update.count > 0) {
            // Post update recipes.
            do {
                print("updating recipes")
                try APIManager().bulkUpdateRecipes(recipes: update,
                onSuccess: {
                    print("success")
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
                print("Error updating recipes")
            }
        }
    }

    func reconcileUpload(onlineRecipes: [Recipe], offlineRecipes: [Recipe]) {
        print(offlineRecipes)
        print(onlineRecipes)
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
