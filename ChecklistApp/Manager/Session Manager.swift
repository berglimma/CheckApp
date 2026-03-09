//
//  Session Manager.swift
//  ChecklistApp
//
//  Created by Luan Carlos on 28/02/26.
//

import SwiftUI
import SwiftData

final class SessionManager: ObservableObject {
    @Published var currentUser: User?
        
        var isLoggedIn: Bool {
            currentUser != nil
        }
        
        var isAdmin: Bool {
            currentUser?.role == .admin
        }
        
        func logout() {
            currentUser = nil
        }
    }
