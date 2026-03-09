import SwiftUI
import SwiftData
import Foundation

struct AutoWiseCadastro: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var context

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isAdmin: Bool = false
    @State private var navigateToHome: Bool = false
    @State private var navigateToLogin: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    private let cadastroController = AutoWiseCadastroController()
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    
                    Section(header: Text("Informações Pessoais").font(.headline).foregroundColor(.primary)) {
                        TextField("Digite seu nome completo", text: $name)
                            .autocapitalization(.words)
                            .padding(.vertical, 8)
                            .textFieldStyle(.roundedBorder)
                        
                        /* TextField("Digite seu e-mail", text: $email)
                         .keyboardType(.emailAddress)
                         .autocapitalization(.none)
                         .padding(.vertical, 8)
                         .textFieldStyle(.roundedBorder) */
                        
                        TextField("Digite seu telefone", text: $phone)
                            .keyboardType(.phonePad)
                            .padding(.vertical, 8)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Seção de Configurações de Conta
                    Section(header: Text("Configurações de Conta").font(.headline).foregroundColor(.primary)) {
                        SecureField("Crie uma senha", text: $password)
                            .padding(.vertical, 8)
                            .textFieldStyle(.roundedBorder)
                        
                        SecureField("Confirme sua senha", text: $confirmPassword)
                            .padding(.vertical, 8)
                            .textFieldStyle(.roundedBorder)
                        
                        Toggle(isOn: $isAdmin) {
                            Text("Conta Administrativa")
                        }
                        .tint(.accentColor)
                    }
                    
                    // Seção de Ações (botões estilizados)
                    Section {
                        // Botão Salvar
                        Button(action: handleSave) {
                            Text("Salvar")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: colorScheme == .dark ? .gray.opacity(0.3) : .black.opacity(0.2), radius: 5, x: 0, y: 3)
                        }
                        .padding(.vertical, 8)
                        .scaleEffect(name.isEmpty || email.isEmpty || password.isEmpty ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: name.isEmpty || email.isEmpty || password.isEmpty)
                        .disabled(name.isEmpty || email.isEmpty || password.isEmpty)
                        
                        // Botão Cancelar
                        Button(action: handleCancel) {
                            Text("Cancelar")
                                .font(.headline)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    colorScheme == .dark ?
                                    Color.gray.opacity(0.2) :
                                        Color.red.opacity(0.1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.red, lineWidth: 1)
                                )
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
                .background(
                    colorScheme == .dark ?
                    LinearGradient(gradient: Gradient(colors: [.gray.opacity(0.3), .black]), startPoint: .top, endPoint: .bottom) :
                        LinearGradient(gradient: Gradient(colors: [.white, .gray.opacity(0.1)]), startPoint: .top, endPoint: .bottom)
                )
            }
            .navigationTitle("Cadastro de Usuário")
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("AutoWise"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"), action: {
                        // Ação adicional se necessário
                    })
                )
            }
            .navigationDestination(isPresented: $navigateToHome) {
                UsersListView()
            }
            }
            .navigationDestination(isPresented: $navigateToLogin) {
                AutoWiseLogin()
            }
        }
    }
    
    // Funções handleSave e handleCancel (mantidas)
    
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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                navigateToHome = true
            }
            
        case .failure(let error):
            
            switch error {
            case .camposObrigatorios:
                alertMessage = "Todos os campos são obrigatórios."
            case .senhasNaoConferem:
                alertMessage = "As senhas não coincidem."
            case .emailDuplicado:
                alertMessage = "Email já cadastrado."
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
    
    private func handleCancel() {
        alertMessage = "Cadastro cancelado. Voltando para o login."
        showAlert = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            navigateToLogin = true
        }
    }
    
    // Tela de destino (mantida)
    struct HomeCheckListView: View {
        var body: some View {
            Text("Bem-vindo à HomeCheckList!")
                .font(.largeTitle)
                .padding()
        }
    }
    
    // Preview
    struct AutoWiseCadastroView_Previews: PreviewProvider {
        static var previews: some View {
            Group {
                AutoWiseCadastro()
                    .preferredColorScheme(.dark)
                
                AutoWiseCadastro()
                    .preferredColorScheme(.light)
            }
        }
    }

