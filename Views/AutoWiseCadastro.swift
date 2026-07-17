//
//  AutoWiseCadastro.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import SwiftUI
import SwiftData
import Foundation

struct AutoWiseCadastro: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isAdmin: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var shouldReturnToLogin: Bool = false
    
    private let cadastroController = AutoWiseCadastroController()
    
    /// Somente admin logado pode criar outra conta admin.
    private var canAssignAdmin: Bool {
        session.isLoggedIn && session.isAdmin
    }
    
    private var canSave: Bool {
        !name.isEmpty && !email.isEmpty && !password.isEmpty
    }
    
    var body: some View {
        ZStack {
            AWScreenBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    AWScreenTitle(
                        title: "Cadastro de Usuário",
                        subtitle: canAssignAdmin
                            ? "Crie acessos para a equipe"
                            : "Crie sua conta de operador"
                    )
                    
                    AWSectionCard(title: "Informações pessoais") {
                        VStack(spacing: 12) {
                            AWTextField(
                                placeholder: "Nome completo",
                                text: $name,
                                autocapitalization: .words
                            )
                            AWTextField(
                                placeholder: "E-mail",
                                text: $email,
                                keyboard: .emailAddress,
                                autocapitalization: .never
                            )
                            AWTextField(
                                placeholder: "Telefone",
                                text: $phone,
                                keyboard: .phonePad,
                                autocapitalization: .never
                            )
                        }
                    }
                    
                    AWSectionCard(title: "Conta") {
                        VStack(spacing: 12) {
                            AWSecureField(placeholder: "Senha", text: $password)
                            AWSecureField(placeholder: "Confirmar senha", text: $confirmPassword)
                            
                            if canAssignAdmin {
                                Toggle(isOn: $isAdmin) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Conta administrativa")
                                            .font(AWTheme.headline(15))
                                            .foregroundStyle(AWTheme.textPrimary)
                                        Text("Somente administradores podem conceder este acesso")
                                            .font(AWTheme.caption(12))
                                            .foregroundStyle(AWTheme.textSecondary)
                                    }
                                }
                                .tint(AWTheme.accent)
                                .padding(.top, 4)
                            } else {
                                Text("Novas contas são criadas como operador. Um administrador pode elevar o acesso depois.")
                                    .font(AWTheme.caption(12))
                                    .foregroundStyle(AWTheme.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    
                    VStack(spacing: 10) {
                        AWPrimaryButton(title: "Salvar", isDisabled: !canSave) {
                            handleSave()
                        }
                        AWSecondaryButton(title: "Cancelar") {
                            dismiss()
                        }
                    }
                    .padding(.bottom, 28)
                }
                .awReadableWidth(AWLayout.formMaxWidth)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AWTheme.screenGray, for: .navigationBar)
        .alert("Auto Wize", isPresented: $showAlert) {
            Button("OK", role: .cancel) {
                if shouldReturnToLogin {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            if !canAssignAdmin { isAdmin = false }
        }
    }
    
    private func handleSave() {
        guard isValidEmail(email) else {
            shouldReturnToLogin = false
            alertMessage = "Formato de e-mail inválido."
            showAlert = true
            return
        }
        
        guard password == confirmPassword else {
            shouldReturnToLogin = false
            alertMessage = "As senhas não coincidem."
            showAlert = true
            return
        }
        
        let role: UserRole = (canAssignAdmin && isAdmin) ? .admin : .normal
        
        Task {
            AuthService.shared.configureIfNeeded()
            do {
                _ = try await AuthService.shared.registerEmail(
                    name: name,
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                    phone: phone,
                    password: password,
                    role: role,
                    context: context
                )
                shouldReturnToLogin = !session.isLoggedIn
                alertMessage = "Conta criada com sucesso."
                showAlert = true
            } catch {
                let result = cadastroController.saveUser(
                    context: context,
                    name: name,
                    email: email,
                    phone: phone,
                    password: password,
                    confirmPassword: confirmPassword,
                    role: role
                )
                switch result {
                case .success:
                    shouldReturnToLogin = !session.isLoggedIn
                    alertMessage = "Conta criada com sucesso."
                    showAlert = true
                case .failure(let cadastroError):
                    shouldReturnToLogin = false
                    switch cadastroError {
                    case .camposObrigatorios:
                        alertMessage = "Todos os campos são obrigatórios."
                    case .senhasNaoConferem:
                        alertMessage = "As senhas não coincidem."
                    case .emailDuplicado:
                        alertMessage = "E-mail já cadastrado."
                    case .erroSalvar:
                        alertMessage = error.localizedDescription
                    }
                    showAlert = true
                }
            }
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPredicate.evaluate(with: email)
    }
}

#Preview {
    NavigationStack {
        AutoWiseCadastro()
    }
    .environmentObject(SessionManager())
    .modelContainer(for: [User.self], inMemory: true)
}
