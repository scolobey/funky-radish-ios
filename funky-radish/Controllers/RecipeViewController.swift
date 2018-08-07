//
//  RecipeViewController.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 7/12/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import UIKit
import Realm
import RealmSwift

class RecipeViewController: BaseViewController {

    var ingredientView: Bool = false
    var ingredientText: String = ""
    var directionText: String = ""

    @IBOutlet weak var recipeTitle: UILabel!
    @IBOutlet weak var recipeInfo: UITextView!

    @IBAction func saveRecipeButton(_ sender: Any) {

        if (ingredientView) {
            //convert to Realm list and save
            let ingredientArray = recipeInfo.text.components(separatedBy: "\n").map({
                (name: String) -> Ingredient in
                let ingToAdd = Ingredient()
                ingToAdd.name = name
                return ingToAdd
            })

            let ingredientRealmList = List<Ingredient>()
            ingredientRealmList.append(objectsIn: ingredientArray)

            do {
                try realm.write {
                    localRecipes[selectedRecipe].setValue(ingredientRealmList, forKey: "directions")
                }
            }
            catch {
                print(error)
            }
        }

        else {
            //convert to Realm list and save
            let directionArray = recipeInfo.text.components(separatedBy: "\n").map({
                (text: String) -> Direction in
                let dirToAdd = Direction()
                dirToAdd.text = text
                return dirToAdd
            })

            let directionRealmList = List<Direction>()
            directionRealmList.append(objectsIn: directionArray)

            do {
                try realm.write {
                    localRecipes[selectedRecipe].setValue(directionRealmList, forKey: "directions")
                }
            }
            catch {
                print(error)
            }
        }

    }

    @IBAction func recipeToggle(_ sender: UISwitch) {
        if (sender.isOn == true) {
            ingredientView = false
            recipeInfo.text = directionText
        }
        else {
            ingredientView = true
            recipeInfo.text = ingredientText
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let recipeBoldFontDescriptor = UIFontDescriptor(name: "Rockwell-Bold", size: 18.0)
        let boldRecipeFont = UIFont(descriptor: recipeBoldFontDescriptor, size: 18.0)

        recipeTitle.text = localRecipes[selectedRecipe].title
        recipeTitle.font = boldRecipeFont

        prepareTextForDisplay(recipe: localRecipes[selectedRecipe])

        recipeInfo.text = directionText

        recipeInfo.layer.masksToBounds = false
        recipeInfo.layer.shadowColor = UIColor.black.cgColor
        recipeInfo.layer.shadowOpacity = 0.5
        recipeInfo.layer.shadowOffset = CGSize(width: 0.5, height: 1)
        recipeInfo.layer.shadowRadius = 2
        recipeInfo.layer.cornerRadius = 10.0

        let recipeFontDescriptor = UIFontDescriptor(name: "Rockwell", size: 18.0)
        let recipeFont = UIFont(descriptor: recipeFontDescriptor, size: 18.0)
        recipeInfo.font = recipeFont

        applyBackgroundGradient(self.view)
    }

//    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//        recipeFilter = searchText
//    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.navigationController!.popViewController(animated: true)
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
