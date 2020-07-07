//
//  APIManager.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 7/26/18.
//  Copyright © 2018 kayso. All rights reserved.

import SwiftKeychainWrapper
import Promises
import os

struct Token: Decodable {
    let success: Bool
    let message : String
    let token : String
}

struct ResponseMessage: Decodable {
    let success: Bool
    let message: String
}

enum RecipeError: Error {
    case noToken
    case invalidToken
    case noInternetConnection
    case invalidLogin
    case createUserError
}

class APIManager: NSObject {
    let keychainWrapper = KeychainWrapper(serviceName: KeychainWrapper.standard.serviceName, accessGroup: "group.myAccessGroup")

    static let sharedInstance = APIManager()

    // Endpoints
    final let baseURL = "https://funky-radish-api.herokuapp.com/"
    final let authEndpoint = "authenticate"
    final let recipesEndpoint = "recipes"
    final let deleteRecipeEndpoint = "recipe"
    final let updateRecipesEndpoint = "updateRecipes"
    final let userEndpoint = "users"
    final let deleteRecipesEndpoint = "deleteRecipes"

    func getToken(email: String, password: String, onSuccess: @escaping() -> Void, onFailure: @escaping(Error) -> Void) throws {

        // Check the internet connection
        if !Reachability.isConnectedToNetwork() {
            throw RecipeError.noInternetConnection
        }

        // Setup the request
        let url : String = baseURL + authEndpoint
        let request: NSMutableURLRequest = NSMutableURLRequest(url: NSURL(string: url)! as URL)

        request.httpMethod = "POST"
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
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
                let saveSuccessful = KeychainWrapper.standard.set(token.token, forKey: "fr_token")
                if (saveSuccessful) {
                    KeychainWrapper.standard.set(email, forKey: "fr_user_email")
                    KeychainWrapper.standard.set(password, forKey: "fr_password")
                    onSuccess()
                }
            }
            catch {
                os_log("Error downloading token.")
            }

        }).resume()
    }

    func callRecipeEndpoint() -> Promise<Data> {

        return Promise<Data> { (fullfill, reject) in
            // Check the internet connection
            if !Reachability.isConnectedToNetwork() {
                throw RecipeError.noInternetConnection
            }

            // Check the keychain for an authorization token.
            guard let retrievedToken: String = KeychainWrapper.standard.string(forKey: "fr_token") else {
                throw RecipeError.noToken
            }

            if(retrievedToken.count < 1) {
                throw RecipeError.noToken
            }

            // Token in hand, we can request our recipes from the API.
                let url : String = self.baseURL + self.recipesEndpoint

            let request: NSMutableURLRequest = NSMutableURLRequest(url: NSURL(string: url)! as URL)
            request.httpMethod = "GET"
            request.addValue(retrievedToken, forHTTPHeaderField: "x-access-token")


            URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {(data, response, error) in
                if let error = error {
                    reject(error)
                    return
                }
                guard let data = data else {
                    let error = NSError(domain: "", code: 100, userInfo: nil)
                    reject(error)
                    return
                }

                fullfill(data)
            }).resume()
        }
    }

    func addRecipe(recipe: Recipe, onSuccess: @escaping() -> Void, onFailure: @escaping(Error) -> Void) {
        let url : String = baseURL + recipesEndpoint

        let session = URLSession.shared
        let request: NSMutableURLRequest = NSMutableURLRequest(url: NSURL(string: url)! as URL)

        request.httpMethod = "POST"
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData

        let accessToken: String? = KeychainWrapper.standard.string(forKey: "fr_token")

        request.addValue(accessToken!, forHTTPHeaderField: "x-access-token")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let ingredients = recipe.ingredients.map({$0.name})
        let directions = recipe.directions.map({$0.text})

        let json: [String: Any] = [
            "title": recipe.title!,
            "ingredients": ingredients,
            "directions": directions
            // , "author": recipe.author!
        ]

        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData

        if (accessToken != nil) {
            let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
                if(error != nil){
                    onFailure(error!)
                }

                    //TODO: check that response is 200
                else{
                    do {
                        guard data != nil else { return }
                    }
                }
            })
            task.resume()
        }
    }

