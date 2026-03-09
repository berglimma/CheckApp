import Foundation
import Combine
import PencilKit

class ChecklistEntregaViewModel: ObservableObject {
    
    @Published var checklistEntrega: Checklist

    init() {
        self.checklistEntrega = Checklist()
    }

    // Salvar um checklist genérico
    private func salvarChecklist(_ checklist: Checklist, tipo: String) {
        print("""
        📝 Checklist de \(tipo) salvo:
        Cliente: \(checklist.cliente ?? "N/A")
        Data: \(formatarData(checklist.dataRegistro))
        Hora: \(checklist.horaRegistro)
        Funcionário: \(checklist.funcionario)
        Placa: \(checklist.placa)
        Combustível: \(Int(checklist.combustivel * 100))%
        Observações: \(checklist.observacoes)
        """)
    }

    // Salvar checklist de entrega
    func salvarChecklistEntrega() {
        salvarChecklist(checklistEntrega, tipo: "Entrega")
        salvarChecklistPersistencia()
    }

    // Persistir checklist usando UserDefaults
    private func salvarChecklistPersistencia() {
        if let data = try? JSONEncoder().encode(checklistEntrega) {
            UserDefaults.standard.set(data, forKey: "checklistEntrega")
            print("✅ Checklist de Entrega salvo com sucesso no UserDefaults.")
        } else {
            print("❌ Erro ao salvar checklist de Entrega.")
        }
    }

    // Carregar checklist persistido do UserDefaults
    func carregarChecklistPersistencia() {
        if let data = UserDefaults.standard.data(forKey: "checklistEntrega"),
           let checklist = try? JSONDecoder().decode(Checklist.self, from: data) {
            checklistEntrega = checklist  // 🚀 Agora realmente carrega o checklist!
            print("📂 Checklist de Entrega carregado com sucesso.")
        } else {
            print("⚠️ Nenhum checklist de Entrega encontrado.")
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
