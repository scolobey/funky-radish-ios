//
//  SignUpViewController.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 7/3/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import UIKit

class SignUpViewController: UIViewController {

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!

    @IBAction func signUpButton(_ sender: Any) {
        // validate email
        // validate password
        let email = emailField.text!
        let username = usernameField.text!
        let pw = passwordField.text!

        do {
            try APIManager().createUser(
                email: email,
                username: username,
                password: pw,
                onSuccess: {
                    print("user creation succesful.")
                    do {
                        try self.getToken(email: email, pw: pw)
                    }
                    catch RecipeError.invalidLogin {
                        print("those aren't the right credentials")
                    }
                    catch {
                        print("other errors")
                    }
                },
                onFailure: { error in
                    print(error)
                }
            )
        }
        catch {
            print("Looks like an error occurred when you tried to create a user.")
        }
    }
    
    @IBAction func dismissSignUp(_ sender: UIButton) {
        print("back to the bottom")
        self.navigationController?.popToRootViewController(animated: true)
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
                print("looks like you got a token.")

                DispatchQueue.main.async {
                    self.navigationController?.popViewController(animated: true)
                }
            },
            onFailure: { error in
                    print(error)
            }
        )
    }
}
