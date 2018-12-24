//
//  APIManager.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 7/26/18.
//  Copyright © 2018 kayso. All rights reserved.


import UIKit
import SwiftKeychainWrapper
import RealmSwift

struct Token: Decodable {
    let success: Bool
    let message: String
    let token: String
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

    // User
    func createUser(email: String, username: String, password: String, onSuccess: @escaping(String) -> Void, onFailure: @escaping(Error) -> Void) throws {
        let url : String = baseURL + userEndpoint

        // Structure the data
        let json: [String: Any] = [
            "name": username,
            "email": email,
            "password": password,
            "admin": false
        ]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)

        // Execute the request
        let request: NSMutableURLRequest = NSMutableURLRequest(url: NSURL(string: url)! as URL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {(data, response, error) in
            guard let data = data, error == nil, response != nil else {onFailure(error!); return}

            do {
                let message = try JSONSerializer().serializeUser(input: data)
                onSuccess(message)
            }
            catch {
                print("Encountered an error when decoding user response.")
                onFailure(error)
            }
        }).resume()
    }

    func getToken(email: String, password: String, onSuccess: @escaping() -> Void, onFailure: @escaping(Error) -> Void) throws {

        print("lets get you a token.")

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
                return
            }

            do {
                // I think that the line below should be refactored into a call to our JSON serializer
                let token = try JSONDecoder().decode(Token.self, from: data)
                let saveSuccessful = KeychainWrapper.standard.set(token.token, forKey: "fr_token")
                if (saveSuccessful) {
                    print("Authorization token recorded.")
                    onSuccess()
                }
            }
            catch {
                print("Encountered an error when decoding authorization token.")
                onFailure(error)
            }

        }).resume()
    }

    // Recipes
    func loadRecipes(onSuccess: @escaping() -> Void, onFailure: @escaping(Error) -> Void) throws {
        print("lets try loading some recipes.")

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
        let url : String = baseURL + recipesEndpoint

        let request: NSMutableURLRequest = NSMutableURLRequest(url: NSURL(string: url)! as URL)
        request.httpMethod = "GET"
        request.addValue(retrievedToken, forHTTPHeaderField: "x-access-token")

        URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {(data, response, error) in
            guard let data = data, error == nil, response != nil else {
                onFailure(error!)
                return
            }

            do {
                try JSONSerializer().serialize(input: data)
                onSuccess()
            }
            catch {
                // If no recipes return, we need to let the user know with a notification.
                onFailure(error)
            }
        }).resume()
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

        if (accessToken == nil) {
            print("no token")
        }

        else {
            let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
                if(error != nil){
                    onFailure(error!)
                }

                //Perhaps check that response is 200
                else{
                    do {
                        guard let data = data else { return }
                        print(data)
                    }
                }
            })
            task.resume()
        }
    }

    func bulkInsertRecipes(recipes: [Recipe], onSuccess: @escaping() -> Void, onFailure: @escaping(Error) -> Void) throws {

        // Check for internet connection
        if !Reachability.isConnectedToNetwork() {
            throw RecipeError.noInternetConnection
        }

        // Get the authorization token.
        guard let retrievedToken: String = KeychainWrapper.standard.string(forKey: "fr_token") else {
            throw RecipeError.noToken
        }

        // Structure the data.
        var json = Array<Any>()

        for recipe in recipes {
            var ing = Array<String>()
            for ingredient in recipe.ingredients {
                ing.append(ingredient.name)
            }

            var dir = Array<String>()
            for direction in recipe.directions {
                dir.append(direction.text)
            }

            let element = [
                "title": recipe.title!,
                "realmID": recipe.realmID,
                "updatedAt": recipe.updatedAt!,
                "ingredients": ing,
                "directions": dir
                ] as [String : Any]

            json.append(element)
        }

        let jsonData = try? JSONSerialization.data(withJSONObject: json)

        // Execute request.
        let url : String = baseURL + recipesEndpoint
        let request: NSMutableURLRequest = NSMutableURLRequest(url: NSURL(string: url)! as URL)
        request.httpMethod = "POST"
        request.addValue(retrievedToken, forHTTPHeaderField: "x-access-token")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        request.httpBody = jsonData

        print("bulk insert")
        print(json)

        URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
            guard let data = data, error == nil, response != nil else {onFailure(error!); return}

            // Update the recipe Id's
            do {
                let uploadedRecipes = try JSONSerializer().serializeUploadedRecipes(input: data)

                for example in uploadedRecipes.enumerated() {
                    print("writing to realm")

                    let realm = try! Realm()

                    if let updatingRecipe = realm.object(ofType: Recipe.self, forPrimaryKey: example.element.realmID) {
                        print("updating recipe id's in Realm")

                        try! realm.write {
                            updatingRecipe._id = example.element._id
                        }
                    }
                }

                onSuccess()
            }
            catch {
                // If no recipes return, we need to let the user know with a notification.
                onFailure(error)
            }
            
        }).resume()
    }

    func bulkUpdateRecipes(recipes: [Recipe], onSuccess: @escaping() -> Void, onFailure: @escaping(Error) -> Void) throws {

        // Check for internet connection
        if !Reachability.isConnectedToNetwork() {
            throw RecipeError.noInternetConnection
        }

        // Get the authorization token.
        guard let retrievedToken: String = KeychainWrapper.standard.string(forKey: "fr_token") else {
            throw RecipeError.noToken
        }

        // Structure the data.
        var json = Array<Any>()

        for recipe in recipes {
            var ing = Array<String>()
            for ingredient in recipe.ingredients {
                ing.append(ingredient.name)
            }

            var dir = Array<String>()
            for direction in recipe.directions {
                dir.append(direction.text)
            }

            let element = [
                "_id": recipe._id!,
                "realmID": recipe.realmID,
                "title": recipe.title!,
                "ingredients": ing,
                "directions": dir,
                "updatedAt": recipe.updatedAt!
                ] as [String : Any]

            json.append(element)
        }

        let jsonData = try? JSONSerialization.data(withJSONObject: json)

        // Execute request.
        let url : String = baseURL + updateRecipesEndpoint
        let request: NSMutableURLRequest = NSMutableURLRequest(url: NSURL(string: url)! as URL)
        request.httpMethod = "PUT"
        request.addValue(retrievedToken, forHTTPHeaderField: "x-access-token")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        request.httpBody = jsonData

        print(String(decoding: jsonData!, as: UTF8.self))

        URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
            guard let data = data, error == nil, response != nil else {onFailure(error!); return}

            print(String(decoding: data, as: UTF8.self))
        }).resume()

    }

    func deleteRecipe(id: String, onSuccess: @escaping() -> Void, onFailure: @escaping(Error) -> Void) {
        let url : String = baseURL + deleteRecipeEndpoint + "/" + id

        let session = URLSession.shared
        let request: NSMutableURLRequest = NSMutableURLRequest(url: NSURL(string: url)! as URL)

        request.httpMethod = "DELETE"
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData

        let accessToken: String? = KeychainWrapper.standard.string(forKey: "fr_token")

        if (accessToken == nil) {
            print("no token")
        }
        else {
            request.addValue(accessToken!, forHTTPHeaderField: "x-access-token")

            print("calling: " + url)

            let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
                if(error != nil){
                    onFailure(error!)
                }

                //Perhaps check that response is 200
                else{
                    do {
                        guard let data = data else { return }
                        print(data)
                    }
                }
            })
            task.resume()
        }
    }

    func bulkDeleteRecipes(recipes: [String], onSuccess: @escaping() -> Void, onFailure: @escaping(Error) -> Void) throws {

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

        print(String(decoding: jsonData!, as: UTF8.self))

        URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
            guard let data = data, error == nil, response != nil else {onFailure(error!); return}

            print(String(decoding: data, as: UTF8.self))
        }).resume()

    }

}
