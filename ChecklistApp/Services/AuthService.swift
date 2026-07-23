//
//  AuthService.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import Foundation
import SwiftData
import AuthenticationServices
import CryptoKit
import UIKit

#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isConfigured: Bool = false
    @Published var authError: String?
    @Published var isLoading: Bool = false
    
    private var currentNonce: String?
    
    var firebaseEnabled: Bool {
        #if canImport(FirebaseAuth)
        return isConfigured
        #else
        return false
        #endif
    }
    
    func configureIfNeeded() {
        #if canImport(FirebaseCore)
        if FirebaseApp.app() == nil {
            if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
                FirebaseApp.configure()
                isConfigured = true
                print("✅ Firebase configurado (checklistapp-6c514).")
            } else {
                isConfigured = false
                print("⚠️ GoogleService-Info.plist não encontrado. Auth social usará modo local.")
            }
        } else {
            isConfigured = true
        }
        #else
        isConfigured = false
        #endif
    }
    
    @discardableResult
    func handleGoogleURL(_ url: URL) -> Bool {
        #if canImport(GoogleSignIn)
        return GIDSignIn.sharedInstance.handle(url)
        #else
        return false
        #endif
    }
    
    // MARK: - Email / Password
    
    func loginEmail(
        email: String,
        password: String,
        context: ModelContext
    ) async throws -> User {
        isLoading = true
        defer { isLoading = false }
        
        configureIfNeeded()
        
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedEmail.isEmpty, !password.isEmpty else {
            throw AuthServiceError.invalidCredentials
        }
        
        #if canImport(FirebaseAuth)
        if isConfigured {
            do {
                let result = try await Auth.auth().signIn(withEmail: normalizedEmail, password: password)
                return try upsertLocalUser(
                    from: result.user,
                    fallbackName: normalizedEmail.components(separatedBy: "@").first ?? "Usuário",
                    password: PasswordHasher.hash(password),
                    context: context
                )
            } catch {
                // Conta só local → cria no Firebase e entra
                if let local = try findLocalUser(email: normalizedEmail, context: context),
                   PasswordHasher.verify(password, against: local.password) {
                    if Self.isFirebaseUserMissing(error) || Self.isFirebaseInvalidCredential(error) {
                        do {
                            try await pushLocalCredentialsToFirebase(
                                email: normalizedEmail,
                                password: password,
                                displayName: local.name
                            )
                            return try finalizeLocalLogin(local, password: password, context: context)
                        } catch {
                            print("⚠️ Sync local→Firebase falhou: \(error.localizedDescription)")
                            return try finalizeLocalLogin(local, password: password, context: context)
                        }
                    }
                    
                    if Self.isFirebaseNetworkError(error) {
                        return try finalizeLocalLogin(local, password: password, context: context)
                    }
                    
                    print("⚠️ Firebase auth divergente; usando conta local. \(error.localizedDescription)")
                    return try finalizeLocalLogin(local, password: password, context: context)
                }
                
                throw mapFirebaseAuthError(error)
            }
        }
        #endif
        
        return try loginLocalOnly(email: normalizedEmail, password: password, context: context)
    }
    
    func registerEmail(
        name: String,
        email: String,
        phone: String,
        password: String,
        role: UserRole,
        context: ModelContext
    ) async throws -> User {
        isLoading = true
        defer { isLoading = false }
        
        configureIfNeeded()
        
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard PasswordPolicy.isValid(password) else {
            throw AuthServiceError.weakPassword
        }
        let hashed = PasswordHasher.hash(password)
        let finalRole = role
        if finalRole == .admin && !SessionManager.canAddAdmin(context: context) {
            throw AuthServiceError.adminLimitReached
        }
        
        #if canImport(FirebaseAuth)
        if isConfigured {
            do {
                let result = try await Auth.auth().createUser(withEmail: normalizedEmail, password: password)
                let change = result.user.createProfileChangeRequest()
                change.displayName = name
                try? await change.commitChanges()
                return try upsertLocalUser(
                    from: result.user,
                    fallbackName: name,
                    phone: phone,
                    role: finalRole,
                    password: hashed,
                    context: context
                )
            } catch {
                if Self.isFirebaseEmailAlreadyInUse(error) {
                    // Já existe no Firebase — valida senha e espelha no SwiftData
                    do {
                        let result = try await Auth.auth().signIn(withEmail: normalizedEmail, password: password)
                        return try upsertLocalUser(
                            from: result.user,
                            fallbackName: name,
                            phone: phone,
                            role: finalRole,
                            password: hashed,
                            context: context
                        )
                    } catch {
                        throw AuthServiceError.emailAlreadyRegistered
                    }
                }
                
                if Self.isFirebaseNetworkError(error) {
                    // Offline / Simulator sem rede: grava local e sincroniza no próximo login
                    return try saveLocalUser(
                        name: name,
                        email: normalizedEmail,
                        phone: phone,
                        passwordHash: hashed,
                        role: finalRole,
                        context: context
                    )
                }
                
                throw mapFirebaseAuthError(error)
            }
        }
        #endif
        
        return try saveLocalUser(
            name: name,
            email: normalizedEmail,
            phone: phone,
            passwordHash: hashed,
            role: finalRole,
            context: context
        )
    }
    
    /// Garante que e-mail/senha existam no Firebase (ex.: conta demo ou migração).
    func ensureFirebaseEmailPassword(
        email: String,
        password: String,
        displayName: String
    ) async {
        configureIfNeeded()
        #if canImport(FirebaseAuth)
        guard isConfigured else { return }
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            _ = try await Auth.auth().signIn(withEmail: normalized, password: password)
            print("✅ Firebase já possui \(normalized)")
        } catch {
            if Self.isFirebaseUserMissing(error) || Self.isFirebaseInvalidCredential(error) {
                do {
                    try await pushLocalCredentialsToFirebase(
                        email: normalized,
                        password: password,
                        displayName: displayName
                    )
                    print("✅ Conta sincronizada no Firebase: \(normalized)")
                } catch {
                    // emailAlreadyInUse com senha diferente — não sobrescreve
                    print("⚠️ ensureFirebaseEmailPassword: \(error.localizedDescription)")
                }
            } else {
                print("⚠️ ensureFirebaseEmailPassword: \(error.localizedDescription)")
            }
        }
        #endif
    }
    
    /// Envia e-mail de recuperação de senha (Firebase) ou gera código local.
    func sendPasswordReset(email: String, context: ModelContext) async throws -> PasswordResetResult {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { throw AuthServiceError.invalidCredentials }
        
        configureIfNeeded()
        
        #if canImport(FirebaseAuth)
        if isConfigured {
            do {
                try await Auth.auth().sendPasswordReset(withEmail: trimmed)
                return .firebaseEmailSent
            } catch {
                print("Firebase reset falhou: \(error.localizedDescription)")
                // Continua para fallback local se a conta existir só no dispositivo
            }
        }
        #endif
        
        let descriptor = FetchDescriptor<User>()
        let users = try context.fetch(descriptor)
        guard let user = users.first(where: {
            $0.email.caseInsensitiveCompare(trimmed) == .orderedSame
        }) else {
            throw AuthServiceError.emailNotFound
        }
        
        let code = String(Int.random(in: 100000...999999))
        user.password = PasswordHasher.hash(code)
        try context.save()
        return .localTemporaryPassword(code: code, phone: user.phone, name: user.name)
    }
    
    // MARK: - Apple
    
    func prepareAppleNonce() -> String {
        let nonce = randomNonce()
        currentNonce = nonce
        return sha256(nonce)
    }
    
    func handleApple(
        authorization: ASAuthorization,
        context: ModelContext
    ) async throws -> User {
        isLoading = true
        defer { isLoading = false }
        
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8) else {
            throw AuthServiceError.appleFailed
        }
        
        let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        let email = credential.email ?? "apple_\(credential.user.prefix(8))@autowize.local"
        let name = fullName.isEmpty ? "Usuário Apple" : fullName
        
        #if canImport(FirebaseAuth)
        if isConfigured {
            guard let nonce = currentNonce else { throw AuthServiceError.appleFailed }
            let oauth = OAuthProvider.appleCredential(
                withIDToken: idToken,
                rawNonce: nonce,
                fullName: credential.fullName
            )
            let result = try await Auth.auth().signIn(with: oauth)
            return try upsertLocalUser(from: result.user, fallbackName: name, context: context)
        }
        #endif
        
        return try upsertSocialLocalUser(
            email: email,
            name: name,
            provider: "apple",
            context: context
        )
    }
    
    // MARK: - Google
    
    func handleGoogle(presenting viewController: UIViewController, context: ModelContext) async throws -> User {
        isLoading = true
        defer { isLoading = false }
        
        #if canImport(GoogleSignIn) && canImport(FirebaseAuth)
        if isConfigured {
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                throw AuthServiceError.firebaseNotConfigured
            }
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthServiceError.googleFailed
            }
            let accessToken = result.user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            let authResult = try await Auth.auth().signIn(with: credential)
            let name = result.user.profile?.name ?? "Usuário Google"
            return try upsertLocalUser(from: authResult.user, fallbackName: name, context: context)
        }
        #endif
        
        throw AuthServiceError.firebaseNotConfigured
    }
    
    func logout() {
        #if canImport(FirebaseAuth)
        try? Auth.auth().signOut()
        #endif
        #if canImport(GoogleSignIn)
        GIDSignIn.sharedInstance.signOut()
        #endif
    }
    
    /// Exclui a conta no Firebase (se houver) e remove dados locais:
    /// usuário, fotos, históricos, checklists, CPF/clientes e reservas.
    func deleteAccount(user: User, context: ModelContext) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let email = user.email
        
        #if canImport(FirebaseAuth)
        if isConfigured, let firebaseUser = Auth.auth().currentUser {
            if (firebaseUser.email ?? "").caseInsensitiveCompare(email) == .orderedSame {
                do {
                    try await firebaseUser.delete()
                } catch {
                    let nsError = error as NSError
                    if nsError.domain == AuthErrorDomain,
                       nsError.code == AuthErrorCode.requiresRecentLogin.rawValue {
                        throw AuthServiceError.requiresRecentLogin
                    }
                    throw AuthServiceError.deleteAccountFailed
                }
            }
        }
        #endif
        
        #if canImport(GoogleSignIn)
        GIDSignIn.sharedInstance.signOut()
        #endif
        
        do {
            // 1) Históricos, devoluções, clientes, carros, fotos, reservas e UserDefaults
            try AccountDataEraser.eraseAllOperationalData(context: context)
            
            // 2) Conta do usuário
            let userEmail = email
            let remainingUsers = try context.fetch(FetchDescriptor<User>())
            for localUser in remainingUsers where localUser.email.caseInsensitiveCompare(userEmail) == .orderedSame {
                context.delete(localUser)
            }
            
            try context.save()
        } catch {
            throw AuthServiceError.deleteAccountFailed
        }
    }
    
    // MARK: - Helpers
    
    private func loginLocalOnly(email: String, password: String, context: ModelContext) throws -> User {
        guard let user = try findLocalUser(email: email, context: context),
              PasswordHasher.verify(password, against: user.password) else {
            throw AuthServiceError.invalidCredentials
        }
        return try finalizeLocalLogin(user, password: password, context: context)
    }
    
    private func finalizeLocalLogin(_ user: User, password: String, context: ModelContext) throws -> User {
        var changed = false
        if PasswordHasher.needsRehash(user.password) {
            user.password = PasswordHasher.hash(password)
            changed = true
        }
        if AppStoreLinks.isPersistentAdminEmail(user.email), user.role != .admin {
            user.role = .admin
            changed = true
        }
        if changed {
            try context.save()
        }
        return user
    }
    
    private func findLocalUser(email: String, context: ModelContext) throws -> User? {
        let users = try context.fetch(FetchDescriptor<User>())
        return users.first { $0.email.caseInsensitiveCompare(email) == .orderedSame }
    }
    
    private func saveLocalUser(
        name: String,
        email: String,
        phone: String,
        passwordHash: String,
        role: UserRole,
        context: ModelContext
    ) throws -> User {
        if (try findLocalUser(email: email, context: context)) != nil {
            throw AuthServiceError.emailAlreadyRegistered
        }
        let user = User(name: name, email: email, phone: phone, password: passwordHash, role: role)
        context.insert(user)
        try context.save()
        return user
    }
    
    #if canImport(FirebaseAuth)
    private func pushLocalCredentialsToFirebase(
        email: String,
        password: String,
        displayName: String
    ) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let change = result.user.createProfileChangeRequest()
            change.displayName = displayName
            try? await change.commitChanges()
        } catch {
            if Self.isFirebaseEmailAlreadyInUse(error) {
                // Já existe — tenta autenticar com a senha local
                _ = try await Auth.auth().signIn(withEmail: email, password: password)
                return
            }
            throw error
        }
    }
    
    private static func isFirebaseUserMissing(_ error: Error) -> Bool {
        let ns = error as NSError
        guard ns.domain == AuthErrorDomain else { return false }
        return AuthErrorCode(rawValue: ns.code) == .userNotFound
    }
    
    private static func isFirebaseInvalidCredential(_ error: Error) -> Bool {
        let ns = error as NSError
        guard ns.domain == AuthErrorDomain else { return false }
        let code = AuthErrorCode(rawValue: ns.code)
        return code == .wrongPassword || code == .invalidCredential
    }
    
    private static func isFirebaseEmailAlreadyInUse(_ error: Error) -> Bool {
        let ns = error as NSError
        guard ns.domain == AuthErrorDomain else { return false }
        return AuthErrorCode(rawValue: ns.code) == .emailAlreadyInUse
    }
    
    private static func isFirebaseNetworkError(_ error: Error) -> Bool {
        let ns = error as NSError
        if ns.domain == NSURLErrorDomain { return true }
        if ns.domain == AuthErrorDomain,
           AuthErrorCode(rawValue: ns.code) == .networkError {
            return true
        }
        return false
    }
    
    private func mapFirebaseAuthError(_ error: Error) -> Error {
        let ns = error as NSError
        if ns.domain == AuthErrorDomain {
            switch AuthErrorCode(rawValue: ns.code) {
            case .wrongPassword, .invalidCredential, .userNotFound, .invalidEmail:
                return AuthServiceError.invalidCredentials
            case .emailAlreadyInUse:
                return AuthServiceError.emailAlreadyRegistered
            case .networkError:
                return AuthServiceError.networkUnavailable
            default:
                break
            }
        }
        if ns.domain == NSURLErrorDomain {
            return AuthServiceError.networkUnavailable
        }
        return error
    }
    
    private func upsertLocalUser(
        from firebaseUser: FirebaseAuth.User,
        fallbackName: String,
        phone: String = "",
        role: UserRole? = nil,
        password: String = "",
        context: ModelContext
    ) throws -> User {
        let email = firebaseUser.email ?? "\(firebaseUser.uid)@autowize.local"
        let name = firebaseUser.displayName?.isEmpty == false ? (firebaseUser.displayName ?? fallbackName) : fallbackName
        
        // Preserva papel local (admin/operador); demo / e-mails privilegiados continuam admin
        let resolvedRole: UserRole = {
            if let role { return role }
            if AppStoreLinks.isPersistentAdminEmail(email) {
                return .admin
            }
            if let existing = try? findLocalUser(email: email, context: context) {
                return existing.role
            }
            return .operador
        }()
        
        return try upsertSocialLocalUser(
            email: email,
            name: name,
            phone: phone,
            role: resolvedRole,
            password: password,
            provider: "firebase",
            context: context
        )
    }
    #endif
    
    private func upsertSocialLocalUser(
        email: String,
        name: String,
        phone: String = "",
        role: UserRole = .operador,
        password: String = "oauth",
        provider: String,
        context: ModelContext
    ) throws -> User {
        if let existing = try findLocalUser(email: email, context: context) {
            existing.name = name
            if !phone.isEmpty { existing.phone = phone }
            // Não rebaixa admin; promove e-mails privilegiados (demo / berg.limma)
            if AppStoreLinks.isPersistentAdminEmail(existing.email)
                || AppStoreLinks.isPersistentAdminEmail(email)
                || role == .admin {
                existing.role = .admin
            }
            if !password.isEmpty, password != "oauth" {
                existing.password = PasswordHasher.isHashed(password) ? password : PasswordHasher.hash(password)
            }
            try context.save()
            return existing
        }
        let storedPassword: String = {
            if password.isEmpty || password == "oauth" { return PasswordHasher.hash(UUID().uuidString) }
            return PasswordHasher.isHashed(password) ? password : PasswordHasher.hash(password)
        }()
        let user = User(name: name, email: email, phone: phone, password: storedPassword, role: role)
        context.insert(user)
        try context.save()
        return user
    }
    
    private func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in UInt8.random(in: 0...255) }
            randoms.forEach { random in
                if remaining == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remaining -= 1
                }
            }
        }
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

