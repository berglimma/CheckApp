//
//  HistoricoViewModel.swift
//  ChecklistApp
//
//  Created by Luan Carlos on 06/12/25.
//

import Foundation
import SwiftData

@MainActor
class CheckHistoricoModel: ObservableObject {
    
    @Published var historico: [CheckListHistorico] = []
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        carregarHistorico()
    }
    
    func carregarHistorico() {
        let descriptor = FetchDescriptor<CheckListHistorico>(
            sortBy: [SortDescriptor(\.data, order: .reverse)]
        )
        
        do {
            historico = try modelContext.fetch(descriptor)
        } catch {
            print("Erro ao buscar histórico:", error)
            historico = []
        }
    }
    
    func formatarData(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        return formatter.string(from: date)
    }
}
