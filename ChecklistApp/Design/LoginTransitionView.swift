//
//  LoginTransitionView.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import SwiftUI

/// Tela de transição: carro (~4s) e depois trator trabalhando (~7s).
struct LoginTransitionView: View {
    var carDuration: TimeInterval = 4
    var tractorDuration: TimeInterval = 7
    var onFinished: () -> Void
    
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    @State private var phase: TransitionPhase = .car
    @State private var carProgress: CGFloat = 0
    @State private var roadOffset: CGFloat = 0
    @State private var brandOpacity: Double = 0
    @State private var brandScale: CGFloat = 0.86
    @State private var subtitleOpacity: Double = 0
    @State private var glowPulse = false
    
    // Trator
    @State private var tractorOpacity: Double = 0
    @State private var carSceneOpacity: Double = 1
    @State private var tractorProgress: CGFloat = 0
    @State private var tractorBounce: CGFloat = 0
    @State private var tractorTilt: Double = 0
    @State private var fieldOffset: CGFloat = 0
    @State private var dustPulse = false
    @State private var wheelRotation: Double = 0
    
    private var isPad: Bool { sizeClass == .regular }
    
    private var subtitleText: String {
        switch phase {
        case .car:
            return "Preparando o painel de operações"
        case .tractor:
            return "Sincronizando frota agrícola…"
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            let width = max(geo.size.width, 1)
            let height = max(geo.size.height, 1)
            let metrics = layoutMetrics(width: width, height: height)
            let travel = width + metrics.carWidth + 100
            let roadSideInset = max(
                metrics.roadSideMargin,
                max(geo.safeAreaInsets.leading, geo.safeAreaInsets.trailing) + metrics.roadSideMargin
            )
            let roadWidth = max(120, width - (roadSideInset * 2))
            
            ZStack {
                AWScreenBackground()
                    .ignoresSafeArea()
                
                RadialGradient(
                    colors: [
                        (phase == .tractor ? AWTheme.moduleTrator : AWTheme.accent)
                            .opacity(glowPulse ? 0.22 : 0.08),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 24,
                    endRadius: max(width, height) * 0.6
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.6), value: phase)
                
                VStack(spacing: metrics.contentSpacing) {
                    Spacer(minLength: metrics.topSpacer)
                    
                    VStack(spacing: 10) {
                        Text("AutoWize")
                            .font(AWTheme.brand(metrics.brandSize))
                            .minimumScaleFactor(0.65)
                            .lineLimit(1)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        .white,
                                        phase == .tractor ? AWTheme.moduleTrator : AWTheme.accent
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(
                                color: (phase == .tractor ? AWTheme.moduleTrator : AWTheme.accent)
                                    .opacity(0.45),
                                radius: glowPulse ? 18 : 8,
                                y: 2
                            )
                            .scaleEffect(brandScale)
                            .opacity(brandOpacity)
                        
                        Text(subtitleText)
                            .font(AWTheme.caption(metrics.subtitleSize))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(AWTheme.textSecondary)
                            .opacity(subtitleOpacity)
                            .id(subtitleText)
                            .transition(.opacity)
                    }
                    .padding(.horizontal, max(metrics.horizontalPadding, roadSideInset))
                    .animation(.easeInOut(duration: 0.35), value: phase)
                    
                    Spacer(minLength: metrics.midSpacer)
                    
                    ZStack {
                        carScene(
                            metrics: metrics,
                            travel: travel,
                            roadWidth: roadWidth
                        )
                        .opacity(carSceneOpacity)
                        
                        tractorScene(
                            metrics: metrics,
                            width: width,
                            fieldWidth: roadWidth
                        )
                        .opacity(tractorOpacity)
                    }
                    .frame(width: width, height: metrics.sceneHeight)
                    .padding(.vertical, 8)
                    
                    Spacer(minLength: metrics.bottomSpacer)
                }
                .padding(.top, geo.safeAreaInsets.top)
                .padding(.bottom, max(geo.safeAreaInsets.bottom, 8))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startAnimation()
        }
    }
    
    // MARK: - Scenes
    
    private func carScene(
        metrics: TransitionMetrics,
        travel: CGFloat,
        roadWidth: CGFloat
    ) -> some View {
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
                .overlay(
                    RoundedRectangle(cornerRadius: metrics.roadCorner, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .frame(width: roadWidth, height: metrics.roadHeight)
                .offset(y: metrics.roadOffsetY)
            
            HStack(spacing: metrics.dashSpacing) {
                ForEach(0..<28, id: \.self) { _ in
                    Capsule()
                        .fill(Color.white.opacity(0.55))
                        .frame(width: metrics.dashWidth, height: 4)
                }
            }
            .frame(width: roadWidth - 24, alignment: .leading)
            .offset(x: roadOffset, y: metrics.roadOffsetY)
            .frame(width: roadWidth - 24, height: metrics.roadHeight, alignment: .center)
            .clipped()
            
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
    }
    
    private func tractorScene(
        metrics: TransitionMetrics,
        width: CGFloat,
        fieldWidth: CGFloat
    ) -> some View {
        // Mais curto na tela, ainda com movimento calmo
        let travel = width * 0.35 + metrics.tractorWidth * 0.1
        
        return ZStack {
            // Terreno de terra / campo — conteúdo dentro da margem do retângulo
            let fieldShape = UnevenRoundedRectangle(
                topLeadingRadius: metrics.roadCorner * 0.6,
                bottomLeadingRadius: metrics.roadCorner,
                bottomTrailingRadius: metrics.roadCorner,
                topTrailingRadius: metrics.roadCorner * 0.6,
                style: .continuous
            )
            let fieldHeight = metrics.roadHeight + 10
            let fieldInset: CGFloat = 3
            
            fieldShape
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.42, green: 0.30, blue: 0.18),
                            Color(red: 0.32, green: 0.22, blue: 0.12),
                            Color(red: 0.24, green: 0.16, blue: 0.09)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: fieldWidth, height: fieldHeight)
                .overlay {
                    ZStack(alignment: .top) {
                        // Faixa de vegetação no topo
                        UnevenRoundedRectangle(
                            topLeadingRadius: metrics.roadCorner * 0.5,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: metrics.roadCorner * 0.5,
                            style: .continuous
                        )
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.34, green: 0.52, blue: 0.24),
                                    Color(red: 0.26, green: 0.40, blue: 0.18)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: (fieldHeight - fieldInset * 2) * 0.38)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        
                        // Sulcos do campo
                        HStack(spacing: 10) {
                            ForEach(0..<18, id: \.self) { i in
                                Capsule()
                                    .fill(Color.black.opacity(i.isMultiple(of: 2) ? 0.18 : 0.10))
                                    .frame(width: 36 + CGFloat(i % 3) * 8, height: 2.5)
                                    .offset(y: CGFloat((i % 4) - 1) * 3)
                            }
                        }
                        .offset(x: fieldOffset * 0.55)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        
                        // Linhas de terra mais escuras
                        HStack(spacing: 18) {
                            ForEach(0..<14, id: \.self) { _ in
                                Capsule()
                                    .fill(Color(red: 0.16, green: 0.10, blue: 0.06).opacity(0.55))
                                    .frame(width: 56, height: 4)
                            }
                        }
                        .offset(x: fieldOffset, y: fieldHeight * 0.12)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    }
                    .padding(fieldInset)
                }
                .clipShape(fieldShape)
                .overlay(
                    fieldShape
                        .stroke(Color(red: 0.20, green: 0.32, blue: 0.14).opacity(0.55), lineWidth: 1)
                )
                .offset(y: metrics.roadOffsetY)
            
            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { i in
                    Circle()
                        .fill(Color(red: 0.55, green: 0.42, blue: 0.28).opacity(dustPulse ? 0.35 : 0.12))
                        .frame(width: CGFloat(5 + i), height: CGFloat(5 + i))
                        .offset(y: dustPulse ? -10 : -3)
                }
            }
            .offset(
                x: -travel / 2 + travel * tractorProgress - metrics.tractorWidth * 0.18,
                y: metrics.carOffsetY + 20
            )
            
