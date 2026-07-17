//
//  ChecklistEntregaViewModel.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import Foundation
import Combine
import SwiftData

@MainActor
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
        
        if let context {
            ReservaStore.ensureNumero(&checklistEntrega, context: context)
            salvarChecklistPersistencia()
            ReservaStore.saveFromChecklist(checklistEntrega, context: context)
        } else {
            checklistEntrega.numeroReserva = ReservaEntrega.normalize(checklistEntrega.numeroReserva)
            salvarChecklistPersistencia()
            ReservaStore.saveFromChecklist(checklistEntrega)
        }
        
        print("✅ Checklist de Entrega salvo. Reserva \(checklistEntrega.numeroReserva).")
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
