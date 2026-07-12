import Foundation

enum MotivoTroca: String, CaseIterable, Identifiable, Codable {
    case manutencao = "Manutenção"
    case sinistro = "Sinistro"
    case avaria = "Avaria"
    case upgrade = "Upgrade / substituição"
    case solicitacaoCliente = "Solicitação do cliente"
    case outro = "Outro"
    
    var id: String { rawValue }
}

struct TrocaProvisoria: Identifiable, Codable {
    var id: UUID = UUID()
    var cliente: String = ""
    var documentoCliente: String = ""
    var telefoneCliente: String = ""
    var funcionario: String = ""
    var dataRegistro: Date = Date()
    var horaRegistro: String = ""
    var motivoCategoria: String = ""
    var motivo: String = ""
    
    // Veículo original
    var placaOriginal: String = ""
    var modeloOriginal: String = ""
    var kmOriginal: String = ""
    var combustivelOriginal: Double = 0.5
    
    // Veículo provisório
    var placaProvisorio: String = ""
    var modeloProvisorio: String = ""
    var kmProvisorio: String = ""
    var combustivelProvisorio: Double = 0.5
    var previsaoDevolucao: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    
    var itensInspecao: [InspectionToggleItem] = InspectionCatalog.veiculoBasico()
    var observacoes: String = ""
    
    var motivoSelecionado: MotivoTroca? {
        get { MotivoTroca(rawValue: motivoCategoria) }
        set { motivoCategoria = newValue?.rawValue ?? "" }
    }
    
    var motivoCompleto: String {
        let categoria = motivoCategoria.trimmingCharacters(in: .whitespacesAndNewlines)
        let detalhe = motivo.trimmingCharacters(in: .whitespacesAndNewlines)
        if categoria.isEmpty { return detalhe }
        if detalhe.isEmpty { return categoria }
        return "\(categoria) — \(detalhe)"
    }
}

struct AvaliacaoTrator: Identifiable, Codable {
    var id: UUID = UUID()
    var cliente: String = ""
    var documentoCliente: String = ""
    var telefoneCliente: String = ""
    var funcionario: String = ""
    var dataRegistro: Date = Date()
    var horaRegistro: String = ""
    
    var identificacao: String = ""
    var marca: String = ""
    var modelo: String = ""
    var serie: String = ""
    var horimetro: String = ""
    var localAvaliacao: String = ""
    
    var condicaoGeral: String = CondicaoGeral.boa.rawValue
    var itensInspecao: [InspectionToggleItem] = InspectionCatalog.trator()
    var recomendacoes: String = ""
    var observacoes: String = ""
    var aprovadoParaUso: Bool = true
}
