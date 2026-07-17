//
//  LoginViewModel.swift
//  ChecklistApp
//
//  Created by Luan Carlos on 28/02/26.
//


import SwiftData
import Foundation

@Observable
final class LoginViewModel {
    
    var email: String = ""
    var password: String = ""
    var errorMessage: String?
    
    func login(context: ModelContext) -> User? {
        
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Preencha todos os campos."
            return nil
        }
        
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let descriptor = FetchDescriptor<User>()
        
        do {
            let users = try context.fetch(descriptor)
            guard let user = users.first(where: {
                $0.email.caseInsensitiveCompare(normalizedEmail) == .orderedSame
            }), PasswordHasher.verify(password, against: user.password) else {
                errorMessage = "Usuário ou senha inválidos."
                return nil
            }
            
            if PasswordHasher.needsRehash(user.password) {
                user.password = PasswordHasher.hash(password)
                try? context.save()
            }
            return user
        } catch {
            errorMessage = "Erro ao buscar usuário."
            return nil
        }
    }
}
