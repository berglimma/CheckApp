//
//  MessageNotifyService.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import Foundation
import MessageUI
import SwiftUI
import UIKit

/// Tipos de aviso enviados por SMS/iMessage e e-mail.
enum NotifyKind: String {
    case reservaAberta = "Reserva aberta"
    case reservaAlterada = "Alteração na reserva"
    case manutencao = "Aviso de manutenção"
    case trator = "Avaliação de trator"
    case devolucao = "Devolução de veículo"
    case avarias = "Registro de avarias"
    case movimentacao = "Movimentação"
}

struct MessageComposePayload: Identifiable, Equatable {
    let id = UUID()
    var recipients: [String]
    var body: String
    var subject: String
    var emailRecipients: [String]
    
    var hasSMS: Bool {
        !recipients.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.isEmpty
            && MFMessageComposeViewController.canSendText()
    }
    
    var hasEmail: Bool {
        !emailRecipients.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.isEmpty
            && MFMailComposeViewController.canSendMail()
    }
}

enum MessageNotifyService {
    
    static func payloadReservaAberta(
        numero: String,
        cliente: String,
        telefone: String,
        email: String,
        placa: String,
        marca: String,
        modelo: String
    ) -> MessageComposePayload {
        let body = """
        Auto Wize — \(NotifyKind.reservaAberta.rawValue)
        
        Olá \(cliente.isEmpty ? "cliente" : cliente),
        
        Sua reserva \(numero) foi aberta.
        Veículo: \(marca) \(modelo) — Placa \(placa)
        
        Em caso de dúvidas, responda esta mensagem.
        """
        return MessageComposePayload(
            recipients: sanitizedPhones(telefone),
            body: body,
            subject: "Auto Wize — Reserva \(numero) aberta",
            emailRecipients: sanitizedEmails(email)
        )
    }
    
    static func payloadReservaAlterada(
        numero: String,
        cliente: String,
        telefone: String,
        email: String,
        detalhe: String
    ) -> MessageComposePayload {
        let body = """
        Auto Wize — \(NotifyKind.reservaAlterada.rawValue)
        
        Olá \(cliente.isEmpty ? "cliente" : cliente),
        
        Houve uma atualização na reserva \(numero):
        \(detalhe)
        
        Em caso de dúvidas, responda esta mensagem.
        """
        return MessageComposePayload(
            recipients: sanitizedPhones(telefone),
            body: body,
            subject: "Auto Wize — Alteração na reserva \(numero)",
            emailRecipients: sanitizedEmails(email)
        )
    }
    
    static func payloadManutencao(
        numero: String,
        cliente: String,
        telefone: String,
        email: String,
        placa: String,
        motivo: String
    ) -> MessageComposePayload {
        let body = """
        Auto Wize — \(NotifyKind.manutencao.rawValue)
        
        Olá \(cliente.isEmpty ? "cliente" : cliente),
        
        O veículo da reserva \(numero) (placa \(placa)) entrou em manutenção.
        Motivo: \(motivo)
        
        Um veículo provisório poderá ser disponibilizado. Acompanhe pelo app.
        """
        return MessageComposePayload(
            recipients: sanitizedPhones(telefone),
            body: body,
            subject: "Auto Wize — Manutenção reserva \(numero)",
            emailRecipients: sanitizedEmails(email)
        )
    }
    
    static func payloadTrator(
        cliente: String,
        telefone: String,
        email: String,
        marca: String,
        modelo: String,
        identificacao: String,
        aprovado: Bool,
        condicao: String
    ) -> MessageComposePayload {
        let status = aprovado ? "APROVADO para uso" : "NÃO aprovado para uso"
        let body = """
        Auto Wize — \(NotifyKind.trator.rawValue)
        
        Olá \(cliente.isEmpty ? "cliente" : cliente),
        
        A avaliação do trator \(marca) \(modelo) (\(identificacao)) foi registrada.
        Condição: \(condicao)
        Status: \(status)
        
        Este aviso foi enviado ao contato vinculado (SMS/iMessage e e-mail).
        """
        return MessageComposePayload(
            recipients: sanitizedPhones(telefone),
            body: body,
            subject: "Auto Wize — Avaliação trator \(identificacao)",
            emailRecipients: sanitizedEmails(email)
        )
    }
    
    static func payloadDevolucao(
        cliente: String,
        telefone: String,
        email: String,
        placa: String,
        marca: String,
        modelo: String,
        kmRetorno: String,
        possuiAvarias: Bool
    ) -> MessageComposePayload {
        let avariasTxt = possuiAvarias ? "Foram registradas avarias no retorno." : "Sem avarias novas registradas."
        let body = """
        Auto Wize — \(NotifyKind.devolucao.rawValue)
        
        Olá \(cliente.isEmpty ? "cliente" : cliente),
        
        A devolução do veículo \(marca) \(modelo) (placa \(placa)) foi registrada.
        KM no retorno: \(kmRetorno.isEmpty ? "-" : kmRetorno)
        \(avariasTxt)
        
        Este aviso foi enviado ao e-mail/telefone vinculados ao cliente.
        """
        return MessageComposePayload(
            recipients: sanitizedPhones(telefone),
            body: body,
            subject: "Auto Wize — Devolução \(placa)",
            emailRecipients: sanitizedEmails(email)
        )
    }
    
