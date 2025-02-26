import SwiftUI

struct AutoWiseCadastro: View {
    @Environment(\.colorScheme) var colorScheme
    
    // Variáveis de estado
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
        NavigationStack { // 🔹 Substitui NavigationView por NavigationStack
            VStack {
                Form {
                    // Seção de Informações Pessoais
                    Section(header: Text("Informações Pessoais")) {
                        TextField("Digite seu nome completo", text: $name)
                            .autocapitalization(.words)
                            .padding(.vertical, 5)
                        
                        TextField("Digite seu e-mail", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(.vertical, 5)
                        
                        TextField("Digite seu telefone", text: $phone)
                            .keyboardType(.phonePad)
                            .padding(.vertical, 5)
                    }
                    
                    // Seção de Configurações de Conta
                    Section(header: Text("Configurações de Conta")) {
                        SecureField("Crie uma senha", text: $password)
                            .padding(.vertical, 5)
                        
                        SecureField("Confirme sua senha", text: $confirmPassword)
                            .padding(.vertical, 5)
                        
                        Toggle(isOn: $isAdmin) {
                            Text("Conta Administrativa")
                        }
                    }
                    
                    // Seção de Ações
                    Section {
                        Button(action: handleSave) {
                            Text("Salvar")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.vertical, 5)
                        
                        Button(action: handleCancel) {
                            Text("Cancelar")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            .navigationTitle("Cadastro de Usuário")
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("AutoWise"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .navigationDestination(isPresented: $navigateToHome) { // 🔹 Substitui NavigationLink(isActive:)
                HomeCheckListView()
            }
            .navigationDestination(isPresented: $navigateToLogin) {
                AutoWiseLogin()
            }
        }
    }
    
    // Função para salvar o cadastro
    private func handleSave() {
        if cadastroController.saveUser(
            name: name,
            email: email,
            phone: phone,
            password: password,
            confirmPassword: confirmPassword,
            isAdmin: isAdmin
        ) {
            alertMessage = "Pronto! Sua conta foi criada com sucesso. Vamos começar a trabalhar!"
            showAlert = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                navigateToHome = true
            }
        } else {
            alertMessage = "Houve um erro ao cadastrar. Verifique os dados informados e tente novamente."
            showAlert = true
        }
    }
    
    // Função para cancelar o cadastro
    private func handleCancel() {
        alertMessage = "Cadastro cancelado. Voltando para o login."
        showAlert = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            navigateToLogin = true
        }
    }
    
    // Tela de destino
    struct HomeCheckListView: View {
        var body: some View {
            Text("Bem-vindo à HomeCheckList!")
                .font(.largeTitle)
                .padding()
        }
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
