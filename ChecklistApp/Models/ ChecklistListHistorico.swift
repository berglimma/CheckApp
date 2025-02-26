//
//  Historico.swift
//  ChecklistApp
//
//  Created by Luan Carlos on 03/12/25.
//

struct ChecklistListHistorico: Identifiable {
    let id = UUID()
    let nomeCliente: String,
    let placa: String,
    let data: Date,
    let tipo: CheckListTipo,
}
enum ChecklistTipo { case entrega, devolucao }
