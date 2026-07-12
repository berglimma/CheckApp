import SwiftUI

// MARK: - Adaptive layout helpers (iPhone + iPad)

enum AWLayout {
    static let formMaxWidth: CGFloat = 720
    static let homeMaxWidth: CGFloat = 980
    static let loginMaxWidth: CGFloat = 520
    static let listMaxWidth: CGFloat = 860
    
    static func horizontalPadding(for sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .regular ? 32 : AWTheme.horizontalPadding
    }
}

struct AWReadableWidth: ViewModifier {
    @Environment(\.horizontalSizeClass) private var sizeClass
    var maxWidth: CGFloat
    var alignment: Alignment = .center
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: sizeClass == .regular ? maxWidth : .infinity, alignment: alignment)
            .frame(maxWidth: .infinity, alignment: alignment)
            .padding(.horizontal, AWLayout.horizontalPadding(for: sizeClass))
    }
}

extension View {
    /// Centraliza o conteúdo com largura legível no iPad.
    func awReadableWidth(_ maxWidth: CGFloat = AWLayout.formMaxWidth) -> some View {
        modifier(AWReadableWidth(maxWidth: maxWidth))
    }
    
    /// Aplica padding horizontal adaptativo.
    func awScreenPadding() -> some View {
        modifier(AWScreenPadding())
    }
}

private struct AWScreenPadding: ViewModifier {
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    func body(content: Content) -> some View {
        content.padding(.horizontal, AWLayout.horizontalPadding(for: sizeClass))
    }
}

/// Container padrão para telas com scroll (formulários / listas).
struct AWScrollScreen<Content: View>: View {
    var maxWidth: CGFloat = AWLayout.formMaxWidth
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        ZStack {
            AWScreenBackground()
            
            ScrollView(showsIndicators: false) {
                content()
                    .awReadableWidth(maxWidth)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
            }
        }
    }
}
