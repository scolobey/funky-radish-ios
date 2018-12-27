//
//  LogInViewController.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 7/3/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

enum loginError: Error {
    case incompleteUsername
    case noConnection
}

class LogInViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!

    @IBAction func loginButton(_ sender: Any) {
        let email = emailField.text!
        let pw = passwordField.text!

        self.view.endEditing(true)

        do {
            if !Reachability.isConnectedToNetwork() {
                throw loginError.noConnection
            }

            else {
                try Validation().isValidEmail(email)
                try Validation().isValidPW(pw)
            }

            activateLoadingIndicator()

            try getToken(email: email, pw: pw)
        }
        catch loginError.noConnection {
            self.navigationController!.showToast(message: "No internet connection.")
        }
        catch validationError.invalidEmail {
            self.navigationController!.showToast(message: "Invalid email.")
        }
        catch validationError.invalidPassword {
            // TODO: Should guide the user on password requirements.
            self.navigationController!.showToast(message: "Invalid password.")
        }
        catch RecipeError.invalidLogin {
            print("those aren't the right credentials")
        }
        catch {
            print("Unknown login error")
        }
    }

    @IBAction func dismissLoginButton(_ sender: UIButton) {
        self.navigationController?.popToRootViewController(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpProperties()
    }

    @IBAction func signupSegue(_ sender: Any) {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SignUpViewController") as? SignUpViewController
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

                DispatchQueue.main.async {
                    try! API.loadRecipes(
                        onSuccess: {
                            print("recipes loaded.")
                        },
                        onFailure: { error in
                            print("recipe load failed")
                        }
                    )

                    self.deactivateLoadingIndicator()
                    self.navigationController?.popToRootViewController(animated: false)
                }
            },
            onFailure: { error in
                DispatchQueue.main.async {
                    self.deactivateLoadingIndicator()
                    self.navigationController!.showToast(message: "Incorrect email or password.")
                }
            }
        )
    }
}
