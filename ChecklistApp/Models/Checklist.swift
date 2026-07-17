//
//  Checklist.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import Foundation
import UIKit

enum CheckList: String, Codable {
    case entrega = "Entrega"
    case devolucao = "Devolução"
}

struct Checklist: Identifiable, Codable {
    var id: UUID = UUID()
    var cliente: String?
    var documentoCliente: String
    var telefoneCliente: String
    var emailCliente: String
    var numeroReserva: String
    var dataRegistro: Date
    var horaRegistro: String
    var funcionario: String
    var placa: String
    var marca: String
    var modelo: String
    var cor: String
    var kmAtual: String
    var combustivel: Double
    var condicaoGeral: String
    var itensInspecao: [InspectionToggleItem]
    var observacoes: String
    var assinatura: UIImage?

    init(
        cliente: String? = nil,
        documentoCliente: String = "",
        telefoneCliente: String = "",
        emailCliente: String = "",
        numeroReserva: String = "",
        dataRegistro: Date = Date(),
        horaRegistro: String = "",
        funcionario: String = "",
        placa: String = "",
        marca: String = "",
        modelo: String = "",
        cor: String = "",
        kmAtual: String = "",
        combustivel: Double = 0.5,
        condicaoGeral: String = CondicaoGeral.boa.rawValue,
        itensInspecao: [InspectionToggleItem] = InspectionCatalog.veiculoBasico(),
        observacoes: String = "",
        assinatura: UIImage? = nil
    ) {
        self.cliente = cliente
        self.documentoCliente = documentoCliente
        self.telefoneCliente = telefoneCliente
        self.emailCliente = emailCliente
        self.numeroReserva = numeroReserva
        self.dataRegistro = dataRegistro
        self.horaRegistro = horaRegistro
        self.funcionario = funcionario
        self.placa = placa
        self.marca = marca
        self.modelo = modelo
        self.cor = cor
        self.kmAtual = kmAtual
        self.combustivel = combustivel
        self.condicaoGeral = condicaoGeral
        self.itensInspecao = itensInspecao
        self.observacoes = observacoes
        self.assinatura = assinatura
    }

    enum CodingKeys: String, CodingKey {
        case id, cliente, documentoCliente, telefoneCliente, emailCliente, numeroReserva
        case dataRegistro, horaRegistro, funcionario
        case placa, marca, modelo, cor, kmAtual
        case combustivel, condicaoGeral, itensInspecao
        case observacoes, assinatura
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(cliente, forKey: .cliente)
        try container.encode(documentoCliente, forKey: .documentoCliente)
        try container.encode(telefoneCliente, forKey: .telefoneCliente)
        try container.encode(emailCliente, forKey: .emailCliente)
        try container.encode(numeroReserva, forKey: .numeroReserva)
        try container.encode(dataRegistro, forKey: .dataRegistro)
        try container.encode(horaRegistro, forKey: .horaRegistro)
        try container.encode(funcionario, forKey: .funcionario)
        try container.encode(placa, forKey: .placa)
        try container.encode(marca, forKey: .marca)
        try container.encode(modelo, forKey: .modelo)
        try container.encode(cor, forKey: .cor)
        try container.encode(kmAtual, forKey: .kmAtual)
        try container.encode(combustivel, forKey: .combustivel)
        try container.encode(condicaoGeral, forKey: .condicaoGeral)
        try container.encode(itensInspecao, forKey: .itensInspecao)
        try container.encode(observacoes, forKey: .observacoes)
        if let assinatura {
            try container.encode(assinatura.pngData(), forKey: .assinatura)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        cliente = try container.decodeIfPresent(String.self, forKey: .cliente)
        documentoCliente = try container.decodeIfPresent(String.self, forKey: .documentoCliente) ?? ""
        telefoneCliente = try container.decodeIfPresent(String.self, forKey: .telefoneCliente) ?? ""
        emailCliente = try container.decodeIfPresent(String.self, forKey: .emailCliente) ?? ""
        numeroReserva = try container.decodeIfPresent(String.self, forKey: .numeroReserva) ?? ""
        dataRegistro = try container.decode(Date.self, forKey: .dataRegistro)
        horaRegistro = try container.decode(String.self, forKey: .horaRegistro)
        funcionario = try container.decode(String.self, forKey: .funcionario)
        placa = try container.decode(String.self, forKey: .placa)
        marca = try container.decodeIfPresent(String.self, forKey: .marca) ?? ""
        modelo = try container.decodeIfPresent(String.self, forKey: .modelo) ?? ""
        cor = try container.decodeIfPresent(String.self, forKey: .cor) ?? ""
        kmAtual = try container.decodeIfPresent(String.self, forKey: .kmAtual) ?? ""
        combustivel = try container.decode(Double.self, forKey: .combustivel)
        condicaoGeral = try container.decodeIfPresent(String.self, forKey: .condicaoGeral) ?? CondicaoGeral.boa.rawValue
        itensInspecao = try container.decodeIfPresent([InspectionToggleItem].self, forKey: .itensInspecao) ?? InspectionCatalog.veiculoBasico()
        observacoes = try container.decode(String.self, forKey: .observacoes)
        if let imageData = try container.decodeIfPresent(Data.self, forKey: .assinatura) {
            assinatura = UIImage(data: imageData)
        } else {
            assinatura = nil
        }
    }
}
