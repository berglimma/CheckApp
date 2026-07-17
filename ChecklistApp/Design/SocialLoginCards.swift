//
//  SocialLoginCards.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import SwiftUI
import AuthenticationServices
import SwiftData

struct SocialLoginCards: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var session: SessionManager
    @ObservedObject private var auth = AuthService.shared
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var appleDelegate: AppleSignInDelegate?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                socialCard(
                    title: "Apple",
                    systemImage: "apple.logo",
                    iconColor: AWTheme.textPrimary,
                    background: AWTheme.fieldFill,
                    bordered: true
                ) {
                    startAppleSignIn()
                }
                
                socialCard(
                    title: "Google",
                    systemImage: "g.circle.fill",
                    iconColor: AWTheme.accent,
                    background: AWTheme.fieldFill,
                    bordered: true
                ) {
                    Task { await handleGoogle() }
                }
            }
            
            if auth.isLoading {
                ProgressView()
                    .scaleEffect(0.85)
            }
        }
        .alert("Login", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    private func socialCard(
        title: String,
        systemImage: String,
        iconColor: Color,
        background: Color,
        bordered: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(iconColor)
                
                Text(title)
                    .font(AWTheme.caption(12))
                    .foregroundStyle(AWTheme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(bordered ? AWTheme.stroke : Color.clear, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(auth.isLoading)
    }
    
    private func startAppleSignIn() {
        let hash = auth.prepareAppleNonce()
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = hash
        
        let delegate = AppleSignInDelegate { result in
            Task { await handleApple(result) }
        }
        appleDelegate = delegate
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = delegate
        controller.presentationContextProvider = delegate
        controller.performRequests()
    }
    
    private func handleApple(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authResult):
            do {
                let user = try await auth.handleApple(authorization: authResult, context: context)
                session.currentUser = user
            } catch {
                alertMessage = error.localizedDescription
                showAlert = true
            }
        case .failure(let error):
            // Usuário cancelou: não mostra alerta
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue { return }
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
    
    private func handleGoogle() async {
        guard let presenter = UIApplication.shared.topViewController() else {
            alertMessage = "Não foi possível abrir o login Google."
            showAlert = true
            return
        }
        do {
            let user = try await auth.handleGoogle(presenting: presenter, context: context)
            session.currentUser = user
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}

private final class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let completion: (Result<ASAuthorization, Error>) -> Void
    
    init(completion: @escaping (Result<ASAuthorization, Error>) -> Void) {
        self.completion = completion
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        completion(.success(authorization))
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        
        if let keyWindow = scenes.flatMap(\.windows).first(where: \.isKeyWindow) {
            return keyWindow
        }
        
        if let scene = scenes.first {
            return ASPresentationAnchor(windowScene: scene)
        }
        
        preconditionFailure("Nenhuma UIWindowScene disponível para Sign in with Apple.")
    }
}

private extension UIApplication {
    func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let base = base ?? connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController
        
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}
