//
//  PasswordPolicy.swift
//  ChecklistApp
//
//  Created by Berg Limma on 23/07/26.
//

import Foundation

/// Regras de senha complexa para cadastro.
enum PasswordPolicy {
    static let minLength = 8
    
    struct Requirement: Identifiable, Equatable {
        let id: String
        let label: String
        let isSatisfied: Bool
    }
    
    static func requirements(for password: String) -> [Requirement] {
        [
            Requirement(
                id: "length",
                label: "Pelo menos \(minLength) caracteres",
                isSatisfied: password.count >= minLength
            ),
            Requirement(
                id: "upper",
                label: "Uma letra maiúscula (A–Z)",
                isSatisfied: password.contains { $0.isUppercase && $0.isLetter }
            ),
            Requirement(
                id: "lower",
                label: "Uma letra minúscula (a–z)",
                isSatisfied: password.contains { $0.isLowercase && $0.isLetter }
            ),
            Requirement(
                id: "digit",
                label: "Um número (0–9)",
                isSatisfied: password.contains { $0.isNumber }
            ),
            Requirement(
                id: "special",
                label: "Um caractere especial (!@#$%…)",
                isSatisfied: password.contains { !$0.isLetter && !$0.isNumber && !$0.isWhitespace }
            )
        ]
    }
    
    static func isValid(_ password: String) -> Bool {
        requirements(for: password).allSatisfy(\.isSatisfied)
    }
    
    static var failureMessage: String {
        "A senha deve ter pelo menos \(minLength) caracteres, com maiúscula, minúscula, número e caractere especial."
    }
}
