//
//  AWPhotoGallery.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import SwiftUI
import PhotosUI
import SwiftData
import UIKit

struct AWPhotoGallery: View {
    let ownerId: String
    let ownerType: PhotoOwnerType
    var title: String = "Fotos"
    var maxPhotos: Int = 8
    
    @Environment(\.modelContext) private var context
    @State private var photos: [(PhotoAttachment, UIImage)] = []
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var showPicker = false
    @State private var replacing: PhotoAttachment?
    @State private var replacePickerItem: PhotosPickerItem?
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(AWTheme.headline(14))
                    .foregroundStyle(AWTheme.textSecondary)
                Spacer()
                Text("\(photos.count)/\(maxPhotos)")
                    .font(AWTheme.caption(12))
                    .foregroundStyle(AWTheme.textSecondary)
            }
            
            if photos.isEmpty {
                Text("Nenhuma foto adicionada.")
                    .font(AWTheme.body(14))
                    .foregroundStyle(AWTheme.textSecondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(photos, id: \.0.id) { item in
                            photoCard(attachment: item.0, image: item.1)
                        }
                    }
                }
            }
            
            HStack(spacing: 10) {
                PhotosPicker(
                    selection: $pickerItems,
                    maxSelectionCount: max(1, maxPhotos - photos.count),
                    matching: .images
                ) {
                    labelButton(title: "Inserir", systemImage: "plus.circle.fill", disabled: photos.count >= maxPhotos)
                }
                .disabled(photos.count >= maxPhotos)
            }
        }
        .onAppear(perform: reload)
        .onChange(of: pickerItems) { _, items in
            Task { await insertPicked(items) }
        }
        .onChange(of: replacePickerItem) { _, item in
            guard let item else { return }
            Task { await replacePicked(item) }
        }
        .alert("Erro", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Falha ao processar foto.")
        }
    }
    
    private func photoCard(attachment: PhotoAttachment, image: UIImage) -> some View {
        VStack(spacing: 6) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(AWTheme.stroke, lineWidth: 1)
                )
            
            HStack(spacing: 8) {
                PhotosPicker(selection: $replacePickerItem, matching: .images) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AWTheme.accentDeep)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    replacing = attachment
                })
                
                Button {
                    delete(attachment)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AWTheme.danger)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func labelButton(title: String, systemImage: String, disabled: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
            Text(title)
        }
        .font(AWTheme.headline(14))
        .foregroundStyle(disabled ? AWTheme.textSecondary : .white)
        .padding(.horizontal, 14)
        .frame(height: 40)
        .background(disabled ? Color.gray.opacity(0.3) : AWTheme.accent)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
    
    private func reload() {
        photos = PhotoStore.shared.loadImages(ownerId: ownerId, context: context)
    }
    
    private func insertPicked(_ items: [PhotosPickerItem]) async {
        defer { pickerItems = [] }
        for item in items {
            guard photos.count < maxPhotos else { break }
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else { continue }
            do {
                try PhotoStore.shared.insert(
                    image: image,
                    ownerId: ownerId,
                    ownerType: ownerType,
                    context: context
                )
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
        reload()
    }
    
    private func replacePicked(_ item: PhotosPickerItem) async {
        defer {
            replacePickerItem = nil
            replacing = nil
        }
        guard let replacing,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        do {
            try PhotoStore.shared.replace(attachment: replacing, with: image, context: context)
            reload()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func delete(_ attachment: PhotoAttachment) {
        do {
            try PhotoStore.shared.delete(attachment: attachment, context: context)
            reload()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

/// Foto única de perfil (inserir / substituir / excluir)
struct AWProfilePhotoPicker: View {
    let ownerId: String
    @Binding var image: UIImage?
    
    @Environment(\.modelContext) private var context
    @State private var pickerItem: PhotosPickerItem?
    @State private var attachment: PhotoAttachment?
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AWTheme.fieldFill)
                    .frame(width: 110, height: 110)
                    .overlay(Circle().stroke(AWTheme.accent.opacity(0.35), lineWidth: 2))
                
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 110, height: 110)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(AWTheme.accent)
                }
            }
            
            HStack(spacing: 10) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Text(image == nil ? "Inserir foto" : "Substituir")
                        .font(AWTheme.headline(14))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .frame(height: 40)
                        .background(AWTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                
                if image != nil {
                    Button("Excluir") {
                        deletePhoto()
                    }
                    .font(AWTheme.headline(14))
                    .foregroundStyle(AWTheme.danger)
                    .padding(.horizontal, 14)
                    .frame(height: 40)
                    .background(AWTheme.fieldFill)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(AWTheme.danger.opacity(0.4), lineWidth: 1)
                    )
                }
            }
        }
        .onAppear(perform: load)
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task { await pick(item) }
        }
    }
    
    private func load() {
        let loaded = PhotoStore.shared.loadImages(ownerId: ownerId, context: context)
        attachment = loaded.first?.0
        image = loaded.first?.1
    }
    
    private func pick(_ item: PhotosPickerItem) async {
        defer { pickerItem = nil }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else { return }
        do {
            if let attachment {
                try PhotoStore.shared.replace(attachment: attachment, with: uiImage, context: context)
            } else {
                let created = try PhotoStore.shared.insert(
                    image: uiImage,
                    ownerId: ownerId,
                    ownerType: .profile,
                    context: context
                )
                attachment = created
            }
            image = uiImage
            // Notifica o painel via binding onChange no ProfileView
        } catch {
            print(error)
        }
    }
    
    private func deletePhoto() {
        guard let attachment else {
            image = nil
            return
        }
        try? PhotoStore.shared.delete(attachment: attachment, context: context)
        self.attachment = nil
        image = nil
    }
}
