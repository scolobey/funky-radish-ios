//
//  LogInViewController.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 7/3/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import UIKit

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

        //  Get an authorization token and handle possible errors.
        do {
            if !Reachability.isConnectedToNetwork() {
                throw loginError.noConnection
            }

            // validation
            else {
                try Validation().isValidEmail(email)
                try Validation().isValidPW(pw)
            }

            navigationController?.activateLoadingIndicator()

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

        // TODO if token is valid, pop the view.
        // else display an error

    }

    @IBAction func dismissLoginButton(_ sender: UIButton) {
        print("back to the bottom")
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

    func setUpProperties() {
        navigationController?.navigationBar.layer.frame.origin.y = 20
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    func getToken(email: String, pw: String) throws {

        // Should we load from API?
        let API = APIManager()

        try API.getToken(email: email, password: pw,
            onSuccess: {
                DispatchQueue.main.async {
                    JSONSerializer().synchRecipes(recipes: [])
                    self.navigationController?.popToRootViewController(animated: false)
                }
            },
            onFailure: { error in
                print(error)
            }
        )
    }
}
