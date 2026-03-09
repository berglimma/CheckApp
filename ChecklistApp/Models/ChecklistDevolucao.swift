import SwiftData
import Foundation

@Model
class ChecklistDevolucao {

    var id: UUID
    var tipo: String
    var dataRegistro: Date
    var horaRegistro: String
    var funcionario: String
    var placa: String
    var combustivel: Double
    var observacoes: String
    var assinaturaData: Data?

    init(
        id: UUID = UUID(),
        tipo: String = "Devolução",
        dataRegistro: Date = Date(),
        horaRegistro: String = "",
        funcionario: String = "",
        placa: String = "",
        combustivel: Double = 0.0,
        observacoes: String = "",
        assinaturaData: Data? = nil
    ) {
        self.id = id
        self.tipo = tipo
        self.dataRegistro = dataRegistro
        self.horaRegistro = horaRegistro
        self.funcionario = funcionario
        self.placa = placa
        self.combustivel = combustivel
        self.observacoes = observacoes
        self.assinaturaData = assinaturaData
    }
}
