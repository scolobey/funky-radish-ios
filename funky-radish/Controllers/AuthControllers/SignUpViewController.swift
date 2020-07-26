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
        let username = usernameField.text!
        let password = passwordField.text!

        self.view.endEditing(true)
        activateLoadingIndicator()
        
        do {
              try signUp(email: email, username: username, password: password)
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
    
    @objc func signUp(email: String, username: String, password: String) throws {
        
        if !Reachability.isConnectedToNetwork() {
            throw loginError.noConnection
        }
        
        try Validation().isValidEmail(email)
        try Validation().isValidPW(password)
        try Validation().isValidUsername(username)
         
        app.usernamePasswordProviderClient().registerEmail(email, password: password, completion: {[weak self](error) in

            DispatchQueue.main.sync {
                
                //TODO: Wait. Do we really need this? If we just restart it in the next function?
                
                self!.deactivateLoadingIndicator()
                
                guard error == nil else {
                    self!.navigationController!.showToast(message: "Signup failed: \(error!.localizedDescription)")
                    return
                }
                          
                self!.signIn(email: email, username: username, password: password)
            }
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
                
                KeychainWrapper.standard.set(email, forKey: "fr_user_email")
                realmManager.refresh()

                self!.navigationController?.popToRootViewController(animated: false)
            }
        };
    }

}
