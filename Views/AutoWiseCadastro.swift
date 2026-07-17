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
    
    /// Ainda há vaga no teto de 5 administradores.
    private var hasAdminSlot: Bool {
        SessionManager.canAddAdmin(context: context)
    }
    
    private var adminCount: Int {
        SessionManager.adminCount(context: context)
    }
    
    /// Primeira conta do dispositivo vira administradora automaticamente.
    private var isBootstrapAdmin: Bool {
        !session.isLoggedIn && SessionManager.userCount(context: context) == 0
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
                        title: "Cadastro de Funcionário",
                        subtitle: canAssignAdmin
                            ? (hasAdminSlot
                               ? "Administradores \(adminCount)/\(SessionManager.maxAdmins) — o nome aparece em Funcionário responsável"
                               : "Limite de \(SessionManager.maxAdmins) admins — cadastre operadores/funcionários")
                            : (isBootstrapAdmin
                               ? "Primeira conta: será administradora"
                               : "Crie sua conta de operador/funcionário")
                    )
                    
                    AWSectionCard(title: "Dados do funcionário") {
                        VStack(spacing: 12) {
                            AWTextField(
                                placeholder: "Nome do funcionário",
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
                    
                    AWSectionCard(title: "Acesso ao app") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("O nome do funcionário será listado automaticamente em Entrega, Devolução, Troca, Avarias e Avaliação.")
                                .font(AWTheme.caption(12))
                                .foregroundStyle(AWTheme.textSecondary)
                            
                            AWSecureField(placeholder: "Senha", text: $password)
                            AWSecureField(placeholder: "Confirmar senha", text: $confirmPassword)
                            
                            if canAssignAdmin {
                                if hasAdminSlot {
                                    Toggle(isOn: $isAdmin) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Conta administrativa")
                                                .font(AWTheme.headline(15))
                                                .foregroundStyle(AWTheme.textPrimary)
                                            Text("Vagas restantes: \(SessionManager.adminSlotsRemaining(context: context)) de \(SessionManager.maxAdmins)")
                                                .font(AWTheme.caption(12))
                                                .foregroundStyle(AWTheme.textSecondary)
                                        }
                                    }
                                    .tint(AWTheme.accent)
                                    .padding(.top, 4)
                                } else {
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundStyle(AWTheme.warning)
                                        Text("Limite de \(SessionManager.maxAdmins) administradores atingido. Você só pode cadastrar operadores. Exclua ou rebaixe um admin em Equipe para liberar vaga.")
                                            .font(AWTheme.caption(12))
                                            .foregroundStyle(AWTheme.textSecondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, 4)
                                }
                            } else if isBootstrapAdmin {
                                HStack(spacing: 8) {
                                    Image(systemName: "shield.checkered")
                                        .foregroundStyle(AWTheme.warning)
                                    Text("Esta será a conta Administradora deste dispositivo.")
                                        .font(AWTheme.caption(12))
                                        .foregroundStyle(AWTheme.textSecondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Text("Novas contas são criadas como Operador. Um administrador pode elevar o acesso em Equipe (máx. \(SessionManager.maxAdmins) admins).")
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
            if !canAssignAdmin || !hasAdminSlot {
                isAdmin = false
            }
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
        
        let wantsAdmin = canAssignAdmin && isAdmin && hasAdminSlot
        if canAssignAdmin && isAdmin && !hasAdminSlot {
            shouldReturnToLogin = false
            alertMessage = "Limite de \(SessionManager.maxAdmins) administradores atingido. Cadastre um operador ou libere uma vaga em Equipe."
            showAlert = true
            return
        }
        
        let role: UserRole = {
            if wantsAdmin { return .admin }
            if isBootstrapAdmin { return .admin }
            return .normal
        }()
        
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
                alertMessage = role == .admin
                    ? "Funcionário administrador cadastrado (\(SessionManager.adminCount(context: context))/\(SessionManager.maxAdmins)). Já disponível em Funcionário responsável."
                    : "Funcionário cadastrado com sucesso. Já disponível em Funcionário responsável."
                showAlert = true
                clearForm()
                isAdmin = false
            } catch let authError as AuthServiceError {
                shouldReturnToLogin = false
                alertMessage = authError.localizedDescription
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
                    alertMessage = role == .admin
                        ? "Funcionário administrador cadastrado (\(SessionManager.adminCount(context: context))/\(SessionManager.maxAdmins)). Já disponível em Funcionário responsável."
                        : "Funcionário cadastrado com sucesso. Já disponível em Funcionário responsável."
                    showAlert = true
                    clearForm()
                    isAdmin = false
                case .failure(let cadastroError):
                    shouldReturnToLogin = false
                    switch cadastroError {
                    case .camposObrigatorios:
                        alertMessage = "Todos os campos são obrigatórios."
                    case .senhasNaoConferem:
                        alertMessage = "As senhas não coincidem."
                    case .emailDuplicado:
                        alertMessage = "E-mail já cadastrado."
                    case .limiteAdmins:
                        alertMessage = "Limite de \(SessionManager.maxAdmins) administradores atingido. Cadastre um operador ou libere uma vaga em Equipe."
                    case .erroSalvar:
                        alertMessage = error.localizedDescription
                    }
                    showAlert = true
                }
            }
        }
    }
    
    private func clearForm() {
        name = ""
        email = ""
        phone = ""
        password = ""
        confirmPassword = ""
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
