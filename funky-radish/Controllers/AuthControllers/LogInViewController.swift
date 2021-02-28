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
        
        do {
              try login(email: email, password: password)
        }
        catch {
            deactivateLoadingIndicator()
            
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
                case apiError.verificationError:
                    self.navigationController!.showToast(message: "You gotta verify your email first.")
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

    func login(email: String, password: String) throws {
        
        if !Reachability.isConnectedToNetwork() {
            throw loginError.noConnection
        }
        
        try Validation().isValidEmail(email)
        try Validation().isValidPW(password)
        
        os_log("count: %@", app.allUsers().description)
        
        try ApiManager().downloadToken(
                    email: email,
                    password: password,
                    onSuccess: {
                        
        //                TODO: make these strings into constants.
                        let token = KeychainWrapper.standard.string(forKey: Constants.TOKEN_KEYCHAIN_STRING)
                        
                        let credentials = AppCredentials.init(jwt: token!)
                        
                        app.login(withCredential: credentials, completion: { [weak self](user, err) in
                            DispatchQueue.main.sync {
                                self!.deactivateLoadingIndicator()
                            
                                if let error = err {
                                    self!.navigationController!.showToast(message: "Signup failed: \(error.localizedDescription)")
                                    return;
                                }
                                
                                KeychainWrapper.standard.set(email, forKey: Constants.EMAIL_KEYCHAIN_STRING)
                                //TODO: Can probably ditch the password.
                                KeychainWrapper.standard.set(password, forKey: Constants.PASSWORD_KEYCHAIN_STRING)
                                
                                realmManager.refresh()
                                
                                print("Login successful!");
                                self?.navigationController?.popToRootViewController(animated: false)
                            }
                        })
                    },
                    onFailure: { error in
                        DispatchQueue.main.sync {
                            self.deactivateLoadingIndicator()
                            
                            if (error == apiError.userNotFound) {
                                self.navigationController?.showToast(message: "User not found.")
                            }
                            else if (error == apiError.badPassword) {
                                self.navigationController?.showToast(message: "Incorrect password.")
                            }
                            else {
                                self.navigationController?.showToast(message: "Login failed.")
                            }
                        }
                    })
    }
}
