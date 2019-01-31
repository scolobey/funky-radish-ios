//
//  SignUpViewController.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 7/3/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import UIKit
import RealmSwift
import SwiftKeychainWrapper
import os

enum signupError: Error {
    case incompleteUsername
    case noConnection
}

class SignUpViewController: UIViewController {
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!

    @IBAction func signUpButton(_ sender: Any) {
        let email = emailField.text!
        let username = usernameField.text!
        let pw = passwordField.text!

        self.view.endEditing(true)

        do {
            if !Reachability.isConnectedToNetwork() {
                throw signupError.noConnection
            }

            if (username.count == 0){
                throw signupError.incompleteUsername
            }
            try Validation().isValidEmail(email)
            try Validation().isValidPW(pw)

            activateLoadingIndicator()

            self.view.endEditing(true)

            // Call API
            try APIManager().createUser(
                email: email,
                username: username,
                password: pw,
                onSuccess: { msg in
                    do {
                        try self.getToken(email: email, pw: pw)
                    }
                    catch RecipeError.invalidLogin {
                        os_log("Those aren't the right credentials")
                    }
                    catch {
                        os_log("Encountered an unidentified token error.")
                    }
                },
                onFailure: { error in
                    self.deactivateLoadingIndicator()
                    self.navigationController!.showToast(message: "Error creating user.")
                }
            )
        }
        catch signupError.incompleteUsername {
            self.navigationController!.showToast(message: "Username required.")
        }
        catch validationError.invalidEmail {
            self.navigationController!.showToast(message: "Invalid email.")
        }
        catch validationError.shortPassword {
            self.navigationController!.showToast(message: "Password must contain at least 8 characters.")
        }
        catch validationError.invalidPassword {
            // TODO: Can't show toast if navigation Controller is not available?.
            self.navigationController!.showToast(message: "Password must contain a number.")
        }
        catch signupError.noConnection {
            self.navigationController!.showToast(message: "No internet connection.")
        }
        catch {
            self.navigationController!.showToast(message: "Unknown signup error.")
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

    override var prefersStatusBarHidden: Bool {
        return true
    }

    func getToken(email: String, pw: String) throws {
        let API = APIManager()

        try API.getToken(email: email, password: pw,
            onSuccess: {
                UserDefaults.standard.set(false, forKey: "fr_isOffline")

                // Synch recipes
                DispatchQueue.main.async {
                    //If you've already added recipes, post them to the API
                    if (localRecipes.count > 0) {
                        do {
                            try APIManager().bulkInsertRecipes(recipes: Array(localRecipes),
                            onSuccess: {
                                os_log("success")
                                DispatchQueue.main.async {
                                    self.deactivateLoadingIndicator()
                                }
                            },
                            onFailure: { error in
                                os_log("Error: %@", error.localizedDescription)
                            })
                        }
                        catch {
                            os_log("Error inserting recipes")
                        }
                    } else {
                       self.deactivateLoadingIndicator()
                    }

                    self.navigationController?.popToRootViewController(animated: false)
                }
            },
            onFailure: { error in
                /* This should never happen. Unless maybe somehow the server went down between creating a user and logging in */
                DispatchQueue.main.async {
                    self.navigationController!.showToast(message: "Error: " + error.localizedDescription)
                }
            }
        )
    }
}
