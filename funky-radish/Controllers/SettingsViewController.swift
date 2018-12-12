//
//  SettingsViewController.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 9/4/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import UIKit
import RealmSwift
import SwiftKeychainWrapper

class SettingsViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var settingsList: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupSettingsListView(settingsList)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(fruser["name"] != nil) {
            return 3
        }
        else {
            return 2
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Dequeue a cell
        let cell: UITableViewCell = {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsViewCell") else {
                return UITableViewCell(style: .default, reuseIdentifier: "SettingsViewCell")
            }
            cell.selectionStyle = .none
            return cell
        }()

        if (indexPath.row == 0) {
            let fontDescriptor = UIFontDescriptor(name: "Rockwell", size: 18.0)
            let font = UIFont(descriptor: fontDescriptor, size: 18.0)

            cell.textLabel?.text = "Log Out"
            cell.textLabel?.font = font
        }

        else if (indexPath.row == 1) {
            let fontDescriptor = UIFontDescriptor(name: "Rockwell", size: 18.0)
            let font = UIFont(descriptor: fontDescriptor, size: 18.0)

            cell.textLabel?.text = "Log in"
            cell.textLabel?.font = font
        }

        else if (indexPath.row == 2) {
            let fontDescriptor = UIFontDescriptor(name: "Rockwell", size: 18.0)
            let font = UIFont(descriptor: fontDescriptor, size: 18.0)

            cell.textLabel?.text = fruser["name"]!
            cell.textLabel?.font = font
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.row == 0) {
            // Remove token key
            KeychainWrapper.standard.set("", forKey: "fr_token")

            // Remove recipes
            let realm = try! Realm()
            
            try! realm.write {
                realm.deleteAll()
            }

            self.navigationController?.popViewController(animated: true)
        }

        else if (indexPath.row == 1) {
            print(indexPath.row)
            // Log in
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LogInViewController") as? LogInViewController
            {
                self.navigationController?.pushViewController(vc, animated: false)
            }

        }


    }

}
