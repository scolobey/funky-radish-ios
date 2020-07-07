//
//  CustomNavigationController.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 7/3/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import os
import Promises

class CustomNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        makeStatusBarInvisible()
        setupCreateButton()
    }

    func makeStatusBarInvisible() {
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        navigationBar.isTranslucent = false
    }

    func setupCreateButton() {
        let button = UIButton(frame: CGRect(origin: CGPoint(x: self.view.frame.width-75, y: self.view.frame.size.height-80), size: CGSize(width: 60, height: 60)))

        button.backgroundColor = UIColor.white

        button.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
        button.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
        button.layer.shadowOpacity = 0.8
        button.layer.shadowRadius = 4.0
        button.layer.masksToBounds = false
        button.layer.cornerRadius = 10.0

        button.setTitleColor(UIColor.black, for: .normal)
        button.titleLabel?.font =  UIFont(name: "rockwell", size: 45)

        if let image = UIImage(named: "add.png") {
            button.setImage(image, for: .normal)
        }

        button.addTarget(self, action: #selector(self.pressButton(_:)), for: .touchUpInside)
        button.tag = 1

        self.view.addSubview(button)
    }

    @objc func pressButton(_ sender: UIButton){
        let alert = UIAlertController(title: "Enter a title for your recipe.", message: nil, preferredStyle: .alert)

        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = "The title goes here..."
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in

            let title = alert.textFields?.first?.text

            do {
                try self.createRecipe(title!)
            }
            catch {
                os_log("Recipe create failed.")
                //TODO:  handle and probably don't set the selected recipe, as we do below.
            }
            
            //TODO: Need to open the correct recipe.
            // Add the recipe to localRecipes and use the right index
            
            os_log("segue to recipe")
            self.performSegue(withIdentifier: "createRecipeSegue", sender: self)
        }))

        self.present(alert, animated: true)
    }

    // Add recipe to Realm
    func createRecipe(_ title: String) throws {
        newRecipe = true
        let recipe = Recipe()
        recipe.title = title
        os_log("Recipe id: %ld", recipe._id!)
        selectedRecipe = recipe._id
        try realmManager.create(recipe)
    }
}



//        return Promise<Data> { (fullfill, reject) in
//            if !Reachability.isConnectedToNetwork() {
//                throw loginError.noConnection
//            }
//
//            try Validation().isValidEmail(email)
//            try Validation().isValidPW(password)
//            try Validation().isValidUsername(username)
//
//            URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {(data, response, error) in
//                if error != nil {
//                    reject(signupError.endpointInaccesible)
//                    return
//                }
//                guard let data = data else {
//                    let error = NSError(domain: "", code: 100, userInfo: nil)
//                    reject(error)
//                    return
//                }
//
//                fullfill(data)
//            }).resume()
//        }
