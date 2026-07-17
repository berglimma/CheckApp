//
//  AccountDataEraser.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import Foundation
import SwiftData

/// Apaga dados operacionais e PII locais (históricos, CPF/clientes, fotos, reservas).
@MainActor
enum AccountDataEraser {
    
    static func eraseAllOperationalData(context: ModelContext) throws {
        try eraseSwiftDataRecords(context: context)
        try PhotoStore.shared.deleteAllPhotos(context: context)
        ReservaStore.clearAll(context: context)
        clearOperationalUserDefaults()
    }
    
    private static func eraseSwiftDataRecords(context: ModelContext) throws {
        let historicos = try context.fetch(FetchDescriptor<CheckListHistorico>())
        historicos.forEach { context.delete($0) }
        
        let devolucoes = try context.fetch(FetchDescriptor<ChecklistDevolucao>())
        devolucoes.forEach { context.delete($0) }
        
        let reservas = try context.fetch(FetchDescriptor<Reserva>())
        reservas.forEach { context.delete($0) }
        
        let cars = try context.fetch(FetchDescriptor<Car>())
        cars.forEach { context.delete($0) }
        
        let clients = try context.fetch(FetchDescriptor<Client>())
        clients.forEach { context.delete($0) }
        
        try context.save()
    }
    
    private static func clearOperationalUserDefaults() {
        let defaults = UserDefaults.standard
        let exactKeys = [
            "reservasEntregaAtivas",
            "checklistEntrega"
        ]
        exactKeys.forEach { defaults.removeObject(forKey: $0) }
        
        let prefixes = [
            "trocaProvisoria_",
            "avaliacaoTrator_"
        ]
        let allKeys = defaults.dictionaryRepresentation().keys
        for key in allKeys {
            if prefixes.contains(where: { key.hasPrefix($0) }) {
                defaults.removeObject(forKey: key)
            }
        }
        defaults.synchronize()
    }
}
