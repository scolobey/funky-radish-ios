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

final class RealmManager {
    var realm: Realm

    init() {
//        for u in SyncUser.all {
//            u.value.logOut()
//        }

        if (SyncUser.current != nil) {
            let config = SyncUser.current?.configuration(realmURL: Constants.REALM_URL, fullSynchronization: true)
            self.realm = try! Realm(configuration: config!)
        }
        else {
            self.realm = try! Realm()
        }

        SyncManager.shared.errorHandler = { error, session in
            let syncError = error as! SyncError
            os_log("Realm Synch error: %@", syncError.localizedDescription)
        }

    }

    func create<T: Object>(_ object: T) {
        do {
            try realm.write {
                realm.add(object, update: .all)
            }
        } catch {
            os_log("Realm error: %@", error.localizedDescription)
        }
    }

    func createOrUpdate<Model, RealmObject: Object>(model: Model, with reverseTransformer: (Model) -> RealmObject) {
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
        let result = realm.objects(object.self)
        return result
    }

    func fetch<T: Object>(_ id: String) -> T {
        let result = realm.object(ofType: T.self, forPrimaryKey: id)
        return result!
    }

    func update<T: Object>(_ object: T, with dictionary: [String: Any]) {
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
        let token = realm.observe(handler)
        return token
    }

    func logout() {
        SyncUser.current?.logOut()
        refresh()
    }

    func refresh() {
        if (SyncUser.current != nil) {
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
                realmManager.delete(rec)
            }

            // first get the current recipes. If they're not in the realm, add them.
            let config = SyncUser.current?.configuration(realmURL: Constants.REALM_URL, fullSynchronization: true)
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