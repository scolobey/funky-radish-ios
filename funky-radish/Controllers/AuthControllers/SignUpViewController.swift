//
//  SignUpViewController.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 7/3/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import UIKit

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

        do {
            // Check for internet connection
            if !Reachability.isConnectedToNetwork() {
                throw signupError.noConnection
            }

            // TODO: Looks like redundant else statements?

            // validation
            else if (username.count == 0){
                throw signupError.incompleteUsername
            }
            else {
                try Validation().isValidEmail(email)
                try Validation().isValidPW(pw)
            }

            activateLoadingIndicator()

            // Call API
            try APIManager().createUser(
                email: email,
                username: username,
                password: pw,
                onSuccess: {
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
                    print("User creation failed")
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
        print("back to the bottom")
        self.navigationController?.popToRootViewController(animated: false)
    }

    @IBAction func loginSegue(_ sender: Any) {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LogInViewController") as? LogInViewController
        {
            self.navigationController?.pushViewController(vc, animated: false)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpProperties()
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
                // Synch recipes
                DispatchQueue.main.async {
                    //If you've already added recipes, post them to the API
                    JSONSerializer().synchRecipes(recipes: [])
                    self.navigationController?.popToRootViewController(animated: true)
                }
            },
            onFailure: { error in
                print(error)
                self.deactivateLoadingIndicator()
            }
        )
    }
}
