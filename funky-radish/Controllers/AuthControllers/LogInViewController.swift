//
//  LogInViewController.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 7/3/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import UIKit

class LogInViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!

    @IBAction func loginButton(_ sender: Any) {
        // validate email
        // validate password
        let email = emailField.text!
        let pw = passwordField.text!

        //  Get an authorization token and handle possible errors.
        do {
            try getToken(email: email, pw: pw)
        }
        catch RecipeError.invalidLogin {
            print("those aren't the right credentials")
        }
        catch {
            print("other errors")
        }

        // if token is valid, pop the view.
        // else display an error
    }

    @IBAction func dismissLoginButton(_ sender: UIButton) {
        dismiss(animated: true)
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

        // Should we load from API?
        let API = APIManager()

        try API.getToken(email: email, password: pw, onSuccess: {
            print("looks like you got a token.")

            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: true)
            }
        },
                         onFailure: { error in
                                print(error)
        })
    }
}
