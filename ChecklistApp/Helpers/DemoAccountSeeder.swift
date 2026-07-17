//
//  DemoAccountSeeder.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import Foundation
import SwiftData

/// Garante conta demo local + sincronização no Firebase (App Review / Simulator).
@MainActor
enum DemoAccountSeeder {
    
    static func seedIfNeeded(context: ModelContext) {
        let email = AppStoreLinks.DemoAccount.email
        let password = AppStoreLinks.DemoAccount.password
        let descriptor = FetchDescriptor<User>()
        let users = (try? context.fetch(descriptor)) ?? []
        
        if let existing = users.first(where: {
            $0.email.caseInsensitiveCompare(email) == .orderedSame
        }) {
            let desiredHash = PasswordHasher.hash(password)
            var changed = false
            if existing.password != desiredHash {
                existing.password = desiredHash
                changed = true
            }
            if existing.name != AppStoreLinks.DemoAccount.name {
                existing.name = AppStoreLinks.DemoAccount.name
                changed = true
            }
            if existing.phone != AppStoreLinks.DemoAccount.phone {
                existing.phone = AppStoreLinks.DemoAccount.phone
                changed = true
            }
            if existing.role != .admin {
                existing.role = .admin
                changed = true
            }
            if changed {
                try? context.save()
            }
        } else {
            let demo = User(
                name: AppStoreLinks.DemoAccount.name,
                email: email,
                phone: AppStoreLinks.DemoAccount.phone,
                password: PasswordHasher.hash(password),
                role: .admin
            )
            context.insert(demo)
            try? context.save()
        }
        
        // Espelha e-mail/senha no Firebase (iPhone e iPad Simulator)
        Task {
            AuthService.shared.configureIfNeeded()
            await AuthService.shared.ensureFirebaseEmailPassword(
                email: email,
                password: password,
                displayName: AppStoreLinks.DemoAccount.name
            )
        }
    }
}
