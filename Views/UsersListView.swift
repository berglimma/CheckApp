//
//  UsersListView.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import SwiftUI
import SwiftData

struct UsersListView: View {
    @Query(sort: \User.name) private var users: [User]
    
    var body: some View {
        ZStack {
            AWScreenBackground()
            
            if users.isEmpty {
                AWEmptyState(
                    systemImage: "person.3",
                    title: "Nenhum usuário",
                    message: "Cadastre colaboradores para liberar o acesso ao Auto Wize."
                )
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
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
        .navigationTitle("Usuários")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AWTheme.screenGray, for: .navigationBar)
    }
    
    private func userRow(_ user: User) -> some View {
        let isAdmin = user.role == .admin
        let badgeColor = isAdmin ? AWTheme.warning : AWTheme.accent
        
        return HStack(alignment: .center, spacing: 12) {
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
                        text: isAdmin ? "Admin" : "Operador",
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
            }
        }
        .padding(14)
        .background(AWTheme.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: AWTheme.radiusM, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AWTheme.radiusM, style: .continuous)
                .stroke(AWTheme.stroke, lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        UsersListView()
    }
    .modelContainer(for: [User.self], inMemory: true)
}
