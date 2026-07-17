//
//  AWComponents.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import SwiftUI
import PencilKit

// MARK: - Screen Background

struct AWScreenBackground: View {
    var body: some View {
        ZStack {
            AWTheme.screenGray
            LinearGradient(
                colors: [
                    Color.black.opacity(0.35),
                    AWTheme.accent.opacity(0.06),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Buttons

struct AWPrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void
    
    @State private var pressed = false
    
    var body: some View {
        Button(action: {
            guard !isLoading && !isDisabled else { return }
            withAnimation(.easeOut(duration: 0.12)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) { pressed = false }
                action()
            }
        }) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
                Text(title)
                    .font(AWTheme.headline(17))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: AWTheme.fieldHeight)
            .background(
                RoundedRectangle(cornerRadius: AWTheme.radiusM, style: .continuous)
                    .fill(isDisabled ? Color.gray.opacity(0.4) : AWTheme.accent)
            )
            .scaleEffect(pressed ? 0.97 : 1)
            .opacity(isDisabled ? 0.75 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || isLoading)
    }
}

struct AWSecondaryButton: View {
    let title: String
    var tint: Color = AWTheme.accentDeep
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AWTheme.headline(17))
                .foregroundStyle(tint)
                .frame(maxWidth: .infinity)
                .frame(height: AWTheme.fieldHeight)
                .background(AWTheme.cardFill)
                .clipShape(RoundedRectangle(cornerRadius: AWTheme.radiusM, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AWTheme.radiusM, style: .continuous)
                        .stroke(tint.opacity(0.4), lineWidth: 1.2)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Fields

struct AWTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    
    var body: some View {
        TextField(placeholder, text: $text)
            .font(AWTheme.body())
            .foregroundStyle(AWTheme.textPrimary)
            .keyboardType(keyboard)
            .textInputAutocapitalization(autocapitalization)
            .padding(.horizontal, 16)
            .frame(height: AWTheme.fieldHeight)
            .background(AWTheme.fieldFill)
            .clipShape(RoundedRectangle(cornerRadius: AWTheme.radiusM, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AWTheme.radiusM, style: .continuous)
                    .stroke(AWTheme.stroke, lineWidth: 1)
            )
    }
}

struct AWSecureField: View {
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        SecureField(placeholder, text: $text)
            .font(AWTheme.body())
            .foregroundStyle(AWTheme.textPrimary)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(.horizontal, 16)
            .frame(height: AWTheme.fieldHeight)
            .background(AWTheme.fieldFill)
            .clipShape(RoundedRectangle(cornerRadius: AWTheme.radiusM, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AWTheme.radiusM, style: .continuous)
                    .stroke(AWTheme.stroke, lineWidth: 1)
            )
    }
}

// MARK: - Section Card

struct AWSectionCard<Content: View>: View {
    var title: String? = nil
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                Text(title)
                    .font(AWTheme.headline(14))
                    .foregroundStyle(AWTheme.textSecondary)
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AWTheme.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: AWTheme.radiusL, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AWTheme.radiusL, style: .continuous)
                .stroke(AWTheme.stroke, lineWidth: 1)
        )
    }
}

// MARK: - Menu Row

struct AWMenuRow<Destination: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let accent: Color
    let destination: Destination
    var delay: Double = 0
    var showsDivider: Bool = false
    
    @State private var appeared = false
    
    var body: some View {
        VStack(spacing: 0) {
            NavigationLink(destination: destination) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(accent.opacity(0.14))
                            .frame(width: 44, height: 44)
                        Image(systemName: systemImage)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(accent)
                            .frame(width: 44, height: 44)
                    }
                    .frame(width: 44, height: 44)
                    .clipped()
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(AWTheme.headline(15))
                            .foregroundStyle(AWTheme.textPrimary)
                            .lineLimit(1)
                        Text(subtitle)
                            .font(AWTheme.caption(12))
                            .foregroundStyle(AWTheme.textSecondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AWTheme.textSecondary.opacity(0.5))
                }
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if showsDivider {
                Divider()
                    .opacity(0.35)
                    .padding(.leading, 56)
            }
        }
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.35).delay(delay)) {
                appeared = true
            }
        }
    }
}

/// Agrupa as operações em um único formulário/card.
struct AWOperationsForm<Content: View>: View {
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Operações")
                .font(AWTheme.headline(14))
                .foregroundStyle(AWTheme.textSecondary)
                .padding(.bottom, 12)
            
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AWTheme.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: AWTheme.radiusL, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AWTheme.radiusL, style: .continuous)
                .stroke(AWTheme.stroke, lineWidth: 1)
        )
    }
}

// MARK: - Empty State

