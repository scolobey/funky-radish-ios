//
//  RecipeSearchViewController.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 7/11/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import UIKit
import RealmSwift
import SwiftKeychainWrapper

let defaults = UserDefaults.standard

var selectedRecipe = 0
var newRecipe = false
var offline = defaults.bool(forKey: "fr_isOffline")
var fruser = defaults.object(forKey: "SavedDict") as? [String: String] ?? [String: String]()
var localRecipes = realm.objects(Recipe.self)
var recipeFilter = ""

class RecipeSearchViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource{

    @IBOutlet weak var recipeList: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Find your recipes
        do {
            try loadRecipes()
            print("success")
        }
        catch RecipeError.noInternetConnection {
            self.navigationController!.showToast(message: "Unable to synch recipes. No internet connection.")
        }
        catch RecipeError.noToken {
            let alert = UIAlertController(title: "Hello", message: "How would you like to get started?", preferredStyle: .alert)
            let signupAction = UIAlertAction(title: "Sign Up", style: .default) { (alert: UIAlertAction!) -> Void in
                self.performSegue(withIdentifier: "signUpSegue", sender: nil)
            }
            let loginAction = UIAlertAction(title: "Login", style: .default) { (alert: UIAlertAction!) -> Void in
                self.performSegue(withIdentifier: "loginSegue", sender: nil)
            }
            let continueAction = UIAlertAction(title: "Continue Offline", style: .destructive) { (alert: UIAlertAction!) -> Void in

                // Set the app to offline mode.
                UserDefaults.standard.set(false, forKey: "fr_isOffline")
                self.navigationController!.showToast(message: "Offline mode")
            }

            alert.addAction(signupAction)
            alert.addAction(loginAction)
            alert.addAction(continueAction)

            present(alert, animated: true, completion: nil)
        }
        catch {
             self.navigationController!.showToast(message: "Sorry. There was an unidentified error loading your recipes.")
        }

        // Styles
        setupRecipeListView(recipeList)
        applyBackgroundGradient(self.view)

    }

    override func viewWillAppear(_ animated: Bool) {

        if (recipeFilter.count > 0){
            self.setSearchText(recipeFilter)
            self.filterTableView(text: recipeFilter)
        }
        else {
            recipeList.reloadData()
        }
    }

    func loadRecipes() throws {
        // TODO: Probably should have a loading indicator here
        // TODO: Realm recipe needs an id and an archive boolean

        // If recipes load from Realm, reload the table before synch
        if (localRecipes.count > 0) {
            recipeList.reloadData()
        }
        else {
            print("no recipes in Realm")
        }

        if (!offline) {
            // Call the API
            try APIManager().loadRecipes(
            onSuccess: {
                print("recipes loaded")
            },
            onFailure: { error in
                print(error)
            })
        }
        else {
            print("offline mode enabled")
        }
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

        self.filterTableView(text: searchText.lowercased())
    }

    func filterTableView(text: String) {
        if (text.count > 0) {
            localRecipes = realm.objects(Recipe.self).filter("title contains [c] %@", text)
        }
        else {
            localRecipes = realm.objects(Recipe.self)
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
        print(indexPath.section)
        selectedRecipe = indexPath.section
        self.performSegue(withIdentifier: "recipeSegue", sender: self)
    }

}
