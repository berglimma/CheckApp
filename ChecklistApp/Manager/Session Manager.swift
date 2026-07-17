//
//  Session Manager.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import SwiftUI
import SwiftData
import UIKit

@MainActor
final class SessionManager: ObservableObject {
    @Published var currentUser: User?
    @Published var profileImage: UIImage?
    
    var isLoggedIn: Bool {
        currentUser != nil
    }
    
    var isAdmin: Bool {
        currentUser?.role == .admin
    }
    
    func loadProfileImage(context: ModelContext) {
        guard let user = currentUser else {
            profileImage = nil
            return
        }
        ensurePhotoOwnerId(for: user, context: context)
        profileImage = PhotoStore.shared
            .loadImages(ownerId: user.photoOwnerId, context: context)
            .first?
            .1
    }
    
    func updateProfileImage(_ image: UIImage?) {
        profileImage = image
    }
    
    func ensurePhotoOwnerId(for user: User, context: ModelContext) {
        guard user.photoOwnerId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        user.photoOwnerId = UUID().uuidString
        try? context.save()
    }
    
    func logout() {
        AuthService.shared.logout()
        currentUser = nil
        profileImage = nil
    }
    
    /// Exclui a conta do usuário atual e encerra a sessão.
    func deleteAccount(context: ModelContext) async throws {
        guard let user = currentUser else {
            throw AuthServiceError.deleteAccountFailed
        }
        
        try await AuthService.shared.deleteAccount(user: user, context: context)
        currentUser = nil
        profileImage = nil
    }
}
