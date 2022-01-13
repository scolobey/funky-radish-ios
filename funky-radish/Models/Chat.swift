//
//  Cha.swift
//  funky-radish
//
//  Created by Ryan on 1/6/22.
//  Copyright © 2022 kayso. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

@objcMembers class Chat: EmbeddedObject  {
    @objc dynamic var _id: String? = ObjectId.generate().stringValue
    @objc dynamic var recipe: Recipe? = nil
}
