//
//  User.swift
//  
//
//  Created by mac on 4/21/19.
//

import Foundation
import FirebaseAuth

struct Users {
    
    let uid: String
    let email: String
 
    init(user: User) {
        self.uid = user.uid
        self.email = user.email!
    }
}
 
