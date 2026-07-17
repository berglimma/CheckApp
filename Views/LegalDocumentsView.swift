//
//  LegalDocumentsView.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import SwiftUI

enum LegalDocument: String, Identifiable, CaseIterable {
    case privacy
    case terms
    case support
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .privacy: return "Política de Privacidade"
        case .terms: return "Termos de Uso"
        case .support: return "Suporte"
        }
    }
    
    var subtitle: String {
        switch self {
        case .privacy: return "LGPD · Auto Wize"
        case .terms: return "Condições de uso do app"
        case .support: return "Ajuda e contato"
        }
    }
    
    var systemImage: String {
        switch self {
        case .privacy: return "hand.raised.fill"
        case .terms: return "doc.text.fill"
        case .support: return "questionmark.circle.fill"
        }
    }
    
    var publicURL: URL {
        switch self {
        case .privacy: return AppStoreLinks.privacyPolicy
        case .terms: return AppStoreLinks.termsOfUse
        case .support: return AppStoreLinks.support
        }
    }
}

struct LegalDocumentsView: View {
    let document: LegalDocument
    
    var body: some View {
        ZStack {
            AWScreenBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    AWScreenTitle(
                        title: document.title,
                        subtitle: document.subtitle
                    )
                    
                    ForEach(sections) { section in
                        AWSectionCard(title: section.title) {
                            Text(section.body)
                                .font(AWTheme.body(14))
                                .foregroundStyle(AWTheme.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    if document == .support {
                        AWSectionCard(title: "Contato") {
                            VStack(spacing: 10) {
                                Link(destination: URL(string: "mailto:\(AppStoreLinks.supportEmail)?subject=Suporte%20Auto%20Wize")!) {
                                    HStack {
                                        Image(systemName: "envelope.fill")
                                        Text(AppStoreLinks.supportEmail)
                                            .font(AWTheme.headline(14))
                                        Spacer()
                                        Image(systemName: "arrow.up.right")
                                    }
                                    .foregroundStyle(AWTheme.accent)
                                }
                                
                                Text("Resposta em até 2 dias úteis (horário de Brasília).")
                                    .font(AWTheme.caption(12))
                                    .foregroundStyle(AWTheme.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        
                        AWSectionCard(title: "Documentos no app") {
                            VStack(spacing: 8) {
                                NavigationLink {
                                    LegalDocumentsView(document: .privacy)
                                } label: {
                                    legalNavRow(title: "Política de Privacidade", systemImage: "hand.raised.fill")
                                }
                                .buttonStyle(.plain)
                                
                                NavigationLink {
                                    LegalDocumentsView(document: .terms)
                                } label: {
                                    legalNavRow(title: "Termos de Uso", systemImage: "doc.text.fill")
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    Text("Última atualização: julho/2026")
                        .font(AWTheme.caption(11))
                        .foregroundStyle(AWTheme.textSecondary)
                        .padding(.top, 4)
                }
                .awReadableWidth(AWLayout.formMaxWidth)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AWTheme.screenGray, for: .navigationBar)
    }
    
    private var sections: [LegalSection] {
        switch document {
        case .privacy: return LegalCopy.privacySections
        case .terms: return LegalCopy.termsSections
        case .support: return LegalCopy.supportSections
        }
    }
    
    private func legalNavRow(title: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(AWTheme.accent)
            Text(title)
                .font(AWTheme.headline(14))
                .foregroundStyle(AWTheme.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AWTheme.textSecondary.opacity(0.5))
        }
        .padding(.vertical, 8)
    }
}

private struct LegalSection: Identifiable {
    var id: String { title }
    let title: String
    let body: String
}

/// Textos oficiais exibidos no app (espelhados nas páginas públicas HTTPS).
private enum LegalCopy {
    static let privacySections: [LegalSection] = [
        .init(
            title: "1. Controlador e finalidade",
            body: "O Auto Wize trata dados pessoais para operação de checklists de frota (entrega, devolução, troca provisória, avarias e avaliação de tratores), autenticação de usuários, gestão de reservas e envio de avisos operacionais ao cliente."
        ),
        .init(
            title: "2. Dados tratados",
            body: """
            • Conta: nome, e-mail, telefone e credenciais de acesso (administrador ou operador).
            • Operações: nome/documento do cliente (incluindo CPF), telefone, e-mail, placa, marca/modelo, quilometragem, fotos, assinaturas, nº de reserva e observações.
            • Identificadores técnicos necessários ao funcionamento do app (ex.: preferências locais).
            """
        ),
        .init(
            title: "3. Base legal (LGPD)",
            body: "Tratamos dados com base na execução de contrato/procedimentos preliminares e no legítimo interesse para segurança operacional da frota, observados os direitos do titular previstos na Lei Geral de Proteção de Dados (Lei nº 13.709/2018)."
        ),
        .init(
            title: "4. Compartilhamento",
            body: "Dados podem ser enviados ao próprio cliente via SMS/iMessage ou e-mail quando uma movimentação é registrada. A autenticação pode usar Firebase Auth, Sign in with Apple ou Google, conforme o método escolhido. Não vendemos dados pessoais."
        ),
        .init(
            title: "5. Armazenamento e retenção",
            body: "Os dados ficam no dispositivo (SwiftData/arquivos locais) e, quando aplicável, em serviços de autenticação. Mantemos enquanto houver necessidade operacional, obrigação legal ou até a exclusão da conta pelo titular."
        ),
        .init(
            title: "6. Direitos do titular e exclusão",
            body: "Você pode solicitar acesso, correção e exclusão. No app: Meu perfil → Excluir minha conta remove a conta e também os dados operacionais locais neste dispositivo (históricos, CPF/documentos de clientes, telefones, e-mails, fotos, assinaturas e reservas)."
        ),
        .init(
            title: "7. Segurança",
            body: "Senhas locais são armazenadas com hash. Recomendamos senhas fortes e não compartilhar códigos de recuperação. Contas administrativas são limitadas (máximo de 5) e gerenciadas pela equipe."
        ),
        .init(
            title: "8. Contato",
            body: "Privacidade e LGPD: \(AppStoreLinks.supportEmail)\nNo app: Meu perfil → Suporte."
        )
    ]
    
    static let termsSections: [LegalSection] = [
        .init(
            title: "1. Aceitação",
            body: "Ao usar o Auto Wize, você concorda com estes Termos de Uso e com a Política de Privacidade disponíveis no aplicativo."
        ),
        .init(
            title: "2. Uso permitido",
            body: "O app destina-se a equipes autorizadas para registro de checklists e operações de frota. É proibido uso indevido, engenharia reversa, exploração de falhas ou tentativa de acesso não autorizado a dados de terceiros."
        ),
        .init(
            title: "3. Contas e perfis",
            body: "Existem perfis de Administrador e Operador. Você é responsável por manter a confidencialidade das credenciais. Contas administrativas só podem ser criadas ou elevadas por administradores já autenticados, respeitado o limite de 5 administradores."
        ),
        .init(
            title: "4. Conteúdo operacional",
            body: "Relatórios, fotos, assinaturas e reservas gerados no app são de responsabilidade da organização usuária. Marcas e modelos de veículos exibidos são apenas referência operacional de seleção."
        ),
        .init(
            title: "5. Disponibilidade",
            body: "O serviço é fornecido “como está”, podendo haver interrupções por manutenção, atualizações ou fatores externos (rede, provedores de login, sistema operacional)."
        ),
        .init(
            title: "6. Limitação de responsabilidade",
            body: "Na máxima extensão permitida pela lei, o Auto Wize não se responsabiliza por danos indiretos decorrentes do uso operacional inadequado dos checklists, falhas de comunicação com o cliente ou decisões tomadas com base nos registros."
        ),
        .init(
            title: "7. Alterações",
            body: "Estes termos podem ser atualizados. O uso contínuo após a publicação das alterações implica ciência das novas condições. A data de atualização consta neste documento."
        ),
        .init(
            title: "8. Contato",
            body: "Dúvidas sobre estes termos: \(AppStoreLinks.supportEmail) ou Meu perfil → Suporte."
        )
    ]
    
    static let supportSections: [LegalSection] = [
        .init(
            title: "Como podemos ajudar",
            body: "O suporte do Auto Wize cobre dúvidas sobre o aplicativo, conta, login, privacidade (LGPD) e operações de frota (entrega, devolução, troca, avarias e tratores)."
        ),
        .init(
            title: "Assuntos frequentes",
            body: """
            • Login, recuperação de senha e Sign in with Apple/Google
            • Perfis Administrador e Operador
            • Exclusão de conta e dados (LGPD)
            • Checklists, reservas e avisos por SMS/iMessage e e-mail
            • Relatórios e histórico em PDF
            """
        ),
        .init(
            title: "Excluir conta",
            body: "No app: Meu perfil → Excluir minha conta. Isso remove a conta e os dados operacionais locais neste dispositivo (históricos, CPF/dados de clientes, fotos, assinaturas e reservas)."
        ),
        .init(
            title: "Horário de atendimento",
            body: "Respondemos por e-mail em até 2 dias úteis, horário de Brasília. Para urgências operacionais da frota, contate também o administrador da sua organização."
        )
    ]
}

#Preview {
    NavigationStack {
        LegalDocumentsView(document: .privacy)
    }
}
