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
    var roleRaw: String = UserRole.operador.rawValue
    var photoOwnerId: String = ""
    
    var role: UserRole {
        get { UserRole.fromStorage(roleRaw) }
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

enum UserRole: String, Codable, CaseIterable, Identifiable {
    case admin
    case operador
    case funcionario
    
    var id: String { rawValue }
    
    /// Perfis selecionáveis no cadastro (exceto bootstrap forçado).
    static var cadastroCases: [UserRole] { [.operador, .funcionario, .admin] }
    
    var titulo: String {
        switch self {
        case .admin: return "Administrador"
        case .operador: return "Operador"
        case .funcionario: return "Funcionário"
        }
    }
    
    var descricao: String {
        switch self {
        case .admin:
            return "Gerencia equipe, cadastros e acessos do Auto Wize"
        case .operador:
            return "Executa checklists e operações de frota no aplicativo"
        case .funcionario:
            return "Aparece como responsável nas operações e pode registrar checklists"
        }
    }
    
    var systemImage: String {
        switch self {
        case .admin: return "shield.checkered"
        case .operador: return "wrench.and.screwdriver.fill"
        case .funcionario: return "person.fill"
        }
    }
    
    /// Compatível com contas antigas salvas como `normal`.
    static func fromStorage(_ raw: String) -> UserRole {
        let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalized == "normal" { return .operador }
        return UserRole(rawValue: normalized) ?? .operador
    }
}

/// Limites de acesso (fora de MainActor para uso em erros/serviços).
enum UserAccessPolicy {
    static let maxAdmins = 5
}

enum CadastroError: Error {
    case camposObrigatorios
    case senhasNaoConferem
    case senhaFraca
    case emailDuplicado
    case erroSalvar
    case limiteAdmins
}
