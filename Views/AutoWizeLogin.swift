import SwiftUI
import SwiftData

struct AutoWiseLogin: View {
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var navigateToRegister: Bool = false
    @State private var isLoading: Bool = false
    
    @State private var viewModel = LoginViewModel()
    
    @State private var showBrand = false
    @State private var showHero = false
    @State private var showForm = false
    @State private var inspectionIndex = 0
    
    @Environment(\.modelContext) private var context
    @EnvironmentObject var session: SessionManager
    
    private let inspectionIcons = [
        "car.fill",
        "checklist",
        "fuelpump.fill",
        "checkmark.seal.fill"
    ]
    
    private let inspectionLabels = [
        "Veículo",
        "Checklist",
        "Combustível",
        "Conferência"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AWScreenBackground()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        brandHeader
                            .padding(.top, 24)
                            .opacity(showBrand ? 1 : 0)
                        
                        inspectionHero
                            .opacity(showHero ? 1 : 0)
                        
                        Text("Checklists inteligentes para o seu negócio")
                            .font(AWTheme.body(15))
                            .foregroundStyle(AWTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .opacity(showHero ? 1 : 0)
                        
                        loginForm(viewModel: viewModel)
                            .padding(.top, 8)
                            .opacity(showForm ? 1 : 0)
                        
                        SocialLoginCards()
                            .padding(.horizontal, 4)
                            .opacity(showForm ? 1 : 0)
                        
                        Spacer(minLength: 32)
                    }
                    .awReadableWidth(AWLayout.loginMaxWidth)
                }
            }
            .alert("Aviso", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .navigationDestination(isPresented: $navigateToRegister) {
                AutoWiseCadastro()
            }
            .onAppear {
                startEntrance()
                AuthService.shared.configureIfNeeded()
            }
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 2_200_000_000)
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                        inspectionIndex = (inspectionIndex + 1) % inspectionIcons.count
                    }
                }
            }
        }
    }
    
    private var brandHeader: some View {
        VStack(spacing: 6) {
            Text("Auto Wize")
                .font(AWTheme.brand(40))
                .foregroundStyle(AWTheme.textPrimary)
            
            Text("FLEET CHECKLISTS")
                .font(AWTheme.caption(11))
                .tracking(2.4)
                .foregroundStyle(AWTheme.accent)
        }
    }
    
    private var inspectionHero: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AWTheme.fieldFill)
                    .frame(width: 112, height: 112)
                    .shadow(color: Color.black.opacity(0.06), radius: 8, y: 3)
                
                Circle()
                    .stroke(AWTheme.accent.opacity(0.3), lineWidth: 2)
                    .frame(width: 112, height: 112)
                
                Image(systemName: inspectionIcons[inspectionIndex])
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(AWTheme.accent)
                    .id(inspectionIndex)
                    .transition(.opacity)
            }
            .animation(.easeInOut(duration: 0.3), value: inspectionIndex)
            
            Text(inspectionLabels[inspectionIndex])
                .font(AWTheme.headline(14))
                .foregroundStyle(AWTheme.textSecondary)
                .frame(height: 20)
            
            HStack(spacing: 6) {
                ForEach(0..<inspectionIcons.count, id: \.self) { i in
                    Capsule()
                        .fill(i == inspectionIndex ? AWTheme.accent : AWTheme.accent.opacity(0.25))
                        .frame(width: i == inspectionIndex ? 16 : 6, height: 6)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func loginForm(viewModel: LoginViewModel) -> some View {
        @Bindable var viewModel = viewModel
        
        return VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("E-mail")
                    .font(AWTheme.caption(12))
                    .foregroundStyle(AWTheme.textSecondary)
                AWTextField(
                    placeholder: "seu@email.com",
                    text: $viewModel.email,
                    keyboard: .emailAddress,
                    autocapitalization: .never
                )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Senha")
                    .font(AWTheme.caption(12))
                    .foregroundStyle(AWTheme.textSecondary)
                AWSecureField(placeholder: "••••••••", text: $viewModel.password)
            }
            
            AWPrimaryButton(
                title: "Entrar",
                isLoading: isLoading,
                isDisabled: viewModel.email.isEmpty || viewModel.password.isEmpty
            ) {
                Task { await performLogin() }
            }
            .padding(.top, 4)
            
            AWSecondaryButton(title: "Criar conta", tint: AWTheme.warning) {
                navigateToRegister = true
            }
        }
        .padding(16)
        .background(AWTheme.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: AWTheme.radiusL, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AWTheme.radiusL, style: .continuous)
                .stroke(AWTheme.stroke, lineWidth: 1)
        )
    }
    
    private func performLogin() async {
        isLoading = true
        do {
            let user = try await AuthService.shared.loginEmail(
                email: viewModel.email,
                password: viewModel.password,
                context: context
            )
            session.currentUser = user
        } catch {
            // fallback viewModel local
            if let user = viewModel.login(context: context) {
                session.currentUser = user
            } else {
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
        isLoading = false
    }
    
    private func startEntrance() {
        withAnimation(.easeOut(duration: 0.4)) { showBrand = true }
        withAnimation(.easeOut(duration: 0.4).delay(0.12)) { showHero = true }
        withAnimation(.easeOut(duration: 0.4).delay(0.24)) { showForm = true }
    }
}

#Preview {
    AutoWiseLogin()
        .environmentObject(SessionManager())
        .modelContainer(for: [User.self], inMemory: true)
}
