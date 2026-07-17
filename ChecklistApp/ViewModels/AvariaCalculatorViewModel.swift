//
//  AvariaCalculatorViewModel.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import PDFKit
import SwiftUI

class AvariaCalculatorViewModel: ObservableObject {
    @Published var avarias: [AvariaItem] = []
    
    @Published var avariaName: String = ""
    @Published var avariaValue: String = ""
    @Published var categoria: AvariaCategoria = .lataria
    @Published var localDano: String = ""
    
    @Published var cliente: String = ""
    @Published var telefoneCliente: String = ""
    @Published var emailCliente: String = ""
    @Published var funcionario: String = ""
    @Published var nomeCarro: String = ""
    @Published var placaCarro: String = ""
    @Published var kmAtual: String = ""
    @Published var observacoes: String = ""
    
    @Published var generatedPDF: Data? = nil
    @Published var errorMessage: String? = nil
    
    func addAvaria() {
        if let error = validarCampos() {
            errorMessage = error
            return
        }
        
        let newAvaria = AvariaItem(
            name: avariaName,
            value: Double(avariaValue.replacingOccurrences(of: ",", with: ".")) ?? 0,
            categoria: categoria.rawValue,
            localDano: localDano
        )
        avarias.append(newAvaria)
        
        avariaName = ""
        avariaValue = ""
        localDano = ""
        categoria = .lataria
        errorMessage = nil
    }
    
    private func validarCampos() -> String? {
        if avariaName.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Informe a descrição da avaria."
        }
        guard let value = Double(avariaValue.replacingOccurrences(of: ",", with: ".")), value > 0 else {
            return "Informe um valor válido maior que zero."
        }
        return nil
    }
    
    func deleteAvaria(at offsets: IndexSet) {
        avarias.remove(atOffsets: offsets)
    }
    
    static func formatarData(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    func generatePDF() {
        guard !avarias.isEmpty else {
            errorMessage = "Não há avarias para gerar o relatório."
            return
        }
        
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        let data = pdfRenderer.pdfData { context in
            context.beginPage()
            var y: CGFloat = 28
            
            func draw(_ text: String, bold: Bool = false, size: CGFloat = 13) {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: bold ? UIFont.boldSystemFont(ofSize: size) : UIFont.systemFont(ofSize: size)
                ]
                text.draw(at: CGPoint(x: 28, y: y), withAttributes: attrs)
                y += size + 10
            }
            
            draw("Relatório de Avarias — Auto Wize", bold: true, size: 18)
            draw("Cliente: \(cliente.isEmpty ? "-" : cliente)")
            draw("Funcionário: \(funcionario.isEmpty ? "-" : funcionario)")
            draw("Veículo: \(nomeCarro.isEmpty ? "-" : nomeCarro) | Placa: \(placaCarro.isEmpty ? "-" : placaCarro)")
            draw("KM: \(kmAtual.isEmpty ? "-" : kmAtual) | Data: \(Self.formatarData(Date()))")
            y += 8
            
            var total: Double = 0
            for avaria in avarias {
                let line = "• [\(avaria.categoria)] \(avaria.name) (\(avaria.localDano.isEmpty ? "s/local" : avaria.localDano)) — R$ \(String(format: "%.2f", avaria.value))"
                draw(line)
                total += avaria.value
            }
            
            y += 8
            draw("Total: R$ \(String(format: "%.2f", total))", bold: true, size: 15)
            if !observacoes.isEmpty {
                draw("Observações: \(observacoes)")
            }
        }
        
        generatedPDF = data
        errorMessage = nil
    }
}
