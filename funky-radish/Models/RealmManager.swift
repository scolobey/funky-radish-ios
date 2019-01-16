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
    //    private let NotificationError = Notification.Name.Realm.realmErrorNotification

    let realm: Realm

    init(realm: Realm = try! Realm()) {
        self.realm = realm
    }

    func create<T: Object>(_ object: T) {
        do {
            try realm.write {
                realm.add(object, update: true)
            }
        } catch {
            os_log("Realm error: %@", error.localizedDescription)
        }
    }

    func createOrUpdate<Model, RealmObject: Object>(model: Model, with reverseTransformer: (Model) -> RealmObject) {
        let object = reverseTransformer(model)
        try! realm.write {
            realm.add(object, update: true)
        }
    }

    func create<T: Object>(_ objects: [T]) {
        do {
            try realm.write {
                realm.add(objects, update: true)
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
}