struct AWEmptyState: View {
    let systemImage: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(AWTheme.accent)
            Text(title)
                .font(AWTheme.headline(18))
                .foregroundStyle(AWTheme.textPrimary)
            Text(message)
                .font(AWTheme.body(14))
                .foregroundStyle(AWTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Badge

struct AWBadge: View {
    let text: String
    var color: Color = AWTheme.accent
    
    var body: some View {
        Text(text)
            .font(AWTheme.caption(11))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .fixedSize()
    }
}

// MARK: - Screen Title

struct AWScreenTitle: View {
    let title: String
    var subtitle: String? = nil
    
    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(AWTheme.title(22))
                .foregroundStyle(AWTheme.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let subtitle {
                Text(subtitle)
                    .font(AWTheme.caption(13))
                    .foregroundStyle(AWTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
}

// MARK: - Fuel Slider

struct AWFuelSlider: View {
    @Binding var value: Double
    var labelProvider: (Double) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "fuelpump.fill")
                    .foregroundStyle(AWTheme.accent)
                Text("Nível: \(labelProvider(value))")
                    .font(AWTheme.headline(14))
                    .foregroundStyle(AWTheme.textPrimary)
                Spacer()
            }
            
            Slider(value: $value, in: 0...1, step: 0.125)
                .tint(AWTheme.accent)
            
            HStack(spacing: 0) {
                ForEach(0..<9, id: \.self) { index in
                    Text("\(index)")
                        .font(AWTheme.caption(10))
                        .foregroundStyle(AWTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - Signature Pad

struct AWSignaturePad: View {
    @Binding var canvasView: PKCanvasView
    var onClear: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Assinatura")
                    .font(AWTheme.headline(14))
                    .foregroundStyle(AWTheme.textPrimary)
                Spacer()
                Button("Limpar", action: onClear)
                    .font(AWTheme.caption(12))
                    .foregroundStyle(AWTheme.danger)
            }
            
            // Sem clipShape/background SwiftUI — eles bloqueiam toques no PKCanvasView.
            CanvasView(canvasView: $canvasView)
                .frame(height: 160)
                .contentShape(Rectangle())
        }
    }
}

// MARK: - Notes Editor

struct AWNotesEditor: View {
    @Binding var text: String
    var placeholder: String = "Digite observações..."
    var minHeight: CGFloat = 100
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(placeholder)
                    .font(AWTheme.body(15))
                    .foregroundStyle(AWTheme.textSecondary.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
            }
            
            TextEditor(text: $text)
                .font(AWTheme.body(15))
                .foregroundStyle(AWTheme.textPrimary)
                .frame(minHeight: minHeight)
                .scrollContentBackground(.hidden)
                .padding(8)
        }
        .background(AWTheme.fieldFill)
        .clipShape(RoundedRectangle(cornerRadius: AWTheme.radiusM, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AWTheme.radiusM, style: .continuous)
                .stroke(AWTheme.stroke, lineWidth: 1)
        )
    }
}

// MARK: - Date Field

struct AWDateField: View {
    let title: String
    @Binding var date: Date
    
    var body: some View {
        DatePicker(title, selection: $date, displayedComponents: .date)
            .font(AWTheme.body(15))
            .foregroundStyle(AWTheme.textPrimary)
            .padding(.horizontal, 12)
            .frame(height: AWTheme.fieldHeight)
            .background(AWTheme.fieldFill)
            .clipShape(RoundedRectangle(cornerRadius: AWTheme.radiusM, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AWTheme.radiusM, style: .continuous)
                    .stroke(AWTheme.stroke, lineWidth: 1)
            )
    }
}

// MARK: - Inspection List

struct AWInspectionList: View {
    @Binding var items: [InspectionToggleItem]
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach($items) { $item in
                Toggle(isOn: $item.isOK) {
                    Text(item.title)
                        .font(AWTheme.body(15))
                        .foregroundStyle(AWTheme.textPrimary)
                }
                .tint(AWTheme.accent)
                .padding(.vertical, 10)
                
                if item.id != items.last?.id {
                    Divider().opacity(0.35)
                }
            }
        }
    }
}

// MARK: - Picker Field

struct AWPickerField<T: Hashable & Identifiable>: View where T: RawRepresentable, T.RawValue == String {
    let title: String
    @Binding var selection: T
    let options: [T]
    
    var body: some View {
        HStack {
            Text(title)
                .font(AWTheme.body(15))
                .foregroundStyle(AWTheme.textSecondary)
            Spacer()
            Picker("", selection: $selection) {
                ForEach(options) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .labelsHidden()
            .tint(AWTheme.accentDeep)
        }
        .padding(.horizontal, 12)
        .frame(height: AWTheme.fieldHeight)
        .background(AWTheme.fieldFill)
        .clipShape(RoundedRectangle(cornerRadius: AWTheme.radiusM, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AWTheme.radiusM, style: .continuous)
                .stroke(AWTheme.stroke, lineWidth: 1)
        )
    }
}

