import Foundation
import Combine
import PencilKit

class ChecklistDevolucaoViewModel: ObservableObject {
    @Published var checklistDevolucao: ChecklistDevolucao

    init() {
        self.checklistDevolucao = ChecklistDevolucao()
    }

    // Salvar um checklist de devolução
    private func salvarChecklist(_ checklist: ChecklistDevolucao, tipo: String) {
        print("""
        📝 Checklist de \(tipo) salvo:
        Data: \(formatarData(checklist.dataRegistro))
        Hora: \(checklist.horaRegistro)
        Funcionário: \(checklist.funcionario)
        Placa: \(checklist.placa)
        Combustível: \(Int(checklist.combustivel * 100))%
        Observações: \(checklist.observacoes)
        """)
    }

    // Salvar checklist de devolução
    func salvarChecklistDevolucao() {
        salvarChecklist(checklistDevolucao, tipo: "Devolução")
        salvarChecklistPersistencia()
    }

    // Persistir checklist usando UserDefaults
    private func salvarChecklistPersistencia() {
        if let data = try? JSONEncoder().encode(checklistDevolucao) {
            UserDefaults.standard.set(data, forKey: "checklistDevolucao")
            print("✅ Checklist de Devolução salvo com sucesso no UserDefaults.")
        } else {
            print("❌ Erro ao salvar checklist de Devolução.")
        }
    }

    // Carregar checklist persistido do UserDefaults
    func carregarChecklistPersistencia() {
        if let data = UserDefaults.standard.data(forKey: "checklistDevolucao"),
           let checklist = try? JSONDecoder().decode(ChecklistDevolucao.self, from: data) {
            checklistDevolucao = checklist  // 🚀 Agora realmente carrega o checklist!
            print("📂 Checklist de Devolução carregado com sucesso.")
        } else {
            print("⚠️ Nenhum checklist de Devolução encontrado.")
        }
    }

    // Formatar data para exibição
    private func formatarData(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    // Rótulos para slider de combustível
    func sliderLabel(for value: Double) -> String {
        switch value {
        case 0.0: return "0/8"
        case 0.125: return "1/8"
        case 0.25: return "1/4"
        case 0.375: return "3/8"
        case 0.5: return "1/2"
        case 0.625: return "5/8"
        case 0.75: return "3/4"
        case 0.875: return "7/8"
        case 1.0: return "8/8"
        default: return "\(Int(value * 8))/8"
        }
    }
}
