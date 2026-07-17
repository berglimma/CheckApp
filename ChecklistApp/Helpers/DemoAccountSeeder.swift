//
//  DemoAccountSeeder.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import Foundation
import SwiftData

/// Garante conta demo para App Review (e-mail/senha em AppStoreLinks.DemoAccount).
@MainActor
enum DemoAccountSeeder {
    
    static func seedIfNeeded(context: ModelContext) {
        let email = AppStoreLinks.DemoAccount.email
        let descriptor = FetchDescriptor<User>()
        let users = (try? context.fetch(descriptor)) ?? []
        
        if let existing = users.first(where: {
            $0.email.caseInsensitiveCompare(email) == .orderedSame
        }) {
            // Mantém senha demo sincronizada (hash) para a review
            let desiredHash = PasswordHasher.hash(AppStoreLinks.DemoAccount.password)
            if existing.password != desiredHash {
                existing.password = desiredHash
                existing.name = AppStoreLinks.DemoAccount.name
                existing.phone = AppStoreLinks.DemoAccount.phone
                existing.role = .admin
                try? context.save()
            }
            return
        }
        
        let demo = User(
            name: AppStoreLinks.DemoAccount.name,
            email: email,
            phone: AppStoreLinks.DemoAccount.phone,
            password: PasswordHasher.hash(AppStoreLinks.DemoAccount.password),
            role: .admin
        )
        context.insert(demo)
        try? context.save()
    }
}
