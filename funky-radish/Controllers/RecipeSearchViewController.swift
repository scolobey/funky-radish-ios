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

var recipeFilter = ""

class RecipeSearchViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource{
    
    @IBOutlet weak var recipeList: UITableView!

    override func viewDidLoad() {
        os_log("view did load")
        
        super.viewDidLoad()
           
        // If recipes load from Realm, reload the table before synch
        if (localRecipes.count > 0) {
            recipeList.reloadData()
        }

        setupRecipeListView(recipeList)
        view.applyBackgroundGradient()
    }

    override func viewWillAppear(_ animated: Bool) {
        os_log("view will appear. loading localRecipes")
        realmManager.refresh()
        localRecipes = realmManager.read(Recipe.self)

        if (recipeFilter.count > 0){
            os_log("filtering")
            self.setSearchText(recipeFilter)
            self.filterTableView(text: recipeFilter)
        }
//        else {
//            recipeList.reloadData()
//        }
        
        recipeList.reloadData()

        os_log("setting up notifications")
        notificationToken = realmManager.subscribe(handler: { notification, realm in
            
            os_log("reloading data")
            
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
             os_log("Filtering localRecipes")
            localRecipes = realmManager.read(Recipe.self).filter("title contains [c] %@", text)
        }
        else {
            os_log("Filtering localRecipes without recipes")
            localRecipes = realmManager.read(Recipe.self)
            self.searchBar.endEditing(true)
        }

        recipeList.reloadData()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return localRecipes.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return localRecipes[section].ingredients.count + 1
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
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedRecipe = localRecipes[indexPath.section]._id
        self.performSegue(withIdentifier: "recipeSegue", sender: self)
    }
}
