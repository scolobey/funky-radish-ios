//
//  LogInViewController.swift
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

enum loginError: Error {
    case noConnection
    case tokenFailure
}

class LogInViewController: UIViewController {
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!

    @IBAction func loginButton(_ sender: Any) {
        let email = emailField.text!
        let password = passwordField.text!

        self.view.endEditing(true)
        activateLoadingIndicator()

/*
         Google promises.
         (https://github.com/google/promises)
*/

        login(email: email, password: password)
            .then { self.decodeTokenData(data: $0, email: email, password: password) }
            .then { self.loginRealmUser(token: $0.token) }
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
                    case loginError.tokenFailure:
                        self.navigationController!.showToast(message: "User not found. Sign up or try again.")
                    case RecipeError.invalidLogin:
                        self.navigationController!.showToast(message: "Invalid token. Please log out and log back in.")
                    default:
                        self.navigationController!.showToast(message: "Unidentified error.")
                }
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

//    override var prefersStatusBarHidden: Bool {
//        return true
//    }

    func login(email: String, password: String) -> Promise<Data> {

        UserDefaults.standard.set(false, forKey: "fr_isOffline")

        //        let url = "https://funky-radish-api.herokuapp.com/authenticate"
        let url = "http://localhost:8080/authenticate"

        let request: NSMutableURLRequest = NSMutableURLRequest(url: NSURL(string: url)! as URL)
        request.httpMethod = "POST"
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        let paramString = "email=" + email + "&password=" + password
        request.httpBody = paramString.data(using: String.Encoding.utf8)

        return Promise<Data> { (fullfill, reject) in
            if !Reachability.isConnectedToNetwork() {
                throw loginError.noConnection
            }

            try Validation().isValidEmail(email)
            try Validation().isValidPW(password)

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

    func decodeTokenData(data: Data, email: String, password: String) -> Promise<Token> {
        return Promise<Token> { (fullfill, reject) in
            do {
                let token = try JSONDecoder().decode(Token.self, from: data)

                // TODO: I think this can safely be extracted from if statement.
                if (token.success) {
                    KeychainWrapper.standard.set(email, forKey: "fr_user_email")
                    KeychainWrapper.standard.set(password, forKey: "fr_password")
                    KeychainWrapper.standard.set(token.token, forKey: "fr_token")

                    fullfill(token)
                }
                else {
                    throw loginError.tokenFailure
                }
            }
            catch {
                throw loginError.tokenFailure
            }
        }
    }

    func loginRealmUser(token: String) -> Promise<Void> {
        let auth_url = Constants.AUTH_URL
        let credentials = SyncCredentials.jwt(token)

        return Promise<Void> { (fullfill, reject) in

            os_log("authenticating realm user")
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
