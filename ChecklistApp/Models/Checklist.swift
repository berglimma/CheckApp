import Foundation
import UIKit

// Enum para o tipo de checklist (Entrega ou Devolução)
enum CheckList: String, Codable {
    case entrega = "Entrega"
    case devolucao = "Devolução"
}

// Modelo de checklist genérico (Entrega ou Devolução)
struct Checklist: Identifiable, Codable {
    var id: UUID = UUID()
    var cliente: String? 
    var dataRegistro: Date
    var horaRegistro: String
    var funcionario: String
    var placa: String
    var combustivel: Double
    var observacoes: String
    var assinatura: UIImage?

    init(
        cliente: String? = nil,  // Cliente só é usado na Entrega
        dataRegistro: Date = Date(),
        horaRegistro: String = "",
        funcionario: String = "",
        placa: String = "",
        combustivel: Double = 0.0,
        observacoes: String = "",
        assinatura: UIImage? = nil
    ) {
        self.cliente = cliente
        self.dataRegistro = dataRegistro
        self.horaRegistro = horaRegistro
        self.funcionario = funcionario
        self.placa = placa
        self.combustivel = combustivel
        self.observacoes = observacoes
        self.assinatura = assinatura
    }

    enum CodingKeys: String, CodingKey {
        case id, tipo, cliente, dataRegistro, horaRegistro, funcionario, placa, combustivel, observacoes, assinatura
    }

    // MARK: - Encoding (Salvar)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(cliente, forKey: .cliente)
        try container.encode(dataRegistro, forKey: .dataRegistro)
        try container.encode(horaRegistro, forKey: .horaRegistro)
        try container.encode(funcionario, forKey: .funcionario)
        try container.encode(placa, forKey: .placa)
        try container.encode(combustivel, forKey: .combustivel)
        try container.encode(observacoes, forKey: .observacoes)

        // Converte UIImage para Data antes de salvar
        if let assinatura = assinatura {
            try container.encode(assinatura.pngData(), forKey: .assinatura)
        }
    }

    // MARK: - Decoding (Carregar)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        cliente = try container.decodeIfPresent(String.self, forKey: .cliente)
        dataRegistro = try container.decode(Date.self, forKey: .dataRegistro)
        horaRegistro = try container.decode(String.self, forKey: .horaRegistro)
        funcionario = try container.decode(String.self, forKey: .funcionario)
        placa = try container.decode(String.self, forKey: .placa)
        combustivel = try container.decode(Double.self, forKey: .combustivel)
        observacoes = try container.decode(String.self, forKey: .observacoes)

        // Converte Data para UIImage ao carregar
        if let imageData = try container.decodeIfPresent(Data.self, forKey: .assinatura) {
            assinatura = UIImage(data: imageData)
        } else {
            assinatura = nil
        }
    }
}
