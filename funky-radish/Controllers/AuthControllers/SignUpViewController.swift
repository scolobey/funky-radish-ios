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
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!

    @IBAction func signUpButton(_ sender: Any) {
        let email = emailField.text!
        let password = passwordField.text!

        self.view.endEditing(true)
        activateLoadingIndicator()
        
        do {
              try signUp(email: email, password: password)
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
    
    @objc func signUp(email: String, password: String) throws {
        
        if !Reachability.isConnectedToNetwork() {
            throw loginError.noConnection
        }
        
        try Validation().isValidEmail(email)
        try Validation().isValidPW(password)
        
        try ApiManager().registerUser(
            email: email,
            password: password,
            onSuccess: {
            
                DispatchQueue.main.sync {
                    self.deactivateLoadingIndicator()

//                    if let error = err {
//                        self!.navigationController!.showToast(message: "Signup failed: \(error.localizedDescription)")
//                        return;
//                    }

//                    KeychainWrapper.standard.set(email, forKey: Constants.EMAIL_KEYCHAIN_STRING)
//                    //TODO: Can probably ditch the password.
//                    KeychainWrapper.standard.set(password, forKey: Constants.PASSWORD_KEYCHAIN_STRING)
//
//                    realmManager.refresh()
                    
                    let alert = UIAlertController(
                        title: "Check your email!",
                        message: "We sent you a link to verify your account.",
                        preferredStyle: .alert
                    )

                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                        self.navigationController?.popToRootViewController(animated: false)
                    }))

                    self.present(alert, animated: true)
                }
                
                
//                TODO: make these strings into constants.
//                let token = KeychainWrapper.standard.string(forKey: Constants.TOKEN_KEYCHAIN_STRING)
//                let credentials = AppCredentials.init(jwt: token!)
              
//                app.login(withCredential: credentials, completion: { [weak self](user, err) in
//                    DispatchQueue.main.sync {
//                        self!.deactivateLoadingIndicator()
//
//                        if let error = err {
//                            self!.navigationController!.showToast(message: "Signup failed: \(error.localizedDescription)")
//                            return;
//                        }
//
//                        KeychainWrapper.standard.set(email, forKey: Constants.EMAIL_KEYCHAIN_STRING)
//                        //TODO: Can probably ditch the password.
//                        KeychainWrapper.standard.set(password, forKey: Constants.PASSWORD_KEYCHAIN_STRING)
//
//                        realmManager.refresh()
//
//                        print("Signup successful!");
//                        self?.navigationController?.popToRootViewController(animated: false)
//                    }
//                })
            },
            onFailure: { error in
                os_log("failure: %@", error.localizedDescription)
                return
            })
    }
    
    @objc func signIn(email: String, username: String, password: String) {
      
        activateLoadingIndicator()

        app.login(withCredential: AppCredentials(username: email, password: password)) { [weak self](user, error) in

            DispatchQueue.main.sync {
                self!.deactivateLoadingIndicator()
                guard error == nil else {
                    self!.navigationController!.showToast(message: "Login failed: \(error!.localizedDescription)")
                    return
                }
                
                KeychainWrapper.standard.set(email, forKey: Constants.EMAIL_KEYCHAIN_STRING)
                realmManager.refresh()

                self!.navigationController?.popToRootViewController(animated: false)
            }
        };
    }

}
