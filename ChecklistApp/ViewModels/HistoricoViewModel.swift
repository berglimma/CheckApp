//
//  HistoricoViewModel.swift
//  ChecklistApp
//
//  Created by Luan Carlos on 06/12/25.
//

import Foundation
import SwiftData

@MainActor
class HistoricoViewModel: ObservableObject {

    @Published var historico: [CheckListHistorico] = []

    func carregarHistorico(context: ModelContext) {
        let descriptor = FetchDescriptor<CheckListHistorico>(
            sortBy: [SortDescriptor(\.data, order: .reverse)]
        )

        do {
            historico = try context.fetch(descriptor)
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
