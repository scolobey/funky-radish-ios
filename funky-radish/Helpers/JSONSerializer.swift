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
    case realmError
}

// Probably can convert this double 'do' to series of guard else to
class JSONSerializer {
    func serialize(input data: Data) throws {
        let jsonDecoder = JSONDecoder()

        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
            guard json is [AnyObject] else {
                throw serializerError.formattingError
            }
            do {
                let recipes = try jsonDecoder.decode([Recipe].self, from: data)
                let realm = try! Realm()

                let localRecs = realm.objects(Recipe.self)

                // Long term, need to maintain a Realm on the server and synch with Mongo at the controller level.

                // Check diff between localRecs and recipes
                // upload recipes without id's.
                // Store unrecorded recipes to Realm
                let cloudRecipes = Array(recipes)
                var localRecipes = Array(localRecs)

                var upload = [Recipe()]

                for (index, recipe) in localRecipes.enumerated() {
                    // Collect recipes without id's for upload.
                    if(recipe._id == nil) {
                        upload.append(recipe)
                        localRecipes.remove(at: index)
                    }
                }

                for recipe in cloudRecipes {
                    // Check for a local recipe with each id occurring in your downloaded recipes.
                    let localInstance = localRecipes.index(where: {$0._id == recipe._id})

                    if ( localInstance != nil) {
                        // If the local recipe was edited more recently, add it to the post list.
                        let webDate = stringToDate(date: recipe.updatedAt!)
                        let locDate = stringToDate(date: localRecipes[localInstance!].updatedAt!)

                        if (webDate > locDate) {
                            // update the local recipe
                        }
                        else {
                            // update the cloud recipe
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

                // Post upload recipes to the API
                // API should recieve a list of recipes and edit those with an id and create those without an id.
                print(upload)

            } catch {
                throw serializerError.realmError
            }
        } catch {
            throw serializerError.failedSerialization
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
