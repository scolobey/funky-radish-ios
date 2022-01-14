//
//  RealmManager.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 1/16/19.
//  Copyright © 2019 kayso. All rights reserved.
//

import Foundation
import RealmSwift
import os
import Promises



enum RealmError: Error {
    case create
    case read
    case fetch
    case update
}

final class RealmManager {
    
    var partitionValue: String
    var realm: Realm

    init() {
//        for u in SyncUser.all {
//            u.value.logOut()
//        }
        
        os_log("init realm")
        
        //TODO: verify schema migration works / remove deleteRealmIfMigrationNeeded
        let config = Realm.Configuration(
//            // Set the new schema version. This must be greater than the previously used
//            // version (if you've never set a schema version before, the version is 0).
//            schemaVersion: 1,
//
//            // Set the block which will be called automatically when opening a Realm with
//            // a schema version lower than the one set above
//            migrationBlock: { migration, oldSchemaVersion in
//                // We haven’t migrated anything yet, so oldSchemaVersion == 0
//                if (oldSchemaVersion < 1) {
//                    // Nothing to do!
//                    // Realm will automatically detect new properties and removed properties
//                    // And will update the schema on disk automatically
//
//                    migration.enumerateObjects(ofType: Direction.className()) { oldObject, newObject in
//                        newObject!["realmID"] = UUID().uuidString
//                    }
//
//                    migration.enumerateObjects(ofType: Ingredient.className()) { oldObject, newObject in
//                        newObject!["realmID"] = UUID().uuidString
//                    }
//                }
//            },
            
//            deleteRealmIfMigrationNeeded: true
        )

        if (app.currentUser != nil && app.currentUser?.id.count ?? 0 > 0) {
            os_log("There's a currentUser and their id is more than 0 characters")
            
            partitionValue = app.currentUser?.id ?? ""
            
            //TODO: Seems awfully redundant?
            if (partitionValue.count > 0) {
                let user_id = app.currentUser?.id
                partitionValue = user_id!
            }
            
            let config = app.currentUser?.configuration(partitionValue: partitionValue)

            realm = try! Realm(configuration: config!)
            os_log("Realm loaded w user: %@", realm.syncSession?.description ?? "no desc")
            
        }
        else {
            os_log("partition value is Nothing Okay!")
            partitionValue = ""
            
            realm = try! Realm()
            
            os_log("Realm loaded w/o user: %@", realm.syncSession?.debugDescription ?? "no desc")
        }
        
        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config
    }
    
    func importWatchedRecipes(recipes: AnyBSON, onSuccess: @escaping(RealmSwift.List<Recipe>) -> Void, onFailure: @escaping(Error) -> Void) throws {
        let client = app.currentUser!.mongoClient("mongodb-atlas")
        let database = client.database(named: "funky_radish_db")
        let collection = database.collection(withName: "Recipe")

        let queryFilter: Document = ["_id": ["$in": recipes]]
        
        var recipeList = RealmSwift.List<Recipe>()
        
        collection.find(filter: queryFilter) { result in
            switch result {
                case .failure(let error):
                    onFailure(error)
                case .success(let document):
                    for rec in document {
                        var watchedRecipe: Recipe = Recipe()
                        watchedRecipe.title = rec["title"]??.stringValue
                        
                        let ingFilter: AnyBSON = rec["ingredients"]! ?? []
                        
                        do {
                            try self.importWatchedIngredients(
                                ingredients: ingFilter,
                                onSuccess: { returnedIngredients in
                                    watchedRecipe.ingredients = returnedIngredients
                                                                        
                                    let dirFilter: AnyBSON = rec["directions"]! ?? []
                                    
                                    do {
                                        try self.importWatchedDirections(
                                            directions: dirFilter,
                                            onSuccess: { returnedDirections in
                                                watchedRecipe.directions = returnedDirections
                                                recipeList.append(watchedRecipe)
                                                                                                
                                                if (recipeList.count == recipes.arrayValue?.count) {
                                                    onSuccess(recipeList)
                                                }                                         
                                            },
                                            onFailure: { error in
                                                onFailure(error)
                                            })
                                    }
                                    catch {
                                        print("catch on the watched direction getter")
                                    }
                                },
                                onFailure: { error in
                                    onFailure(error)
                                })
                        }
                        catch {
                            print("catch on the watched ingredient getter")
                        }
                    }
            }
        }
    }

