//
//  InspectionCatalog.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import Foundation

struct InspectionToggleItem: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var isOK: Bool
    
    init(id: String, title: String, isOK: Bool = true) {
        self.id = id
        self.title = title
        self.isOK = isOK
    }
}

enum InspectionCatalog {
    
    static func veiculoBasico() -> [InspectionToggleItem] {
        [
            .init(id: "docs", title: "Documentação do veículo"),
            .init(id: "estepe", title: "Estepe"),
            .init(id: "macaco", title: "Macaco"),
            .init(id: "chave_roda", title: "Chave de roda"),
            .init(id: "triangulo", title: "Triângulo"),
            .init(id: "extintor", title: "Extintor"),
            .init(id: "tapetes", title: "Tapetes"),
            .init(id: "radio", title: "Rádio / multimídia"),
            .init(id: "limpeza", title: "Limpeza interna/externa"),
            .init(id: "pneus", title: "Pneus em bom estado"),
            .init(id: "farois", title: "Faróis e lanternas"),
            .init(id: "retrovisores", title: "Retrovisores")
        ]
    }
    
    static func devolucaoExtra() -> [InspectionToggleItem] {
        [
            .init(id: "lataria", title: "Lataria sem novos danos"),
            .init(id: "vidros", title: "Vidros íntegros"),
            .init(id: "interior", title: "Interior sem danos"),
            .init(id: "chave", title: "Chave / controle devolvido"),
            .init(id: "acessorios", title: "Acessórios conferidos")
        ]
    }
    
    static func trator() -> [InspectionToggleItem] {
        [
            .init(id: "oleo_motor", title: "Nível de óleo do motor"),
            .init(id: "oleo_hidraulico", title: "Óleo hidráulico"),
            .init(id: "combustivel", title: "Sistema de combustível"),
            .init(id: "radiador", title: "Radiador / arrefecimento"),
            .init(id: "pneus_esteiras", title: "Pneus / esteiras"),
            .init(id: "freios", title: "Freios"),
            .init(id: "direcao", title: "Direção"),
            .init(id: "hidraulico", title: "Sistema hidráulico"),
            .init(id: "eletrica", title: "Parte elétrica"),
            .init(id: "iluminacao", title: "Iluminação"),
            .init(id: "cabine", title: "Cabine / assento"),
            .init(id: "implementos", title: "Implementos acoplados"),
            .init(id: "vazamentos", title: "Sem vazamentos aparentes"),
            .init(id: "ruido", title: "Sem ruídos anormais")
        ]
    }
}

enum AvariaCategoria: String, CaseIterable, Identifiable {
    case lataria = "Lataria"
    case pintura = "Pintura"
    case vidro = "Vidro"
    case pneu = "Pneu"
    case interior = "Interior"
    case mecanica = "Mecânica"
    case eletrica = "Elétrica"
    case outro = "Outro"
    
    var id: String { rawValue }
}

enum CondicaoGeral: String, CaseIterable, Identifiable {
    case excelente = "Excelente"
    case boa = "Boa"
    case regular = "Regular"
    case ruim = "Ruim"
    
    var id: String { rawValue }
}
