//
//  ReservaStore.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import Foundation
import SwiftData

struct ReservaEntrega: Identifiable, Codable, Equatable {
    var id: UUID
    var numeroReserva: String
    var cliente: String
    var documentoCliente: String
    var telefoneCliente: String
    var emailCliente: String
    var placa: String
    var marca: String
    var modelo: String
    var cor: String
    var kmAtual: String
    var funcionario: String
    var dataRegistro: Date
    var checklistId: UUID
    
    var numeroNormalizado: String {
        Self.normalize(numeroReserva)
    }
    
    static func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
            .replacingOccurrences(of: " ", with: "")
    }
}

enum ReservaStore {
    private static let storageKey = "reservasEntregaAtivas"
    
    static func all() -> [ReservaEntrega] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let items = try? JSONDecoder().decode([ReservaEntrega].self, from: data) else {
            return []
        }
        return items.sorted { $0.dataRegistro > $1.dataRegistro }
    }
    
    /// Combina reservas salvas + entregas do histórico (SwiftData).
    @MainActor
    static func allDisponiveis(context: ModelContext? = nil) -> [ReservaEntrega] {
        var byNumero: [String: ReservaEntrega] = [:]
        
        for reserva in all() {
            byNumero[reserva.numeroNormalizado] = reserva
        }
        
        if let context {
            for reserva in fromHistorico(context: context) {
                if byNumero[reserva.numeroNormalizado] == nil {
                    byNumero[reserva.numeroNormalizado] = reserva
                }
            }
        }
        
        return byNumero.values.sorted { $0.dataRegistro > $1.dataRegistro }
    }
    
    static func find(byNumero numero: String) -> ReservaEntrega? {
        let key = ReservaEntrega.normalize(numero)
        guard !key.isEmpty else { return nil }
        return all().first { $0.numeroNormalizado == key }
    }
    
    @MainActor
    static func find(byNumero numero: String, context: ModelContext?) -> ReservaEntrega? {
        let key = ReservaEntrega.normalize(numero)
        guard !key.isEmpty else { return nil }
        return allDisponiveis(context: context).first { $0.numeroNormalizado == key }
    }
    
    @MainActor
    static func search(query: String, context: ModelContext?) -> [ReservaEntrega] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let all = allDisponiveis(context: context)
        guard !q.isEmpty else { return all }
        
        let normalized = ReservaEntrega.normalize(q)
        return all.filter { reserva in
            reserva.numeroNormalizado.contains(normalized)
                || reserva.cliente.localizedCaseInsensitiveContains(q)
                || reserva.placa.localizedCaseInsensitiveContains(q)
                || reserva.modelo.localizedCaseInsensitiveContains(q)
                || reserva.marca.localizedCaseInsensitiveContains(q)
        }
    }
    
    static func save(_ reserva: ReservaEntrega) {
        var items = all()
        let key = reserva.numeroNormalizado
        items.removeAll { $0.numeroNormalizado == key || $0.checklistId == reserva.checklistId }
        items.insert(reserva, at: 0)
        persist(items)
    }
    
    static func saveFromChecklist(_ checklist: Checklist) {
        let numero = ReservaEntrega.normalize(checklist.numeroReserva)
        guard !numero.isEmpty else { return }
        
        let reserva = ReservaEntrega(
            id: UUID(),
            numeroReserva: numero,
            cliente: checklist.cliente ?? "",
            documentoCliente: checklist.documentoCliente,
            telefoneCliente: checklist.telefoneCliente,
            emailCliente: checklist.emailCliente,
            placa: checklist.placa,
            marca: checklist.marca,
            modelo: checklist.modelo,
            cor: checklist.cor,
            kmAtual: checklist.kmAtual,
            funcionario: checklist.funcionario,
            dataRegistro: checklist.dataRegistro,
            checklistId: checklist.id
        )
        save(reserva)
    }
    
    static func remove(numero: String) {
        let key = ReservaEntrega.normalize(numero)
        var items = all()
        items.removeAll { $0.numeroNormalizado == key }
        persist(items)
    }
    
    @MainActor
    private static func fromHistorico(context: ModelContext) -> [ReservaEntrega] {
        let descriptor = FetchDescriptor<CheckListHistorico>(
            sortBy: [SortDescriptor(\.data, order: .reverse)]
        )
        guard let items = try? context.fetch(descriptor) else { return [] }
        
        return items.compactMap { item -> ReservaEntrega? in
            guard item.tipo == "Entrega",
                  let snapshot = item.snapshot else { return nil }
            
            let numero = ReservaEntrega.normalize(snapshot.campos["Nº Reserva"] ?? "")
            guard !numero.isEmpty else { return nil }
            
            return ReservaEntrega(
                id: snapshot.id,
                numeroReserva: numero,
                cliente: snapshot.cliente,
                documentoCliente: snapshot.campos["Documento"] ?? "",
                telefoneCliente: snapshot.campos["Telefone"] ?? "",
                emailCliente: snapshot.campos["E-mail"] ?? "",
                placa: snapshot.placa,
                marca: snapshot.campos["Marca"] ?? "",
                modelo: snapshot.campos["Modelo"] ?? "",
                cor: snapshot.campos["Cor"] ?? "",
                kmAtual: snapshot.campos["KM"] ?? "",
                funcionario: snapshot.funcionario,
                dataRegistro: snapshot.dataRegistro,
                checklistId: snapshot.id
            )
        }
    }
    
    private static func persist(_ items: [ReservaEntrega]) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    static func clearAll() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}
