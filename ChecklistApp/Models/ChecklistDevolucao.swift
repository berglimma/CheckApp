import SwiftData
import Foundation

@Model
class ChecklistDevolucao {
    var id: UUID = UUID()
    var tipo: String = "Devolução"
    var cliente: String = ""
    var documentoCliente: String = ""
    var telefoneCliente: String = ""
    var dataRegistro: Date = Date()
    var horaRegistro: String = ""
    var funcionario: String = ""
    var placa: String = ""
    var marca: String = ""
    var modelo: String = ""
    var cor: String = ""
    var kmSaida: String = ""
    var kmRetorno: String = ""
    var combustivel: Double = 0.5
    var condicaoGeral: String = "Boa"
    var itensInspecaoJSON: String = "[]"
    var possuiAvarias: Bool = false
    var descricaoAvarias: String = ""
    var observacoes: String = ""
    var assinaturaData: Data?

    init(
        id: UUID = UUID(),
        tipo: String = "Devolução",
        cliente: String = "",
        documentoCliente: String = "",
        telefoneCliente: String = "",
        dataRegistro: Date = Date(),
        horaRegistro: String = "",
        funcionario: String = "",
        placa: String = "",
        marca: String = "",
        modelo: String = "",
        cor: String = "",
        kmSaida: String = "",
        kmRetorno: String = "",
        combustivel: Double = 0.5,
        condicaoGeral: String = CondicaoGeral.boa.rawValue,
        itensInspecao: [InspectionToggleItem] = InspectionCatalog.veiculoBasico() + InspectionCatalog.devolucaoExtra(),
        possuiAvarias: Bool = false,
        descricaoAvarias: String = "",
        observacoes: String = "",
        assinaturaData: Data? = nil
    ) {
        self.id = id
        self.tipo = tipo
        self.cliente = cliente
        self.documentoCliente = documentoCliente
        self.telefoneCliente = telefoneCliente
        self.dataRegistro = dataRegistro
        self.horaRegistro = horaRegistro
        self.funcionario = funcionario
        self.placa = placa
        self.marca = marca
        self.modelo = modelo
        self.cor = cor
        self.kmSaida = kmSaida
        self.kmRetorno = kmRetorno
        self.combustivel = combustivel
        self.condicaoGeral = condicaoGeral
        self.itensInspecaoJSON = Self.encodeItems(itensInspecao)
        self.possuiAvarias = possuiAvarias
        self.descricaoAvarias = descricaoAvarias
        self.observacoes = observacoes
        self.assinaturaData = assinaturaData
    }
    
    var itensInspecao: [InspectionToggleItem] {
        get {
            let decoded = Self.decodeItems(itensInspecaoJSON)
            return decoded.isEmpty
                ? InspectionCatalog.veiculoBasico() + InspectionCatalog.devolucaoExtra()
                : decoded
        }
        set { itensInspecaoJSON = Self.encodeItems(newValue) }
    }
    
    private static func encodeItems(_ items: [InspectionToggleItem]) -> String {
        guard let data = try? JSONEncoder().encode(items),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }
    
    private static func decodeItems(_ json: String) -> [InspectionToggleItem] {
        guard let data = json.data(using: .utf8),
              let items = try? JSONDecoder().decode([InspectionToggleItem].self, from: data) else {
            return []
        }
        return items
    }
}