            // Trator completo + sprites das rodas girando por cima das rodas da arte
            let tw = metrics.tractorWidth
            let th = metrics.tractorHeight
            // Centros medidos na PNG 1024×609 (template match)
            let frontSize = tw * (268.0 / 1024.0)
            let rearSize = tw * (358.0 / 1024.0)
            
            Image("transition_tractor")
                .resizable()
                .interpolation(.high)
                .frame(width: tw, height: th)
                .overlay {
                    ZStack(alignment: .topLeading) {
                        // Dianteira — centro do pneu na arte (um pouco mais alto que o match anterior)
                        Image("transition_tractor_wheel_front")
                            .resizable()
                            .interpolation(.high)
                            .frame(width: frontSize, height: frontSize)
                            .rotationEffect(.degrees(-wheelRotation * 1.35))
                            .offset(
                                x: tw * 0.2363 - frontSize / 2,
                                y: th * 0.7725 - frontSize / 2
                            )
                        
                        // Traseira — posição que já estava correta
                        Image("transition_tractor_wheel_rear")
                            .resizable()
                            .interpolation(.high)
                            .frame(width: rearSize, height: rearSize)
                            .rotationEffect(.degrees(-wheelRotation))
                            .offset(
                                x: tw * 0.7393 - rearSize / 2,
                                y: th * 0.7126 - rearSize / 2
                            )
                    }
                    .frame(width: tw, height: th, alignment: .topLeading)
                }
                .scaleEffect(x: -1, y: 1)
                .rotationEffect(.degrees(tractorTilt))
                .offset(
                    x: -travel / 2 + travel * tractorProgress,
                    y: metrics.carOffsetY + tractorBounce
                )
                .shadow(color: .black.opacity(0.35), radius: 10, y: 6)
                .shadow(color: AWTheme.moduleTrator.opacity(0.28), radius: 14, y: 0)
                .accessibilityHidden(true)
        }
    }
    
    // MARK: - Layout
    
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
        // Proporção real do asset (1024×609)
        let tractorWidth = carWidth * 0.92
        let tractorHeight = tractorWidth * (609.0 / 1024.0)
        let roadHeight: CGFloat = isPad ? 100 : (compactHeight ? 62 : 76)
        let sceneHeight = max(max(carHeight, tractorHeight) + roadHeight * 0.75, isPad ? 190 : 140)
        
        return TransitionMetrics(
            brandSize: brandSize,
            subtitleSize: isPad ? 16 : (compactHeight ? 12 : 13),
            horizontalPadding: isPad ? 48 : 20,
            roadSideMargin: isPad ? 36 : 22,
            contentSpacing: isPad ? 20 : 10,
            topSpacer: isPad ? max(48, height * 0.12) : (compactHeight ? 36 : max(40, height * 0.08)),
            midSpacer: isPad ? 36 : (compactHeight ? 18 : 28),
            bottomSpacer: isPad ? max(40, height * 0.10) : (compactHeight ? 28 : max(32, height * 0.07)),
            carWidth: carWidth,
            carHeight: carHeight,
            tractorWidth: tractorWidth,
            tractorHeight: tractorHeight,
            carOffsetY: -roadHeight * 0.35,
            roadHeight: roadHeight,
            roadCorner: isPad ? 24 : 16,
            roadOffsetY: carHeight * 0.22,
            sceneHeight: sceneHeight,
            dashWidth: isPad ? 44 : 28,
            dashSpacing: isPad ? 24 : 16
        )
    }
    
    // MARK: - Animation
    
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
        
        withAnimation(.linear(duration: carDuration)) {
            carProgress = 1
            roadOffset = -320
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + carDuration) {
            startTractorPhase()
        }
    }
    
    private func startTractorPhase() {
        withAnimation(.easeInOut(duration: 0.45)) {
            phase = .tractor
            carSceneOpacity = 0
            tractorOpacity = 1
        }
        
        withAnimation(.linear(duration: tractorDuration)) {
            tractorProgress = 1
            fieldOffset = -55
        }
        
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
            tractorBounce = -2.5
            tractorTilt = -1.0
            dustPulse = true
        }
        
        wheelRotation = 0
        withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false)) {
            wheelRotation = 360
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + tractorDuration) {
            onFinished()
        }
    }
}

private enum TransitionPhase {
    case car
    case tractor
}

private struct TransitionMetrics {
    let brandSize: CGFloat
    let subtitleSize: CGFloat
    let horizontalPadding: CGFloat
    let roadSideMargin: CGFloat
    let contentSpacing: CGFloat
    let topSpacer: CGFloat
    let midSpacer: CGFloat
    let bottomSpacer: CGFloat
    let carWidth: CGFloat
    let carHeight: CGFloat
    let tractorWidth: CGFloat
    let tractorHeight: CGFloat
    let carOffsetY: CGFloat
    let roadHeight: CGFloat
    let roadCorner: CGFloat
    let roadOffsetY: CGFloat
    let sceneHeight: CGFloat
    let dashWidth: CGFloat
    let dashSpacing: CGFloat
}

#Preview("iPhone") {
    LoginTransitionView {}
        .preferredColorScheme(.dark)
}

#Preview("iPad") {
    LoginTransitionView {}
        .preferredColorScheme(.dark)
}
