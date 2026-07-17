//
//  HomeCheckListView.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import SwiftUI

struct HomeCheckListView: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.modelContext) private var context
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    private var greetingName: String {
        session.currentUser?.name.components(separatedBy: " ").first ?? "Operador"
    }
    
    private var avatarSize: CGFloat {
        sizeClass == .regular ? 54 : 46
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AWScreenBackground()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        
                        AWOperationsForm {
                            AWMenuRow(
                                title: "Checklist Entrega",
                                subtitle: "Registrar saída do veículo",
                                systemImage: "car.fill",
                                accent: AWTheme.moduleEntrega,
                                destination: ChecklistView(),
                                delay: 0.04,
                                showsDivider: true
                            )
                            
                            AWMenuRow(
                                title: "Checklist Devolução",
                                subtitle: "Registrar retorno e inspeção",
                                systemImage: "car.rear.fill",
                                accent: AWTheme.moduleDevolucao,
                                destination: ChecklistDevolucaoView(),
                                delay: 0.08,
                                showsDivider: true
                            )
                            
                            AWMenuRow(
                                title: "Troca Provisória",
                                subtitle: "Substituir veículo temporariamente",
                                systemImage: "car.2.fill",
                                accent: AWTheme.moduleTroca,
                                destination: TrocaProvisoriaView(),
                                delay: 0.12,
                                showsDivider: true
                            )
                            
                            AWMenuRow(
                                title: "Avarias",
                                subtitle: "Calcular e exportar danos",
                                systemImage: "wrench.and.screwdriver.fill",
                                accent: AWTheme.moduleAvarias,
                                destination: AvariaCalculator(),
                                delay: 0.16,
                                showsDivider: true
                            )
                            
                            AWMenuRow(
                                title: "Avaliação Trator",
                                subtitle: "Checklist de equipamento pesado",
                                systemImage: "gearshape.2.fill",
                                accent: AWTheme.moduleTrator,
                                destination: AvaliacaoTratorView(),
                                delay: 0.2,
                                showsDivider: true
                            )
                            
                            AWMenuRow(
                                title: "Relatórios PDF",
                                subtitle: "Exportar tudo o que foi registrado",
                                systemImage: "doc.richtext.fill",
                                accent: AWTheme.moduleHistorico,
                                destination: RelatoriosView(),
                                delay: 0.24,
                                showsDivider: true
                            )
                            
                            AWMenuRow(
                                title: "Histórico",
                                subtitle: "Consultar operações anteriores",
                                systemImage: "clock.arrow.circlepath",
                                accent: AWTheme.moduleHistorico,
                                destination: HistoricoCheck(),
                                delay: 0.28,
                                showsDivider: true
                            )
                            
                            AWMenuRow(
                                title: "Meu perfil",
                                subtitle: "Foto, dados e tipo de acesso",
                                systemImage: "person.crop.circle",
                                accent: AWTheme.moduleUsuarios,
                                destination: ProfileView(),
                                delay: 0.32,
                                showsDivider: session.isAdmin
                            )
                            
                            if session.isAdmin {
                                AWMenuRow(
                                    title: "Cadastro de Usuários",
                                    subtitle: "Criar operador ou administrador",
                                    systemImage: "person.badge.plus",
                                    accent: AWTheme.moduleUsuarios,
                                    destination: AutoWiseCadastro(),
                                    delay: 0.36,
                                    showsDivider: true
                                )
                                
                                AWMenuRow(
                                    title: "Equipe",
                                    subtitle: "Listar e alterar perfis de acesso",
                                    systemImage: "person.3.fill",
                                    accent: AWTheme.moduleUsuarios,
                                    destination: UsersListView(),
                                    delay: 0.4,
                                    showsDivider: false
                                )
                            }
                        }
                        
                        logoutButton
                            .padding(.top, 4)
                            .padding(.bottom, 24)
                    }
                    .awReadableWidth(AWLayout.homeMaxWidth)
                    .padding(.top, 8)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                session.loadProfileImage(context: context)
            }
        }
        .navigationSplitViewStyle(.automatic)
    }
    
    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Olá, \(greetingName)")
                    .font(AWTheme.caption(13))
                    .foregroundStyle(AWTheme.textSecondary)
                
                Text("Auto Wize")
                    .font(AWTheme.brand(sizeClass == .regular ? 34 : 28))
                    .foregroundStyle(AWTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text("Painel de operações")
                    .font(AWTheme.body(14))
                    .foregroundStyle(AWTheme.textSecondary)
                
                Text(session.roleTitle)
                    .font(AWTheme.caption(12))
                    .foregroundStyle(session.isAdmin ? AWTheme.warning : AWTheme.accent)
            }
            
            Spacer(minLength: 8)
            
            NavigationLink {
                ProfileView()
            } label: {
                profileAvatar
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Meu perfil")
        }
        .padding(16)
        .background(AWTheme.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: AWTheme.radiusL, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AWTheme.radiusL, style: .continuous)
                .stroke(AWTheme.stroke, lineWidth: 1)
        )
    }
    
    private var profileAvatar: some View {
        ZStack {
            Circle()
                .fill(AWTheme.fieldFill)
                .frame(width: avatarSize, height: avatarSize)
                .overlay(
                    Circle()
                        .stroke(AWTheme.accent.opacity(0.35), lineWidth: 1.5)
                )
            
            if let image = session.profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: avatarSize, height: avatarSize)
                    .clipShape(Circle())
            } else {
                Text(String(greetingName.prefix(1)).uppercased())
                    .font(AWTheme.headline(sizeClass == .regular ? 20 : 17))
                    .foregroundStyle(AWTheme.accent)
            }
        }
    }
    
    private var logoutButton: some View {
        Button {
            session.logout()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Sair da conta")
            }
            .font(AWTheme.caption(13))
            .foregroundStyle(AWTheme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AWTheme.cardFill)
            .clipShape(RoundedRectangle(cornerRadius: AWTheme.radiusM, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AWTheme.radiusM, style: .continuous)
                    .stroke(AWTheme.stroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeCheckListView()
        .environmentObject(SessionManager())
}
