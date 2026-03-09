//
//  UsersListView.swift
//  ChecklistApp
//
//  Created by Luan Carlos on 09/03/26.
//

import SwiftUI
import SwiftData

struct UsersListView: View {

    @Query(sort: \User.name) private var users: [User]

    var body: some View {
        NavigationStack {
            List(users) { user in
                
                VStack(alignment: .leading, spacing: 6) {
                    
                    Text(user.name)
                        .font(.headline)
                    
                    Text(user.email)
                        .font(.subheadline)
                    
                    Text(user.phone)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(user.role.rawValue.capitalized)
                        .font(.caption2)
                        .padding(4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(5)
                }
            }
            .navigationTitle("Usuários cadastrados")
        }
    }
}

#Preview {
    UsersListView()
}
