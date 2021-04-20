//
//  Direction.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 7/31/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

class Direction: Object { 
    @objc dynamic var _id: String? = ObjectId.generate().stringValue
    @objc dynamic var author: String = ""
    @objc dynamic var text: String = ""

    override static func primaryKey() -> String? {
        return "_id"
    }
    
    convenience init(text: String) {
        self.init()
        self.text = text
    }
}
