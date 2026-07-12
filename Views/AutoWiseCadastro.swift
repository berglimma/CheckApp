import SwiftUI
import SwiftData
import Foundation

struct AutoWiseCadastro: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isAdmin: Bool = false
    @State private var navigateToUsers: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    private let cadastroController = AutoWiseCadastroController()
    
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
                        subtitle: "Crie acessos para a equipe"
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
                            
                            Toggle(isOn: $isAdmin) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Conta administrativa")
                                        .font(AWTheme.headline(15))
                                        .foregroundStyle(AWTheme.textPrimary)
                                    Text("Acesso completo às operações")
                                        .font(AWTheme.caption(12))
                                        .foregroundStyle(AWTheme.textSecondary)
                                }
                            }
                            .tint(AWTheme.accent)
                            .padding(.top, 4)
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
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .navigationDestination(isPresented: $navigateToUsers) {
            UsersListView()
        }
    }
    
    private func handleSave() {
        guard isValidEmail(email) else {
            alertMessage = "Formato de e-mail inválido."
            showAlert = true
            return
        }
        
        let role: UserRole = isAdmin ? .admin : .normal
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
            alertMessage = "Conta criada com sucesso."
            showAlert = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                navigateToUsers = true
            }
        case .failure(let error):
            switch error {
            case .camposObrigatorios:
                alertMessage = "Todos os campos são obrigatórios."
            case .senhasNaoConferem:
                alertMessage = "As senhas não coincidem."
            case .emailDuplicado:
                alertMessage = "E-mail já cadastrado."
            case .erroSalvar:
                alertMessage = "Erro ao salvar usuário."
            }
            showAlert = true
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
    .modelContainer(for: [User.self], inMemory: true)
}