//    func bulkInsertRecipes(recipes: [Recipe], onSuccess: @escaping() -> Void, onFailure: @escaping(Error) -> Void) throws {
//
//        // Check for internet connection
//        if !Reachability.isConnectedToNetwork() {
//            throw RecipeError.noInternetConnection
//        }
//
//        // Get the authorization token.
//        guard let retrievedToken: String = KeychainWrapper.standard.string(forKey: "fr_token") else {
//            throw RecipeError.noToken
//        }
//
//        // Structure the data.
//        var json = Array<Any>()
//
//        for recipe in recipes {
//            var ing = Array<String>()
//            for ingredient in recipe.ingredients {
//                ing.append(ingredient.name)
//            }
//
//            var dir = Array<String>()
//            for direction in recipe.directions {
//                dir.append(direction.text)
//            }
//
//            let element = [
//                "title": recipe.title!,
//                "realmID": recipe.realmID,
//                "updatedAt": recipe.updatedAt!,
//                "ingredients": ing,
//                "directions": dir
//                ] as [String : Any]
//
//            json.append(element)
//        }
//
//        let jsonData = try? JSONSerialization.data(withJSONObject: json)
//
//        // Execute request.
//        let url : String = baseURL + recipesEndpoint
//        let request: NSMutableURLRequest = NSMutableURLRequest(url: NSURL(string: url)! as URL)
//        request.httpMethod = "POST"
//        request.addValue(retrievedToken, forHTTPHeaderField: "x-access-token")
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
//        
//        request.httpBody = jsonData
//
//        os_log("Bulk insertion: %@", String(data: jsonData!, encoding: .utf8)!)
//
//        URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
//            guard let data = data, error == nil, response != nil else {onFailure(error!); return}
//
//            // Update the recipe Id's
//            do {
//                let uploadedRecipes = try JSONSerializer().serializeUploadedRecipes(input: data)
//
//                // Update ._id of local recipes.
//                let realmManager = RealmManager()
//
//                let offlineRecipes = realmManager.read(Recipe.self)
//
//                for recipe in offlineRecipes {
//                    let onlineRecipes = uploadedRecipes.filter { $0.realmID == recipe.realmID }
//                    if onlineRecipes.count > 0 {
//                        let onlineRecipe = onlineRecipes[0]
//                        realmManager.update(recipe, with: ["_id": onlineRecipe._id!])
//                    }
//                }
//
////                for example in uploadedRecipes.enumerated() {
////                    let realmManager = RealmManager()
////
////                    let updatingRecipe = realmManager.fetch(example.element.realmID)
////                    realmManager.update(updatingRecipe, with: ["_id": example.element.realmID])
////                }
//
//                onSuccess()
//            }
//            catch {
//                // If no recipes return, we need to let the user know with a notification.
//                onFailure(error)
//            }
//
//        }).resume()
//    }

//    func bulkUpdateRecipes(recipes: [Recipe], onSuccess: @escaping() -> Void, onFailure: @escaping(Error) -> Void) throws {
//        // Check for internet connection
//        if !Reachability.isConnectedToNetwork() {
//            throw RecipeError.noInternetConnection
//        }
//
//        // Get the authorization token.
//        guard let retrievedToken: String = KeychainWrapper.standard.string(forKey: "fr_token") else {
//            throw RecipeError.noToken
//        }
//
//        // Structure the data.
//        var json = Array<Any>()
//
//        for recipe in recipes {
//            var ing = Array<String>()
//            for ingredient in recipe.ingredients {
//                ing.append(ingredient.name!)
//            }
//
//            var dir = Array<String>()
//            for direction in recipe.directions {
//                dir.append(direction.text)
//            }
//
//            let element = [
//                "_id": recipe._id!,
//                "realmID": recipe.realmID,
//                "title": recipe.title!,
//                "ingredients": ing,
//                "directions": dir,
//                "updatedAt": recipe.updatedAt!
//                ] as [String : Any]
//
//            json.append(element)
//        }
//
//        let jsonData = try? JSONSerialization.data(withJSONObject: json)
//
//        // Execute request.
//        let url : String = baseURL + updateRecipesEndpoint
//        let request: NSMutableURLRequest = NSMutableURLRequest(url: NSURL(string: url)! as URL)
//        request.httpMethod = "PUT"
//        request.addValue(retrievedToken, forHTTPHeaderField: "x-access-token")
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
//        request.httpBody = jsonData
//
//        URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
//            guard let _ = data, error == nil, response != nil else {onFailure(error!); return}
//        }).resume()
//
//    }

    func deleteRecipe(id: String, onSuccess: @escaping() -> Void, onFailure: @escaping(Error) -> Void) throws {
        os_log("Recipe deletion.")

        // Check the internet connection
        if !Reachability.isConnectedToNetwork() {
            throw RecipeError.noInternetConnection
        }

        let url : String = baseURL + deleteRecipeEndpoint + "/" + id

        let session = URLSession.shared
        let request: NSMutableURLRequest = NSMutableURLRequest(url: NSURL(string: url)! as URL)

        request.httpMethod = "DELETE"
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData

        let accessToken: String? = KeychainWrapper.standard.string(forKey: "fr_token")

        if (accessToken != nil) {
            request.addValue(accessToken!, forHTTPHeaderField: "x-access-token")

            let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
                if(error != nil){
                    onFailure(error!)
                }

                    //Perhaps check that response is 200
                else{
                    do {
                        guard data != nil else { return }
                    }
                }
            })
            task.resume()
        }
    }

    func bulkDeleteRecipes(recipes: [String], onSuccess: @escaping() -> Void, onFailure: @escaping(Error) -> Void) throws {
        os_log("Recipe deletion.")

        // Check for internet connection
        if !Reachability.isConnectedToNetwork() {
            throw RecipeError.noInternetConnection
        }

        // Get the authorization token.
        guard let retrievedToken: String = KeychainWrapper.standard.string(forKey: "fr_token") else {
            throw RecipeError.noToken
        }

        let jsonData = try? JSONSerialization.data(withJSONObject: recipes)

        // Execute request.
        let url : String = baseURL + deleteRecipesEndpoint
        let request: NSMutableURLRequest = NSMutableURLRequest(url: NSURL(string: url)! as URL)
        request.httpMethod = "DELETE"
        request.addValue(retrievedToken, forHTTPHeaderField: "x-access-token")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
            guard let _ = data, error == nil, response != nil else {onFailure(error!); return}
        }).resume()
    }
}
