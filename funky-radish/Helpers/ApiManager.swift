//
//  ApiManager.swift
//  funky-radish
//
//  Created by Ryan on 12/6/20.
//  Copyright © 2020 kayso. All rights reserved.
//

import Foundation
import SwiftKeychainWrapper
import os

struct Token: Decodable {
    let message : String
    let token : String
    let error : String
}

enum apiError: Error {
    case endpointFailed
    case noToken
    case invalidToken
    case noInternetConnection
    case invalidLogin
    case createUserError
    case emailTaken
    case verificationError
}

class ApiManager {
    
    func downloadToken(email:String, password:String, onSuccess: @escaping() -> Void, onFailure: @escaping(Error) -> Void) throws {
        let endpoint = Constants.TOKEN_ENDPOINT
         
         // Setup the request
         let request: NSMutableURLRequest = NSMutableURLRequest(url: endpoint)

         request.httpMethod = "POST"
         request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
         
         //TODO: This can't be a safe way to do this.
         let paramString = "email=" + email + "&password=" + password
         request.httpBody = paramString.data(using: String.Encoding.utf8)

         // I think the error structuring on this can be improved.
         URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {(data, response, error) in
            
             guard let data = data, error == nil, response != nil else {
                 onFailure(error!)
                 return
             }

             do {
                let token = try JSONDecoder().decode(Token.self, from: data)
                
                if (token.token.count > 0) {
                    let saveSuccessful = KeychainWrapper.standard.set(token.token, forKey: Constants.TOKEN_KEYCHAIN_STRING)
                    if (saveSuccessful) {
                        onSuccess()
                    } else {
                        onFailure(apiError.noToken)
                    }
                }
                else if (token.message == "Email not verified."){
                    onFailure(apiError.verificationError)
                }
                else if (token.error.count > 0){
                    os_log("API error: %@", token.error)
                    onFailure(apiError.noToken)
                }
             }
             catch {
                os_log("Error downloading token: %@", error.localizedDescription)
                onFailure(apiError.noToken)
             }

         }).resume()
    }
    
    func registerUser(email:String, password:String, onSuccess: @escaping() -> Void, onFailure: @escaping(Error) -> Void) throws {
    
        let endpoint = Constants.USER_ENDPOINT
           
        let request: NSMutableURLRequest = NSMutableURLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
           
        //TODO: This can't be a safe way to do this.
        let paramString = "email=" + email + "&password=" + password
        request.httpBody = paramString.data(using: String.Encoding.utf8)

        // I think the error structuring on this can be improved.
        URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {(data, response, error) in
              
            guard let data = data, error == nil, response != nil else {
                onFailure(error!)
                return
            }

            do {
                let userResponse = try JSONDecoder().decode(Token.self, from: data)
                    
                if (userResponse.message == "Verification email sent.") {
                    onSuccess()
                }
                else if (userResponse.message == "User validation failed: email: email is already taken.") {
                    onFailure(apiError.emailTaken)
                }
                else {
                    onFailure(apiError.createUserError)
                }
            }
            catch {
                os_log("Error creating a user: %@", error.localizedDescription)
                onFailure(apiError.noToken)
            }
        }).resume()
    }
}
