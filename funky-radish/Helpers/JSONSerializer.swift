//
//  JSONSerializer.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 7/29/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import Foundation
import RealmSwift
import SwiftKeychainWrapper
import os

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

            KeychainWrapper.standard.set(user.email!, forKey: "fr_user_email")

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
        os_log("synchronizing recipes")
        // Accepts an array of online recipes in the format returned from bulk recipe creation.
        // Compares to locally stored recipes.
        // local recipes, uploading any offline recipes that are not present online,

        let realm = try! Realm()

        let offlineRecipes = realm.objects(Recipe.self)

        let cloudRecipes = recipes
        var localRecipes = Array(offlineRecipes)
        let deleteRecipes = UserDefaults.standard.stringArray(forKey: "DeletedQueue") ?? [String]()

        var upload = Array<Recipe>()
        var update = Array<Recipe>()

        // Any local recipes without ._id?
        for (index, recipe) in localRecipes.enumerated().reversed() {
            if(recipe._id == "") {
                os_log("queueing %@ for upload", recipe.title ?? "*no-title*")

                upload.append(recipe)
                localRecipes.remove(at: index)
            }
        }

        // Any online recipes?
        if(cloudRecipes.count > 0) {
            for recipe in cloudRecipes {
                let localInstance = localRecipes.index(where: {$0._id == recipe._id})
                let shouldDelete = deleteRecipes.index(where: {$0 == recipe._id})

                // Is there an existing local version of this online recipe?
                if ( localInstance != nil) {
                    // Compare recipe.updatedAt to select the most recent version
                    let webDate = stringToDate(date: recipe.updatedAt!)
                    let locDate = stringToDate(date: localRecipes[localInstance!].updatedAt!)

                    if (NSCalendar.current.isDate(webDate, equalTo: locDate, toGranularity: .second)) {
                        os_log("identical recipe")
                    } else if (webDate > locDate) {
                        os_log("online recipe is more recent, update realm recipe.")
                        try! realm.write {
                            localRecipes[localInstance!].setValue(recipe._id, forKey: "_id")
                            localRecipes[localInstance!].setValue(recipe.updatedAt, forKey: "updatedAt")
                            localRecipes[localInstance!].setValue(recipe.title, forKey: "title")
                            localRecipes[localInstance!].setValue(recipe.directions, forKey: "directions")
                            localRecipes[localInstance!].setValue(recipe.ingredients, forKey: "ingredients")
                        }
                    } else {
                        // Add the local recipe to update queue
                        update.append(localRecipes[localInstance!])
                    }
                }
                // if the recipe is in the deletion queue
                else if (shouldDelete != nil) {
                    // Don't save this recipe. It's supposed to be deleted.
                    os_log("Not saving %@", recipe.title!)
                }
                // If there isn't already an offline version, add one.
                else {
                    os_log("Adding %@ to Realm.", recipe.title!)

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
                os_log("uploading recipes")
                try APIManager().bulkInsertRecipes(recipes: upload,
                onSuccess: {
                    os_log("successful recipe upload")
                },
                onFailure: { error in
                    os_log("Error: %@", error.localizedDescription)
                })
            }
            catch RecipeError.noInternetConnection {
                os_log("No internet connection")
            }
            catch RecipeError.noToken {
                os_log("No token")
            }
            catch {
                os_log("Error posting recipes")
            }
        }

        if (update.count > 0) {
            // Post update recipes.
            do {
                os_log("updating recipes")
                try APIManager().bulkUpdateRecipes(recipes: update,
                onSuccess: {
                    os_log("successful recipe bulk update.")
                },
                onFailure: { error in
                    os_log("Error: %@", error.localizedDescription)
                })
            }
            catch RecipeError.noInternetConnection {
                os_log("No internet connection")
            }
            catch RecipeError.noToken {
                os_log("No token")
            }
            catch {
                os_log("Error updating recipes")
            }
        }

        if (deleteRecipes.count > 0) {
            // Post update recipes.
            do {
                os_log("deleting recipes")
                try APIManager().bulkDeleteRecipes(recipes: deleteRecipes,
                onSuccess: {
                    os_log("successful bulk delete.")
                    //Set the recipes to delete list to nada
                    let delete_queue = [String]()
                    UserDefaults.standard.set(delete_queue, forKey: "DeletedQueue")
                },
                onFailure: { error in
                    os_log("Error: %@", error.localizedDescription)
                })
            }
            catch RecipeError.noInternetConnection {
                os_log("No internet connection")
            }
            catch RecipeError.noToken {
                os_log("No token")
            }
            catch {
                os_log("Error updating recipes")
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
