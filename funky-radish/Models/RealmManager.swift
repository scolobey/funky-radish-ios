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
    
    var partitionValue: String = "PUBLIC"
    
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
                os_log("setting partition in user exists zone")
                partitionValue = "PUBLIC"
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
            os_log("creating w/ partition: %@", "PUBLIC")
            object.setValue("PUBLIC", forKey: "_partition")
            
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
        
        os_log("creating or updating w/ partition: %@", "PUBLIC")
        object.setValue("PUBLIC", forKey: "_partition")
        
        try! realm.write {
            realm.add(object, update: .all)
        }
    }

    func create<T: Object>(_ objects: [T]) {
        do {
            for object in objects {
                os_log("creating many w/ partition: %@", "PUBLIC")
                object.setValue("PUBLIC", forKey: "_partition")
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
        os_log("running read: %@", result.description)
        return result
    }

    func fetch<T: Object>(_ id: String) -> T {
        let result = realm.object(ofType: T.self, forPrimaryKey: id)
        return result!
    }

    func update<T: Object>(_ object: T, with dictionary: [String: Any]) {
        do {
            try realm.write {
                os_log("updating w/ partition: %@", "PUBLIC")
                object.setValue("PUBLIC", forKey: "_partition")
                
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
        self.realm = try! Realm()
        completion()
    }

    // TODO: Rename this realmRefresh to encourage a little more caution.
    func refresh() {
        
        os_log("refreshing")
                
        if (app.currentUser() != nil) { // you were logged in.
            let offlineRecipes = realmManager.read(Recipe.self)
            var recipeArray = [Recipe]()

            // TODO: confusing that I used rec and recipe in the same function.
            for rec in offlineRecipes {
                let recipe = Recipe()
                let ing = List<Ingredient>()
                let dir = List<Direction>()

                for ingredient in rec.ingredients {
                    ing.append(ingredient)
                }

                for direction in rec.directions {
                    dir.append(direction)
                }

                recipe.title = rec.title
                recipe.ingredients = ing
                recipe.directions = dir

                recipeArray.append(recipe)
                
                os_log("deleting recipe here.")
                realmManager.delete(rec)
            }
            
            //TODO: Gotta go ahead and pick a better partition.
            partitionValue = "PUBLIC"
            
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
            
//           os_log("copying recipe w/ partition: %@", "PUBLIC")
//           recipe.setValue("PUBLIC", forKey: "_partition")
//                    
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

