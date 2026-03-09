import Foundation

// Representa os estados possíveis de um item do checklist
enum ChecklistStatus: String, Codable {
    case pendente = "Pendente"
    case entregue = "Entregue"
    case devolvido = "Devolvido"
    case completo = "Completo"
}

