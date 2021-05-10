//
//  Reachability.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 8/18/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import Foundation
import SystemConfiguration
import CoreTelephony
import os

public class Reachability {

    class func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)

        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }

        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }

        let isReachable = flags == .reachable
        let needsConnection = flags == .connectionRequired

        // Would prefer to know explicitly if cellular is enabled for this app, but this works.
        return (isReachable || flags.contains(.isWWAN)) && !needsConnection
    }

}
