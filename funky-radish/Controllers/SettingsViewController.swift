//
//  SettingsViewController.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 9/4/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import SwiftKeychainWrapper
import os
import Promises

class SettingsViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var settingsList: UITableView!
    var fruser = KeychainWrapper.standard.string(forKey: Constants.EMAIL_KEYCHAIN_STRING)
    var frpw = KeychainWrapper.standard.string(forKey: Constants.PASSWORD_KEYCHAIN_STRING)
    var offline = UserDefaults.standard.bool(forKey: "fr_isOffline")

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSettingsListView(settingsList)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Setup the font
        let fontDescriptor = UIFontDescriptor(name: "Rockwell", size: 18.0)
        let font = UIFont(descriptor: fontDescriptor, size: 18.0)

        // Dequeue a cell
        let cell: UITableViewCell = {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsViewCell") else {
                return UITableViewCell(style: .default, reuseIdentifier: "SettingsViewCell")
            }
            cell.selectionStyle = .none
            return cell
        }()

        if (fruser?.count ?? 0 > 0){
            if (indexPath.row == 0) {
                cell.textLabel?.text = fruser!
                cell.textLabel?.font = font
            }
            else if (indexPath.row == 1) {
                cell.textLabel?.text = "Log Out"
                cell.textLabel?.font = font
            }
        }
        
        else {
            if (indexPath.row == 0) {
                cell.textLabel?.text = "Log In"
                cell.textLabel?.font = font
            }
            else if (indexPath.row == 1) {
                cell.textLabel?.text = "Sign Up!"
                cell.textLabel?.font = font
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        var userState = 0
        
        if (fruser?.count ?? 0 > 0){
            if (indexPath.row == 0) {
                // display user
                userState = 0
            } else if (indexPath.row == 1) {
                // log out
                userState = 3
            }
        }
        else {
            if (indexPath.row == 0) {
                // log in
                userState = 1
            } else if (indexPath.row == 1) {
                // sign up
                userState = 2
            }
        }

        switch userState {
        // Log in.
        case 1:
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LogInViewController") as? LogInViewController {
                self.navigationController?.pushViewController(vc, animated: false)
            }
        // Sign up.
        case 2:
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SignUpViewController") as? SignUpViewController {
                self.navigationController?.pushViewController(vc, animated: false)
            }
        // Log out.
        case 3:
            let alertController = UIAlertController(title: "Fair warning!", message: "Once you log out, any unsaved recipes will be lost forever.", preferredStyle: .alert)

            let approveAction = UIAlertAction(title: "Continue", style: UIAlertAction.Style.default) { UIAlertAction in
                
                realmManager.logout(completion: {
                    KeychainWrapper.standard.set("", forKey: Constants.EMAIL_KEYCHAIN_STRING)
                    KeychainWrapper.standard.set("", forKey: Constants.PASSWORD_KEYCHAIN_STRING)
                    KeychainWrapper.standard.set("", forKey: Constants.TOKEN_KEYCHAIN_STRING)
                                        
                    DispatchQueue.main.async {
                        self.navigationController?.popViewController(animated: true)
                    }
                })
                
                
            }

            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) { UIAlertAction in
                return
            }

            alertController.addAction(approveAction)
            alertController.addAction(cancelAction)

            self.present(alertController, animated: true, completion: nil)
        default:
            os_log("Selected item does not have an associated action.")
        }
    }
}
