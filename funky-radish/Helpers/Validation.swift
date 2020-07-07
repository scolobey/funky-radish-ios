//
//  Validation.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 9/11/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import Foundation

enum validationError: Error {
    case invalidEmail
    case shortPassword
    case invalidPassword
    case invalidUsername
}

class Validation {
    func isValidEmail(_ email:String) throws {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        if(emailTest.evaluate(with: email)) {
            return
        }
        else {
            throw validationError.invalidEmail
        }
    }

    func isValidPW(_ pw:String) throws {
        let pwRegEx = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{8,}$"
        let pwTest = NSPredicate(format:"SELF MATCHES %@", pwRegEx)
        if(pwTest.evaluate(with: pw)) {
            return
        }
        else {
            if(pw.count < 8) {
                throw validationError.shortPassword
            }
            else {
                throw validationError.invalidPassword
            }
        }
    }

    func isValidUsername(_ username:String) throws {
        if (username.count == 0){
            throw validationError.invalidUsername
        }
        else {
            return
        }
    }
}



