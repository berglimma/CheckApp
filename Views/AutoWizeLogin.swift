import SwiftUI

struct AutoWiseLogin: View {
    @State private var alertMessage: String = ""
    @State private var isAnimating: Bool = false
    @State private var navigateToHome: Bool = false
    @State private var navigateToRegister: Bool = false
    @State private var showAlert: Bool = false
    
    @State private var viewModel = LoginViewModel()
    
    
    @Environment(\.modelContext) private var context
    @EnvironmentObject var session: SessionManager
    

    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack { 
            VStack {
                Spacer()
                
                // Ícone principal com animação
                Image(systemName: "checkmark.seal.text.page")
                    .font(.system(size: 170))
                    .foregroundColor(colorScheme == .dark ? .green : .black)
                    .padding(.bottom, 20)
                    .offset(x: isAnimating ? 10 : -10)
                    .scaleEffect(isAnimating ? 1.05 : 0.95)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                // Título e Subtítulo
                Text("Auto Wize")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .green : .black)
                    .padding(.bottom, 20)
                
                Text("Checklists Inteligentes para o Seu Negócio")
                    .font(.system(size: 18.5, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.bottom, 40)
                
                Spacer()
                
                // Campos de texto
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Usuário:")
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                      //  TextField("Senha", text: $username)
                            .padding(12)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(20.0)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.black, lineWidth: 2)
                            )
                            .frame(width: 300)
                            .font(.system(size: 18, weight: .regular))
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Senha:")
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                      //SecureField("", text: $password)
                            .padding(12)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(20.0)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.black, lineWidth: 2)
                            )
                            .frame(width: 300)
                            .font(.system(size: 18, weight: .regular))
                            .disableAutocorrection(true)
                    }
                }
                .padding(.bottom, 30)
                
                // Botões de ação
                HStack(spacing: 16) {
                    // Botão de Login
                    Button(action: {
                        if let user = viewModel.login(context:context) {
                            session.currentUser = user
                            navigateToHome = true
                        } else {
                            alertMessage = viewModel.errorMessage ?? "Usuário ou Senha Inválidos."
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
            .navigationDestination(isPresented: $navigateToHome) { 
                HomeCheckList()
            }
            .navigationDestination(isPresented: $navigateToRegister) {
                AutoWiseCadastro()
            }
            
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(colorScheme == .dark ? Color.black : Color.white)
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
