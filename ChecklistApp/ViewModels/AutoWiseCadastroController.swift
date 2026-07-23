//
//  AutoWiseCadastroController.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import SwiftData
import Foundation

@MainActor
final class AutoWiseCadastroController {
    
    func saveUser(
        context: ModelContext,
        name: String,
        email: String,
        phone: String,
        password: String,
        confirmPassword: String,
        role: UserRole
    ) -> Result<Bool, CadastroError> {
        
        guard !name.isEmpty,
              !email.isEmpty,
              !phone.isEmpty,
              !password.isEmpty else {
            return .failure(.camposObrigatorios)
            
        }
        
        guard password == confirmPassword else {
            return .failure(.senhasNaoConferem)
        }
        
        guard PasswordPolicy.isValid(password) else {
            return .failure(.senhaFraca)
        }
        
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.email == email }
        )
        
        if let existing = try? context.fetch(descriptor), !existing.isEmpty {
            return .failure(.emailDuplicado)
        }
        
        let finalRole = role
        if finalRole == .admin && !SessionManager.canAddAdmin(context: context) {
            return .failure(.limiteAdmins)
        }
        
        let user = User(
            name: name,
            email: email,
            phone: phone,
            password: PasswordHasher.hash(password),
            role: finalRole
        )
        
        context.insert(user)
        
        do {
            try context.save()
            return .success(true)
        } catch {
            return .failure(.erroSalvar)
        }
    }
}
