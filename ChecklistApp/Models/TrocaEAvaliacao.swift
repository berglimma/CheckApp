//
//  TrocaEAvaliacao.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import Foundation

enum MotivoTroca: String, CaseIterable, Identifiable, Codable {
    case manutencao = "Manutenção"
    case sinistro = "Sinistro"
    case avaria = "Avaria"
    case upgrade = "Upgrade / substituição"
    case solicitacaoCliente = "Solicitação do cliente"
    case outro = "Outro"
    
    var id: String { rawValue }
}

struct TrocaProvisoria: Identifiable, Codable {
    var id: UUID = UUID()
    var cliente: String = ""
    var documentoCliente: String = ""
    var telefoneCliente: String = ""
    var emailCliente: String = ""
    var funcionario: String = ""
    var dataRegistro: Date = Date()
    var horaRegistro: String = ""
    var motivoCategoria: String = ""
    var motivo: String = ""
    
    /// Número da reserva da entrega — atrela a troca à reserva original.
    var numeroReserva: String = ""
    /// Nome de quem retornou o carro original.
    var nomeQuemRetornou: String = ""
    /// Indica se a reserva foi encontrada e vinculada.
    var reservaAtrelada: Bool = false
    
    // Veículo original
    var placaOriginal: String = ""
    var marcaOriginal: String = ""
    var modeloOriginal: String = ""
    var kmOriginal: String = ""
    var combustivelOriginal: Double = 0.5
    
    // Veículo provisório
    var placaProvisorio: String = ""
    var marcaProvisorio: String = ""
    var modeloProvisorio: String = ""
    var kmProvisorio: String = ""
    var combustivelProvisorio: Double = 0.5
    var previsaoDevolucao: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    
    var itensInspecao: [InspectionToggleItem] = InspectionCatalog.veiculoBasico()
    var observacoes: String = ""
    
    var motivoSelecionado: MotivoTroca? {
        get { MotivoTroca(rawValue: motivoCategoria) }
        set { motivoCategoria = newValue?.rawValue ?? "" }
    }
    
    var motivoCompleto: String {
        let categoria = motivoCategoria.trimmingCharacters(in: .whitespacesAndNewlines)
        let detalhe = motivo.trimmingCharacters(in: .whitespacesAndNewlines)
        if categoria.isEmpty { return detalhe }
        if detalhe.isEmpty { return categoria }
        return "\(categoria) — \(detalhe)"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, cliente, documentoCliente, telefoneCliente, emailCliente
        case funcionario, dataRegistro, horaRegistro
        case motivoCategoria, motivo
        case numeroReserva, nomeQuemRetornou, reservaAtrelada
        case placaOriginal, marcaOriginal, modeloOriginal, kmOriginal, combustivelOriginal
        case placaProvisorio, marcaProvisorio, modeloProvisorio, kmProvisorio, combustivelProvisorio
        case previsaoDevolucao, itensInspecao, observacoes
    }
    
    init() {}
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        cliente = try c.decodeIfPresent(String.self, forKey: .cliente) ?? ""
        documentoCliente = try c.decodeIfPresent(String.self, forKey: .documentoCliente) ?? ""
        telefoneCliente = try c.decodeIfPresent(String.self, forKey: .telefoneCliente) ?? ""
        emailCliente = try c.decodeIfPresent(String.self, forKey: .emailCliente) ?? ""
        funcionario = try c.decodeIfPresent(String.self, forKey: .funcionario) ?? ""
        dataRegistro = try c.decodeIfPresent(Date.self, forKey: .dataRegistro) ?? Date()
        horaRegistro = try c.decodeIfPresent(String.self, forKey: .horaRegistro) ?? ""
        motivoCategoria = try c.decodeIfPresent(String.self, forKey: .motivoCategoria) ?? ""
        motivo = try c.decodeIfPresent(String.self, forKey: .motivo) ?? ""
        numeroReserva = try c.decodeIfPresent(String.self, forKey: .numeroReserva) ?? ""
        nomeQuemRetornou = try c.decodeIfPresent(String.self, forKey: .nomeQuemRetornou) ?? ""
        reservaAtrelada = try c.decodeIfPresent(Bool.self, forKey: .reservaAtrelada) ?? false
        placaOriginal = try c.decodeIfPresent(String.self, forKey: .placaOriginal) ?? ""
        marcaOriginal = try c.decodeIfPresent(String.self, forKey: .marcaOriginal) ?? ""
        modeloOriginal = try c.decodeIfPresent(String.self, forKey: .modeloOriginal) ?? ""
        kmOriginal = try c.decodeIfPresent(String.self, forKey: .kmOriginal) ?? ""
        combustivelOriginal = try c.decodeIfPresent(Double.self, forKey: .combustivelOriginal) ?? 0.5
        placaProvisorio = try c.decodeIfPresent(String.self, forKey: .placaProvisorio) ?? ""
        marcaProvisorio = try c.decodeIfPresent(String.self, forKey: .marcaProvisorio) ?? ""
        modeloProvisorio = try c.decodeIfPresent(String.self, forKey: .modeloProvisorio) ?? ""
        kmProvisorio = try c.decodeIfPresent(String.self, forKey: .kmProvisorio) ?? ""
        combustivelProvisorio = try c.decodeIfPresent(Double.self, forKey: .combustivelProvisorio) ?? 0.5
        previsaoDevolucao = try c.decodeIfPresent(Date.self, forKey: .previsaoDevolucao)
            ?? (Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        itensInspecao = try c.decodeIfPresent([InspectionToggleItem].self, forKey: .itensInspecao)
            ?? InspectionCatalog.veiculoBasico()
        observacoes = try c.decodeIfPresent(String.self, forKey: .observacoes) ?? ""
    }
}

