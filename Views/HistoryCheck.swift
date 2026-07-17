//
//  HistoryCheck.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import SwiftUI
import SwiftData

struct HistoricoCheck: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = HistoricoViewModel()
    @State private var itemToDelete: CheckListHistorico?
    @State private var showDeleteConfirm = false
    
    var body: some View {
        ZStack {
            AWScreenBackground()
            
            if viewModel.historico.isEmpty {
                AWEmptyState(
                    systemImage: "clock.arrow.circlepath",
                    title: "Nenhum histórico",
                    message: "Os checklists, trocas, avaliações e avarias salvos aparecerão aqui."
                )
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.historico) { item in
                            historicoCard(item)
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
        }
        .navigationTitle("Histórico")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AWTheme.screenGray, for: .navigationBar)
        .task {
            viewModel.carregarHistorico(context: context)
        }
        .confirmationDialog(
            "Excluir registro?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Excluir", role: .destructive) {
                if let itemToDelete {
                    ReportRepository.delete(item: itemToDelete, context: context)
                    viewModel.carregarHistorico(context: context)
                }
                itemToDelete = nil
            }
            Button("Cancelar", role: .cancel) {
                itemToDelete = nil
            }
        } message: {
            Text("Essa ação remove o registro e as fotos associadas.")
        }
    }
    
    private func historicoCard(_ item: CheckListHistorico) -> some View {
        let badgeColor: Color = {
            switch item.tipo {
            case "Devolução": return AWTheme.moduleDevolucao
            case "Troca": return AWTheme.moduleTroca
            case "Trator": return AWTheme.moduleTrator
            case "Avarias": return AWTheme.moduleAvarias
            default: return AWTheme.moduleEntrega
            }
        }()
        
        let icon: String = {
            switch item.tipo {
            case "Devolução": return "car.rear.fill"
            case "Troca": return "car.2.fill"
            case "Trator": return "gearshape.2.fill"
            case "Avarias": return "wrench.and.screwdriver.fill"
            default: return "car.fill"
            }
        }()
        
        return HStack(alignment: .top, spacing: 10) {
            NavigationLink {
                HistoricoDetailView(item: item)
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(badgeColor.opacity(0.14))
                            .frame(width: 40, height: 40)
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(badgeColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .top, spacing: 8) {
                            Text(item.nomeCliente.isEmpty ? "Sem cliente" : item.nomeCliente)
                                .font(AWTheme.headline(15))
                                .foregroundStyle(AWTheme.textPrimary)
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            AWBadge(text: item.tipo, color: badgeColor)
                        }
                        
                        Text("Placa: \(item.placa.isEmpty ? "-" : item.placa)")
                            .font(AWTheme.body(14))
                            .foregroundStyle(AWTheme.textSecondary)
                        
                        Text(viewModel.formatarData(item.data))
                            .font(AWTheme.caption(12))
                            .foregroundStyle(AWTheme.textSecondary)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AWTheme.textSecondary)
                        .padding(.top, 4)
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
            .accessibilityLabel("Excluir do histórico")
        }
        .padding(14)
        .background(AWTheme.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: AWTheme.radiusM, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AWTheme.radiusM, style: .continuous)
                .stroke(AWTheme.stroke, lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        HistoricoCheck()
    }
    .modelContainer(for: [CheckListHistorico.self], inMemory: true)
}
