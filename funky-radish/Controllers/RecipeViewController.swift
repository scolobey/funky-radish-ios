//
//  RecipeViewController.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 7/12/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import UIKit

class RecipeViewController: BaseViewController {

    @IBOutlet weak var recipeTitle: UILabel!
    @IBOutlet weak var recipeInfo: UITextView!
    
    @IBAction func recipeToggle(_ sender: UISwitch) {
        if (sender.isOn == true) {
            recipeInfo.text = localRecipes[selectedRecipe].directions[0].text
        }
        else {
            recipeInfo.text = localRecipes[selectedRecipe].ingredients[0].name
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let recipeBoldFontDescriptor = UIFontDescriptor(name: "Rockwell-Bold", size: 18.0)
        let boldRecipeFont = UIFont(descriptor: recipeBoldFontDescriptor, size: 18.0)

        recipeTitle.text = localRecipes[selectedRecipe].title
        recipeTitle.font = boldRecipeFont

        recipeInfo.text = localRecipes[selectedRecipe].directions[0].text
        recipeInfo.layer.masksToBounds = false
        recipeInfo.layer.shadowColor = UIColor.black.cgColor
        recipeInfo.layer.shadowOpacity = 0.5
        recipeInfo.layer.shadowOffset = CGSize(width: 0.5, height: 1)
        recipeInfo.layer.shadowRadius = 2
        recipeInfo.layer.cornerRadius = 10.0

        let recipeFontDescriptor = UIFontDescriptor(name: "Rockwell", size: 18.0)
        let recipeFont = UIFont(descriptor: recipeFontDescriptor, size: 18.0)
        recipeInfo.font = recipeFont

        applyBackgroundGradient(view: self.view)
    }

//    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//        recipeFilter = searchText
//    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.navigationController!.popViewController(animated: true)
    }

}
