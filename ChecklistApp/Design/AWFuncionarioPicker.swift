//
//  AWFuncionarioPicker.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import SwiftUI
import SwiftData

/// Seleção de funcionário responsável a partir dos usuários cadastrados.
struct AWFuncionarioPicker: View {
    @Binding var funcionario: String
    var title: String = "Funcionário responsável"
    
    @Query(sort: \User.name) private var users: [User]
    @EnvironmentObject private var session: SessionManager
    
    @State private var didApplyDefault = false
    
    private var sortedUsers: [User] {
        users.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }
    
    private var selectedUser: User? {
        let trimmed = funcionario.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return sortedUsers.first {
            $0.name.caseInsensitiveCompare(trimmed) == .orderedSame
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AWTheme.caption(12))
                .foregroundStyle(AWTheme.textSecondary)
            
            if sortedUsers.isEmpty {
                emptyState
            } else {
                Menu {
                    ForEach(sortedUsers, id: \.persistentModelID) { user in
                        Button {
                            funcionario = user.name
                        } label: {
                            if selectedUser?.persistentModelID == user.persistentModelID {
                                Label(menuLabel(for: user), systemImage: "checkmark")
                            } else {
                                Text(menuLabel(for: user))
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(AWTheme.accent)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(
                                funcionario.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? "Selecionar funcionário"
                                : funcionario
                            )
                            .font(AWTheme.body())
                            .foregroundStyle(
                                funcionario.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? AWTheme.textSecondary
                                : AWTheme.textPrimary
                            )
                            .lineLimit(1)
                            
                            if let selectedUser {
                                Text(selectedUser.role.titulo)
                                    .font(AWTheme.caption(11))
                                    .foregroundStyle(AWTheme.textSecondary)
                            } else if !sortedUsers.isEmpty {
                                Text("\(sortedUsers.count) funcionário(s) cadastrado(s)")
                                    .font(AWTheme.caption(11))
                                    .foregroundStyle(AWTheme.textSecondary)
                            }
                        }
                        
                        Spacer(minLength: 8)
                        
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AWTheme.textSecondary)
                    }
                    .padding(.horizontal, 16)
                    .frame(minHeight: AWTheme.fieldHeight)
                    .background(AWTheme.fieldFill)
                    .clipShape(RoundedRectangle(cornerRadius: AWTheme.radiusM, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AWTheme.radiusM, style: .continuous)
                            .stroke(AWTheme.stroke, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(sortedUsers, id: \.persistentModelID) { user in
                            employeeChip(user)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .onAppear {
            applyDefaultIfNeeded()
        }
        .onChange(of: users.count) { _, _ in
            applyDefaultIfNeeded()
        }
    }
    
    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "person.badge.plus")
                    .foregroundStyle(AWTheme.warning)
                Text("Nenhum funcionário cadastrado. Cadastre em Cadastro de Funcionário / Equipe.")
                    .font(AWTheme.caption(12))
                    .foregroundStyle(AWTheme.textSecondary)
            }
            
            AWTextField(
                placeholder: title,
                text: $funcionario,
                autocapitalization: .words
            )
        }
    }
    
    private func employeeChip(_ user: User) -> some View {
        let isSelected = selectedUser?.persistentModelID == user.persistentModelID
            || user.name.caseInsensitiveCompare(
                funcionario.trimmingCharacters(in: .whitespacesAndNewlines)
            ) == .orderedSame
        
        return Button {
            funcionario = user.name
        } label: {
            HStack(spacing: 6) {
                Image(systemName: user.role.systemImage)
                    .font(.system(size: 10, weight: .semibold))
                Text(user.name)
                    .font(AWTheme.caption(12))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? .white : AWTheme.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? AWTheme.accent : AWTheme.fieldFill)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(
                        isSelected ? AWTheme.accent : AWTheme.stroke,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private func menuLabel(for user: User) -> String {
        "\(user.name) · \(user.role.titulo)"
    }
    
    private func applyDefaultIfNeeded() {
        guard !didApplyDefault else { return }
        let trimmed = funcionario.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty, let current = session.currentUser?.name, !current.isEmpty {
            funcionario = current
        }
        didApplyDefault = true
    }
}
