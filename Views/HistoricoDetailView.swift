//
//  HistoricoDetailView.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import SwiftUI
import SwiftData
import UIKit

struct HistoricoDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    let item: CheckListHistorico
    
    @State private var photos: [UIImage] = []
    @State private var shareItem: PDFShareItem?
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showDeleteConfirm = false
    @State private var isUploadingDrive = false
    @State private var driveLink: URL?
    
    private var snapshot: ReportSnapshot {
        let ownerId = item.ownerId.isEmpty ? item.id.uuidString : item.ownerId
        return item.snapshot ?? ReportSnapshot(
            id: item.id,
            tipo: item.tipo.isEmpty ? "Relatório" : item.tipo,
            titulo: "Relatório de \(item.tipo.isEmpty ? "operação" : item.tipo)",
            cliente: item.nomeCliente,
            placa: item.placa,
            funcionario: item.funcionario,
            dataRegistro: item.data,
            horaRegistro: item.horaRegistro,
            campos: [:],
            observacoes: "",
            ownerId: ownerId
        )
    }
    
    private var sortedCampos: [(String, String)] {
        snapshot.campos
            .map { ($0.key, $0.value) }
            .sorted { $0.0.localizedCaseInsensitiveCompare($1.0) == .orderedAscending }
    }
    
    private var badgeColor: Color {
        switch item.tipo {
        case "Devolução": return AWTheme.moduleDevolucao
        case "Troca": return AWTheme.moduleTroca
        case "Trator": return AWTheme.moduleTrator
        case "Avarias": return AWTheme.moduleAvarias
        default: return AWTheme.moduleEntrega
        }
    }
    
    var body: some View {
        ZStack {
            AWScreenBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    headerCard
                    
                    AWSectionCard(title: "Detalhes") {
                        if sortedCampos.isEmpty {
                            Text("Sem detalhes adicionais.")
                                .font(AWTheme.body(14))
                                .foregroundStyle(AWTheme.textSecondary)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(sortedCampos, id: \.0) { key, value in
                                    detailRow(
                                        title: key,
                                        value: value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                            ? "-"
                                            : value
                                    )
                                }
                            }
                        }
                    }
                    
                    if !snapshot.itensInspecao.isEmpty {
                        AWSectionCard(title: "Inspeção") {
                            VStack(alignment: .leading, spacing: 10) {
                                let ok = snapshot.itensInspecao.filter(\.isOK).count
                                let nok = snapshot.itensInspecao.count - ok
                                Text("\(ok) OK · \(nok) NOK")
                                    .font(AWTheme.caption(12))
                                    .foregroundStyle(AWTheme.textSecondary)
                                
                                ForEach(snapshot.itensInspecao) { inspItem in
                                    HStack(spacing: 10) {
                                        Image(systemName: inspItem.isOK ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundStyle(inspItem.isOK ? AWTheme.accent : AWTheme.danger)
                                        Text(inspItem.title)
                                            .font(AWTheme.body(14))
                                            .foregroundStyle(AWTheme.textPrimary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Text(inspItem.isOK ? "OK" : "NOK")
                                            .font(AWTheme.caption(12))
                                            .foregroundStyle(inspItem.isOK ? AWTheme.accent : AWTheme.danger)
                                    }
                                }
                            }
                        }
                    }
                    
                    if !snapshot.observacoes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        AWSectionCard(title: "Observações") {
                            Text(snapshot.observacoes)
                                .font(AWTheme.body(14))
                                .foregroundStyle(AWTheme.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    if let signature = snapshot.signatureImage {
                        AWSectionCard(title: "Assinatura") {
                            Image(uiImage: signature)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 140)
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(AWTheme.stroke, lineWidth: 1)
                                )
                        }
                    }
                    
                    if !photos.isEmpty {
                        AWSectionCard(title: "Fotos (\(photos.count))") {
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: 10),
                                    GridItem(.flexible(), spacing: 10)
                                ],
                                spacing: 10
                            ) {
                                ForEach(Array(photos.enumerated()), id: \.offset) { _, image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(minHeight: 120)
                                        .frame(maxWidth: .infinity)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                            }
                        }
                    }
                    
                    VStack(spacing: 8) {
                        AWPrimaryButton(title: "Exportar PDF") {
                            exportPDF()
                        }
                        
                        AWSecondaryButton(title: "Enviar ao Google Drive", tint: AWTheme.moduleHistorico) {
                            Task { await uploadToDrive() }
                        }
                        .disabled(isUploadingDrive)
                    }
                    .padding(.bottom, 28)
                }
                .awReadableWidth(AWLayout.formMaxWidth)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            
            if isUploadingDrive {
                Color.black.opacity(0.35).ignoresSafeArea()
                ProgressView("Enviando ao Google Drive…")
                    .padding(20)
                    .background(AWTheme.cardFill)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .navigationTitle(snapshot.titulo)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AWTheme.screenGray, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(AWTheme.danger)
                }
                .accessibilityLabel("Excluir")
            }
        }
        .task {
            loadPhotos()
        }
        .sheet(item: $shareItem) { item in
            PDFShareSheet(url: item.url)
        }
        .alert("Relatório", isPresented: $showAlert) {
            if let driveLink {
                Button("Abrir no Drive") {
                    UIApplication.shared.open(driveLink)
                }
            }
            Button("OK", role: .cancel) {
                self.driveLink = nil
            }
        } message: {
            Text(alertMessage)
        }
        .confirmationDialog(
            "Excluir relatório?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Excluir", role: .destructive) {
                ReportRepository.delete(item: item, context: context)
                dismiss()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Essa ação remove o relatório e as fotos associadas.")
        }
    }
    
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(snapshot.cliente.isEmpty ? "Sem cliente" : snapshot.cliente)
                        .font(AWTheme.headline(18))
                        .foregroundStyle(AWTheme.textPrimary)
                    Text(format(snapshot.dataRegistro) + (snapshot.horaRegistro.isEmpty ? "" : " · \(snapshot.horaRegistro)"))
                        .font(AWTheme.caption(12))
                        .foregroundStyle(AWTheme.textSecondary)
                }
                Spacer()
                AWBadge(text: snapshot.tipo, color: badgeColor)
            }
            
            Divider().opacity(0.35)
            
            detailRow(title: "Placa / ID", value: snapshot.placa.isEmpty ? "-" : snapshot.placa)
            detailRow(title: "Funcionário", value: snapshot.funcionario.isEmpty ? "-" : snapshot.funcionario)
        }
        .padding(16)
        .background(AWTheme.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: AWTheme.radiusL, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AWTheme.radiusL, style: .continuous)
                .stroke(AWTheme.stroke, lineWidth: 1)
        )
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(AWTheme.caption(12))
                .foregroundStyle(AWTheme.textSecondary)
                .frame(width: 120, alignment: .leading)
            Text(value)
                .font(AWTheme.body(14))
                .foregroundStyle(AWTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func loadPhotos() {
        photos = PhotoStore.shared
            .loadImages(ownerId: snapshot.ownerId, context: context)
            .map(\.1)
    }
    
    private func exportPDF() {
        guard let url = ReportPDFService.generate(
            snapshot: snapshot,
            photos: photos,
            signature: snapshot.signatureImage
        ) else {
            alertMessage = "Não foi possível gerar o PDF."
            driveLink = nil
            showAlert = true
            return
        }
        shareItem = PDFShareItem(url: url)
    }
    
    private func uploadToDrive() async {
        guard let url = ReportPDFService.generate(
            snapshot: snapshot,
            photos: photos,
            signature: snapshot.signatureImage
        ) else {
            alertMessage = "Não foi possível gerar o PDF."
            driveLink = nil
            showAlert = true
            return
        }
        
        let stamp = formatFileStamp(snapshot.dataRegistro)
        let safeClient = snapshot.cliente
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
        let name = "AutoWize_\(snapshot.tipo)_\(safeClient)_\(stamp).pdf"
        
        isUploadingDrive = true
        defer { isUploadingDrive = false }
        
        do {
            let result = try await GoogleDriveService.uploadPDF(
                fileURL: url,
                preferredName: name
            )
            driveLink = result.webViewLink
            alertMessage = "PDF enviado para a pasta “\(GoogleDriveService.folderName)” no Google Drive.\nArquivo: \(result.fileName)"
            showAlert = true
        } catch {
            driveLink = nil
            if let driveError = error as? GoogleDriveError, case .cancelled = driveError {
                return
            }
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
    
    private func format(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "dd/MM/yyyy"
        return f.string(from: date)
    }
    
    private func formatFileStamp(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyyMMdd_HHmm"
        return f.string(from: date)
    }
}
