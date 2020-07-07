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

enum RealmError: Error {
    case create
    case read
    case fetch
    case update
}

final class RealmManager {
    
    var partitionValue: String = ""
    
    var realm:Realm 

    init() {
        
//        for u in SyncUser.all {
//            u.value.logOut()
//        }
        
        //TODO: verify schema migration works
        let config = Realm.Configuration(
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: 1,

            // Set the block which will be called automatically when opening a Realm with
            // a schema version lower than the one set above
            migrationBlock: { migration, oldSchemaVersion in
                // We haven’t migrated anything yet, so oldSchemaVersion == 0
                if (oldSchemaVersion < 1) {
                    // Nothing to do!
                    // Realm will automatically detect new properties and removed properties
                    // And will update the schema on disk automatically

                    migration.enumerateObjects(ofType: Direction.className()) { oldObject, newObject in
                        newObject!["realmID"] = UUID().uuidString
                    }

                    migration.enumerateObjects(ofType: Ingredient.className()) { oldObject, newObject in
                        newObject!["realmID"] = UUID().uuidString
                    }
                }
            },
            deleteRealmIfMigrationNeeded: true
        )

        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config

        if (app.currentUser() != nil) {
            if (partitionValue.count > 0) {
                partitionValue = "partition_value"
            }
            
            let config = app.currentUser()?.configuration(partitionValue: partitionValue)
            self.realm = try! Realm(configuration: config!)
            os_log("Realm loaded w user: %@", realm.syncSession?.description ?? "no desc")
        }
        else {
            self.realm = try! Realm()
            
            os_log("Realm loaded w/o user: %@", realm.syncSession?.debugDescription ?? "no desc")
        }

//        SyncManager.shared.errorHandler = { error, session in
//            let syncError = error as! SyncError
//            os_log("Realm Synch error: %@", syncError.localizedDescription)
//        }
    }

    func create<T: Object>(_ object: T) throws {
        do {
            try realm.write {
                realm.add(object)
            }
        } catch {
            os_log("Error: %@", error.localizedDescription)
            throw RealmError.create
        }
    }

    func createOrUpdate<Model, RealmObject: Object>(model: Model, with reverseTransformer: (Model) -> RealmObject) {
        os_log("Realm loaded create or update: %@", realm.syncSession?.description ?? "no desc")
        
        let object = reverseTransformer(model)
        try! realm.write {
            realm.add(object, update: .all)
        }
    }

    func create<T: Object>(_ objects: [T]) {
        do {
            try realm.write {
                realm.add(objects, update: .all)
            }
        } catch {
            os_log("Realm error: %@", error.localizedDescription)
        }
    }

    func read<T: Object>(_ object: T.Type) -> Results<T> {
        os_log("Realm read: %@", realm.syncSession?.description ?? "no desc")
        let result = realm.objects(object.self)
        return result
    }

    func fetch<T: Object>(_ id: String) -> T {
        os_log("Realm fetch: %@", realm.syncSession?.description ?? "no desc")
        let result = realm.object(ofType: T.self, forPrimaryKey: id)
        return result!
    }

    func update<T: Object>(_ object: T, with dictionary: [String: Any]) {
        os_log("Realm update from dictionary: %@", realm.syncSession?.description ?? "no desc")
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
        os_log("Realm delete: %@", realm.syncSession?.description ?? "no desc")
        do {
            try realm.write {
                realm.delete(object)
            }
        } catch {
            os_log("Realm error: %@", error.localizedDescription)
        }
    }

    func clearAll() {
        os_log("Realm clear all: %@", realm.syncSession?.description ?? "no desc")
        do {
            try realm.write {
                realm.deleteAll()
            }
        } catch {
            os_log("Realm error: %@", error.localizedDescription)
        }
    }

    func subscribe(handler: @escaping (Realm.Notification, Realm) -> Void) -> NotificationToken {
        os_log("Realm subscribe: %@", realm.syncSession?.description ?? "no desc")
        let token = realm.observe(handler)
        return token
    }

    func logout() {
        os_log("Realm logout: %@", realm.syncSession?.description ?? "no desc")
        app.logOut(completion: { (error) in
            DispatchQueue.main.sync {
                self.refresh()
            }
        })
    }

    func refresh() {
        os_log("Realm refresh: %@", realm.syncSession?.description ?? "no desc")
        
        if (app.currentUser() != nil) {
            
            // Get the current recipes so we can add them if they're not in the realm.
            let offlineRecipes = realmManager.read(Recipe.self)
            var recipeArray = [Recipe]()

            for rec in offlineRecipes {
                let recipe = Recipe()
                let ing = List<Ingredient>()
                let dir = List<Direction>()

                for ingredient in rec.ingredients {
                    ing.append(ingredient)
                }

                for direction in recipe.directions {
                    dir.append(direction)
                }

                recipe.title = rec.title
                recipe.ingredients = ing
                recipe.directions = dir

                recipeArray.append(recipe)
                
                os_log("deleting a recipe here.")
                realmManager.delete(rec)
            }
            
            //TODO: Gotta go ahead and pick a better partition.
            partitionValue = app.currentUser()?.identity ?? "partition"
            
            let config = app.currentUser()?.configuration(partitionValue: partitionValue)
            self.realm = try! Realm(configuration: config!)

            if (recipeArray.count > 0) {
                realmManager.copyRecipes(recipes: recipeArray)
            }

        }
        else {
            self.realm = try! Realm()
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
