//
//  DriveRelatoriosView.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import SwiftUI
import UIKit

struct DriveRelatoriosView: View {
    @State private var searchText = ""
    @State private var files: [GoogleDriveFile] = []
    @State private var isLoading = false
    @State private var didLoadOnce = false
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var tipoFilter = "Todos"
    
    private let tipoFilters = ["Todos", "Entrega", "Devolução", "Troca", "Trator", "Avarias"]
    
    private var filteredFiles: [GoogleDriveFile] {
        guard tipoFilter != "Todos" else { return files }
        return files.filter {
            $0.inferredTipo.localizedCaseInsensitiveCompare(tipoFilter) == .orderedSame
        }
    }
    
    private var dayGroups: [GoogleDriveDayGroup] {
        GoogleDriveService.groupByDay(filteredFiles)
    }
    
    var body: some View {
        ZStack {
            AWScreenBackground()
            
            VStack(spacing: 0) {
                searchHeader
                
                if isLoading && files.isEmpty {
                    Spacer()
                    ProgressView("Buscando no Google Drive…")
                    Spacer()
                } else if dayGroups.isEmpty {
                    AWEmptyState(
                        systemImage: "externaldrive.badge.icloud",
                        title: didLoadOnce ? "Nenhum relatório no Drive" : "Google Drive",
                        message: didLoadOnce
                            ? "Envie PDFs em Relatórios ou ajuste a busca/filtro."
                            : "Toque em Atualizar para listar os PDFs da pasta Auto Wize Relatórios."
                    )
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(alignment: .leading, spacing: 16, pinnedViews: [.sectionHeaders]) {
                            ForEach(dayGroups) { group in
                                Section {
                                    ForEach(group.files) { file in
                                        driveFileRow(file)
                                    }
                                } header: {
                                    dayHeader(group)
                                }
                            }
                        }
                        .awReadableWidth(AWLayout.listMaxWidth)
                        .padding(.top, 8)
                        .padding(.bottom, 28)
                    }
                    .refreshable {
                        await loadReports(force: true)
                    }
                }
            }
            
            if isLoading && !files.isEmpty {
                VStack {
                    ProgressView()
                        .padding(12)
                        .background(AWTheme.cardFill)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .navigationTitle("Drive")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AWTheme.screenGray, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await loadReports(force: true) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(isLoading)
                .accessibilityLabel("Atualizar")
            }
        }
        .task {
            if !didLoadOnce {
                await loadReports(force: false)
            }
        }
        .alert("Google Drive", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    private var searchHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AWTheme.textSecondary)
                
                TextField("Buscar por cliente, tipo ou nome…", text: $searchText)
                    .font(AWTheme.body(15))
                    .foregroundStyle(AWTheme.textPrimary)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit {
                        Task { await loadReports(force: true) }
                    }
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        Task { await loadReports(force: true) }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AWTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
                
                Button {
                    Task { await loadReports(force: true) }
                } label: {
                    Text("Buscar")
                        .font(AWTheme.caption(13))
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AWTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(AWTheme.fieldFill)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(tipoFilters, id: \.self) { item in
                        Button(item) {
                            tipoFilter = item
                        }
                        .font(AWTheme.caption(12))
                        .foregroundStyle(tipoFilter == item ? .white : AWTheme.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(tipoFilter == item ? AWTheme.moduleHistorico : AWTheme.fieldFill)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }
            
            Text("Pasta: \(GoogleDriveService.folderName) · \(filteredFiles.count) arquivo(s)")
                .font(AWTheme.caption(12))
                .foregroundStyle(AWTheme.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }
    
    private func dayHeader(_ group: GoogleDriveDayGroup) -> some View {
        HStack {
            Text(group.title)
                .font(AWTheme.headline(13))
                .foregroundStyle(AWTheme.textPrimary)
            Spacer()
            Text("\(group.files.count)")
                .font(AWTheme.caption(12))
                .foregroundStyle(AWTheme.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AWTheme.fieldFill)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
        .background(AWTheme.screenGray.opacity(0.95))
    }
    
    private func driveFileRow(_ file: GoogleDriveFile) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "doc.richtext.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AWTheme.moduleHistorico)
                    .frame(width: 36)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(file.inferredCliente)
                        .font(AWTheme.headline(15))
                        .foregroundStyle(AWTheme.textPrimary)
                        .lineLimit(2)
                    
                    Text(formatDateTime(file.sortDate))
                        .font(AWTheme.caption(12))
                        .foregroundStyle(AWTheme.textSecondary)
                    
                    Text(file.name)
                        .font(AWTheme.caption(11))
                        .foregroundStyle(AWTheme.textSecondary.opacity(0.85))
                        .lineLimit(1)
                    
                    if let size = file.sizeBytes {
                        Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                            .font(AWTheme.caption(11))
                            .foregroundStyle(AWTheme.textSecondary)
                    }
                }
                
                Spacer(minLength: 8)
                
                AWBadge(text: file.inferredTipo, color: color(for: file.inferredTipo))
            }
            
            HStack(spacing: 8) {
                if let link = file.webViewLink {
                    Button {
                        UIApplication.shared.open(link)
                    } label: {
                        Label("Abrir", systemImage: "arrow.up.right.square")
                            .font(AWTheme.caption(13))
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(AWTheme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    
                    ShareLink(item: link) {
                        Label("Compartilhar", systemImage: "square.and.arrow.up")
                            .font(AWTheme.caption(13))
                            .fontWeight(.semibold)
                            .foregroundStyle(AWTheme.moduleHistorico)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(AWTheme.cardFill)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(AWTheme.moduleHistorico.opacity(0.4), lineWidth: 1)
                            )
                    }
                } else {
                    Text("Link indisponível")
                        .font(AWTheme.caption(12))
                        .foregroundStyle(AWTheme.textSecondary)
                }
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
    
    private func loadReports(force: Bool) async {
        if isLoading { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await GoogleDriveService.listReports(searchQuery: searchText)
            files = result
            didLoadOnce = true
        } catch {
            if let driveError = error as? GoogleDriveError, case .cancelled = driveError {
                return
            }
            if force || !didLoadOnce {
                alertMessage = error.localizedDescription
                showAlert = true
            }
            didLoadOnce = true
        }
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "dd/MM/yyyy HH:mm"
        return f.string(from: date)
    }
    
    private func color(for tipo: String) -> Color {
        switch tipo {
        case "Devolução": return AWTheme.moduleDevolucao
        case "Troca": return AWTheme.moduleTroca
        case "Trator": return AWTheme.moduleTrator
        case "Avarias": return AWTheme.moduleAvarias
        case "Entrega": return AWTheme.moduleEntrega
        default: return AWTheme.moduleHistorico
        }
    }
}

#Preview {
    NavigationStack { DriveRelatoriosView() }
}
