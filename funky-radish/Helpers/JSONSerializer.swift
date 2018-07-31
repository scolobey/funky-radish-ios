//
//  JSONSerializer.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 7/29/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import Foundation
import RealmSwift

class JSONSerializer {
    func serialize(input data: Data) {

        let jsonDecoder = JSONDecoder()

        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
            guard json is [AnyObject] else {
                assert(false, "failed to parse")
                return
            }
            do {
                let recipes = try jsonDecoder.decode([Recipe].self, from: data)
                let realm = try! Realm()
                for recipe in recipes {
                    print(recipe)
                    try! realm.write {
                        realm.add(recipe)
                    }
                }
            } catch {
                print("failed to convert data")
                print(error)
            }
        } catch let error {
            print(error)
        }
    }
}
