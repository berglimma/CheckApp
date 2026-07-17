//
//  Reserva.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import Foundation
import SwiftData

enum ReservaStatus: String, CaseIterable, Codable {
    case ativa = "ativa"
    case emTroca = "emTroca"
    case emManutencao = "emManutencao"
    case devolvida = "devolvida"
    
    var titulo: String {
        switch self {
        case .ativa: return "Ativa"
        case .emTroca: return "Em troca"
        case .emManutencao: return "Manutenção"
        case .devolvida: return "Devolvida"
        }
    }
}

/// Reserva operacional persistida no banco (SwiftData).
@Model
final class Reserva {
    var id: UUID = UUID()
    var numeroReserva: String = ""
    var statusRaw: String = ReservaStatus.ativa.rawValue
    
    var cliente: String = ""
    var documentoCliente: String = ""
    var telefoneCliente: String = ""
    var emailCliente: String = ""
    
    /// Veículo atualmente com o cliente (pode mudar após troca).
    var placa: String = ""
    var marca: String = ""
    var modelo: String = ""
    var cor: String = ""
    var kmAtual: String = ""
    
    /// Veículo da entrega original.
    var placaOriginal: String = ""
    var marcaOriginal: String = ""
    var modeloOriginal: String = ""
    
    var funcionario: String = ""
    var checklistEntregaId: UUID = UUID()
    var dataAbertura: Date = Date()
    var dataAtualizacao: Date = Date()
    var dataDevolucao: Date?
    var motivoUltimaMovimentacao: String = ""
    var nomeQuemRetornou: String = ""
    
    var status: ReservaStatus {
        get { ReservaStatus(rawValue: statusRaw) ?? .ativa }
        set { statusRaw = newValue.rawValue }
    }
    
    var numeroNormalizado: String {
        ReservaEntrega.normalize(numeroReserva)
    }
    
    init(
        id: UUID = UUID(),
        numeroReserva: String,
        status: ReservaStatus = .ativa,
        cliente: String = "",
        documentoCliente: String = "",
        telefoneCliente: String = "",
        emailCliente: String = "",
        placa: String = "",
        marca: String = "",
        modelo: String = "",
        cor: String = "",
        kmAtual: String = "",
        funcionario: String = "",
        checklistEntregaId: UUID = UUID(),
        dataAbertura: Date = Date()
    ) {
        self.id = id
        self.numeroReserva = ReservaEntrega.normalize(numeroReserva)
        self.statusRaw = status.rawValue
        self.cliente = cliente
        self.documentoCliente = documentoCliente
        self.telefoneCliente = telefoneCliente
        self.emailCliente = emailCliente
        self.placa = placa
        self.marca = marca
        self.modelo = modelo
        self.cor = cor
        self.kmAtual = kmAtual
        self.placaOriginal = placa
        self.marcaOriginal = marca
        self.modeloOriginal = modelo
        self.funcionario = funcionario
        self.checklistEntregaId = checklistEntregaId
        self.dataAbertura = dataAbertura
        self.dataAtualizacao = dataAbertura
    }
    
    func asEntregaDTO() -> ReservaEntrega {
        ReservaEntrega(
            id: id,
            numeroReserva: numeroReserva,
            cliente: cliente,
            documentoCliente: documentoCliente,
            telefoneCliente: telefoneCliente,
            emailCliente: emailCliente,
            placa: placa,
            marca: marca,
            modelo: modelo,
            cor: cor,
            kmAtual: kmAtual,
            funcionario: funcionario,
            dataRegistro: dataAbertura,
            checklistId: checklistEntregaId,
            status: status
        )
    }
}
