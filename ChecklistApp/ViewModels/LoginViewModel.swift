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
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate {
                $0.email == email &&
                $0.password == password
            }
        )
        
        do {
            let users = try context.fetch(descriptor)
            
            if let user = users.first {
                return user
            } else {
                errorMessage = "Usuário ou senha inválidos."
                return nil
            }
            
        } catch {
            errorMessage = "Erro ao buscar usuário."
            return nil
        }
    }
}