struct AvaliacaoTrator: Identifiable, Codable {
    var id: UUID = UUID()
    var cliente: String = ""
    var documentoCliente: String = ""
    var telefoneCliente: String = ""
    var emailCliente: String = ""
    var funcionario: String = ""
    var dataRegistro: Date = Date()
    var horaRegistro: String = ""
    
    var identificacao: String = ""
    var marca: String = ""
    var modelo: String = ""
    var serie: String = ""
    var horimetro: String = ""
    var localAvaliacao: String = ""
    
    var condicaoGeral: String = CondicaoGeral.boa.rawValue
    var itensInspecao: [InspectionToggleItem] = InspectionCatalog.trator()
    var recomendacoes: String = ""
    var observacoes: String = ""
    var aprovadoParaUso: Bool = true
    
    enum CodingKeys: String, CodingKey {
        case id, cliente, documentoCliente, telefoneCliente, emailCliente
        case funcionario, dataRegistro, horaRegistro
        case identificacao, marca, modelo, serie, horimetro, localAvaliacao
        case condicaoGeral, itensInspecao, recomendacoes, observacoes, aprovadoParaUso
    }
    
    init() {}
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        cliente = try c.decodeIfPresent(String.self, forKey: .cliente) ?? ""
        documentoCliente = try c.decodeIfPresent(String.self, forKey: .documentoCliente) ?? ""
        telefoneCliente = try c.decodeIfPresent(String.self, forKey: .telefoneCliente) ?? ""
        emailCliente = try c.decodeIfPresent(String.self, forKey: .emailCliente) ?? ""
        funcionario = try c.decodeIfPresent(String.self, forKey: .funcionario) ?? ""
        dataRegistro = try c.decodeIfPresent(Date.self, forKey: .dataRegistro) ?? Date()
        horaRegistro = try c.decodeIfPresent(String.self, forKey: .horaRegistro) ?? ""
        identificacao = try c.decodeIfPresent(String.self, forKey: .identificacao) ?? ""
        marca = try c.decodeIfPresent(String.self, forKey: .marca) ?? ""
        modelo = try c.decodeIfPresent(String.self, forKey: .modelo) ?? ""
        serie = try c.decodeIfPresent(String.self, forKey: .serie) ?? ""
        horimetro = try c.decodeIfPresent(String.self, forKey: .horimetro) ?? ""
        localAvaliacao = try c.decodeIfPresent(String.self, forKey: .localAvaliacao) ?? ""
        condicaoGeral = try c.decodeIfPresent(String.self, forKey: .condicaoGeral) ?? CondicaoGeral.boa.rawValue
        itensInspecao = try c.decodeIfPresent([InspectionToggleItem].self, forKey: .itensInspecao) ?? InspectionCatalog.trator()
        recomendacoes = try c.decodeIfPresent(String.self, forKey: .recomendacoes) ?? ""
        observacoes = try c.decodeIfPresent(String.self, forKey: .observacoes) ?? ""
        aprovadoParaUso = try c.decodeIfPresent(Bool.self, forKey: .aprovadoParaUso) ?? true
    }
}
