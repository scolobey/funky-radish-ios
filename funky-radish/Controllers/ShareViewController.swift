//
//  ShareViewController.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 2/15/20.
//  Copyright © 2020 kayso. All rights reserved.
//

import UIKit
import CoreBluetooth
import os

class ShareViewController: UIViewController {

    var peripheralManager = CBPeripheralManager()
    var transferCharacteristic: CBMutableCharacteristic?
    var connectedCentral: CBCentral?

    override func viewDidLoad() {
        peripheralManager = CBPeripheralManager(delegate: self as CBPeripheralManagerDelegate, queue: nil, options: [CBPeripheralManagerOptionShowPowerAlertKey: true])
    peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [Constants.SERVICE_UUID]])

        super.viewDidLoad()
    }

    private func setupPeripheral() {
        let transferCharacteristic = CBMutableCharacteristic(type: Constants.CHARACTERISTIC_UUID,
                                                             properties: [.notify, .writeWithoutResponse],
                                                             value: nil,
                                                             permissions: [.readable, .writeable])

        // Create a service from the characteristic.
        let transferService = CBMutableService(type: Constants.SERVICE_UUID, primary: true)

        // Add the characteristic to the service.
        transferService.characteristics = [transferCharacteristic]

        // And add it to the peripheral manager.
        peripheralManager.add(transferService)

        // Save the characteristic for later.
        self.transferCharacteristic = transferCharacteristic
    }

    private func sendData() {
        os_log("send data called.")

        guard let transferCharacteristic = transferCharacteristic else {
            return
        }

        if (peripheralManager.isAdvertising) {
            peripheralManager.stopAdvertising()
        }

        //Convert recipe to data
        let recipe = localRecipes.filter("_id == %@", selectedRecipe!).first!.toDictionary()
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: recipe, options: .prettyPrinted)

            os_log("Sending the following recipe: %s", String(describing: jsonData))

            let stringFromData = String(data: jsonData, encoding: .utf8)!

            os_log("Sending the data: %s", stringFromData)

            //        // Broadcast the recipe
            let data = peripheralManager.updateValue(jsonData, for: transferCharacteristic, onSubscribedCentrals: nil)

            peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey:[Constants.SERVICE_UUID], CBAdvertisementDataLocalNameKey: data])
        } catch {
            print(error.localizedDescription)
        }

//
//        let ingredients = recipe.ingredients.map({$0.name})
//        let directions = recipe.directions.map({$0.text})
//
//        let dictionaryToSend: [String: Any] = [
//            "realmID": recipe.realmID,
//            "title": recipe.title!,
//            "ingredients": ingredients,
//            "directions": directions
//        ]
//
//        os_log("dictionary: %s", String(describing: dictionaryToSend))

//        let jsonData = try? JSONSerialization.data(withJSONObject: dictionaryToSend)
//
//        os_log("Sending the following json: %s", String(describing: jsonData))
//
//        let dataToSend: Data = NSKeyedArchiver.archivedData(withRootObject: recipe)
//
////        let dictionary: Dictionary? = NSKeyedUnarchiver.unarchiveObject(with: dataExample) as! [String : Any]
//



        //TODO: Redirect to the recipe view with that recipe at the top.
    }

    @IBAction func signalOpen() {
        //Todo : why have a button? Just put a transmitting animation. And make it change when you get a message that the recipe has been received.
        os_log("bluetooth connecting")
        setupPeripheral()
        sendData()
    }

    @IBAction func dismissViewController(_ sender: Any) {
        peripheralManager.stopAdvertising()
        self.dismiss(animated: true, completion: nil)
    }
}

extension ShareViewController: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if (peripheral.state == .poweredOn){
            sendData()
        }
    }
}
