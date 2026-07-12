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
