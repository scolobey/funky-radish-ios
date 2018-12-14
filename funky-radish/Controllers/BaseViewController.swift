//
//  BaseViewController.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 7/14/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import UIKit

var settingsOpen = false

class BaseViewController: UIViewController, UISearchBarDelegate{

    let searchBar:UISearchBar = UISearchBar()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
    }

    func setupNavBar() {
        searchBar.delegate = self
        searchBar.placeholder = "Search Recipes"
        navigationItem.titleView = searchBar

        var image = UIImage(named: "menu.png")
        image = scaleImage(image: image!, newWidth: 30.0)

        let button = UIButton()
        button.setBackgroundImage(image, for: UIControlState.normal)
        button.frame = CGRect(x: 0.0, y: 0.0, width: 10.0, height: 10.0)
        button.addTarget(self, action: #selector(toggleSettings), for: .touchDown)

        let userButton = UIBarButtonItem()
        userButton.customView = button

        navigationItem.setRightBarButton(userButton, animated: false)
    }

    func setSearchText(_ filterText: String) {
        searchBar.text = filterText
    }

    @objc func toggleSettings() {
        if (settingsOpen) {
            settingsOpen = false
            self.navigationController?.popViewController(animated: false)
        }
        else {
            settingsOpen = true
            self.navigationController?.performSegue(withIdentifier: "settingsSegue", sender: nil)
        }
    }
}
