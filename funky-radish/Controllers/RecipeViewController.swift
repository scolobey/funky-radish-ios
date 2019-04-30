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

    let realmManager = RealmManager()

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

        recipeTitle.text = localRecipes[selectedRecipe].title
        prepareTextForDisplay(recipe: localRecipes[selectedRecipe])

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
        UIApplication.shared.isIdleTimerDisabled = true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }

    @objc func back(sender: UIBarButtonItem) {
        if ingredientView && ingredientText != recipeInfo.text {
            let alert = UIAlertController(title: "Save ingredients?", message: "Would you like to save changes to your ingredients before continuing?", preferredStyle: .alert)

            let continueAction = UIAlertAction(title: "Yes", style: .default) { (alert: UIAlertAction!) -> Void in
                self.saveRecipe(title: localRecipes[selectedRecipe].title!, directions: self.directionText, ingredients: self.recipeInfo.text)
                self.navigationController?.popViewController(animated: true)
            }

            let cancelAction = UIAlertAction(title: "No", style: .default) { (alert: UIAlertAction!) -> Void in
                self.navigationController?.popViewController(animated: true)
            }

            alert.addAction(continueAction)
            alert.addAction(cancelAction)
            self.present(alert, animated: true)
        }
        else if !ingredientView && directionText != recipeInfo.text {
            let alert = UIAlertController(title: "Save directions?", message: "Would you like to save changes to your directions before continuing?", preferredStyle: .alert)

            let continueAction = UIAlertAction(title: "Yes", style: .default) { (alert: UIAlertAction!) -> Void in
                self.saveRecipe(title: localRecipes[selectedRecipe].title!, directions: self.recipeInfo.text, ingredients: self.ingredientText)
                self.navigationController?.popViewController(animated: true)
            }

            let cancelAction = UIAlertAction(title: "No", style: .default) { (alert: UIAlertAction!) -> Void in
                self.navigationController?.popViewController(animated: true)
            }

            alert.addAction(continueAction)
            alert.addAction(cancelAction)
            self.present(alert, animated: true)
        }
        else {
            self.navigationController?.popViewController(animated: true)
        }
    }

    @objc func didSwipeRight(gesture: UIGestureRecognizer) {
        if (!ingredientView) {
            if (directionText != recipeInfo.text) {
                saveRecipe(title: localRecipes[selectedRecipe].title!, directions: recipeInfo.text, ingredients: ingredientText)
            }

            prepareTextForDisplay(recipe: localRecipes[selectedRecipe])
            ingredientView = true
            recipeInfo.text = ingredientText
            contentLabel.text = "Ingredients"

            contentSwitch.isOn = false
        }
    }

    @objc func didSwipeLeft(gesture: UIGestureRecognizer) {
        if (ingredientView) {
            if (ingredientText != recipeInfo.text) {
                saveRecipe(title: localRecipes[selectedRecipe].title!, directions: directionText, ingredients: recipeInfo.text)
            }

            prepareTextForDisplay(recipe: localRecipes[selectedRecipe])
            ingredientView = false
            recipeInfo.text = directionText
            contentLabel.text = "Directions"

            contentSwitch.isOn = true
        }
    }

    @IBAction func saveRecipeButton(_ sender: Any) {
        if (ingredientView) {
            saveRecipe(title: localRecipes[selectedRecipe].title!, directions: directionText, ingredients: recipeInfo.text)
        }
        else {
            saveRecipe(title: localRecipes[selectedRecipe].title!, directions: recipeInfo.text, ingredients: ingredientText)
        }
    }

    @IBAction func deleteRecipeButton(_ sender: Any) {
        let deleteId = localRecipes[selectedRecipe]._id

        // Warn the user these changes are permanent.
        let alertController = UIAlertController(title: "Fair warning!", message: "Once you delete this recipe, it will be lost forever.", preferredStyle: .alert)

        let approveAction = UIAlertAction(title: "Delete", style: UIAlertAction.Style.default) { UIAlertAction in
            do {
                self.realmManager.delete(localRecipes[selectedRecipe])

                // Delete the recipe from the API if it has an id
                if (deleteId != nil) {
                    try APIManager().deleteRecipe(id: deleteId!,
                                                  onSuccess: {
                                                    os_log("Recipe deleted.")
                    },
                                                  onFailure: { error in
                                                    os_log("Delete failed.")
                                                    var delete_queue = UserDefaults.standard.stringArray(forKey: "DeletedQueue") ?? [String]()
                                                    delete_queue.append(deleteId!)
                                                    UserDefaults.standard.set(delete_queue, forKey: "DeletedQueue")
                    })
                }
                else {
                    os_log("This recipe is not in the API.")
                }
            }
            catch RecipeError.noInternetConnection {
                os_log("no internet connection. adding to queue until internet is restored.")
                var delete_queue = UserDefaults.standard.stringArray(forKey: "DeletedQueue") ?? [String]()
                delete_queue.append(deleteId!)
                UserDefaults.standard.set(delete_queue, forKey: "DeletedQueue")
            }
            catch {
                os_log("Probably a Realm error.")
            }

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
            textField.text = localRecipes[selectedRecipe].title
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { action in
            let title = alert.textFields?.first?.text
            self.saveRecipe(title: title!, directions: self.directionText, ingredients: self.ingredientText)
            self.recipeTitle.text = title!
        }))

        self.present(alert, animated: true)
    }

    @IBAction func recipeToggle(_ sender: UISwitch) {
        if (ingredientView) {
            saveRecipe(title: localRecipes[selectedRecipe].title!, directions: directionText, ingredients: recipeInfo.text)
        }
        else {
            saveRecipe(title: localRecipes[selectedRecipe].title!, directions: recipeInfo.text, ingredients: ingredientText)
        }
        
        if (sender.isOn == true) {
            prepareTextForDisplay(recipe: localRecipes[selectedRecipe])
            ingredientView = false
            recipeInfo.text = directionText
            contentLabel.text = "Directions"
        }
        else {
            prepareTextForDisplay(recipe: localRecipes[selectedRecipe])
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

        /* To resolve a bug where, when editing the recipe info field,
         then saving, then changing the recipe title, the recipe info field
         is returned to the previous state. */
        if (ingredientView) {
            ingredientText = recipeInfo.text
        }
        else {
            directionText = recipeInfo.text
        }

        let date = Date()
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "UTC")

        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        let result = formatter.string(from: date)

        //convert ingredients to Realm list and save
        let ingredientArray = ingredients.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\n").map({
            (name: String) -> Ingredient in
            let ingToAdd = Ingredient()
            ingToAdd.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            return ingToAdd
        })
        let ingredientRealmList = List<Ingredient>()
        ingredientRealmList.append(objectsIn: ingredientArray)

        //convert directions to Realm list and save
        let directionArray = directions.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\n").map({
            (text: String) -> Direction in
            let dirToAdd = Direction()
            dirToAdd.text = text.trimmingCharacters(in: .whitespaces)
            return dirToAdd
        })
        let directionRealmList = List<Direction>()
        directionRealmList.append(objectsIn: directionArray)

        realmManager.update(localRecipes[selectedRecipe], with: [
            "title": title,
            "ingredients": ingredientRealmList,
            "directions": directionRealmList,
            "updatedAt": result
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
