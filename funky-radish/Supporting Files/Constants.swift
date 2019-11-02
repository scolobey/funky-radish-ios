//
//  Constants.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 10/13/19.
//  Copyright © 2019 kayso. All rights reserved.
//

import Foundation

struct Constants {
    static let MY_INSTANCE_ADDRESS = "funkyradish.us1.cloud.realm.io"

    static let AUTH_URL  = URL(string: "https://\(MY_INSTANCE_ADDRESS)")!
    static let REALM_URL = URL(string: "realms://\(MY_INSTANCE_ADDRESS)/~/recipes")!
}