    // TODO: Consolidate these 2 functions that are nearly identical
    func importWatchedIngredients(ingredients: AnyBSON, onSuccess: @escaping(RealmSwift.List<Ingredient>) -> Void, onFailure: @escaping(Error) -> Void) throws {
        
        let client = app.currentUser!.mongoClient("mongodb-atlas")
        let database = client.database(named: "funky_radish_db")
        let ingCollection = database.collection(withName: "Ingredient")
        
        var embeddedIngredients = RealmSwift.List<Ingredient>()
        let ingFilter: Document = ["_id": ["$in": ingredients]]
        
     
        ingCollection.find(filter: ingFilter) { ingResult in
            switch ingResult {
                case .failure(let error):
                    onFailure(error)
                case .success(let ingredientDocument):
                    
                    for returnedIngredient in ingredientDocument {
                        let ing = Ingredient()
                        ing._id = returnedIngredient["_id"]??.stringValue
                        ing.name = returnedIngredient["name"]??.stringValue ?? ""
                        embeddedIngredients.append(ing)
                    }
                    
                    onSuccess(embeddedIngredients)
            }
        }
    }
    
    func importWatchedDirections(directions: AnyBSON, onSuccess: @escaping(RealmSwift.List<Direction>) -> Void, onFailure: @escaping(Error) -> Void) throws {
        
        let client = app.currentUser!.mongoClient("mongodb-atlas")
        let database = client.database(named: "funky_radish_db")
        let dirCollection = database.collection(withName: "Direction")
        
        var embeddedDirections = RealmSwift.List<Direction>()
        let dirFilter: Document = ["_id": ["$in": directions]]
        
        dirCollection.find(filter: dirFilter) { dirResult in
            switch dirResult {
                case .failure(let error):
                    onFailure(error)
                case .success(let directionDocument):
                    
                    for returnedDirection in directionDocument {
                        let dir = Direction()
                        dir._id = returnedDirection["_id"]??.stringValue
                        dir.text = returnedDirection["text"]??.stringValue ?? ""
                        embeddedDirections.append(dir)
                    }
                    
                    onSuccess(embeddedDirections)
            }
        }
    }
    
    func create<T: Object>(_ object: T) throws {
        do {
            let user_id = app.currentUser?.id
            
            if (user_id != nil) {
                os_log("creating w/ partition: %@", user_id!)
                object.setValue(user_id, forKey: "author")
            }
            
            try realm.write {
                realm.add(object)
            }
        } catch {
            os_log("Error: %@", error.localizedDescription)
            throw RealmError.create
        }
    }

    func createOrUpdate<Model, RealmObject: Object>(model: Model, with reverseTransformer: (Model) -> RealmObject) {
        let object = reverseTransformer(model)
             
        let user_id = app.currentUser?.id

        if (user_id != nil) {
            os_log("creating or updating w/ partition: %@", user_id!)
            object.setValue(user_id, forKey: "author")
        }
        
        try! realm.write {
            realm.add(object, update: .all)
        }
    }

    func create<T: Object>(_ objects: [T]) {
        do {
            for object in objects {
                let user_id = app.currentUser?.id
      
                if (user_id != nil) {
                    os_log("creating many w/ partition: %@", user_id!)
                    object.setValue(user_id, forKey: "author")
                }
            }
            
            try realm.write {
                realm.add(objects, update: .all)
            }
        } catch {
            os_log("Realm error: %@", error.localizedDescription)
        }
    }

    func read<T: Object>(_ object: T.Type) -> Results<T> {
        let result = realm.objects(object.self)
        return result
    }

