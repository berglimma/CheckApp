//
//  LegalDocumentsView.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import SwiftUI

enum LegalDocument: String, Identifiable {
    case privacy
    case terms
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .privacy: return "Política de Privacidade"
        case .terms: return "Termos de Uso"
        }
    }
}

struct LegalDocumentsView: View {
    let document: LegalDocument
    
    private var publicURL: URL {
        switch document {
        case .privacy: return AppStoreLinks.privacyPolicy
        case .terms: return AppStoreLinks.termsOfUse
        }
    }
    
    var body: some View {
        ZStack {
            AWScreenBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    AWScreenTitle(
                        title: document.title,
                        subtitle: "Auto Wize — conformidade LGPD"
                    )
                    
                    AWSectionCard {
                        Link(destination: publicURL) {
                            HStack {
                                Image(systemName: "safari")
                                Text("Abrir versão pública (HTTPS)")
                                    .font(AWTheme.headline(14))
                                Spacer()
                                Image(systemName: "arrow.up.right")
                            }
                            .foregroundStyle(AWTheme.accent)
                        }
                    }
                    
                    AWSectionCard {
                        Text(content)
                            .font(AWTheme.body(14))
                            .foregroundStyle(AWTheme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
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
    
    private var content: String {
        switch document {
        case .privacy: return Self.privacyText
        case .terms: return Self.termsText
        }
    }
    
    private static let privacyText = """
    1. Controlador e finalidade
    O Auto Wize trata dados pessoais para operação de checklists de frota (entrega, devolução, troca, avarias e avaliação de tratores), autenticação de usuários e envio de avisos operacionais ao cliente.

    2. Dados tratados
    • Conta: nome, e-mail, telefone e credenciais de acesso
    • Operações: nome/documento do cliente, telefone, e-mail, placa, marca/modelo, quilometragem, fotos, assinaturas e observações
    • Identificadores técnicos necessários ao funcionamento do app

    3. Base legal (LGPD)
    Execução de contrato/procedimentos preliminares e legítimo interesse para segurança operacional da frota, observados os direitos do titular.

    4. Compartilhamento
    Dados podem ser enviados ao próprio cliente via SMS/iMessage ou e-mail quando uma movimentação é registrada. Autenticação pode usar Firebase Auth / Apple / Google conforme o método de login escolhido.

    5. Armazenamento e retenção
    Dados ficam no dispositivo (SwiftData/arquivos locais) e, quando aplicável, em serviços de autenticação. Mantemos enquanto houver necessidade operacional ou obrigação legal.

    6. Direitos do titular
    Você pode solicitar acesso, correção e exclusão. No app: Meu perfil → Excluir minha conta remove a conta e também os dados operacionais locais neste dispositivo (históricos, CPF/documentos de clientes, telefones, e-mails, fotos, assinaturas e reservas).

    7. Segurança
    Senhas locais são armazenadas com hash. Recomendamos senhas fortes e não compartilhar códigos de recuperação.

    8. Contato
    Para exercer direitos LGPD, fale com o responsável pela frota/administrador do Auto Wize na sua organização.

    Última atualização: julho/2026.
    """
    
    private static let termsText = """
    1. Aceitação
    Ao usar o Auto Wize, você concorda com estes Termos e com a Política de Privacidade.

    2. Uso permitido
    O app destina-se a equipes autorizadas para registro de checklists e operações de frota. É proibido uso indevido, engenharia reversa ou tentativa de acesso não autorizado.

    3. Contas
    Você é responsável por manter a confidencialidade das credenciais. Contas administrativas só podem ser criadas por administradores já autenticados.

    4. Conteúdo operacional
    Relatórios, fotos e assinaturas gerados no app são de responsabilidade da organização usuária. Marcas e modelos de veículos exibidos são apenas referência operacional.

    5. Disponibilidade
    O serviço é fornecido “como está”, podendo haver interrupções por manutenção ou fatores externos (rede, provedores de login).

    6. Limitação
    Na máxima extensão permitida pela lei, o Auto Wize não se responsabiliza por danos indiretos decorrentes do uso operacional inadequado dos checklists.

    7. Alterações
    Estes termos podem ser atualizados. O uso contínuo após alterações implica ciência das novas condições.

    8. Contato
    Dúvidas sobre estes termos devem ser dirigidas ao administrador da sua organização.

    Última atualização: julho/2026.
    """
}