enum AuthServiceError: LocalizedError {
    case invalidCredentials
    case appleFailed
    case googleFailed
    case firebaseNotConfigured
    case emailNotFound
    case emailAlreadyRegistered
    case deleteAccountFailed
    case requiresRecentLogin
    case adminLimitReached
    case networkUnavailable
    case weakPassword
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "E-mail ou senha inválidos."
        case .appleFailed: return "Falha no login com Apple."
        case .googleFailed: return "Falha no login com Google."
        case .firebaseNotConfigured:
            return "Firebase não configurado. Adicione o GoogleService-Info.plist e os pacotes Firebase/GoogleSignIn no Xcode."
        case .emailNotFound:
            return "Nenhuma conta encontrada com este e-mail."
        case .emailAlreadyRegistered:
            return "E-mail já cadastrado. Faça login ou recupere a senha."
        case .deleteAccountFailed:
            return "Não foi possível excluir a conta. Tente novamente."
        case .requiresRecentLogin:
            return "Por segurança, faça login novamente e tente excluir a conta."
        case .adminLimitReached:
            return "Limite de \(UserAccessPolicy.maxAdmins) administradores atingido. Cadastre um operador ou libere uma vaga."
        case .networkUnavailable:
            return "Sem conexão. Verifique a rede do Simulator/dispositivo e tente de novo."
        case .weakPassword:
            return PasswordPolicy.failureMessage
        }
    }
}

enum PasswordResetResult {
    case firebaseEmailSent
    case localTemporaryPassword(code: String, phone: String, name: String)
}
