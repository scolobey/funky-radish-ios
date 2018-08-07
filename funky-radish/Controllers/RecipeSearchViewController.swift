//
//  RecipeSearchViewController.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 7/11/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import UIKit
import RealmSwift

let realm = RealmService.shared.realm

var selectedRecipe = 0

var localRecipes = realm.objects(Recipe.self)

class RecipeSearchViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource{

    final let url = URL(string: "https://funky-radish-api.herokuapp.com/")

    @IBOutlet weak var recipeList: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        //  Find your recipes
        loadRecipes()

        //  Style 'em out
        setupRecipeListView(recipeList)
        applyBackgroundGradient(self.view)
    }

//    override func viewWillAppear(_ animated: Bool) {
//        if (recipeFilter.count > 0){
//            self.filterTableView(text: recipeFilter)
//        }
//    }

    func loadRecipes() {
        // Check Realm for recipes
        // else check for a token and download
        // reconcile Realm db with json result

        // todo: Realm recipe needs an id and an archive boolean
        // How do we decide if a recipe has been deleted?

        if (localRecipes.count > 0) {
            recipeList.reloadData()
        }
        else {
            downloadRecipes()
        }
    }

    func downloadRecipes() {
        guard let downloadURL = url else {return}

        URLSession.shared.dataTask(with: downloadURL, completionHandler: {(data, response, error) in
            guard let data = data, error == nil, response != nil else {print(error!); return}

            let serializer = JSONSerializer()
            serializer.serialize(input: data)

            DispatchQueue.main.async {
                self.recipeList.reloadData()
            }
        }).resume()
    }

//    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//        self.filterTableView(text: searchText)
//    }

//    func filterTableView(text: String) {
//        if (text.count > 0) {
//            recipesRefined = recipes.filter({(recipe) -> Bool in
//                return recipe.title.contains(text)
//            })
//        }
//        else {
//            recipesRefined = recipes
//        }
//        recipeList.reloadData()
//    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return localRecipes.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("rows: " + localRecipes[section].ingredients.count.description)
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
            print(localRecipes[indexPath.section].ingredients[indexPath.row])
            let recipeFontDescriptor = UIFontDescriptor(name: "Rockwell", size: 18.0)
            let recipeFont = UIFont(descriptor: recipeFontDescriptor, size: 18.0)

            cell.textLabel?.text = localRecipes[indexPath.section].ingredients[indexPath.row].name
            cell.textLabel?.font = recipeFont

            cell.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 0.0)
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
        selectedRecipe = indexPath.section
        self.performSegue(withIdentifier: "recipeSegue", sender: self)
    }

}
