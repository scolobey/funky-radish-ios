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
    case tokenExpired
}

struct recipeResponse: Decodable {
    let success: Bool
    let message : String
}

class JSONSerializer {

    func serialize(input data: Data) throws {
        let jsonDecoder = JSONDecoder()

        // Make sure the response is properly formatted json
        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)

        guard json is [AnyObject] else {
            let error = try jsonDecoder.decode(recipeResponse.self, from: data)
            if error.message.contains("Token verification error."){
                throw RecipeError.noToken
            }
            else {
                throw serializerError.formattingError
            }
        }

        let recipes = try jsonDecoder.decode([Recipe].self, from: data)

        synchRecipes(recipes: recipes)
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

    func synchRecipes(recipes: [Recipe]) {
        // Accepts an array of online recipes in the format returned from bulk recipe creation.
        // Compares to locally stored recipes.
        // local recipes, uploading any offline recipes that are not present online,

        //        let realm = try! Realm()
        let realmManager = RealmManager()
        let offlineRecipes = realmManager.read(Recipe.self)

        let cloudRecipes = recipes
        var localRecipes = Array(offlineRecipes)
        let deleteRecipes = UserDefaults.standard.stringArray(forKey: "DeletedQueue") ?? [String]()

        var upload = Array<Recipe>()
        var update = Array<Recipe>()

        // Any local recipes without ._id?
        for (index, recipe) in localRecipes.enumerated().reversed() {
            if(recipe._id == "") {
                upload.append(recipe)
                localRecipes.remove(at: index)
            }
        }

        // Any online recipes?
        if(cloudRecipes.count > 0) {
            for recipe in cloudRecipes {
                let localInstance = localRecipes.firstIndex(where: {$0._id == recipe._id})
                let shouldDelete = deleteRecipes.firstIndex(where: {$0 == recipe._id})

                // Is there an existing local version of this online recipe?
                if ( localInstance != nil) {
                    // Compare recipe.updatedAt to select the most recent version
                    let webDate = stringToDate(date: recipe.updatedAt!)
                    let locDate = stringToDate(date: localRecipes[localInstance!].updatedAt!)

                    if (NSCalendar.current.isDate(webDate, equalTo: locDate, toGranularity: .second)) {
                    } else if (webDate > locDate) {
                        realmManager.create(recipe)
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
                    os_log("Adding %@ to Realm", recipe.title!)

                    realmManager.create(recipe)

                }
            }
        }

        if (upload.count > 0) {
            // Post update recipes.
            do {
                os_log("Uploading recipes.")
                try APIManager().bulkInsertRecipes(recipes: upload,
                                                   onSuccess: {
                                                    os_log("Successful recipe upload")
                },
                                                   onFailure: { error in
                                                    os_log("Error uploading recipes: %@", error.localizedDescription)
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
                os_log("Recipe bulk update.")
                try APIManager().bulkUpdateRecipes(recipes: update,
                                                   onSuccess: {
                                                    os_log("Successful recipe bulk update.")
                },
                                                   onFailure: { error in
                                                    os_log("Error updating recipes: ", error.localizedDescription)
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
            os_log("Deleting recipes.")

            // Post update recipes.
            do {
                try APIManager().bulkDeleteRecipes(recipes: deleteRecipes,
                                                   onSuccess: {
                                                    os_log("Successful bulk recipe delete.")
                                                    //Set the recipes to delete list to nada
                                                    let delete_queue = [String]()
                                                    UserDefaults.standard.set(delete_queue, forKey: "DeletedQueue")
                                                    print(delete_queue)
                },
                                                   onFailure: { error in
                                                    os_log("Error bulk deleting recipes: ", error.localizedDescription)
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
