//
//  StyleHelpers.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 7/13/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import UIKit

// Probably can structure some of theses as view extensions

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

func applyBackgroundGradient (_ view: UIView) {
    let startGreen = hexStringToUIColor(hex: "A2FFB1")

    let gradient = CAGradientLayer()
    gradient.frame = view.bounds
    gradient.colors = [UIColor.white.cgColor, startGreen.withAlphaComponent(0.6).cgColor]
    gradient.locations = [0.05, 0.99]

    view.layer.insertSublayer(gradient, at: 0)
}

func setupRecipeListView(_ tableView: UITableView) {
    tableView.sectionHeaderHeight = 0.0
    tableView.backgroundColor = UIColor.clear
    tableView.clipsToBounds = false

    tableView.layer.shadowColor = UIColor.black.cgColor
    tableView.layer.shadowOpacity = 0.5
    tableView.layer.shadowOffset = CGSize(width: 0.5, height: 1)
    tableView.layer.shadowRadius = 2

    tableView.separatorStyle = UITableViewCellSeparatorStyle.none

    let inset = UIEdgeInsets(top: 0, left: 0, bottom: 45, right: 0)
    tableView.contentInset = inset
}

extension UIView {

    func roundCorners(corners:UIRectCorner, radius: CGFloat) {
        DispatchQueue.main.async {
            let path = UIBezierPath(roundedRect: self.bounds,
                                    byRoundingCorners: corners,
                                    cornerRadii: CGSize(width: radius, height: radius))
            let maskLayer = CAShapeLayer()
            maskLayer.frame = self.bounds
            maskLayer.path = path.cgPath
            self.layer.mask = maskLayer
        }
    }
}
