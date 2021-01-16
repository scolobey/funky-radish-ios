//
//  Constants.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 10/13/19.
//  Copyright © 2019 kayso. All rights reserved.
//

import Foundation
import CoreBluetooth

struct Constants {
    
    static let REALM_INSTANCE_ADDRESS = "recipe-realm.us1.cloud.realm.io"
    static let REALM_AUTH_URL  = URL(string: "https://\(REALM_INSTANCE_ADDRESS)")!
    static let REALM_URL = URL(string: "realms://\(REALM_INSTANCE_ADDRESS)/~/recipes")!
    static let REALM_APP_ID = "funky-radish-twdxv"
    
    static let API_ADDRESS = "https://funky-radish-api.herokuapp.com"
//    static let API_ADDRESS = "http://localhost:8080"
    static let USER_ENDPOINT  = URL(string: "\(API_ADDRESS)/users")!
    static let TOKEN_ENDPOINT  = URL(string: "\(API_ADDRESS)/authenticate")!
    
    static let TOKEN_KEYCHAIN_STRING = "fr_token"
    static let EMAIL_KEYCHAIN_STRING = "fr_user_email"
    static let PASSWORD_KEYCHAIN_STRING = "fr_password"
    
    //TODO: Make sure we need both of these. It might be just a one-sided bluetooth transmission and only need 1 id?
    static let SERVICE_UUID = CBUUID(string: "0679FEB7-D13B-4B5E-A677-F8C6B2A80259")
    static let CHARACTERISTIC_UUID = CBUUID(string: "B18D6181-52B4-4CB5-A8A8-A5D0869AFEB3")
}
