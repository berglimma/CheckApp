//
//  EsqueciSenhaView.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import SwiftUI
import SwiftData
import MessageUI

struct EsqueciSenhaView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @State private var email = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var shouldDismiss = false
    @State private var messagePayload: MessageComposePayload?
    
    var initialEmail: String = ""
    
    var body: some View {
        ZStack {
            AWScreenBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    AWScreenTitle(
                        title: "Recuperar senha",
                        subtitle: "Enviaremos um link ou código para o seu contato"
                    )
                    
                    AWSectionCard(title: "Conta") {
                        VStack(spacing: 12) {
                            AWTextField(
                                placeholder: "E-mail cadastrado",
                                text: $email,
                                keyboard: .emailAddress,
                                autocapitalization: .never
                            )
                            
                            Text("Com Firebase, você recebe um e-mail com link. Em modo local, o código temporário é enviado por SMS/iMessage ou e-mail — não é exibido na tela.")
                                .font(AWTheme.caption(12))
                                .foregroundStyle(AWTheme.textSecondary)
                        }
                    }
                    
                    VStack(spacing: 10) {
                        AWPrimaryButton(
                            title: "Enviar recuperação",
                            isLoading: isLoading,
                            isDisabled: email.trimmingCharacters(in: .whitespaces).isEmpty
                        ) {
                            Task { await enviar() }
                        }
                        
                        AWSecondaryButton(title: "Voltar ao login") {
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
        .onAppear {
            if email.isEmpty { email = initialEmail }
            AuthService.shared.configureIfNeeded()
        }
        .alert("Auto Wize", isPresented: $showAlert) {
            Button("OK") {
                if shouldDismiss { dismiss() }
            }
        } message: {
            Text(alertMessage)
        }
        .sheet(item: $messagePayload) { payload in
            MessageComposerRepresentable(payload: payload) {
                messagePayload = nil
                showAlert = true
            }
        }
    }
    
    private func enviar() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await AuthService.shared.sendPasswordReset(
                email: email,
                context: context
            )
            
            switch result {
            case .firebaseEmailSent:
                alertMessage = "E-mail de recuperação enviado. Verifique sua caixa de entrada."
                shouldDismiss = true
                showAlert = true
                
            case .localTemporaryPassword(let code, let phone, let name):
                let body = """
                Auto Wize — Recuperação de senha
                
                Olá \(name.isEmpty ? "!" : name),
                Seu código temporário de acesso é: \(code)
                
                Use este código como senha no app e altere assim que entrar.
                """
                
                let payload = MessageComposePayload(
                    recipients: phone.isEmpty ? [] : [phone],
                    body: body,
                    subject: "Auto Wize — Recuperação de senha",
                    emailRecipients: [email]
                )
                
                if payload.hasSMS || payload.hasEmail {
                    alertMessage = "Código temporário gerado. Confirme o envio por SMS/iMessage ou e-mail — ele não será mostrado nesta tela."
                    shouldDismiss = true
                    messagePayload = payload
                } else {
                    alertMessage = "Código gerado, mas este dispositivo não pode enviar SMS/iMessage nem e-mail. Configure o app Mensagens/Mail ou contate o administrador."
                    shouldDismiss = false
                    showAlert = true
                }
            }
        } catch {
            shouldDismiss = false
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}

#Preview {
    NavigationStack {
        EsqueciSenhaView()
    }
    .modelContainer(for: [User.self], inMemory: true)
}
