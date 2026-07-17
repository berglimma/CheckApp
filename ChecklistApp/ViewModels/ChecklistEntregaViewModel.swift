//
//  ChecklistEntregaViewModel.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import Foundation
import Combine
import PencilKit
import SwiftData

class ChecklistEntregaViewModel: ObservableObject {
    
    @Published var checklistEntrega: Checklist
    @Published var condicao: CondicaoGeral = .boa

    init() {
        self.checklistEntrega = Checklist()
        if let match = CondicaoGeral(rawValue: checklistEntrega.condicaoGeral) {
            condicao = match
        }
    }

    func salvarChecklistEntrega(context: ModelContext? = nil) {
        checklistEntrega.condicaoGeral = condicao.rawValue
        checklistEntrega.numeroReserva = ReservaEntrega.normalize(checklistEntrega.numeroReserva)
        salvarChecklistPersistencia()
        ReservaStore.saveFromChecklist(checklistEntrega)
        
        if let context {
            let historico = CheckListHistorico(
                nomeCliente: checklistEntrega.cliente ?? checklistEntrega.funcionario,
                placa: checklistEntrega.placa,
                data: checklistEntrega.dataRegistro,
                tipo: "Entrega"
            )
            context.insert(historico)
            try? context.save()
        }
        
        print("✅ Checklist de Entrega salvo.")
    }

    private func salvarChecklistPersistencia() {
        if let data = try? JSONEncoder().encode(checklistEntrega) {
            UserDefaults.standard.set(data, forKey: "checklistEntrega")
        }
    }

    func sliderLabel(for value: Double) -> String {
        let nivel = Int(round(value * 8))
        return "\(nivel)/8"
    }
}
