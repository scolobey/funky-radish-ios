//
//  SettingsViewController.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 9/4/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import SwiftKeychainWrapper
import os
import CoreBluetooth
import Promises

class SettingsViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var settingsList: UITableView!
    var centralManager: CBCentralManager!
    var recipePeripheral: CBPeripheral!

    var fruser = KeychainWrapper.standard.string(forKey: "fr_user_email")
    var frpw = KeychainWrapper.standard.string(forKey: "fr_password")
    var offline = UserDefaults.standard.bool(forKey: "fr_isOffline")

    override func viewDidLoad() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
        super.viewDidLoad()
        setupSettingsListView(settingsList)
    }

    override func viewWillDisappear(_ animated: Bool) {
        centralManager.stopScan()
        super.viewWillDisappear(animated)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (!Reachability.isConnectedToNetwork() || (offline && fruser?.count ?? 0 > 0)){
            return 2
        }

        else {
            return 4
        }
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
            else if (indexPath.row == 2) {
                cell.textLabel?.text = "Receive Transmission"
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
            else if (indexPath.row == 2) {
                cell.textLabel?.text = "Receive Transmission"
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
            }  else if (indexPath.row == 2) {
                // bluetooth
                userState = 4
            }
        }
        else {
            if (indexPath.row == 0) {
                // log in
                userState = 1
            } else if (indexPath.row == 1) {
                // sign up
                userState = 2
            } else if (indexPath.row == 2) {
                // bluetooth
                userState = 4
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
                    KeychainWrapper.standard.set("", forKey: "fr_user_email")
                    KeychainWrapper.standard.set("", forKey: "fr_password")
                    KeychainWrapper.standard.set("", forKey: "token")
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
        case 4:
            os_log("Queue up a bluetooth interaction.")
            centralManager.scanForPeripherals(withServices: [CBUUID(string: "AF0BADB1-5B99-43CD-917A-A77BC549E3CC")])
//            centralManager.scanForPeripherals(withServices: [Constants.SERVICE_UUID], options: nil)
        default:
            os_log("Selected item does not have an associated action.")
        }
    }
}

extension SettingsViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
          case .unknown:
            print("central.state is .unknown")
          case .resetting:
            print("central.state is .resetting")
          case .unsupported:
            print("central.state is .unsupported")
          case .unauthorized:
            print("central.state is .unauthorized")
          case .poweredOff:
            print("central.state is .poweredOff")
            // prompt to enable bluetooth.
            // https://stackoverflow.com/questions/5655674/opening-the-settings-app-from-another-app
          case .poweredOn:
            print("central.state is .poweredOn")

//            centralManager.scanForPeripherals(withServices: [Constants.SERVICE_UUID])

            centralManager.scanForPeripherals(withServices: nil)

        @unknown default:
            print("Fatal error in centralManagerDidUpdateState")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {

        os_log("Discovered peripheral: %ds", peripheral)

        //make sure the signal is good
        guard RSSI.intValue >= -50
            else {
                os_log("Discovered perhiperal not in expected range, at %d", RSSI.intValue)
                return
        }

        // TODO: turn this into an alert. Do you want to accept this recipe?
        recipePeripheral = peripheral
        recipePeripheral.delegate = self

        centralManager.stopScan()

        centralManager.connect(recipePeripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        os_log("connecting")

//        peripheral.discoverServices([Constants.SERVICE_UUID])

        peripheral.discoverServices(nil)

    }
}

extension SettingsViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }

        for service in services {
          peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
      guard let characteristics = service.characteristics else { return }

      for characteristic in characteristics {
        print(characteristic)

        if characteristic.properties.contains(.read) {
          print("\(characteristic.uuid): properties contains .read")
        }
        if characteristic.properties.contains(.notify) {
          print("\(characteristic.uuid): properties contains .notify")
        }

        peripheral.readValue(for: characteristic)
      }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

        print(characteristic.value ?? "no value")

    }
}


