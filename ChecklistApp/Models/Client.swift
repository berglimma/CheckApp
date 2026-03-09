//
//  Client.swift
//  ChecklistApp
//
//  Created by Luan Carlos on 13/02/26.
//

import SwiftData
import Foundation

@Model
class Client {
    var name: String
    var cpf: String
    var phone: String
    var email: String?
    var cars: [Car] = []
    
    init(name: String, cpf: String, phone: String, email: String? = nil) {
        self.name = name
        self.cpf = cpf
        self.phone = phone
        self.email = email
    }
}
