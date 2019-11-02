//
//  SettingsViewController.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 9/4/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import SwiftKeychainWrapper
import os

class SettingsViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var settingsList: UITableView!

    var fruser = KeychainWrapper.standard.string(forKey: "fr_user_email")
    var frpw = KeychainWrapper.standard.string(forKey: "fr_password")
    var offline = UserDefaults.standard.bool(forKey: "fr_isOffline")

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSettingsListView(settingsList)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (!Reachability.isConnectedToNetwork() || (offline && fruser?.count ?? 0 > 0)){
            return 1
        }

        else {
            return 3
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

        if (!Reachability.isConnectedToNetwork()){
            os_log("no network connection.")
            if (indexPath.row == 0) {
                let fontDescriptor = UIFontDescriptor(name: "Rockwell", size: 18.0)
                let font = UIFont(descriptor: fontDescriptor, size: 18.0)

                cell.textLabel?.text = "No Wifi Detected"
                cell.textLabel?.font = font
            }
        }

        else if (offline && (fruser?.count == 0 || fruser == nil)) {
            os_log("Offline. No user.")
            if (indexPath.row == 0) {
                let fontDescriptor = UIFontDescriptor(name: "Rockwell", size: 18.0)
                let font = UIFont(descriptor: fontDescriptor, size: 18.0)

                cell.textLabel?.text = "Log In"
                cell.textLabel?.font = font
            }

            else if (indexPath.row == 1) {
                let fontDescriptor = UIFontDescriptor(name: "Rockwell", size: 18.0)
                let font = UIFont(descriptor: fontDescriptor, size: 18.0)

                cell.textLabel?.text = "Sign Up!"
                cell.textLabel?.font = font
            }

            else if (indexPath.row == 2) {
                let fontDescriptor = UIFontDescriptor(name: "Rockwell", size: 18.0)
                let font = UIFont(descriptor: fontDescriptor, size: 18.0)

                cell.textLabel?.text = "Currently Offline"
                cell.textLabel?.font = font
            }
        }

        else if (offline && fruser?.count ?? 0 > 0) {
            os_log("Offline. Yes user.")
            if (indexPath.row == 0) {
                let fontDescriptor = UIFontDescriptor(name: "Rockwell", size: 18.0)
                let font = UIFont(descriptor: fontDescriptor, size: 18.0)

                cell.textLabel?.text = "Toggle Online"
                cell.textLabel?.font = font
            }
        }

        else if (!offline && fruser?.count ?? 0 > 0){
            os_log("Online. Yes user.")
            if (indexPath.row == 0) {
                let fontDescriptor = UIFontDescriptor(name: "Rockwell", size: 18.0)
                let font = UIFont(descriptor: fontDescriptor, size: 18.0)

                cell.textLabel?.text = "Log Out"
                cell.textLabel?.font = font
            }

            else if (indexPath.row == 1) {
                let fontDescriptor = UIFontDescriptor(name: "Rockwell", size: 18.0)
                let font = UIFont(descriptor: fontDescriptor, size: 18.0)

                cell.textLabel?.text = fruser!
                cell.textLabel?.font = font
            }

            else if (indexPath.row == 2) {
                let fontDescriptor = UIFontDescriptor(name: "Rockwell", size: 18.0)
                let font = UIFont(descriptor: fontDescriptor, size: 18.0)

                cell.textLabel?.text = "Toggle Offline"
                cell.textLabel?.font = font
            }
        }

        else if (!offline && (fruser == nil || fruser?.count == 0)){
            os_log("Online. No user.")
            if (indexPath.row == 0) {
                let fontDescriptor = UIFontDescriptor(name: "Rockwell", size: 18.0)
                let font = UIFont(descriptor: fontDescriptor, size: 18.0)

                cell.textLabel?.text = "Log in"
                cell.textLabel?.font = font
            }

            else if (indexPath.row == 1) {
                let fontDescriptor = UIFontDescriptor(name: "Rockwell", size: 18.0)
                let font = UIFont(descriptor: fontDescriptor, size: 18.0)

                cell.textLabel?.text = "Sign Up!"
                cell.textLabel?.font = font
            }

            else if (indexPath.row == 2) {
                let fontDescriptor = UIFontDescriptor(name: "Rockwell", size: 18.0)
                let font = UIFont(descriptor: fontDescriptor, size: 18.0)

                cell.textLabel?.text = "Toggle Offline"
                cell.textLabel?.font = font
            }
        }

//        //TODO: remove this else
//        else {
//            let fontDescriptor = UIFontDescriptor(name: "Rockwell", size: 18.0)
//            let font = UIFont(descriptor: fontDescriptor, size: 18.0)
//
//            cell.textLabel?.text = "settings malfunction!"
//            cell.textLabel?.font = font
//        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        var userState = 0

        if (!Reachability.isConnectedToNetwork()){
            if (indexPath.row == 0) {
                // no wifi
                userState = 0
            }
        } else if (offline && (fruser?.count == 0 || fruser == nil)) {
            if (indexPath.row == 0) {
                // log in
                userState = 1
            } else if (indexPath.row == 1) {
                // sign up
                userState = 2
            } else if (indexPath.row == 2) {
                // no action
                userState = 0
            }
        } else if (offline && fruser?.count ?? 0 > 0) {
            if (indexPath.row == 0) {
                // toggle online
                userState = 4
            }
        } else if (!offline && fruser?.count ?? 0 > 0){
            if (indexPath.row == 0) {
                // log out
                userState = 3
            } else if (indexPath.row == 1) {
                // display user
                userState = 0
            } else if (indexPath.row == 2) {
                // toggle offline
                userState = 5
            }
        } else if (!offline && (fruser?.count == 0 || fruser == nil)) {
            if (indexPath.row == 0) {
                // log out
                userState = 1
            } else if (indexPath.row == 1) {
                // sign up
                userState = 2
            } else if (indexPath.row == 2) {
                // toffle offline
                userState = 5
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
                // Remove user data
                KeychainWrapper.standard.set("", forKey: "fr_token")
                KeychainWrapper.standard.set("", forKey: "fr_user_email")
                KeychainWrapper.standard.set("", forKey: "fr_password")

                UserDefaults.standard.set(true, forKey: "fr_isOffline")

                realmManager.logout()

                self.navigationController?.popViewController(animated: true)
            }

            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) { UIAlertAction in
                return
            }

            alertController.addAction(approveAction)
            alertController.addAction(cancelAction)

            self.present(alertController, animated: true, completion: nil)
        // Toggle online.
        case 4:
            UserDefaults.standard.set(false, forKey: "fr_isOffline")
            self.navigationController?.popViewController(animated: true)
        // Toggle offline.
        case 5:
            UserDefaults.standard.set(true, forKey: "fr_isOffline")
            self.navigationController?.popViewController(animated: true)
        default:
            os_log("Selected item does not have an associated action.")
        }
    }
}
