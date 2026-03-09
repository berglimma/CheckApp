import SwiftUI
import SwiftData
import Foundation

@MainActor
class ChecklistDevolucaoViewModel: ObservableObject {

    @Published var checklistDevolucao: ChecklistDevolucao
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.checklistDevolucao = ChecklistDevolucao()
    }
    
    // MARK: - Salvar Checklist
    
    func salvarChecklistDevolucao() {
        modelContext.insert(checklistDevolucao)
        salvarHistorico()
        
        do {
            try modelContext.save()
            print("✅ Checklist e histórico salvos com sucesso no SwiftData.")
        } catch {
            print("❌ Erro ao salvar dados:", error)
        }
    }
    
    // MARK: - Histórico
    
    private func salvarHistorico() {
        let historico = CheckListHistorico(
            nomeCliente: checklistDevolucao.funcionario,
            placa: checklistDevolucao.placa,
            data: checklistDevolucao.dataRegistro,
            tipo: "Devolução"
        )
        
        modelContext.insert(historico)
    }
    
    // MARK: - Slider
    
    func sliderLabel(for value: Double) -> String {
        let nivel = Int(round(value * 8))
        return "\(nivel)/8"
    }
}
