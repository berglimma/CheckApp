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
        guard let user = currentUser else { return false }
        if user.role == .admin { return true }
        return AppStoreLinks.isPersistentAdminEmail(user.email)
    }
    
    var roleTitle: String {
        if isAdmin { return UserRole.admin.titulo }
        return currentUser?.role.titulo ?? UserRole.operador.titulo
    }
    
    /// Limite máximo de contas administradoras.
    static var maxAdmins: Int { UserAccessPolicy.maxAdmins }
    
    /// Quantidade de administradores no banco.
    static func adminCount(context: ModelContext) -> Int {
        let users = (try? context.fetch(FetchDescriptor<User>())) ?? []
        return users.filter { $0.role == .admin }.count
    }
    
    static func userCount(context: ModelContext) -> Int {
        (try? context.fetch(FetchDescriptor<User>()))?.count ?? 0
    }
    
    /// Ainda há vaga para criar/promover administrador (< 5).
    static func canAddAdmin(context: ModelContext) -> Bool {
        adminCount(context: context) < UserAccessPolicy.maxAdmins
    }
    
    static func adminSlotsRemaining(context: ModelContext) -> Int {
        max(0, UserAccessPolicy.maxAdmins - adminCount(context: context))
    }
    
    enum RoleChangeResult {
        case success
        case lastAdmin
        case maxAdminsReached
    }
    
    /// Promove/rebaixa com proteção do último admin e teto de 5 admins.
    @discardableResult
    func setRole(_ role: UserRole, for user: User, context: ModelContext) throws -> RoleChangeResult {
        if user.role == role {
            return .success
        }
        
        if user.role == .admin && role != .admin {
            if Self.adminCount(context: context) <= 1 {
                return .lastAdmin
            }
        }
        
        if user.role != .admin && role == .admin {
            if !Self.canAddAdmin(context: context) {
                return .maxAdminsReached
            }
        }
        
        user.role = role
        try context.save()
        if currentUser?.persistentModelID == user.persistentModelID {
            objectWillChange.send()
        }
        return .success
    }
    
    /// Exclui um usuário da equipe (não apaga dados operacionais globais).
    func deleteUser(_ user: User, context: ModelContext) throws -> RoleChangeResult {
        let isSelf = currentUser?.persistentModelID == user.persistentModelID
        
        if user.role == .admin && Self.adminCount(context: context) <= 1 {
            return .lastAdmin
        }
        
        if !user.photoOwnerId.isEmpty {
            let photos = PhotoStore.shared.loadImages(ownerId: user.photoOwnerId, context: context)
            for (attachment, _) in photos {
                try? PhotoStore.shared.delete(attachment: attachment, context: context)
            }
        }
        
        context.delete(user)
        try context.save()
        
        if isSelf {
            logout()
        }
        return .success
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
