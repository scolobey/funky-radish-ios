//
//  SignUpViewController.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 7/3/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import os
import Promises
import RealmSwift

enum signupError: Error {
    case incompleteUsername
    case noConnection
    case endpointInaccesible
    case userResponseInvalid
    case userCreationFailed
    case emailTaken
}

class SignUpViewController: UIViewController {
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!

    @IBAction func signUpButton(_ sender: Any) {
        let email = emailField.text!
        let password = passwordField.text!
        let username = usernameField.text!

        self.view.endEditing(true)
        activateLoadingIndicator()

        signup(email: email, password: password, username: username)
            .then { self.decodeUserResponse(data: $0, email: email, password: password) }
            .then { self.createRealmUser(token: $0) }
            .then {
                realmManager.refresh()
                self.deactivateLoadingIndicator()
                self.navigationController?.popToRootViewController(animated: false)
            }
            .catch { error in
                self.deactivateLoadingIndicator()

                switch error {
                case loginError.noConnection:
                    self.navigationController!.showToast(message: "No internet connection.")
                case validationError.invalidEmail:
                    self.navigationController!.showToast(message: "Invalid email.")
                case validationError.shortPassword:
                    self.navigationController!.showToast(message: "Password must contain at least 8 characters.")
                case validationError.invalidPassword:
                    self.navigationController!.showToast(message: "Password must contain a number.")
                case validationError.invalidUsername:
                    self.navigationController!.showToast(message: "Username required.")
                case signupError.endpointInaccesible:
                    self.navigationController!.showToast(message: "User post failed.")
                case signupError.userResponseInvalid:
                    self.navigationController!.showToast(message: "User response invalid.")
                case signupError.userCreationFailed:
                    self.navigationController!.showToast(message: "Could not create a user.")
                case signupError.emailTaken:
                    self.navigationController!.showToast(message: "Email already associated with an account.")
                case loginError.tokenFailure:
                    self.navigationController!.showToast(message: "There's a problem with the token.")
                case RecipeError.invalidLogin:
                    self.navigationController!.showToast(message: "Invalid token. Please log out and log back in.")
                case serializerError.failedSerialization:
                    self.navigationController!.showToast(message: "Recipe serialization failed.")
                case serializerError.formattingError:
                    self.navigationController!.showToast(message: "Recipe response invalid.")
                default:
                    self.navigationController!.showToast(message: "Unidentified error.")
                }
        }
    }

    @IBAction func dismissSignUp(_ sender: UIButton) {
        self.navigationController?.popToRootViewController(animated: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpProperties()
    }

    @IBAction func loginSegue(_ sender: Any) {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LogInViewController") as? LogInViewController
        {
            self.navigationController?.pushViewController(vc, animated: false)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }

    func setUpProperties() {
        navigationController?.navigationBar.layer.frame.origin.y = 20
    }

    func signup(email: String, password: String, username: String) -> Promise<Data> {

//        let url = "https://funky-radish-api.herokuapp.com/users"
        let url = "http://localhost:8080/users"

        UserDefaults.standard.set(false, forKey: "fr_isOffline")

        let offlineRecipes = realmManager.read(Recipe.self)
        let localRecipes = Array(offlineRecipes)

        var recipeArray = Array<Any>()

        for recipe in localRecipes {
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

            recipeArray.append(element)
        }

        let json: [String: Any] = [
            "name": username,
            "email": email,
            "password": password,
            "admin": false,
            "recipes": recipeArray
        ]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)

        let request: NSMutableURLRequest = NSMutableURLRequest(url: NSURL(string: url)! as URL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        return Promise<Data> { (fullfill, reject) in
            if !Reachability.isConnectedToNetwork() {
                throw loginError.noConnection
            }

            try Validation().isValidEmail(email)
            try Validation().isValidPW(password)
            try Validation().isValidUsername(username)

            URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {(data, response, error) in
                if error != nil {
                    reject(signupError.endpointInaccesible)
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

    func decodeUserResponse(data: Data, email: String, password: String) -> Promise<String> {
        return Promise<String> { (fullfill, reject) in

                let userResponse = try JSONDecoder().decode(UserResponse.self, from: data)

                // Ensure that UserResponse was decoded and that User was created.
                if (userResponse.message.contains("email is already taken")) {
                    throw signupError.emailTaken
                }
                else if (userResponse.message.contains("User created successfully.") == false) {
                    throw signupError.userResponseInvalid
                }

                // Set the token.
                if (userResponse.token != nil && userResponse.token!.count > 0) {
                    KeychainWrapper.standard.set(email, forKey: "fr_user_email")
                    KeychainWrapper.standard.set(password, forKey: "fr_password")
                    KeychainWrapper.standard.set(userResponse.token!, forKey: "fr_token")
                }
                else {
                    throw loginError.tokenFailure
                }

                // Update ._id of local recipes.
                let realmManager = RealmManager()

                let offlineRecipes = realmManager.read(Recipe.self)

                for recipe in offlineRecipes {
                    let onlineRecipe = userResponse.userData!.recipes.filter { $0.realmID == recipe.realmID } [0]
                    realmManager.update(recipe, with: ["_id": onlineRecipe._id!])
                }

                fullfill(userResponse.token!)
        }
    }

    func createRealmUser(token: String) -> Promise<Void> {
        let auth_url = Constants.AUTH_URL
        let credentials = SyncCredentials.jwt(token)

        return Promise<Void> { (fullfill, reject) in

            os_log("creating a realm user")
            
            SyncUser.logIn(with: credentials, server: auth_url) { [weak self] (user, err) in
                guard let `self` = self else  { return }

                if let error = err {
                    self.deactivateLoadingIndicator()
                    let alert = UIAlertController(title: "Uh Oh", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Okay!", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                } else if let _ = user {
                    fullfill(())
                }
            }

        }
    }

}
