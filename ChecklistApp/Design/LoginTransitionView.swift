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
    
    @State private var carProgress: CGFloat = 0
    @State private var roadOffset: CGFloat = 0
    @State private var brandOpacity: Double = 0
    @State private var brandScale: CGFloat = 0.86
    @State private var subtitleOpacity: Double = 0
    @State private var glowPulse = false
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let carWidth = min(220, width * 0.42)
            let travel = width + carWidth + 40
            
            ZStack {
                AWScreenBackground()
                
                // Atmosfera
                RadialGradient(
                    colors: [
                        AWTheme.accent.opacity(glowPulse ? 0.22 : 0.10),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 20,
                    endRadius: max(width, height) * 0.55
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer(minLength: height * 0.18)
                    
                    Text("AutoWize")
                        .font(AWTheme.brand(min(48, width * 0.12)))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, AWTheme.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: AWTheme.accent.opacity(0.45), radius: glowPulse ? 18 : 8, y: 2)
                        .scaleEffect(brandScale)
                        .opacity(brandOpacity)
                    
                    Text("Preparando o painel de operações")
                        .font(AWTheme.caption(14))
                        .foregroundStyle(AWTheme.textSecondary)
                        .padding(.top, 10)
                        .opacity(subtitleOpacity)
                    
                    Spacer()
                    
                    roadScene(
                        width: width,
                        carWidth: carWidth,
                        travel: travel
                    )
                    .frame(height: 160)
                    .padding(.bottom, max(36, height * 0.12))
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startAnimation()
        }
    }
    
    private func roadScene(width: CGFloat, carWidth: CGFloat, travel: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            // Asfalto
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.13, blue: 0.15),
                            Color(red: 0.07, green: 0.08, blue: 0.09)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 88)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .padding(.horizontal, 12)
            
            // Faixa tracejada em movimento
            HStack(spacing: 18) {
                ForEach(0..<16, id: \.self) { _ in
                    Capsule()
                        .fill(Color.white.opacity(0.55))
                        .frame(width: 34, height: 5)
                }
            }
            .offset(x: roadOffset)
            .mask(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .frame(height: 88)
                    .padding(.horizontal, 20)
            )
            .padding(.bottom, 40)
            
            // Carro em deslocamento (imagem original aponta à esquerda)
            Image("vehicle_sedan")
                .resizable()
                .scaledToFit()
                .frame(width: carWidth)
                .scaleEffect(x: -1, y: 1)
                .shadow(color: .black.opacity(0.55), radius: 12, y: 8)
                .shadow(color: AWTheme.accent.opacity(0.25), radius: 16, y: 0)
                .offset(
                    x: -travel / 2 + travel * carProgress,
                    y: -52
                )
        }
        .frame(maxWidth: .infinity)
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
            roadOffset = -220
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            onFinished()
        }
    }
}

#Preview {
    LoginTransitionView(duration: 4) {}
        .preferredColorScheme(.dark)
}
