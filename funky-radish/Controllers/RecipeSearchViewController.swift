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

enum AuthError: Error {
    case noEmail
    case noPassword
}

var selectedRecipe = 0
var newRecipe = false

var fruser = KeychainWrapper.standard.string(forKey: "fr_user_email")
var frpw = KeychainWrapper.standard.string(forKey: "fr_password")
var offline = UserDefaults.standard.bool(forKey: "fr_isOffline")

var localRecipes = realm.objects(Recipe.self)
var notificationToken: NotificationToken?

var recipeFilter = ""

class RecipeSearchViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource{

    @IBOutlet weak var recipeList: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Data
        do {
//          activateLoadingIndicator()
            try loadRecipes()
        }
        catch RecipeError.noInternetConnection {
            deactivateLoadingIndicator()
            self.navigationController!.showToast(message: "Unable to synch recipes. No internet connection.")
        }
        catch RecipeError.noToken {
            deactivateLoadingIndicator()

            let alert = UIAlertController(title: "Hello", message: "How would you like to get started?", preferredStyle: .alert)

            let signupAction = UIAlertAction(title: "Sign Up", style: .default) { (alert: UIAlertAction!) -> Void in
                if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SignUpViewController") as? SignUpViewController {
                    self.navigationController?.pushViewController(vc, animated: false)
                }

            }
            let loginAction = UIAlertAction(title: "Login", style: .default) { (alert: UIAlertAction!) -> Void in

                if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LogInViewController") as? LogInViewController {
                    self.navigationController?.pushViewController(vc, animated: false)
                }

            }
            let continueAction = UIAlertAction(title: "Continue Offline", style: .destructive) { (alert: UIAlertAction!) -> Void in
                // Set the app to offline mode.
                UserDefaults.standard.set(true, forKey: "fr_isOffline")
                self.navigationController!.showToast(message: "Offline mode")
            }

            alert.addAction(signupAction)
            alert.addAction(loginAction)
            alert.addAction(continueAction)

            present(alert, animated: true, completion: nil)
        }
        catch serializerError.failedSerialization {
            deactivateLoadingIndicator()
            do {
                // check if there's an email and password saved in UserDefaults
                guard let retrievedEmail: String = KeychainWrapper.standard.string(forKey: "fr_user_email") else {
                    throw AuthError.noEmail
                }

                guard let retrievedPassword: String = KeychainWrapper.standard.string(forKey: "fr_password") else {
                    throw AuthError.noPassword
                }

                if(retrievedEmail.count > 0 && retrievedPassword.count > 0) {
                    let API = APIManager()

                    try API.getToken(
                        email: retrievedEmail,
                        password: retrievedPassword,
                        onSuccess: {

                            UserDefaults.standard.set(false, forKey: "fr_isOffline")

                            // Synch recipes
                            DispatchQueue.main.async {
                                //If you've already added recipes, post them to the API
                                if (localRecipes.count > 0) {
                                    do {
                                        try APIManager().bulkInsertRecipes(
                                            recipes: Array(localRecipes),
                                            onSuccess: {
                                                DispatchQueue.main.async {
                                                    self.deactivateLoadingIndicator()
                                                }
                                            },
                                            onFailure: { error in
                                                print("Error: " + error.localizedDescription)
                                            })
                                        }
                                    catch {
                                        print("Error inserting recipes")
                                        self.deactivateLoadingIndicator()
                                    }
                                } else {
                                    self.deactivateLoadingIndicator()
                                }
                            }
                        },
                        onFailure: { error in
                            self.deactivateLoadingIndicator()
                            self.recipeList.reloadData()
                        }
                    )


                } else {
                    // if there are no user credentials, toast and transition to log in instead.
                    self.navigationController!.showToast(message: "Token not valid.")

                    if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LogInViewController") as? LogInViewController {
                        self.navigationController?.pushViewController(vc, animated: false)
                    }
                }
            }
            catch {

            }
        }
        catch {
            deactivateLoadingIndicator()
            self.navigationController!.showToast(message: "Sorry. There was an unidentified error loading your recipes.")
        }

        // Styles
        setupRecipeListView(recipeList)
        self.view.applyBackgroundGradient()
    }

    override func viewWillAppear(_ animated: Bool) {
        do {
            try loadRecipes()
        }
        catch RecipeError.noInternetConnection {
            print("No internet connection.")
        }
        catch RecipeError.noToken {
            print("No token")
        }
        catch {
            print("There was an unidentified error loading recipes.")
        }

        if (recipeFilter.count > 0){
            self.setSearchText(recipeFilter)
            self.filterTableView(text: recipeFilter)
        }
        else {
            recipeList.reloadData()
        }

        notificationToken = realm.observe { notification, realm in
            self.recipeList.reloadData()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        notificationToken?.invalidate()
    }

    func loadRecipes() throws {

        for x in localRecipes {
            print(x.title! + "--" + x._id!)
        }

        // If recipes load from Realm, reload the table before synch
        if (localRecipes.count > 0) {
            recipeList.reloadData()
        }
        else {
            print("no recipes in Realm")
        }

        if (!offline) {
            print(!offline)
            print("what's goin on here?")
            // Call the API
            try APIManager().loadRecipes(
                onSuccess: {
                    print("recipes loaded")
                },
                onFailure: { error in
                    print(error)
                }
            )
        }
        else {
            print("offline mode enabled")
        }

        print("load recipes called")
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        recipeFilter = ""
        self.filterTableView(text: searchText.lowercased())
    }

    func filterTableView(text: String) {
        if (text.count > 0) {
            localRecipes = realm.objects(Recipe.self).filter("title contains [c] %@", text)
        }
        else {
            localRecipes = realm.objects(Recipe.self)
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
        print(indexPath.section)
        selectedRecipe = indexPath.section
        self.performSegue(withIdentifier: "recipeSegue", sender: self)
    }

}
