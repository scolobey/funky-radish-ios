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

struct RecipeResponseList: Decodable {
    let recipes : [RecipeResponse]
}

struct RecipeResponse: Decodable {
    let _id: String
    let author: String
    let title: String
    let ing: [String]
    let dir: [String]
}

enum apiError: Error {
    case endpointFailed
    case noToken
    case invalidToken
    case noInternetConnection
    case invalidLogin
    case createUserError
    case userNotFound
    case badPassword
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
                else if (token.error == "User not found"){
                    onFailure(apiError.userNotFound)
                }
                else if (token.error == "Incorrect password."){
                    onFailure(apiError.badPassword)
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
    
    func searchRecipes(query: String, onSuccess: @escaping([RecipeResponse]) -> Void, onFailure: @escaping(Error) -> Void) throws {
        // Get the realm key in order to get access to the search endpoint.
        let realmKey = Bundle.main.object(forInfoDictionaryKey: "REALM_KEY") as? String
        
        guard let key = realmKey, !key.isEmpty else {
            os_log("API key does not exist")
            return
        }
        
        let endpoint = Constants.SEARCH_ENDPOINT
        
        let queryEndpoint = URL(string: endpoint + query.replacingOccurrences(of: " ", with: "%20"))!
        
        os_log("endpoint: %@", queryEndpoint as CVarArg)
        
        let request: NSMutableURLRequest = NSMutableURLRequest(url: queryEndpoint)
        request.httpMethod = "GET"
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        request.addValue(key, forHTTPHeaderField: "x-access-token")
           

        // I think the error structuring on this can be improved.
        URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {(data, response, error) in
              
            guard let data = data, error == nil, response != nil else {
                onFailure(error!)
                return
            }

            do {
                os_log("data: %@", data as CVarArg)

                let recipeSearchResponse = try JSONDecoder().decode(RecipeResponseList.self, from: data)
                
                onSuccess(recipeSearchResponse.recipes)
            }
            catch {
                print(String(describing: error))
//                onFailure(apiError.noToken)
            }
        }).resume()
    }
}
