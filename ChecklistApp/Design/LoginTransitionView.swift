//
//  LoginTransitionView.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import SwiftUI

/// Tela de transição animada entre login e painel de operações (~4s).
struct LoginTransitionView: View {
    var duration: TimeInterval = 4
    var onFinished: () -> Void
    
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    @State private var carProgress: CGFloat = 0
    @State private var roadOffset: CGFloat = 0
    @State private var brandOpacity: Double = 0
    @State private var brandScale: CGFloat = 0.86
    @State private var subtitleOpacity: Double = 0
    @State private var glowPulse = false
    
    private var isPad: Bool { sizeClass == .regular }
    
    var body: some View {
        GeometryReader { geo in
            let width = max(geo.size.width, 1)
            let height = max(geo.size.height, 1)
            let metrics = layoutMetrics(width: width, height: height)
            let travel = width + metrics.carWidth + 100
            
            ZStack {
                AWScreenBackground()
                
                RadialGradient(
                    colors: [
                        AWTheme.accent.opacity(glowPulse ? 0.20 : 0.08),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 24,
                    endRadius: max(width, height) * 0.6
                )
                
                VStack(spacing: metrics.contentSpacing) {
                    Spacer(minLength: metrics.topSpacer)
                    
                    VStack(spacing: 10) {
                        Text("AutoWize")
                            .font(AWTheme.brand(metrics.brandSize))
                            .minimumScaleFactor(0.65)
                            .lineLimit(1)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, AWTheme.accent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(
                                color: AWTheme.accent.opacity(0.45),
                                radius: glowPulse ? 18 : 8,
                                y: 2
                            )
                            .scaleEffect(brandScale)
                            .opacity(brandOpacity)
                        
                        Text("Preparando o painel de operações")
                            .font(AWTheme.caption(metrics.subtitleSize))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(AWTheme.textSecondary)
                            .opacity(subtitleOpacity)
                    }
                    .padding(.horizontal, metrics.horizontalPadding)
                    
                    Spacer(minLength: metrics.midSpacer)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: metrics.roadCorner, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.14, green: 0.15, blue: 0.17),
                                        Color(red: 0.08, green: 0.09, blue: 0.10)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: metrics.roadHeight)
                            .overlay(
                                RoundedRectangle(cornerRadius: metrics.roadCorner, style: .continuous)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )
                            .padding(.horizontal, metrics.horizontalPadding)
                            .offset(y: metrics.roadOffsetY)
                        
                        HStack(spacing: metrics.dashSpacing) {
                            ForEach(0..<28, id: \.self) { _ in
                                Capsule()
                                    .fill(Color.white.opacity(0.55))
                                    .frame(width: metrics.dashWidth, height: 4)
                            }
                        }
                        .offset(x: roadOffset, y: metrics.roadOffsetY)
                        .mask(
                            RoundedRectangle(cornerRadius: metrics.roadCorner, style: .continuous)
                                .frame(height: metrics.roadHeight)
                                .padding(.horizontal, metrics.horizontalPadding + 12)
                        )
                        
                        Image("transition_sedan")
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: metrics.carWidth, height: metrics.carHeight)
                            .scaleEffect(x: -1, y: 1)
                            .shadow(color: .black.opacity(0.35), radius: 10, y: 6)
                            .shadow(color: AWTheme.accent.opacity(0.22), radius: 14, y: 0)
                            .offset(
                                x: -travel / 2 + travel * carProgress,
                                y: metrics.carOffsetY
                            )
                            .accessibilityHidden(true)
                    }
                    .frame(height: metrics.sceneHeight)
                    .frame(maxWidth: .infinity)
                    // Permite o carro entrar/sair sem cortar verticalmente
                    .padding(.vertical, 8)
                    
                    Spacer(minLength: metrics.bottomSpacer)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startAnimation()
        }
    }
    
    private func layoutMetrics(width: CGFloat, height: CGFloat) -> TransitionMetrics {
        let compactHeight = height < 700
        let brandSize: CGFloat = {
            if isPad { return min(64, width * 0.075) }
            return min(compactHeight ? 34 : 42, width * 0.105)
        }()
        
        let carWidth: CGFloat = {
            if isPad { return min(380, width * 0.36) }
            return min(compactHeight ? 168 : 200, width * 0.56)
        }()
        
        let carHeight = carWidth * 0.40
        let roadHeight: CGFloat = isPad ? 100 : (compactHeight ? 62 : 76)
        let sceneHeight = max(carHeight + roadHeight * 0.75, isPad ? 180 : 130)
        
        return TransitionMetrics(
            brandSize: brandSize,
            subtitleSize: isPad ? 16 : (compactHeight ? 12 : 13),
            horizontalPadding: isPad ? 48 : 20,
            contentSpacing: isPad ? 20 : 10,
            topSpacer: isPad ? max(48, height * 0.12) : (compactHeight ? 36 : max(40, height * 0.08)),
            midSpacer: isPad ? 36 : (compactHeight ? 18 : 28),
            bottomSpacer: isPad ? max(40, height * 0.10) : (compactHeight ? 28 : max(32, height * 0.07)),
            carWidth: carWidth,
            carHeight: carHeight,
            carOffsetY: -roadHeight * 0.35,
            roadHeight: roadHeight,
            roadCorner: isPad ? 24 : 16,
            roadOffsetY: carHeight * 0.22,
            sceneHeight: sceneHeight,
            dashWidth: isPad ? 44 : 28,
            dashSpacing: isPad ? 24 : 16
        )
    }
    
    private func startAnimation() {
        withAnimation(.easeOut(duration: 0.7)) {
            brandOpacity = 1
            brandScale = 1
        }
        
        withAnimation(.easeIn(duration: 0.8).delay(0.35)) {
            subtitleOpacity = 1
        }
        
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            glowPulse = true
        }
        
        withAnimation(.linear(duration: duration)) {
            carProgress = 1
            roadOffset = -320
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            onFinished()
        }
    }
}

private struct TransitionMetrics {
    let brandSize: CGFloat
    let subtitleSize: CGFloat
    let horizontalPadding: CGFloat
    let contentSpacing: CGFloat
    let topSpacer: CGFloat
    let midSpacer: CGFloat
    let bottomSpacer: CGFloat
    let carWidth: CGFloat
    let carHeight: CGFloat
    let carOffsetY: CGFloat
    let roadHeight: CGFloat
    let roadCorner: CGFloat
    let roadOffsetY: CGFloat
    let sceneHeight: CGFloat
    let dashWidth: CGFloat
    let dashSpacing: CGFloat
}

#Preview("iPhone") {
    LoginTransitionView(duration: 4) {}
        .preferredColorScheme(.dark)
}

#Preview("iPad") {
    LoginTransitionView(duration: 4) {}
        .preferredColorScheme(.dark)
}
