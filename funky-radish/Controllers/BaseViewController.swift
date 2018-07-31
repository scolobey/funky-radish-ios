//
//  BaseViewController.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 7/14/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController, UISearchBarDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
    }

    func setupNavBar() {
        let searchController = UISearchController(searchResultsController: nil)
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.searchController?.searchBar.delegate = self
    }

}
