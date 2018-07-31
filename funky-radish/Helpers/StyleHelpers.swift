//
//  StyleHelpers.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 7/13/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import UIKit

func hexStringToUIColor (hex:String) -> UIColor {
    var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

    if (cString.hasPrefix("#")) {
        cString.remove(at: cString.startIndex)
    }

    if ((cString.count) != 6) {
        return UIColor.gray
    }

    var rgbValue:UInt32 = 0
    Scanner(string: cString).scanHexInt32(&rgbValue)

    return UIColor(
        red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
        blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
        alpha: CGFloat(1.0)
    )
}

func applyBackgroundGradient (view: UIView) {
    let startGreen = hexStringToUIColor(hex: "A2FFB1")

    let gradient = CAGradientLayer()
    gradient.frame = view.bounds
    gradient.colors = [UIColor.white.cgColor, startGreen.withAlphaComponent(0.6).cgColor]
    gradient.locations = [0.05, 0.99]

    view.layer.insertSublayer(gradient, at: 0)
}

class StyleHelpers: NSObject {

}
