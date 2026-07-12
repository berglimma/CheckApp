import SwiftUI
import SwiftData
import Foundation

@MainActor
class ChecklistDevolucaoViewModel: ObservableObject {
    @Published var checklistDevolucao: ChecklistDevolucao
    @Published var itensInspecao: [InspectionToggleItem]
    @Published var condicao: CondicaoGeral = .boa
    
    init() {
        let checklist = ChecklistDevolucao()
        self.checklistDevolucao = checklist
        self.itensInspecao = checklist.itensInspecao
        if let match = CondicaoGeral(rawValue: checklist.condicaoGeral) {
            condicao = match
        }
    }
    
    func salvarChecklistDevolucao(context: ModelContext) {
        checklistDevolucao.condicaoGeral = condicao.rawValue
        checklistDevolucao.itensInspecao = itensInspecao
        
        context.insert(checklistDevolucao)
        
        do {
            try context.save()
            print("✅ Checklist de devolução salvo.")
        } catch {
            print("❌ Erro ao salvar:", error)
        }
    }
    
    func sliderLabel(for value: Double) -> String {
        let nivel = Int(round(value * 8))
        return "\(nivel)/8"
    }
}
