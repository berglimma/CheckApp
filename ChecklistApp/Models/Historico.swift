import SwiftData
import Foundation

@Model
class CheckListHistorico {
    var id: UUID = UUID()
    var nomeCliente: String = ""
    var placa: String = ""
    var data: Date = Date()
    var tipo: String = ""
    var ownerId: String = ""
    var reportJSON: String = ""
    var horaRegistro: String = ""
    var funcionario: String = ""
    
    init(
        id: UUID = UUID(),
        nomeCliente: String,
        placa: String,
        data: Date,
        tipo: String,
        ownerId: String = "",
        reportJSON: String = "",
        horaRegistro: String = "",
        funcionario: String = ""
    ) {
        self.id = id
        self.nomeCliente = nomeCliente
        self.placa = placa
        self.data = data
        self.tipo = tipo
        self.ownerId = ownerId
        self.reportJSON = reportJSON
        self.horaRegistro = horaRegistro
        self.funcionario = funcionario
    }
    
    var snapshot: ReportSnapshot? {
        guard let data = reportJSON.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(ReportSnapshot.self, from: data)
    }
    
    static func encodeSnapshot(_ snapshot: ReportSnapshot) -> String {
        guard let data = try? JSONEncoder().encode(snapshot),
              let json = String(data: data, encoding: .utf8) else { return "" }
        return json
    }
}
