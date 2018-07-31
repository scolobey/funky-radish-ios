//
//  AuthViewController.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 7/3/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import UIKit

class AuthViewController: UIViewController {

    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
