import Foundation

struct AvariaItem: Identifiable {
    let id: UUID
    var name: String
    var value: Double
    var categoria: String
    var localDano: String
    
    init(
        name: String,
        value: Double,
        categoria: String = AvariaCategoria.outro.rawValue,
        localDano: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.value = value
        self.categoria = categoria
        self.localDano = localDano
    }
}
