//
//  AWBrandModelPicker.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import SwiftUI
import UIKit

struct AWBrandModelPicker: View {
    @Binding var marca: String
    @Binding var modelo: String
    var kind: VehicleBrand.Kind = .car
    var title: String = "Marca e modelo"
    
    @State private var selectedBrandId: String?
    
    private var brands: [VehicleBrand] {
        VehicleCatalog.brands(for: kind)
    }
    
    private var selectedBrand: VehicleBrand? {
        if let selectedBrandId,
           let brand = brands.first(where: { $0.id == selectedBrandId }) {
            return brand
        }
        return VehicleCatalog.brand(named: marca, kind: kind)
    }
    
    private var selectedModel: VehicleModel? {
        selectedBrand?.models.first { $0.name.caseInsensitiveCompare(modelo) == .orderedSame }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(AWTheme.headline(14))
                .foregroundStyle(AWTheme.textSecondary)
            
            Text("Marcas")
                .font(AWTheme.caption(12))
                .foregroundStyle(AWTheme.textSecondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(brands) { brand in
                        brandCard(brand)
                    }
                }
                .padding(.vertical, 2)
            }
            
            if let brand = selectedBrand {
                Text("Modelos — \(brand.name)")
                    .font(AWTheme.caption(12))
                    .foregroundStyle(AWTheme.textSecondary)
                
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10)
                    ],
                    spacing: 10
                ) {
                    ForEach(brand.models) { model in
                        modelCard(model, brandColor: brand.color)
                    }
                }
            } else {
                Text("Selecione uma marca para ver os modelos.")
                    .font(AWTheme.caption(12))
                    .foregroundStyle(AWTheme.textSecondary)
            }
            
            if !marca.isEmpty || !modelo.isEmpty {
                HStack(spacing: 8) {
                    if let brand = selectedBrand {
                        brandLogo(brand, size: 28, cornerRadius: 6)
                    } else {
                        Image(systemName: kind == .tractor ? "leaf.fill" : "car.fill")
                            .foregroundStyle(AWTheme.accent)
                    }
                    Text([marca, modelo].filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(AWTheme.caption(13))
                        .foregroundStyle(AWTheme.textPrimary)
                    Spacer()
                    Button("Limpar") {
                        marca = ""
                        modelo = ""
                        selectedBrandId = nil
                    }
                    .font(AWTheme.caption(12))
                    .foregroundStyle(AWTheme.accent)
                }
                .padding(10)
                .background(AWTheme.fieldFill)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            
            AWTextField(placeholder: "Marca (ou digite)", text: $marca)
            AWTextField(placeholder: "Modelo (ou digite)", text: $modelo)
        }
        .onAppear {
            syncSelectionFromBindings()
        }
        .onChange(of: marca) { _, _ in
            syncSelectionFromBindings()
        }
    }
    
    private func brandCard(_ brand: VehicleBrand) -> some View {
        let isSelected = selectedBrand?.id == brand.id
        return Button {
            selectedBrandId = brand.id
            marca = brand.name
            if let current = selectedModel,
               brand.models.contains(where: { $0.name == current.name }) {
                // keep model if still valid
            } else {
                modelo = ""
            }
        } label: {
            VStack(spacing: 8) {
                brandLogo(brand, size: 56, cornerRadius: 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                isSelected ? brand.color : Color.white.opacity(0.12),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(color: isSelected ? brand.color.opacity(0.35) : .clear, radius: 6, y: 2)
                
                Text(brand.name)
                    .font(AWTheme.caption(11))
                    .foregroundStyle(isSelected ? AWTheme.textPrimary : AWTheme.textSecondary)
                    .lineLimit(1)
                    .frame(width: 78)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? brand.color.opacity(0.16) : AWTheme.fieldFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? brand.color : AWTheme.stroke, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func brandLogo(_ brand: VehicleBrand, size: CGFloat, cornerRadius: CGFloat) -> some View {
        if UIImage(named: brand.logoImageName) != nil {
            Image(brand.logoImageName)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(brand.color.opacity(0.18))
                Image(systemName: brand.symbol)
                    .font(.system(size: size * 0.38, weight: .semibold))
                    .foregroundStyle(brand.color)
            }
            .frame(width: size, height: size)
        }
    }
    
    private func modelCard(_ model: VehicleModel, brandColor: Color) -> some View {
        let isSelected = selectedModel?.id == model.id
        return Button {
            modelo = model.name
            if let brand = selectedBrand {
                marca = brand.name
            }
        } label: {
            VStack(spacing: 6) {
                Image(model.category.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                
                Text(model.name)
                    .font(AWTheme.caption(12))
                    .foregroundStyle(AWTheme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(minHeight: 28)
                
                Text(modelSubtitle(model))
                    .font(AWTheme.caption(10))
                    .foregroundStyle(powertrainColor(model.powertrain))
                    .lineLimit(1)
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? brandColor.opacity(0.18) : AWTheme.fieldFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? brandColor : AWTheme.stroke, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func modelSubtitle(_ model: VehicleModel) -> String {
        if model.powertrain == .combustion {
            return model.category.rawValue
        }
        return "\(model.category.rawValue) · \(model.powertrain.shortLabel)"
    }
    
    private func powertrainColor(_ powertrain: VehiclePowertrain) -> Color {
        switch powertrain {
        case .combustion: return AWTheme.textSecondary
        case .hybrid, .plugInHybrid: return Color(red: 0.15, green: 0.55, blue: 0.35)
        case .electric: return Color(red: 0.10, green: 0.45, blue: 0.75)
        }
    }
    
    private func syncSelectionFromBindings() {
        if let brand = VehicleCatalog.brand(named: marca, kind: kind) {
            selectedBrandId = brand.id
        }
    }
}
