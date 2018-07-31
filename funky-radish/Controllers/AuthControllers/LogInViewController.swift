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
        getToken()
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

    func getToken() {

        APIManager.sharedInstance.getToken(email: emailField.text!, password: passwordField.text!, onSuccess: {
            DispatchQueue.main.async {
                print("token should be loaded")
            }
        }, onFailure: { error in
            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
            self.show(alert, sender: nil)
        })

    }

}
