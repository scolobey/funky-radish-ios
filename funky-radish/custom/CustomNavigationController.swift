//
//  CustomNavigationController.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 7/3/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import UIKit

class CustomNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        makeStatusBarInvisible()
    }

    func makeStatusBarInvisible() {
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        navigationBar.isTranslucent = false
    }
}