    static func payloadAvarias(
        cliente: String,
        telefone: String,
        email: String,
        placa: String,
        veiculo: String,
        total: String,
        detalhe: String
    ) -> MessageComposePayload {
        let body = """
        Auto Wize — \(NotifyKind.avarias.rawValue)
        
        Olá \(cliente.isEmpty ? "cliente" : cliente),
        
        Foi registrado um relatório de avarias para \(veiculo.isEmpty ? "o veículo" : veiculo) (placa \(placa)).
        Total: \(total)
        
        \(detalhe)
        
        Este aviso foi enviado ao contato vinculado ao cliente.
        """
        return MessageComposePayload(
            recipients: sanitizedPhones(telefone),
            body: body,
            subject: "Auto Wize — Avarias \(placa)",
            emailRecipients: sanitizedEmails(email)
        )
    }
    
    /// Aviso genérico de qualquer movimentação vinculada ao cliente.
    static func payloadMovimentacao(
        tipo: String,
        cliente: String,
        telefone: String,
        email: String,
        detalhe: String
    ) -> MessageComposePayload {
        let body = """
        Auto Wize — \(NotifyKind.movimentacao.rawValue)
        
        Olá \(cliente.isEmpty ? "cliente" : cliente),
        
        Movimentação: \(tipo)
        \(detalhe)
        
        Este aviso foi enviado automaticamente ao contato vinculado.
        """
        return MessageComposePayload(
            recipients: sanitizedPhones(telefone),
            body: body,
            subject: "Auto Wize — \(tipo)",
            emailRecipients: sanitizedEmails(email)
        )
    }
    
    private static func sanitizedPhones(_ raw: String) -> [String] {
        let cleaned = raw
            .components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined()
        return cleaned.isEmpty ? [] : [cleaned]
    }
    
    private static func sanitizedEmails(_ raw: String) -> [String] {
        let email = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return email.contains("@") ? [email] : []
    }
}

// MARK: - SwiftUI wrappers (SMS/iMessage + Mail)

struct MessageComposerRepresentable: UIViewControllerRepresentable {
    let payload: MessageComposePayload
    var onFinish: () -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        // Prioridade: SMS/iMessage se houver telefone; senão e-mail
        if payload.hasSMS {
            let vc = MFMessageComposeViewController()
            vc.messageComposeDelegate = context.coordinator
            vc.recipients = payload.recipients
            vc.body = payload.body
            return vc
        }
        
        if payload.hasEmail {
            let vc = MFMailComposeViewController()
            vc.mailComposeDelegate = context.coordinator
            vc.setToRecipients(payload.emailRecipients)
            vc.setSubject(payload.subject)
            vc.setMessageBody(payload.body, isHTML: false)
            return vc
        }
        
        let fallback = UIViewController()
        DispatchQueue.main.async { onFinish() }
        return fallback
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate {
        let onFinish: () -> Void
        
        init(onFinish: @escaping () -> Void) {
            self.onFinish = onFinish
        }
        
        func messageComposeViewController(
            _ controller: MFMessageComposeViewController,
            didFinishWith result: MessageComposeResult
        ) {
            controller.dismiss(animated: true) { [onFinish] in
                onFinish()
            }
        }
        
        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            controller.dismiss(animated: true) { [onFinish] in
                onFinish()
            }
        }
    }
}

/// Oferece envio por SMS/iMessage e, em seguida, e-mail se ambos estiverem disponíveis.
struct NotifyComposeSheet: View {
    let payload: MessageComposePayload
    var onFinishedAll: () -> Void
    
    @State private var stage: Stage = .sms
    @State private var showUnavailable = false
    
    private enum Stage {
        case sms, email, done
    }
    
    var body: some View {
        Group {
            switch stage {
            case .sms:
                if payload.hasSMS {
                    MessageComposerRepresentable(payload: payload) {
                        stage = payload.hasEmail ? .email : .done
                        if stage == .done { onFinishedAll() }
                    }
                } else if payload.hasEmail {
                    Color.clear.onAppear { stage = .email }
                } else {
                    unavailableView
                }
            case .email:
                if payload.hasEmail {
                    // Força composer de e-mail
                    MailOnlyComposer(payload: payload) {
                        stage = .done
                        onFinishedAll()
                    }
                } else {
                    Color.clear.onAppear {
                        stage = .done
                        onFinishedAll()
                    }
                }
            case .done:
                Color.clear.onAppear(perform: onFinishedAll)
            }
        }
    }
    
    private var unavailableView: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Não foi possível abrir SMS/iMessage ou Mail neste dispositivo.")
                    .font(AWTheme.body(15))
                    .foregroundStyle(AWTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Text(payload.body)
                    .font(AWTheme.caption(12))
                    .foregroundStyle(AWTheme.textSecondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AWTheme.fieldFill)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                AWPrimaryButton(title: "OK") { onFinishedAll() }
            }
            .padding()
            .background(AWTheme.screenGray)
        }
    }
}

private struct MailOnlyComposer: UIViewControllerRepresentable {
    let payload: MessageComposePayload
    var onFinish: () -> Void
    
    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(payload.emailRecipients)
        vc.setSubject(payload.subject)
        vc.setMessageBody(payload.body, isHTML: false)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onFinish: () -> Void
        init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
        
        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            controller.dismiss(animated: true) { [onFinish] in onFinish() }
        }
    }
}
