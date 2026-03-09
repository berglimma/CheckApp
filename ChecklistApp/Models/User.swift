//
//  User.swift
//  ChecklistApp
//
//  Created by Luan Carlos on 13/02/26.
//
import Foundation
import SwiftData

@Model
final class User {
    var name: String
    
    @Attribute(.unique)
    var email: String
    
    var phone: String
    var password: String
    var createdAt: Date
    var role: UserRole
    
    init(name: String,
         email: String,
         phone: String,
         password: String,
         role: UserRole) {
        
        self.name = name
        self.email = email
        self.phone = phone
        self.password = password
        self.role = role
        self.createdAt = Date()
    }
}

enum UserRole: String, Codable {
    case admin
    case normal
}

enum CadastroError: Error {
    case camposObrigatorios
    case senhasNaoConferem
    case emailDuplicado
    case erroSalvar
}
