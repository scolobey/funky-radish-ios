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
                    print(msg)
                    do {
                        try self.getToken(email: email, pw: pw)
                    }
                    catch RecipeError.invalidLogin {
                        print("Those aren't the right credentials")
                    }
                    catch {
                        print("Encountered an unidentified token error.")
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
        catch validationError.invalidPassword {
            // TODO: Should guide the user on password requirements.
            // TODO: Can't show toast if navigation Controller is not available.
            self.navigationController!.showToast(message: "Invalid password.")
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
                KeychainWrapper.standard.set(email, forKey: "fr_user_email")
                UserDefaults.standard.set(false, forKey: "fr_isOffline")

                // Synch recipes
                DispatchQueue.main.async {
                    //If you've already added recipes, post them to the API
                    if (localRecipes.count > 0) {
                        do {
                            try APIManager().bulkInsertRecipes(recipes: Array(localRecipes),
                            onSuccess: {
                                print("success")
                            },
                            onFailure: { error in
                                print("Error: " + error.localizedDescription)
                            })
                        }
                        catch {
                            print("Error inserting recipes")
                        }
                    } else {
                       self.deactivateLoadingIndicator()
                    }

                    self.navigationController?.popToRootViewController(animated: false)
                }
            },
            onFailure: { error in
                self.deactivateLoadingIndicator()
                self.navigationController!.showToast(message: "Error: " + error.localizedDescription)
            }
        )
    }
}
