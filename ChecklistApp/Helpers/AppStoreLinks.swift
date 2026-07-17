//
//  AppStoreLinks.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import Foundation

/// URLs públicas para App Store Connect e links no app (GitHub Pages).
enum AppStoreLinks {
    static let privacyPolicy = URL(string: "https://berglimma.github.io/CheckApp/privacy.html")!
    static let termsOfUse = URL(string: "https://berglimma.github.io/CheckApp/terms.html")!
    static let support = URL(string: "https://berglimma.github.io/CheckApp/support.html")!
    static let supportEmail = "suporte.autowize@gmail.com"
    
    /// Conta de demonstração para App Review (também criada no seed local).
    enum DemoAccount {
        static let email = "demo@autowize.app"
        static let password = "Demo@Autowize2026!"
        static let name = "Demo App Review"
        static let phone = "11999990000"
    }
}
