//
//  Historico.swift
//  ChecklistApp
//
//  Created by Luan Carlos on 03/12/25.
//

import Foundation
import UIKit

struct ChecklistListHistorico: Identifiable, Codable {
    let id: UUID
    let nomeCliente: String
    let placa: String
    let data: Date

    init(id: UUID = UUID(), nomeCliente: String, placa: String, data: Date) {
        self.id = id
        self.nomeCliente = nomeCliente
        self.placa = placa
        self.data = data
    }
}

enum ChecklistTipo: String, Codable {
    case entrega
    case devolucao
}

