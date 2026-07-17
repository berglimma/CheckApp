//
//  User.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import Foundation
import SwiftData

@Model
final class User {
    var name: String = ""
    
    @Attribute(.unique)
    var email: String = ""
    
    var phone: String = ""
    var password: String = ""
    var createdAt: Date = Date()
    var roleRaw: String = UserRole.normal.rawValue
    var photoOwnerId: String = ""
    
    var role: UserRole {
        get { UserRole(rawValue: roleRaw) ?? .normal }
        set { roleRaw = newValue.rawValue }
    }
    
    init(name: String,
         email: String,
         phone: String,
         password: String,
         role: UserRole) {
        self.name = name
        self.email = email
        self.phone = phone
        self.password = password
        self.roleRaw = role.rawValue
        self.createdAt = Date()
        self.photoOwnerId = UUID().uuidString
    }
}

enum UserRole: String, Codable, CaseIterable {
    case admin
    case normal
    
    var titulo: String {
        switch self {
        case .admin: return "Administrador"
        case .normal: return "Operador"
        }
    }
    
    var descricao: String {
        switch self {
        case .admin:
            return "Gerencia usuários e acessos da equipe"
        case .normal:
            return "Registra checklists e operações de frota"
        }
    }
}

/// Limites de acesso (fora de MainActor para uso em erros/serviços).
enum UserAccessPolicy {
    static let maxAdmins = 5
}

enum CadastroError: Error {
    case camposObrigatorios
    case senhasNaoConferem
    case emailDuplicado
    case erroSalvar
    case limiteAdmins
}
