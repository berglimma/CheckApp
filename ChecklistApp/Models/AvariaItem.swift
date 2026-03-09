import Foundation

struct AvariaItem: Identifiable {
    let id: UUID
    let name: String
    let value: Double
    
    init(name: String, value: Double) {
        self.id = UUID() 
        self.name = name
        self.value = value
    }
}
