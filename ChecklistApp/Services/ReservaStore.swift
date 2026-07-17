//
//  ReservaStore.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import Foundation
import SwiftData

/// DTO leve para listas/UI (busca de reserva).
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
    var status: ReservaStatus
    
    var numeroNormalizado: String {
        Self.normalize(numeroReserva)
    }
    
    static func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
            .replacingOccurrences(of: " ", with: "")
    }
    
    enum CodingKeys: String, CodingKey {
        case id, numeroReserva, cliente, documentoCliente, telefoneCliente, emailCliente
        case placa, marca, modelo, cor, kmAtual, funcionario, dataRegistro, checklistId, status
    }
    
    init(
        id: UUID,
        numeroReserva: String,
        cliente: String,
        documentoCliente: String,
        telefoneCliente: String,
        emailCliente: String,
        placa: String,
        marca: String,
        modelo: String,
        cor: String,
        kmAtual: String,
        funcionario: String,
        dataRegistro: Date,
        checklistId: UUID,
        status: ReservaStatus = .ativa
    ) {
        self.id = id
        self.numeroReserva = numeroReserva
        self.cliente = cliente
        self.documentoCliente = documentoCliente
        self.telefoneCliente = telefoneCliente
        self.emailCliente = emailCliente
        self.placa = placa
        self.marca = marca
        self.modelo = modelo
        self.cor = cor
        self.kmAtual = kmAtual
        self.funcionario = funcionario
        self.dataRegistro = dataRegistro
        self.checklistId = checklistId
        self.status = status
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        numeroReserva = try c.decode(String.self, forKey: .numeroReserva)
        cliente = try c.decode(String.self, forKey: .cliente)
        documentoCliente = try c.decode(String.self, forKey: .documentoCliente)
        telefoneCliente = try c.decode(String.self, forKey: .telefoneCliente)
        emailCliente = try c.decode(String.self, forKey: .emailCliente)
        placa = try c.decode(String.self, forKey: .placa)
        marca = try c.decode(String.self, forKey: .marca)
        modelo = try c.decode(String.self, forKey: .modelo)
        cor = try c.decode(String.self, forKey: .cor)
        kmAtual = try c.decode(String.self, forKey: .kmAtual)
        funcionario = try c.decode(String.self, forKey: .funcionario)
        dataRegistro = try c.decode(Date.self, forKey: .dataRegistro)
        checklistId = try c.decode(UUID.self, forKey: .checklistId)
        if let raw = try c.decodeIfPresent(String.self, forKey: .status),
           let parsed = ReservaStatus(rawValue: raw) {
            status = parsed
        } else {
            status = .ativa
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(numeroReserva, forKey: .numeroReserva)
        try c.encode(cliente, forKey: .cliente)
        try c.encode(documentoCliente, forKey: .documentoCliente)
        try c.encode(telefoneCliente, forKey: .telefoneCliente)
        try c.encode(emailCliente, forKey: .emailCliente)
        try c.encode(placa, forKey: .placa)
        try c.encode(marca, forKey: .marca)
        try c.encode(modelo, forKey: .modelo)
        try c.encode(cor, forKey: .cor)
        try c.encode(kmAtual, forKey: .kmAtual)
        try c.encode(funcionario, forKey: .funcionario)
        try c.encode(dataRegistro, forKey: .dataRegistro)
        try c.encode(checklistId, forKey: .checklistId)
        try c.encode(status.rawValue, forKey: .status)
    }
}

@MainActor
enum ReservaStore {
    private static let legacyKey = "reservasEntregaAtivas"
    private static let counterKey = "reservaNumeroSequencial"
    
    // MARK: - Geração automática
    
    /// Gera número único no formato AW-AAMMDD-XXXX (ex.: AW-250717-0003).
    static func generateNumero(context: ModelContext) -> String {
        migrateLegacyIfNeeded(context: context)
        
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "en_US_POSIX")
        dayFormatter.timeZone = .current
        dayFormatter.dateFormat = "yyMMdd"
        let day = dayFormatter.string(from: Date())
        let prefix = "AW-\(day)-"
        
        let existing = allModels(context: context)
            .map(\.numeroNormalizado)
            .filter { $0.hasPrefix(prefix) }
        
        var next = existing.count + 1
        var candidate = String(format: "%@%04d", prefix, next)
        while existing.contains(candidate) {
            next += 1
            candidate = String(format: "%@%04d", prefix, next)
        }
        
