//
//  CustomNavigationController.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 7/3/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import UIKit
import RealmSwift
import SwiftKeychainWrapper

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

        button.tag = 1
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

                //TODO: Need to open the correct recipe.
                // Add the recipe to localRecipes and us the right index
                self.performSegue(withIdentifier: "createRecipeSegue", sender: self)
            }
            catch {
                print(error)
            }
        }))

        self.present(alert, animated: true)
    }

    // Add recipe to Realm
    func createRecipe(_ title: String) throws {
        do {
            let realm = try Realm()

            let recipe = Recipe()
            newRecipe = true

            recipe.title = title
            selectedRecipe = localRecipes.count
            print(selectedRecipe, "*")

            try! realm.write {
                realm.add(recipe)
            }
        }
        catch {
            print(error)
        }
    }
}

