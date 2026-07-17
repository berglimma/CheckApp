//
//  RelatoriosView.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import SwiftUI
import SwiftData
import UIKit

struct RelatoriosView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \CheckListHistorico.data, order: .reverse) private var historicos: [CheckListHistorico]
    
    @State private var filter: String = "Todos"
    @State private var shareItem: PDFShareItem?
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var itemToDelete: CheckListHistorico?
    @State private var showDeleteConfirm = false
    @State private var isUploadingDrive = false
    @State private var driveLink: URL?
    
    private let filters = ["Todos", "Entrega", "Devolução", "Troca", "Trator", "Avarias"]
    
    private var filtered: [CheckListHistorico] {
        if filter == "Todos" { return historicos }
        return historicos.filter { $0.tipo == filter }
    }
    
    var body: some View {
        ZStack {
            AWScreenBackground()
            
            if filtered.isEmpty {
                VStack(spacing: 16) {
                    AWEmptyState(
                        systemImage: "doc.richtext",
                        title: "Sem relatórios",
                        message: "Salve checklists, trocas, avaliações ou avarias para exportar em PDF."
                    )
                    
                    NavigationLink {
                        DriveRelatoriosView()
                    } label: {
                        Label("Buscar no Google Drive", systemImage: "externaldrive.badge.icloud")
                            .font(AWTheme.headline(15))
                            .foregroundStyle(AWTheme.moduleHistorico)
                    }
                }
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(filters, id: \.self) { item in
                                    Button(item) {
                                        filter = item
                                    }
                                    .font(AWTheme.caption(12))
                                    .foregroundStyle(filter == item ? .white : AWTheme.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(filter == item ? AWTheme.accent : AWTheme.fieldFill)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                            }
                        }
                        
                        ForEach(filtered) { item in
                            reportRow(item)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        itemToDelete = item
                                        showDeleteConfirm = true
                                    } label: {
                                        Label("Excluir", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .awReadableWidth(AWLayout.listMaxWidth)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
            }
            
            if isUploadingDrive {
                Color.black.opacity(0.35).ignoresSafeArea()
                ProgressView("Enviando ao Google Drive…")
                    .padding(20)
                    .background(AWTheme.cardFill)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .navigationTitle("Relatórios")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AWTheme.screenGray, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    DriveRelatoriosView()
                } label: {
                    Label("Drive", systemImage: "externaldrive.badge.icloud")
                }
                .accessibilityLabel("Buscar no Google Drive")
            }
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
                if let itemToDelete {
                    ReportRepository.delete(item: itemToDelete, context: context)
                }
                itemToDelete = nil
            }
            Button("Cancelar", role: .cancel) {
                itemToDelete = nil
            }
        } message: {
            Text("Essa ação remove o relatório e as fotos associadas.")
        }
    }
    
    private func reportRow(_ item: CheckListHistorico) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                NavigationLink {
                    HistoricoDetailView(item: item)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.nomeCliente.isEmpty ? "Sem cliente" : item.nomeCliente)
                                .font(AWTheme.headline(15))
                                .foregroundStyle(AWTheme.textPrimary)
                            Text("\(item.tipo) · \(item.placa)")
                                .font(AWTheme.caption(12))
                                .foregroundStyle(AWTheme.textSecondary)
                            Text(format(item.data))
                                .font(AWTheme.caption(12))
                                .foregroundStyle(AWTheme.textSecondary)
                        }
                        Spacer()
                        AWBadge(text: item.tipo, color: color(for: item.tipo))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AWTheme.textSecondary)
                    }
                }
                .buttonStyle(.plain)
                
                Button {
                    itemToDelete = item
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AWTheme.danger)
                        .padding(8)
                        .background(AWTheme.danger.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Excluir relatório")
            }
            
            VStack(spacing: 8) {
                AWPrimaryButton(title: "Exportar PDF") {
                    export(item)
                }
                
                AWSecondaryButton(title: "Enviar ao Google Drive", tint: AWTheme.moduleHistorico) {
                    Task { await uploadToDrive(item) }
                }
                .disabled(isUploadingDrive)
            }
        }
        .padding(14)
        .background(AWTheme.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: AWTheme.radiusM, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AWTheme.radiusM, style: .continuous)
                .stroke(AWTheme.stroke, lineWidth: 1)
        )
    }
    
    private func makePDFURL(for item: CheckListHistorico) -> URL? {
        let ownerId = item.ownerId.isEmpty ? item.id.uuidString : item.ownerId
        
        let snapshot = item.snapshot ?? ReportSnapshot(
            id: item.id,
            tipo: item.tipo.isEmpty ? "Relatório" : item.tipo,
            titulo: "Relatório de \(item.tipo.isEmpty ? "operação" : item.tipo)",
            cliente: item.nomeCliente,
            placa: item.placa,
            funcionario: item.funcionario,
            dataRegistro: item.data,
            horaRegistro: item.horaRegistro,
            campos: [
                "Registro": item.id.uuidString
            ],
            observacoes: "",
            ownerId: ownerId
        )
        
        let photos = PhotoStore.shared
            .loadImages(ownerId: snapshot.ownerId, context: context)
            .map(\.1)
        
        return ReportPDFService.generate(
            snapshot: snapshot,
            photos: photos,
            signature: snapshot.signatureImage
        )
    }
    
    private func export(_ item: CheckListHistorico) {
        guard let url = makePDFURL(for: item) else {
            alertMessage = "Não foi possível gerar o PDF."
            driveLink = nil
            showAlert = true
            return
        }
        shareItem = PDFShareItem(url: url)
    }
    
    private func uploadToDrive(_ item: CheckListHistorico) async {
        guard let url = makePDFURL(for: item) else {
            alertMessage = "Não foi possível gerar o PDF."
            driveLink = nil
            showAlert = true
            return
        }
        
        let stamp = formatFileStamp(item.data)
        let safeClient = item.nomeCliente
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
        let name = "AutoWize_\(item.tipo)_\(safeClient)_\(stamp).pdf"
        
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
        f.dateFormat = "dd/MM/yyyy HH:mm"
        return f.string(from: date)
    }
    
    private func formatFileStamp(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyyMMdd_HHmm"
        return f.string(from: date)
    }
    
    private func color(for tipo: String) -> Color {
        switch tipo {
        case "Devolução": return AWTheme.moduleDevolucao
        case "Troca": return AWTheme.moduleTroca
        case "Trator": return AWTheme.moduleTrator
        case "Avarias": return AWTheme.moduleAvarias
        default: return AWTheme.moduleEntrega
        }
    }
}

#Preview {
    NavigationStack { RelatoriosView() }
}
