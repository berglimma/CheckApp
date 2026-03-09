//
//  Historico.swift
//  ChecklistApp
//
//  Created by Luan Carlos on 28/02/26.
//
import SwiftData
import Foundation

@Model
class CheckListHistorico {
    
    var id: UUID
    var nomeCliente: String
    var placa: String
    var data: Date
    var tipo: String
    
    init(
        id: UUID = UUID(),
        nomeCliente: String,
        placa: String,
        data: Date,
        tipo: String
    ) {
        self.id = id
        self.nomeCliente = nomeCliente
        self.placa = placa
        self.data = data
        self.tipo = tipo
    }
}
