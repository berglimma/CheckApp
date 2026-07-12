import SwiftUI
import UIKit

enum AWTheme {
    
    // MARK: - Colors (layout preto)
    
    static let accent = Color(red: 0.18, green: 0.78, blue: 0.72)
    static let accentDeep = Color(red: 0.12, green: 0.62, blue: 0.58)
    
    /// Fundo principal quase preto
    static let screenGray = Color(red: 0.05, green: 0.05, blue: 0.06)
    /// Cards elevados
    static let cardWhite = Color(red: 0.11, green: 0.11, blue: 0.13)
    /// Campos de formulário
    static let fieldWhite = Color(red: 0.16, green: 0.16, blue: 0.18)
    
    static let danger = Color(red: 0.95, green: 0.38, blue: 0.36)
    static let warning = Color(red: 0.95, green: 0.68, blue: 0.22)
    static let success = Color(red: 0.28, green: 0.82, blue: 0.58)
    
    static let textPrimary = Color(red: 0.96, green: 0.96, blue: 0.97)
    static let textSecondary = Color(red: 0.62, green: 0.64, blue: 0.68)
    
    // MARK: - Module accents
    
    static let moduleEntrega = Color(red: 0.18, green: 0.78, blue: 0.68)
    static let moduleDevolucao = Color(red: 0.40, green: 0.62, blue: 0.95)
    static let moduleTroca = Color(red: 0.95, green: 0.65, blue: 0.25)
    static let moduleAvarias = Color(red: 0.95, green: 0.42, blue: 0.38)
    static let moduleHistorico = Color(red: 0.55, green: 0.65, blue: 0.78)
    static let moduleUsuarios = Color(red: 0.62, green: 0.58, blue: 0.95)
    static let moduleTrator = Color(red: 0.58, green: 0.78, blue: 0.42)
    
    // MARK: - Typography
    
    static func brand(_ size: CGFloat = 36) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    
    static func title(_ size: CGFloat = 24) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    
    static func headline(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
    
    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
    
    static func caption(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
    
    // MARK: - Layout
    
    static let radiusS: CGFloat = 10
    static let radiusM: CGFloat = 14
    static let radiusL: CGFloat = 16
    static let spacing: CGFloat = 16
    static let fieldHeight: CGFloat = 50
    static let horizontalPadding: CGFloat = 20
    
    // MARK: - Surfaces
    
    static var fieldFill: Color { fieldWhite }
    static var cardFill: Color { cardWhite }
    static var stroke: Color { Color.white.opacity(0.10) }
    
    /// UIKit helpers (nav bar / sistema)
    static var uiScreen: UIColor {
        UIColor(red: 0.05, green: 0.05, blue: 0.06, alpha: 1)
    }
    
    static var uiCard: UIColor {
        UIColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 1)
    }
}
