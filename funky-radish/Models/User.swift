//
//  User.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 7/31/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import Foundation
import RealmSwift

class User: Object {
    @objc dynamic var name : String? = nil
    @objc dynamic var email : String? = nil
    @objc dynamic var password : String? = nil
    let recipes = List<Recipe>()

    override static func primaryKey() -> String? {
        return "email"
    }
}
