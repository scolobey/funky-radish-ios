////
////  User.swift
////  funky-radish
////
////  Created by Ryn Goodwin on 7/31/18.
////  Copyright © 2018 kayso. All rights reserved.
////
//
//import Foundation
//import Realm
//import RealmSwift
//
//@objcMembers class User: Object {
//
//    @objc dynamic var _id: ObjectId? = ObjectId.generate()
//     let __v = RealmOptional<Int>()
//     let admin = RealmOptional<Bool>()
//     @objc dynamic var createdAt: Date? = nil
//     @objc dynamic var email: String? = nil
//     @objc dynamic var name: String? = nil
//     @objc dynamic var password: String? = nil
//     let recipes = RealmSwift.List<Recipe>()
//     @objc dynamic var updatedAt: Date? = nil
//     @objc dynamic var user: ObjectId = ObjectId.generate()
//
//    override static func primaryKey() -> String? {
//        return "_id"
//    }
//
////    private enum UserCodingKeys: String, CodingKey {
////        case _id
////        case name
////        case email
////        case recipes
////    }
////
////    convenience init(_id: String, name: String, email: String, recipes: List<Recipe>) {
////        self.init()
////        self._id = _id
////        self.name = name
////        self.email = email
////        self.recipes = recipes
////    }
////
////    convenience required init(from decoder: Decoder) throws {
////        let container = try decoder.container(keyedBy: UserCodingKeys.self)
////        let _id = try container.decode(String.self, forKey: ._id)
////        let name = try container.decode(String.self, forKey: .name)
////        let email = try container.decode(String.self, forKey: .email)
////
////        let recipeArray = try container.decode([Recipe].self, forKey: .recipes)
////
////        let recipeList = List<Recipe>()
////        recipeList.append(objectsIn: recipeArray)
////
////        self.init(_id: _id, name: name, email: email, recipes: recipeList)
////    }
////
////    required init() {
////        super.init()
////    }
//
//}
