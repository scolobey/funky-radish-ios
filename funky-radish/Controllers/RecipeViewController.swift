//
//  RecipeViewController.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 7/12/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import UIKit
import RealmSwift
import os

class RecipeViewController: BaseViewController {

    var ingredientView: Bool = false
    var ingredientText: String = ""
    var directionText: String = ""
    var rec: Recipe? = nil

    @IBOutlet weak var recipeTitle: UILabel!
    @IBOutlet weak var recipeInfo: UITextView!
    @IBOutlet weak var contentLabel: UILabel!

    @IBOutlet weak var contentSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "Recipes", style: UIBarButtonItem.Style.plain, target: self, action: #selector(back))
        self.navigationItem.leftBarButtonItem = newBackButton

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeRight))
        swipeRight.direction = UISwipeGestureRecognizer.Direction.left
        self.view.addGestureRecognizer(swipeRight)

        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeLeft))
        swipeLeft.direction = UISwipeGestureRecognizer.Direction.right
        self.view.addGestureRecognizer(swipeLeft)

        let recipeBoldFontDescriptor = UIFontDescriptor(name: "Rockwell-Bold", size: 18.0)
        let boldRecipeFont = UIFont(descriptor: recipeBoldFontDescriptor, size: 18.0)
        
        rec = localRecipes.filter("_id == %@", selectedRecipe!).first!

        recipeTitle.text = rec!.title
        prepareTextForDisplay(recipe: rec!)

        contentLabel.text = "Directions"

        recipeInfo.text = directionText
        recipeTitle.font = boldRecipeFont

        recipeInfo.layer.masksToBounds = true
        recipeInfo.layer.shadowColor = UIColor.black.cgColor
        recipeInfo.layer.shadowOpacity = 0.5
        recipeInfo.layer.shadowOffset = CGSize(width: 0.5, height: 1)
        recipeInfo.layer.shadowRadius = 2
        recipeInfo.layer.cornerRadius = 10.0

        let recipeFontDescriptor = UIFontDescriptor(name: "Rockwell", size: 18.0)
        let recipeFont = UIFont(descriptor: recipeFontDescriptor, size: 18.0)
        recipeInfo.font = recipeFont

        self.view.applyBackgroundGradient()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }

    override func willMove(toParent parent: UIViewController?) {
        UIApplication.shared.isIdleTimerDisabled = true
    }

    @objc func back(sender: UIBarButtonItem) {
        if ingredientView && ingredientText != recipeInfo.text {
            self.saveRecipe(title: self.rec!.title!, directions: self.directionText, ingredients: self.recipeInfo.text)
            self.navigationController?.popViewController(animated: true)
        }
        else if !ingredientView && directionText != recipeInfo.text {
            self.saveRecipe(title: self.rec!.title!, directions: self.recipeInfo.text, ingredients: self.ingredientText)
            self.navigationController?.popViewController(animated: true)
        }
        else {
            self.navigationController?.popViewController(animated: true)
        }
        UIApplication.shared.isIdleTimerDisabled = false
    }

    @objc func didSwipeRight(gesture: UIGestureRecognizer) {
        if (!ingredientView) {
            if (directionText != recipeInfo.text) {
                saveRecipe(title: self.rec!.title!, directions: recipeInfo.text, ingredients: ingredientText)
            }

            prepareTextForDisplay(recipe: self.rec!)
            ingredientView = true
            recipeInfo.text = ingredientText
            contentLabel.text = "Ingredients"

            contentSwitch.isOn = false
        }
    }

    @objc func didSwipeLeft(gesture: UIGestureRecognizer) {
        if (ingredientView) {
            if (ingredientText != recipeInfo.text) {
                saveRecipe(title: self.rec!.title!, directions: directionText, ingredients: recipeInfo.text)
            }

            prepareTextForDisplay(recipe: self.rec!)
            ingredientView = false
            recipeInfo.text = directionText
            contentLabel.text = "Directions"

            contentSwitch.isOn = true
        }
    }

    @IBAction func deleteRecipeButton(_ sender: Any) {
        // Warn the user these changes are permanent.
        let alertController = UIAlertController(title: "Fair warning!", message: "Once you delete this recipe, it will be lost forever.", preferredStyle: .alert)

        let approveAction = UIAlertAction(title: "Delete", style: UIAlertAction.Style.default) { UIAlertAction in
            for ing in self.rec!.ingredients {
                realmManager.delete(ing)
            }

            for ing in self.rec!.directions {
                realmManager.delete(ing)
            }
            
            realmManager.delete(self.rec!)
            
            self.navigationController?.popViewController(animated: true)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) { UIAlertAction in
            return
        }

        alertController.addAction(approveAction)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true, completion: nil)
    }

    @IBAction func editTitle(_ sender: Any) {
        let alert = UIAlertController(title: "Change your recipe title.", message: nil, preferredStyle: .alert)

        alert.addTextField(configurationHandler: { textField in
            textField.text = self.rec!.title
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { action in
            let title = alert.textFields?.first?.text
            self.saveRecipe(title: title!, directions: self.directionText, ingredients: self.ingredientText)

            if (self.ingredientView) {
                self.saveRecipe(title: title!, directions: self.directionText, ingredients: self.recipeInfo.text)
            }
            else {
                self.saveRecipe(title: self.rec!.title!, directions: self.recipeInfo.text, ingredients: self.ingredientText)
            }

            self.recipeTitle.text = title!
        }))

        self.present(alert, animated: true)
    }

    @IBAction func recipeToggle(_ sender: UISwitch) {
        if (ingredientView) {
            saveRecipe(title: self.rec!.title!, directions: directionText, ingredients: recipeInfo.text)
        }
        else {
            saveRecipe(title: self.rec!.title!, directions: recipeInfo.text, ingredients: ingredientText)
        }
        
        if (sender.isOn == true) {
            prepareTextForDisplay(recipe: self.rec!)
            ingredientView = false
            recipeInfo.text = directionText
            contentLabel.text = "Directions"
        }
        else {
            prepareTextForDisplay(recipe: self.rec!)
            ingredientView = true
            recipeInfo.text = ingredientText
            contentLabel.text = "Ingredients"
        }
    }

    @objc func backButtonAction() {
        os_log("You did tap the back button.")
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        recipeFilter = searchText
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        navigationController?.popViewController(animated: true)
    }

    func saveRecipe(title: String, directions: String, ingredients: String) {
        let user_id = realmManager.partitionValue
        os_log("saving recipe to partition: %@", user_id)
        
        var ingredientArray = [Ingredient()]
        var directionArray = [Direction()]

        // To avoid adding empty ingredients to the Realm.
        if ingredients.trimmingCharacters(in: .whitespaces).isEmpty {
            ingredientArray = []
        }
        else {
            //convert ingredients to Realm list and save
            ingredientArray = ingredients.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\n").map({
                (name: String) -> Ingredient in
                let ingToAdd = Ingredient()
                ingToAdd.author = user_id
                ingToAdd.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                return ingToAdd
            })
        }

        // To avoid adding empty directions to the Realm.
        if directions.trimmingCharacters(in: .whitespaces).isEmpty {
            directionArray = []
        }
        else {
            //convert directions to Realm list and save
            directionArray = directions.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\n").map({
                (text: String) -> Direction in
                let dirToAdd = Direction()
                dirToAdd.author = user_id
                dirToAdd.text = text.trimmingCharacters(in: .whitespaces)
                return dirToAdd
            })
        }

        let ingredientRealmList = List<Ingredient>()
        ingredientRealmList.append(objectsIn: ingredientArray)

        let directionRealmList = List<Direction>()
        directionRealmList.append(objectsIn: directionArray)

        // TODO: There's probably a better way.
        // I'm manually deleting the ingredients and directions to be replaced with the new ones
        // Otherwise, the orphaned realm objects remain in the realm.
        // Also, this editedRec name is lame.
        
        let editedRec = localRecipes.filter("_id == %@", selectedRecipe!).first!
        
        for ing in editedRec.ingredients {
            realmManager.delete(ing)
        }

        for ing in editedRec.directions {
            realmManager.delete(ing)
        }

        realmManager.update(self.rec!, with: [
            "title": title,
            "ingredients": ingredientRealmList,
            "directions": directionRealmList
        ])
    }
    

    func prepareTextForDisplay(recipe: Recipe) {
        let directions = recipe.directions
        let ingredients = recipe.ingredients
        var directionSet: [String] = []
        var ingredientSet: [String] = []

        for direction in directions {
            directionSet.append(direction.text)
        }

        for ingredient in ingredients {
            ingredientSet.append(ingredient.name)
        }

        directionText = directionSet.joined(separator: "\n")
        ingredientText = ingredientSet.joined(separator: "\n")
    }

}
