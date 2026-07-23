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
    @State private var selectedRole: UserRole = .operador
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var shouldReturnToLogin: Bool = false
    
    private let cadastroController = AutoWiseCadastroController()
    
    /// Somente admin logado pode escolher perfil Administrador.
    private var canAssignAdmin: Bool {
        session.isLoggedIn && session.isAdmin
    }
    
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
    
    private var availableRoles: [UserRole] {
        if isBootstrapAdmin {
            return [.admin]
        }
        if canAssignAdmin {
            return UserRole.cadastroCases
        }
        // Auto-cadastro público: operador ou funcionário
        return [.operador, .funcionario]
    }
    
    private var canSave: Bool {
        !name.isEmpty
            && !email.isEmpty
            && !password.isEmpty
            && PasswordPolicy.isValid(password)
            && password == confirmPassword
    }
    
    private var passwordRequirements: [PasswordPolicy.Requirement] {
        PasswordPolicy.requirements(for: password)
    }
    
    private var passwordsMatch: Bool {
        !confirmPassword.isEmpty && password == confirmPassword
    }
    
    var body: some View {
        ZStack {
            AWScreenBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    AWScreenTitle(
                        title: "Cadastro de Usuário",
                        subtitle: isBootstrapAdmin
                            ? "Primeira conta: perfil Administrador"
                            : (canAssignAdmin
                               ? "Escolha o perfil: Operador, Funcionário ou Administrador (\(adminCount)/\(SessionManager.maxAdmins))"
                               : "Escolha Operador ou Funcionário")
                    )
                    
                    AWSectionCard(title: "Perfil de cadastro") {
                        VStack(spacing: 10) {
                            ForEach(availableRoles) { role in
                                profileOption(role)
                            }
                            
                            if canAssignAdmin && !hasAdminSlot {
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(AWTheme.warning)
                                    Text("Limite de \(SessionManager.maxAdmins) administradores atingido. Selecione Operador ou Funcionário, ou libere vaga em Equipe.")
                                        .font(AWTheme.caption(12))
                                        .foregroundStyle(AWTheme.textSecondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 4)
                            }
                        }
                    }
                    
                    AWSectionCard(title: "Dados pessoais") {
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
                    
                    AWSectionCard(title: "Acesso ao app") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("O nome cadastrado aparece em Funcionário responsável nas operações.")
                                .font(AWTheme.caption(12))
                                .foregroundStyle(AWTheme.textSecondary)
                            
                            AWSecureField(placeholder: "Senha", text: $password)
                            AWSecureField(placeholder: "Confirmar senha", text: $confirmPassword)
                            
                            passwordRequirementsList
                            
                            confirmPasswordRow
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
            syncDefaultRole()
        }
        .onChange(of: hasAdminSlot) { _, _ in
            syncDefaultRole()
        }
    }
    
    private func profileOption(_ role: UserRole) -> some View {
        let isSelected = selectedRole == role
        let adminBlocked = role == .admin && canAssignAdmin && !hasAdminSlot && !isBootstrapAdmin
        let tint = color(for: role)
        
        return Button {
            guard !adminBlocked else { return }
            selectedRole = role
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: role.systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : tint)
                    .frame(width: 36, height: 36)
                    .background((isSelected ? tint : tint.opacity(0.14)))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(role.titulo)
                            .font(AWTheme.headline(15))
                            .foregroundStyle(AWTheme.textPrimary)
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(tint)
                        }
                    }
                    Text(role.descricao)
                        .font(AWTheme.caption(12))
                        .foregroundStyle(AWTheme.textSecondary)
                        .multilineTextAlignment(.leading)
                    
                    if role == .admin && canAssignAdmin {
                        Text("Vagas: \(SessionManager.adminSlotsRemaining(context: context)) de \(SessionManager.maxAdmins)")
                            .font(AWTheme.caption(11))
                            .foregroundStyle(adminBlocked ? AWTheme.warning : AWTheme.textSecondary)
                    }
                }
            }
            .padding(12)
            .background(isSelected ? tint.opacity(0.12) : AWTheme.fieldFill)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? tint : AWTheme.stroke, lineWidth: isSelected ? 1.5 : 1)
            )
            .opacity(adminBlocked ? 0.45 : 1)
        }
        .buttonStyle(.plain)
        .disabled(adminBlocked)
    }
    
    private func color(for role: UserRole) -> Color {
        switch role {
        case .admin: return AWTheme.warning
        case .operador: return AWTheme.moduleEntrega
        case .funcionario: return AWTheme.moduleHistorico
        }
    }
    
    private var passwordRequirementsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("A senha deve conter:")
                .font(AWTheme.caption(12))
                .foregroundStyle(AWTheme.textSecondary)
            
            ForEach(passwordRequirements) { requirement in
                passwordRequirementRow(requirement)
            }
        }
        .padding(.top, 4)
        .animation(.easeInOut(duration: 0.2), value: password)
    }
    
    private func passwordRequirementRow(_ requirement: PasswordPolicy.Requirement) -> some View {
        let tint = requirement.isSatisfied ? AWTheme.success : AWTheme.danger
        return HStack(alignment: .center, spacing: 8) {
            Image(systemName: requirement.isSatisfied ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
            Text(requirement.label)
                .font(AWTheme.caption(12))
                .foregroundStyle(tint)
        }
    }
    
    private var confirmPasswordRow: some View {
        let tint: Color = {
            if confirmPassword.isEmpty { return AWTheme.textSecondary }
            return passwordsMatch ? AWTheme.success : AWTheme.danger
        }()
        let icon: String = {
            if confirmPassword.isEmpty { return "circle" }
            return passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill"
        }()
        let label: String = {
            if confirmPassword.isEmpty { return "Confirme a senha" }
            return passwordsMatch ? "As senhas coincidem" : "As senhas não coincidem"
        }()
        
        return HStack(alignment: .center, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
            Text(label)
                .font(AWTheme.caption(12))
                .foregroundStyle(tint)
        }
        .animation(.easeInOut(duration: 0.2), value: confirmPassword)
        .animation(.easeInOut(duration: 0.2), value: password)
    }
    
    private func syncDefaultRole() {
        if isBootstrapAdmin {
            selectedRole = .admin
            return
        }
        if selectedRole == .admin && (!canAssignAdmin || !hasAdminSlot) {
            selectedRole = .operador
        }
        if !availableRoles.contains(selectedRole) {
            selectedRole = availableRoles.first ?? .operador
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
        
        guard PasswordPolicy.isValid(password) else {
            shouldReturnToLogin = false
            alertMessage = PasswordPolicy.failureMessage
            showAlert = true
            return
        }
        
        var role = selectedRole
        if isBootstrapAdmin {
            role = .admin
        }
        
        if role == .admin && !isBootstrapAdmin {
            guard canAssignAdmin else {
                shouldReturnToLogin = false
                alertMessage = "Somente administradores podem cadastrar outro administrador."
                showAlert = true
                return
            }
            guard hasAdminSlot else {
                shouldReturnToLogin = false
                alertMessage = "Limite de \(SessionManager.maxAdmins) administradores atingido. Cadastre Operador ou Funcionário, ou libere uma vaga em Equipe."
                showAlert = true
                return
            }
        }
        
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
                alertMessage = successMessage(for: role)
                showAlert = true
                clearForm()
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
                    alertMessage = successMessage(for: role)
                    showAlert = true
                    clearForm()
                case .failure(let cadastroError):
                    shouldReturnToLogin = false
                    switch cadastroError {
                    case .camposObrigatorios:
                        alertMessage = "Todos os campos são obrigatórios."
                    case .senhasNaoConferem:
                        alertMessage = "As senhas não coincidem."
                    case .senhaFraca:
                        alertMessage = PasswordPolicy.failureMessage
                    case .emailDuplicado:
                        alertMessage = "E-mail já cadastrado."
                    case .limiteAdmins:
                        alertMessage = "Limite de \(SessionManager.maxAdmins) administradores atingido. Cadastre Operador ou Funcionário, ou libere uma vaga em Equipe."
                    case .erroSalvar:
                        alertMessage = error.localizedDescription
                    }
                    showAlert = true
                }
            }
        }
    }
    
    private func successMessage(for role: UserRole) -> String {
        switch role {
        case .admin:
            return "Administrador cadastrado (\(SessionManager.adminCount(context: context))/\(SessionManager.maxAdmins)). Já disponível nas operações."
        case .operador:
            return "Operador cadastrado com sucesso. Já disponível em Funcionário responsável."
        case .funcionario:
            return "Funcionário cadastrado com sucesso. Já disponível em Funcionário responsável."
        }
    }
    
    private func clearForm() {
        name = ""
        email = ""
        phone = ""
        password = ""
        confirmPassword = ""
        syncDefaultRole()
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
