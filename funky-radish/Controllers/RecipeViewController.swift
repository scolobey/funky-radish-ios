//
//  RecipeViewController.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 7/12/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import UIKit
import RealmSwift

let realm = try! Realm()

class RecipeViewController: BaseViewController {

    var ingredientView: Bool = false
    var ingredientText: String = ""
    var directionText: String = ""

    @IBOutlet weak var recipeTitle: UILabel!
    @IBOutlet weak var recipeInfo: UITextView!
    @IBOutlet weak var contentLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

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
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
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
                try realm.write {
                    realm.delete(localRecipes[selectedRecipe])
                }

                // Delete the recipe from the API if it has an id
                if (deleteId != nil) {
                    print(deleteId!.description)

                    try APIManager().deleteRecipe(id: deleteId!,
                        onSuccess: {
                            print("recipe deleted")
                    },
                        onFailure: { error in
                            print("Delete failed. Adding to queue until API communication is restored.")

                            var delete_queue = UserDefaults.standard.stringArray(forKey: "DeletedQueue") ?? [String]()
                            delete_queue.append(deleteId!)
                            UserDefaults.standard.set(delete_queue, forKey: "DeletedQueue")
                            print(delete_queue)
                    })
                }
                else {
                    print("not in the api")
                }
            }
            catch RecipeError.noInternetConnection {
                print("no internet connection. adding to queue until internet is restored.")
                var delete_queue = UserDefaults.standard.stringArray(forKey: "DeletedQueue") ?? [String]()
                delete_queue.append(deleteId!)
                UserDefaults.standard.set(delete_queue, forKey: "DeletedQueue")
                print(delete_queue)
            }
            catch {
                print("realm error")
            }

            self.navigationController?.popViewController(animated: true)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) { UIAlertAction in
            print("Delete Canceled")
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

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
         recipeFilter = searchText
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        navigationController?.popViewController(animated: true)
    }

    func saveRecipe(title: String, directions: String, ingredients: String) {
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

        do {
            try realm.write {
                localRecipes[selectedRecipe].setValue(title, forKey: "title")
                localRecipes[selectedRecipe].setValue(ingredientRealmList, forKey: "ingredients")
                localRecipes[selectedRecipe].setValue(directionRealmList, forKey: "directions")
                localRecipes[selectedRecipe].setValue(result, forKey: "updatedAt")
            }
        }
        catch {
            print(error)
        }
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
