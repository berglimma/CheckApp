import SwiftUI

struct AutoWiseLogin: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isAnimating: Bool = false
    @State private var navigateToHome: Bool = false
    @State private var navigateToRegister: Bool = false
    @State private var showAlert: Bool = false // Estado para mostrar alerta
    @State private var alertMessage: String = "" // Mensagem do alerta

    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack { // 🔹 Substitui NavigationView por NavigationStack
            VStack {
                Spacer()
                
                // Ícone principal com animação
                Image(systemName: "checklist.checked")
                    .font(.system(size: 160))
                    .foregroundColor(.green)
                    .padding(.bottom, 20)
                    .offset(x: isAnimating ? 10 : -10)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                // Título e Subtítulo
                Text("CheckLock")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.yellow)
                    .padding(.bottom, 20)
                
                Text("Checklists Inteligentes para o Seu Negócio")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.bottom, 40)
                
                Spacer()
                
                // Campos de texto
                VStack(spacing: 16) {
                    TextField("Usuário", text: $username)
                        .padding(12)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(20.0)
                        .frame(width: 300)
                        .font(.system(size: 18, weight: .regular))
                    
                    SecureField("Senha", text: $password)
                        .padding(12)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(20.0)
                        .frame(width: 300)
                        .font(.system(size: 18, weight: .regular))
                        .disableAutocorrection(true)
                }
                .padding(.bottom, 30)
                
                // Botões de ação
                HStack(spacing: 16) {
                    // Botão de Login
                    Button(action: {
                        if username.isEmpty || password.isEmpty {
                            alertMessage = "Por favor, insira o usuário e a senha."
                            showAlert = true
                        } else if DatabaseManager.shared.validateUser(email: username, password: password) {
                            navigateToHome = true
                        } else {
                            alertMessage = "Usuário ou senha inválidos."
                            showAlert = true
                        }
                    }) {
                        Text("Entrar")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 140, height: 50)
                            .background(Color.green)
                            .cornerRadius(25.0)
                    }
                    
                    // Botão de Cadastro
                    Button(action: {
                        navigateToRegister = true
                    }) {
                        Text("Cadastrar")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 140, height: 50)
                            .background(Color.orange)
                            .cornerRadius(25.0)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Aviso"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                isAnimating = true
            }
            .navigationDestination(isPresented: $navigateToHome) { // 🔹 Substitui NavigationLink(isActive:)
                HomeCheckList()
            }
            .navigationDestination(isPresented: $navigateToRegister) {
                AutoWiseCadastro()
            }
        }
    }
}

struct HomeCheckList: View {
    var body: some View {
        Text("Bem-vindo à HomeCheckList!")
            .font(.largeTitle)
            .padding()
    }
}

struct AutoWiseLogin_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AutoWiseLogin()
                .preferredColorScheme(.dark)
            
            AutoWiseLogin()
                .preferredColorScheme(.light)
        }
    }
}
