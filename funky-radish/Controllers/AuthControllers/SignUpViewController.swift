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
        if (emailField.text?.isEmpty)! {
            print(emailField.text!)
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

}
