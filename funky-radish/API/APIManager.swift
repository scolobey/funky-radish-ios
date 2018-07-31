//
//  APIManager.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 7/26/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

struct Token: Decodable {
    let success: Bool
    let message: String
    let token: String
}

class APIManager: NSObject {

    let baseURL = "https://funky-radish-api.herokuapp.com/"

    let keychainWrapper = KeychainWrapper(serviceName: KeychainWrapper.standard.serviceName, accessGroup: "group.myAccessGroup")

    static let sharedInstance = APIManager()

    static let getAuthEndpoint = "authenticate"
    static let getRecipesEndpoint = "recipes"

    func getToken(email: String, password: String, onSuccess: @escaping() -> Void, onFailure: @escaping(Error) -> Void) {

        let url : String = baseURL + APIManager.getAuthEndpoint

        let session = URLSession.shared
        let request: NSMutableURLRequest = NSMutableURLRequest(url: NSURL(string: url)! as URL)

        request.httpMethod = "POST"
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        let paramString = "email=" + email + "&password=" + password
        request.httpBody = paramString.data(using: String.Encoding.utf8)

        let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
            if(error != nil){
                onFailure(error!)
            }
                //Perhaps check that response is 200
            else{
                do {
                    guard let data = data else { return }
                    let token = try JSONDecoder().decode(Token.self, from: data)

                    print(token.token)
                    let saveSuccessful: Bool = KeychainWrapper.standard.set(token.token, forKey: "fr_token")
                    if (saveSuccessful) {
                        print("Token stored.")
                    }
                    else {
                        print("something wrong. U A pendejo")
                    }
                }
                catch {
                    print(error)
                }
            }
        })
        task.resume()

    }

}
