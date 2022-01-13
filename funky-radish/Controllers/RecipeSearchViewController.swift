//
//  RecipeSearchViewController.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 7/11/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import RealmSwift
import SwiftKeychainWrapper
import Promises
import os

enum AuthError: Error {
    case noEmail
    case noPassword
}

var selectedRecipe: String?
var newRecipe = false

var fruser = KeychainWrapper.standard.string(forKey: Constants.EMAIL_KEYCHAIN_STRING)
var frpw = KeychainWrapper.standard.string(forKey: Constants.PASSWORD_KEYCHAIN_STRING)
var offline = UserDefaults.standard.bool(forKey: "fr_isOffline")

var localRecipes = realmManager.read(Recipe.self)
var notificationToken: NotificationToken?

var otherRecipes = RealmSwift.List<Recipe>()

var recipeFilter = ""

class RecipeSearchViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource{
    
    @IBOutlet weak var recipeList: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
           
        // If recipes load from Realm, reload the table before synch
        if (localRecipes.count > 0) {
            recipeList.reloadData()
        }

        setupRecipeListView(recipeList)
        view.applyBackgroundGradient()
    }

    override func viewWillAppear(_ animated: Bool) {
        os_log("View will appear I guess")
        
        // Let's replace this with a function that just refreshes, but doesn't necesarily update all of the recipes.
        realmManager.refreshLite()
        
        localRecipes = realmManager.read(Recipe.self)
        
        // If you're logged in, check for watched recipes.
        if ((app.currentUser?.isLoggedIn) != nil) {
                        
            let queryFilter: AnyBSON = app.currentUser?.customData["recipes"]! ?? []

            
            do {
                try realmManager.importWatchedRecipes(
                    recipes: queryFilter,
                    onSuccess: { returnedRecipes in
                        DispatchQueue.main.sync {
                            // get the list of recipes and append it to localRecipes.
                            print("mongo recipes: \(returnedRecipes.count)")
                            print("other recipes: \(otherRecipes.count)")
                            
                            otherRecipes = returnedRecipes
                            
                            print("other recipes afterwards: \(otherRecipes.count)")
                            
                            self.recipeList.reloadData()
                        }
                    },
                    onFailure: { error in
                        DispatchQueue.main.sync {
                            self.navigationController?.showToast(message: "Failed to import watched recipes.")
                        }
                    })
            }
            catch {
                print("catch on the watched recipe getter")
            }
        }

        
        if (recipeFilter.count > 0){
            self.setSearchText(recipeFilter)
            self.filterTableView(text: recipeFilter)
        }
        
        recipeList.reloadData()

        notificationToken = realmManager.subscribe(handler: { notification, realm in
            self.recipeList.reloadData()
        })
    }

    override func viewWillDisappear(_ animated: Bool) {
        notificationToken?.invalidate()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        recipeFilter = ""
        self.filterTableView(text: searchText.lowercased())
    }

    func filterTableView(text: String) {
        if (text.count > 0) {
            localRecipes = realmManager.read(Recipe.self).filter("title contains [c] %@", text)
        }
        else {
            localRecipes = realmManager.read(Recipe.self)
            self.searchBar.endEditing(true)
        }

        recipeList.reloadData()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        print("#of sections: \(localRecipes.count + otherRecipes.count )")
        return localRecipes.count + otherRecipes.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section > localRecipes.count-1) {
            return otherRecipes[section-localRecipes.count].ingredients.count + 1
        }
        else {
            return localRecipes[section].ingredients.count + 1
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerCell: UITableViewCell = {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "RecipeListViewHeaderCell") else {
                return UITableViewCell(style: .default, reuseIdentifier: "RecipeListViewHeaderCell")
            }
            return cell
        }()

        headerCell.backgroundColor = UIColor.clear
        return headerCell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 25
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Dequeue a cell
        let cell: UITableViewCell = {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "RecipeListViewCell") else {
                return UITableViewCell(style: .default, reuseIdentifier: "RecipeListViewCell")
            }
            cell.selectionStyle = .none
            return cell
        }()

        // Watched Recipes Listings
        if (indexPath.section > localRecipes.count-1) {
            // Top cell
            if (indexPath.row == 0) {
                let recipeFontDescriptor = UIFontDescriptor(name: "Rockwell", size: 18.0)
                let recipeFont = UIFont(descriptor: recipeFontDescriptor, size: 18.0)

                if(otherRecipes[indexPath.section - localRecipes.count].ingredients.count < 1) {
                    let recipeFontDescriptor = UIFontDescriptor(name: "Rockwell-Bold", size: 18.0)
                    let boldRecipeFont = UIFont(descriptor: recipeFontDescriptor, size: 18.0)

                    cell.textLabel?.text = otherRecipes[indexPath.section - localRecipes.count].title
                    cell.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 10.0)
                    cell.textLabel?.font = boldRecipeFont
                }
                else {
                    cell.textLabel?.text = otherRecipes[indexPath.section - localRecipes.count].ingredients[indexPath.row].name
                    cell.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 0.0)
                    cell.textLabel?.font = recipeFont
                }

                cell.roundCorners(corners: [.topLeft, .topRight], radius: 10.0)
            }

            // Middle cell
            else if (indexPath.row < (otherRecipes[indexPath.section - localRecipes.count].ingredients.count)) {
                let recipeFontDescriptor = UIFontDescriptor(name: "Rockwell", size: 18.0)
                let recipeFont = UIFont(descriptor: recipeFontDescriptor, size: 18.0)

                cell.textLabel?.text = otherRecipes[indexPath.section - localRecipes.count].ingredients[indexPath.row].name
                cell.textLabel?.font = recipeFont

                cell.roundCorners(corners: [.topLeft, .topRight, .bottomLeft, .bottomRight], radius: 0.0)
            }
            
            // Bottom cell
            else {
                let recipeFontDescriptor = UIFontDescriptor(name: "Rockwell-Bold", size: 18.0)
                let boldRecipeFont = UIFont(descriptor: recipeFontDescriptor, size: 18.0)

                cell.textLabel?.text = otherRecipes[indexPath.section - localRecipes.count].title
                cell.textLabel?.font = boldRecipeFont

                cell.roundCorners(corners: [.topLeft, .topRight], radius: 0.0)
                cell.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 10.0)
            }
            
            cell.backgroundColor = UIColor(hexString: "#E1FBFB")
            return cell
        }
        
        // Authored Recipes Listings
        else {
            // Top cell
            if (indexPath.row == 0) {
                let recipeFontDescriptor = UIFontDescriptor(name: "Rockwell", size: 18.0)
                let recipeFont = UIFont(descriptor: recipeFontDescriptor, size: 18.0)

                if(localRecipes[indexPath.section].ingredients.count < 1) {
                    let recipeFontDescriptor = UIFontDescriptor(name: "Rockwell-Bold", size: 18.0)
                    let boldRecipeFont = UIFont(descriptor: recipeFontDescriptor, size: 18.0)

                    cell.textLabel?.text = localRecipes[indexPath.section].title
                    cell.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 10.0)
                    cell.textLabel?.font = boldRecipeFont
                }
                else {
                    cell.textLabel?.text = localRecipes[indexPath.section].ingredients[indexPath.row].name
                    cell.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 0.0)
                    cell.textLabel?.font = recipeFont
                }

                cell.roundCorners(corners: [.topLeft, .topRight], radius: 10.0)
            }

                // Middle cell
            else if (indexPath.row < (localRecipes[indexPath.section].ingredients.count)) {
                let recipeFontDescriptor = UIFontDescriptor(name: "Rockwell", size: 18.0)
                let recipeFont = UIFont(descriptor: recipeFontDescriptor, size: 18.0)

                cell.textLabel?.text = localRecipes[indexPath.section].ingredients[indexPath.row].name
                cell.textLabel?.font = recipeFont

                cell.roundCorners(corners: [.topLeft, .topRight, .bottomLeft, .bottomRight], radius: 0.0)
            }

                // Bottom cell
            else {
                let recipeFontDescriptor = UIFontDescriptor(name: "Rockwell-Bold", size: 18.0)
                let boldRecipeFont = UIFont(descriptor: recipeFontDescriptor, size: 18.0)

                cell.textLabel?.text = localRecipes[indexPath.section].title
                cell.textLabel?.font = boldRecipeFont

                cell.roundCorners(corners: [.topLeft, .topRight], radius: 0.0)
                cell.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 10.0)
            }
            
            cell.backgroundColor = UIColor.white
            return cell
        }

    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedRecipe = ""
        
        if (indexPath.section > localRecipes.count-1) {
            selectedRecipe = otherRecipes[indexPath.section - localRecipes.count]._id
        }
        else {
            selectedRecipe = localRecipes[indexPath.section]._id
        }
        
        self.performSegue(withIdentifier: "recipeSegue", sender: self)
    }
}
