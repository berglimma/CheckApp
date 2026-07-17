//
//  UsersListView.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import SwiftUI
import SwiftData

struct UsersListView: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.modelContext) private var context
    @Query(sort: \User.name) private var users: [User]
    
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var userToDelete: User?
    
    private var adminCount: Int {
        users.filter { $0.role == .admin }.count
    }
    
    private var canPromoteToAdmin: Bool {
        adminCount < SessionManager.maxAdmins
    }
    
    var body: some View {
        ZStack {
            AWScreenBackground()
            
            if !session.isAdmin {
                AWEmptyState(
                    systemImage: "lock.fill",
                    title: "Acesso restrito",
                    message: "Somente administradores podem gerenciar a equipe."
                )
            } else if users.isEmpty {
                AWEmptyState(
                    systemImage: "person.3",
                    title: "Nenhum funcionário",
                    message: "Cadastre funcionários em Cadastro de Funcionário para usá-los nas operações."
                )
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Funcionários cadastrados: \(users.count)")
                                .font(AWTheme.headline(14))
                                .foregroundStyle(AWTheme.textPrimary)
                            Text("Administradores: \(adminCount)/\(SessionManager.maxAdmins)")
                                .font(AWTheme.caption(12))
                                .foregroundStyle(AWTheme.warning)
                            Text(
                                canPromoteToAdmin
                                    ? "Com vaga livre você pode promover a Administrador. Sem vaga, cadastre apenas operadores."
                                    : "Limite atingido. Exclua ou rebaixe um administrador para liberar nova vaga."
                            )
                            .font(AWTheme.caption(12))
                            .foregroundStyle(AWTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 4)
                        
                        ForEach(users) { user in
                            userRow(user)
                        }
                    }
                    .awReadableWidth(AWLayout.listMaxWidth)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
            }
        }
        .navigationTitle("Equipe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AWTheme.screenGray, for: .navigationBar)
        .alert("Equipe", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .confirmationDialog(
            "Excluir usuário?",
            isPresented: Binding(
                get: { userToDelete != nil },
                set: { if !$0 { userToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Excluir permanentemente", role: .destructive) {
                if let user = userToDelete {
                    deleteUser(user)
                }
                userToDelete = nil
            }
            Button("Cancelar", role: .cancel) {
                userToDelete = nil
            }
        } message: {
            Text("A conta será removida. Se for administrador, a vaga (\(SessionManager.maxAdmins) máx.) será liberada.")
        }
    }
    
    private func userRow(_ user: User) -> some View {
        let isAdminUser = user.role == .admin
        let badgeColor = isAdminUser ? AWTheme.warning : AWTheme.accent
        let isSelf = session.currentUser?.persistentModelID == user.persistentModelID
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(badgeColor.opacity(0.14))
                        .frame(width: 42, height: 42)
                    Text(String(user.name.prefix(1)).uppercased())
                        .font(AWTheme.headline(15))
                        .foregroundStyle(badgeColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 8) {
                        Text(user.name)
                            .font(AWTheme.headline(15))
                            .foregroundStyle(AWTheme.textPrimary)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        AWBadge(
                            text: user.role.titulo,
                            color: badgeColor
                        )
                    }
                    
                    Text(user.email)
                        .font(AWTheme.body(13))
                        .foregroundStyle(AWTheme.textSecondary)
                        .lineLimit(1)
                    
                    if !user.phone.isEmpty {
                        Text(user.phone)
                            .font(AWTheme.caption(12))
                            .foregroundStyle(AWTheme.textSecondary)
                    }
                    
                    if isSelf {
                        Text("Você")
                            .font(AWTheme.caption(11))
                            .foregroundStyle(AWTheme.accent)
                    }
                }
            }
            
            HStack(spacing: 8) {
                roleButton(
                    title: "Operador",
                    selected: user.role == .normal,
                    color: AWTheme.accent,
                    disabled: false
                ) {
                    changeRole(user, to: .normal)
                }
                
                roleButton(
                    title: "Administrador",
                    selected: user.role == .admin,
                    color: AWTheme.warning,
                    disabled: user.role != .admin && !canPromoteToAdmin
                ) {
                    changeRole(user, to: .admin)
                }
            }
            
            Button(role: .destructive) {
                userToDelete = user
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                    Text(isSelf ? "Excluir minha conta" : "Excluir usuário")
                }
                .font(AWTheme.caption(12))
                .foregroundStyle(AWTheme.danger)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(AWTheme.danger.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(AWTheme.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: AWTheme.radiusM, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AWTheme.radiusM, style: .continuous)
                .stroke(AWTheme.stroke, lineWidth: 1)
        )
    }
    
    private func roleButton(
        title: String,
        selected: Bool,
        color: Color,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(AWTheme.caption(12))
                .foregroundStyle(selected ? Color.white : (disabled ? AWTheme.textSecondary : AWTheme.textPrimary))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(selected ? color : AWTheme.fieldFill)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(selected ? color : AWTheme.stroke, lineWidth: 1)
                )
                .opacity(disabled && !selected ? 0.45 : 1)
        }
        .buttonStyle(.plain)
        .disabled(selected || disabled)
    }
    
    private func changeRole(_ user: User, to role: UserRole) {
        guard user.role != role else { return }
        do {
            switch try session.setRole(role, for: user, context: context) {
            case .success:
                break
            case .lastAdmin:
                alertMessage = "Não é possível remover o último administrador do sistema."
                showAlert = true
            case .maxAdminsReached:
                alertMessage = "Limite de \(SessionManager.maxAdmins) administradores atingido. Exclua ou rebaixe um admin para liberar vaga."
                showAlert = true
            }
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
    
    private func deleteUser(_ user: User) {
        do {
            switch try session.deleteUser(user, context: context) {
            case .success:
                alertMessage = "Usuário excluído. Vagas de admin: \(SessionManager.adminCount(context: context))/\(SessionManager.maxAdmins)."
                showAlert = true
            case .lastAdmin:
                alertMessage = "Não é possível excluir o último administrador."
                showAlert = true
            case .maxAdminsReached:
                break
            }
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}

#Preview {
    NavigationStack {
        UsersListView()
    }
    .environmentObject(SessionManager())
    .modelContainer(for: [User.self], inMemory: true)
}
