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
    @objc dynamic var _id = ObjectId.generate()
    @objc dynamic var _partition = ""
    @objc dynamic var text: String = ""

    override static func primaryKey() -> String? {
        return "_id"
    }
    
    convenience init(partition: String, text: String) {
        self.init()
        self._partition = partition
        self.text = text
    }

//    private enum DirectionCodingKeys: String, CodingKey {
//        case text
//    }

//    convenience init(text: String) {
//        self.init()
//        self.text = text
//    }
//
//    convenience required init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: DirectionCodingKeys.self)
//        let text = try container.decode(String.self, forKey: .text)
//        self.init(text: text)
//    }
//
//    required init() {
//        super.init()
//    }
}
