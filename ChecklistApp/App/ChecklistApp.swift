//
//  ChecklistApp.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import SwiftUI
import SwiftData
import UIKit

@main
struct ChecklistAppApp: App {
    @StateObject private var session = SessionManager()
    @State private var isShowingLoginTransition = false
    
    init() {
        AuthService.shared.configureIfNeeded()
    }
    
    private let modelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            Car.self,
            Client.self,
            ChecklistDevolucao.self,
            CheckListHistorico.self,
            PhotoAttachment.self,
            Reserva.self
        ])
        
        do {
            return try ModelContainer(for: schema)
        } catch {
            let storeURL = URL.applicationSupportDirectory.appending(path: "default.store")
            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("wal"))
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))
            
            do {
                return try ModelContainer(for: schema)
            } catch {
                fatalError("Falha ao criar ModelContainer: \(error)")
            }
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !session.isLoggedIn {
                    AutoWiseLogin()
                        .transition(.opacity)
                } else if isShowingLoginTransition {
                    LoginTransitionView {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            isShowingLoginTransition = false
                        }
                    }
                    .transition(.opacity)
                } else {
                    HomeCheckListView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: session.isLoggedIn)
            .animation(.easeInOut(duration: 0.3), value: isShowingLoginTransition)
            .environmentObject(session)
            .preferredColorScheme(.dark)
            .background(AWTheme.screenGray.ignoresSafeArea())
            .tint(AWTheme.accent)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: session.isLoggedIn) { _, loggedIn in
                if loggedIn {
                    isShowingLoginTransition = true
                } else {
                    isShowingLoginTransition = false
                }
            }
            .task {
                await MainActor.run {
                    Self.configureUIAppearance()
                    DemoAccountSeeder.seedIfNeeded(context: modelContainer.mainContext)
                }
            }
            .onOpenURL { url in
                _ = AuthService.shared.handleGoogleURL(url)
            }
        }
        .modelContainer(modelContainer)
    }
    
    @MainActor
    private static func configureUIAppearance() {
        let screen = AWTheme.uiScreen
        
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = screen
        nav.titleTextAttributes = [.foregroundColor: UIColor.white]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        let navigationBar = UINavigationBar.appearance()
        navigationBar.standardAppearance = nav
        navigationBar.scrollEdgeAppearance = nav
        navigationBar.compactAppearance = nav
        navigationBar.tintColor = UIColor(AWTheme.accent)
        
        UITableView.appearance().backgroundColor = screen
        UICollectionView.appearance().backgroundColor = screen
        // Não usar UITextField/UITextView.appearance().keyboardAppearance —
        // no iOS recente isso crasha (setKeyboardAppearance off main thread).
        // preferredColorScheme(.dark) já aplica teclado escuro.
    }
}
