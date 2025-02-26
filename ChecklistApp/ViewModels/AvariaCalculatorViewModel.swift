import SwiftUI
import PDFKit

class AvariaCalculatorViewModel: ObservableObject {
    // Lista de Avarias
    @Published var avarias: [AvariaItem] = []
    
    // Campos de entrada
    @Published var avariaName: String = ""
    @Published var avariaValue: String = ""
    
    // PDF Gerado
    @Published var generatedPDF: Data? = nil
    
    // Mensagem de erro
    @Published var errorMessage: String? = nil
    
    // Adiciona uma Nova Avaria
    func addAvaria() {
        if let error = validarCampos() {
            errorMessage = error
            return
        }
        
        // Cria uma nova avaria e adiciona à lista
        let newAvaria = AvariaItem(name: avariaName, value: Double(avariaValue)!)
        avarias.append(newAvaria)
        
        // Limpa os campos de entrada e mensagens de erro
        avariaName = ""
        avariaValue = ""
        errorMessage = nil
    }
    
    // Valida os campos de entrada
    private func validarCampos() -> String? {
        if avariaName.isEmpty {
            return "O nome da avaria não pode estar vazio."
        }
        guard let value = Double(avariaValue), value > 0 else {
            return "Por favor, insira um valor válido para a avaria."
        }
        return nil
    }
    
    // Remove uma Avaria
    func deleteAvaria(at offsets: IndexSet) {
        avarias.remove(atOffsets: offsets)
    }
    
    // Formata a data no estilo desejado
    static func formatarData(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // Gera um PDF com os dados das Avarias
    func generatePDF() {
        guard !avarias.isEmpty else {
            errorMessage = "Não há avarias para gerar o relatório."
            return
        }
        
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        let data = pdfRenderer.pdfData { context in
            context.beginPage()
            
            desenharTitulo(context)
            desenharListaDeAvarias(context)
        }
        
        // Salva o PDF gerado
        self.generatedPDF = data
    }
    
    // Desenha o título no PDF
    private func desenharTitulo(_ context: UIGraphicsPDFRendererContext) {
        let title = "Relatório de Avarias"
        title.draw(at: CGPoint(x: 20, y: 20), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 18)])
    }
    
    // Desenha a lista de avarias e o total no PDF
    private func desenharListaDeAvarias(_ context: UIGraphicsPDFRendererContext) {
        var yPosition = 60
        var totalValue: Double = 0
        
        for avaria in avarias {
            let text = "\(avaria.name): R$ \(String(format: "%.2f", avaria.value))"
            text.draw(at: CGPoint(x: 20, y: CGFloat(yPosition)), withAttributes: [.font: UIFont.systemFont(ofSize: 14)])
            yPosition += 20
            totalValue += avaria.value
        }
        
        // Exibe o total
        let totalText = "Total: R$ \(String(format: "%.2f", totalValue))"
        totalText.draw(at: CGPoint(x: 20, y: CGFloat(yPosition + 20)), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 16)])
    }
}