        UserDefaults.standard.set(next, forKey: "\(counterKey)_\(day)")
        return candidate
    }
    
    static func ensureNumero(_ checklist: inout Checklist, context: ModelContext) {
        if ReservaEntrega.normalize(checklist.numeroReserva).isEmpty {
            checklist.numeroReserva = generateNumero(context: context)
        } else {
            checklist.numeroReserva = ReservaEntrega.normalize(checklist.numeroReserva)
        }
    }
    
    // MARK: - Persistência (banco)
    
    @discardableResult
    static func saveFromChecklist(_ checklist: Checklist, context: ModelContext) -> Reserva {
        migrateLegacyIfNeeded(context: context)
        
        let numero = ReservaEntrega.normalize(checklist.numeroReserva)
        guard !numero.isEmpty else {
            // Garante número se o caller esqueceu
            var copy = checklist
            copy.numeroReserva = generateNumero(context: context)
            return saveFromChecklist(copy, context: context)
        }
        
        if let existing = findModel(byNumero: numero, context: context) {
            existing.cliente = checklist.cliente ?? ""
            existing.documentoCliente = checklist.documentoCliente
            existing.telefoneCliente = checklist.telefoneCliente
            existing.emailCliente = checklist.emailCliente
            existing.placa = checklist.placa
            existing.marca = checklist.marca
            existing.modelo = checklist.modelo
            existing.cor = checklist.cor
            existing.kmAtual = checklist.kmAtual
            existing.placaOriginal = checklist.placa
            existing.marcaOriginal = checklist.marca
            existing.modeloOriginal = checklist.modelo
            existing.funcionario = checklist.funcionario
            existing.checklistEntregaId = checklist.id
            existing.dataAtualizacao = Date()
            if existing.status == .devolvida {
                existing.status = .ativa
                existing.dataDevolucao = nil
            }
            try? context.save()
            syncLegacyCache(context: context)
            return existing
        }
        
        let reserva = Reserva(
            numeroReserva: numero,
            status: .ativa,
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
            checklistEntregaId: checklist.id,
            dataAbertura: checklist.dataRegistro
        )
        context.insert(reserva)
        try? context.save()
        syncLegacyCache(context: context)
        return reserva
    }
    
    /// Compat: algumas chamadas antigas sem context.
    static func saveFromChecklist(_ checklist: Checklist) {
        // Sem ModelContext não há banco — só espelho UserDefaults (legado).
        let numero = ReservaEntrega.normalize(checklist.numeroReserva)
        guard !numero.isEmpty else { return }
        let dto = ReservaEntrega(
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
            checklistId: checklist.id,
            status: .ativa
        )
        var items = legacyAll()
        items.removeAll { $0.numeroNormalizado == numero || $0.checklistId == checklist.id }
        items.insert(dto, at: 0)
        persistLegacy(items)
    }
    
    // MARK: - Consulta
    
    static func find(byNumero numero: String, context: ModelContext?) -> ReservaEntrega? {
        guard let context else {
            let key = ReservaEntrega.normalize(numero)
            return legacyAll().first { $0.numeroNormalizado == key }
        }
        migrateLegacyIfNeeded(context: context)
        return findModel(byNumero: numero, context: context)?.asEntregaDTO()
    }
    
    static func findModel(byNumero numero: String, context: ModelContext) -> Reserva? {
        let key = ReservaEntrega.normalize(numero)
        guard !key.isEmpty else { return nil }
        return allModels(context: context).first { $0.numeroNormalizado == key }
    }
    
    static func search(
        query: String,
        context: ModelContext?,
        onlyOpen: Bool = true
    ) -> [ReservaEntrega] {
        guard let context else {
            return filterDTO(legacyAll(), query: query, onlyOpen: onlyOpen)
        }
        migrateLegacyIfNeeded(context: context)
        let dtos = allModels(context: context).map { $0.asEntregaDTO() }
        return filterDTO(dtos, query: query, onlyOpen: onlyOpen)
    }
    
    static func allDisponiveis(context: ModelContext? = nil) -> [ReservaEntrega] {
        search(query: "", context: context, onlyOpen: true)
    }
    
    // MARK: - Integração Troca / Manutenção / Devolução
    
    static func applyTroca(
        numero: String,
        placaProvisorio: String,
        marcaProvisorio: String,
        modeloProvisorio: String,
        kmProvisorio: String,
        nomeQuemRetornou: String,
        motivo: String,
        isManutencao: Bool,
        context: ModelContext
    ) {
        migrateLegacyIfNeeded(context: context)
        guard let reserva = findModel(byNumero: numero, context: context) else { return }
        
        reserva.placa = placaProvisorio
        reserva.marca = marcaProvisorio
        reserva.modelo = modeloProvisorio
        reserva.kmAtual = kmProvisorio
        reserva.nomeQuemRetornou = nomeQuemRetornou
        reserva.motivoUltimaMovimentacao = motivo
        reserva.status = isManutencao ? .emManutencao : .emTroca
        reserva.dataAtualizacao = Date()
        try? context.save()
        syncLegacyCache(context: context)
    }
    
    static func closeOnDevolucao(
        numero: String,
        kmRetorno: String,
        context: ModelContext
    ) {
        migrateLegacyIfNeeded(context: context)
        guard let reserva = findModel(byNumero: numero, context: context) else { return }
        
        reserva.kmAtual = kmRetorno
        reserva.status = .devolvida
        reserva.dataDevolucao = Date()
        reserva.dataAtualizacao = Date()
        reserva.motivoUltimaMovimentacao = "Devolução"
        try? context.save()
        syncLegacyCache(context: context)
    }
    
    static func clearAll(context: ModelContext? = nil) {
        if let context {
            allModels(context: context).forEach { context.delete($0) }
            try? context.save()
        }
        UserDefaults.standard.removeObject(forKey: legacyKey)
    }
    
    // MARK: - Internals
    
    private static func filterDTO(
        _ items: [ReservaEntrega],
        query: String,
        onlyOpen: Bool
    ) -> [ReservaEntrega] {
        var list = items.sorted { $0.dataRegistro > $1.dataRegistro }
        if onlyOpen {
            list = list.filter { $0.status != .devolvida }
        }
        
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return list }
        
        let normalized = ReservaEntrega.normalize(q)
        return list.filter { reserva in
            reserva.numeroNormalizado.contains(normalized)
                || reserva.cliente.localizedCaseInsensitiveContains(q)
                || reserva.emailCliente.localizedCaseInsensitiveContains(q)
                || reserva.placa.localizedCaseInsensitiveContains(q)
                || reserva.modelo.localizedCaseInsensitiveContains(q)
                || reserva.marca.localizedCaseInsensitiveContains(q)
        }
    }
    
    private static func allModels(context: ModelContext) -> [Reserva] {
        let descriptor = FetchDescriptor<Reserva>(
            sortBy: [SortDescriptor(\.dataAbertura, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    private static func migrateLegacyIfNeeded(context: ModelContext) {
        let legacy = legacyAll()
        guard !legacy.isEmpty else { return }
        
        let existing = Set(allModels(context: context).map(\.numeroNormalizado))
        var imported = false
        
        for dto in legacy where !existing.contains(dto.numeroNormalizado) {
            let model = Reserva(
                id: dto.id,
                numeroReserva: dto.numeroReserva,
                status: dto.status,
                cliente: dto.cliente,
                documentoCliente: dto.documentoCliente,
                telefoneCliente: dto.telefoneCliente,
                emailCliente: dto.emailCliente,
                placa: dto.placa,
                marca: dto.marca,
                modelo: dto.modelo,
                cor: dto.cor,
                kmAtual: dto.kmAtual,
                funcionario: dto.funcionario,
                checklistEntregaId: dto.checklistId,
                dataAbertura: dto.dataRegistro
            )
            context.insert(model)
            imported = true
        }
        
        if imported {
            try? context.save()
        }
        // Mantém legado sincronizado; não apaga para não perder dados em builds antigos.
        syncLegacyCache(context: context)
    }
    
    private static func syncLegacyCache(context: ModelContext) {
        let dtos = allModels(context: context).map { $0.asEntregaDTO() }
        persistLegacy(dtos)
    }
    
    private static func legacyAll() -> [ReservaEntrega] {
        guard let data = UserDefaults.standard.data(forKey: legacyKey),
              let items = try? JSONDecoder().decode([ReservaEntrega].self, from: data) else {
            return []
        }
        return items
    }
    
    private static func persistLegacy(_ items: [ReservaEntrega]) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: legacyKey)
        }
    }
}