    func fetch<T: Object>(_ id: String) -> T {
        let result = realm.object(ofType: T.self, forPrimaryKey: id)
        return result!
    }

    func update<T: Object>(_ object: T, with dictionary: [String: Any]) {
        // Todo: Someday this should be reworked. the logic is strange here where we're viewing each ingredient in the context of
        // it's order in the recipe, as opposed to it's relationship with a real-world ingredient.
        os_log("Realm update: ", dictionary)
        do {
            try realm.write {
                for (key, value) in dictionary {
                    object.setValue(value, forKey: key)
                }
            }
        } catch {
            os_log("Realm error: %@", error.localizedDescription)
        }
    }

    func delete<T: Object>(_ object: T) {   
        do {
            try realm.write {
                realm.delete(object)
            }
        } catch {
            os_log("Realm error: %@", error.localizedDescription)
        }
    }

    func clearAll() {
        do {
            try realm.write {
                realm.deleteAll()
            }
        } catch {
            os_log("Realm error: %@", error.localizedDescription)
        }
    }

    func subscribe(handler: @escaping (Realm.Notification, Realm) -> Void) -> NotificationToken {
        os_log("subscribing")
        
        let token = realm.observe(handler)
        return token
    }
    
    func logout(completion: @escaping () -> Void) {
        os_log("calling logout")
        
        let user = app.currentUser
        
        if (user != nil) {
            //slightly concerned here. Previous function threw an error.
            app.currentUser?.logOut { (_) in
                completion()
            }
        }
        else {
            // This solves for the random case where the user isn't there, but their records are still held.
            completion()
        }
    }

    func refresh() {
        os_log("refreshing")
                
        if (app.currentUser != nil) { // you were logged in.
            let offlineRecipes = realmManager.read(Recipe.self)
           
            var recipeArray = [Recipe]()
            
            partitionValue = app.currentUser?.id ?? ""

            // TODO: confusing that I used rec and recipe in the same function.
            // Also. Does it really make sense to do all of this?
            // Also. How do I not do this if the recipes are already synched?
            for rec in offlineRecipes {
                let recipe = Recipe()
                let ing = List<Ingredient>()
                let dir = List<Direction>()

                for ingredient in rec.ingredients {
                    realmManager.update(ingredient, with: ["author": partitionValue])
                    ing.append(ingredient)
                }

                for direction in rec.directions {
                    realmManager.update(direction, with: ["author": partitionValue])
                    dir.append(direction)
                }

                recipe.title = rec.title
                recipe.author = partitionValue
                recipe.ingredients = ing
                recipe.directions = dir

                recipeArray.append(recipe)
                realmManager.delete(rec)
            }
            
            os_log("Refreshing Realm w/ partition: %@", partitionValue)
            
            let config = app.currentUser?.configuration(partitionValue: partitionValue)
            realm = try! Realm(configuration: config!)
            
            if (recipeArray.count > 0) {
                realmManager.copyRecipes(recipes: recipeArray)
            }

        }
        else {
            os_log("Refreshing Realm w/ partition = nothing okay!")
            
            realm = try! Realm()
        }
    }
    
    func refreshLite() {
        os_log("refreshing: the light version")
                
        if (app.currentUser != nil) { // you were logged in.
            partitionValue = app.currentUser?.id ?? ""
            
            let config = app.currentUser?.configuration(partitionValue: partitionValue)
            realm = try! Realm(configuration: config!)
        }
        else {
            os_log("Refreshing Realm w/ partition = nothing okay!")
            realm = try! Realm()
        }
    }


    func copyRecipes(recipes: [Recipe]) {
        os_log("copy array of recipes: %@", realm.syncSession?.description ?? "no desc")
        for recipe in recipes {
            do {
                try realm.write {
                    realm.create(Recipe.self, value: recipe)
                }
            } catch {
                os_log("Realm error: %@", error.localizedDescription)
            }
        }
    }
    
}

