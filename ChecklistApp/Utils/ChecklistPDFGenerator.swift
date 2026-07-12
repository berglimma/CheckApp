import UIKit
import PencilKit

struct ChecklistPDFGenerator {
    
    static func gerarPDF(checklist viewModel: ChecklistEntregaViewModel, assinatura: PKCanvasView) -> URL? {
        let checklist = viewModel.checklistEntrega

        let pdfMetaData = [
            kCGPDFContextCreator: "Checklist App",
            kCGPDFContextAuthor: "Seu Nome ou Empresa"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth = 612.0
        let pageHeight = 792.0
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)

        let fileName = UUID().uuidString + ".pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try renderer.writePDF(to: url) { context in
                context.beginPage()
                _ = context.cgContext

                var y: CGFloat = 20
                let lineHeight: CGFloat = 24

                func draw(_ label: String, _ value: String) {
                    let text = "\(label): \(value)"
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.alignment = .left

                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 16),
                        .paragraphStyle: paragraphStyle
                    ]

                    text.draw(in: CGRect(x: 20, y: y, width: pageWidth - 40, height: lineHeight), withAttributes: attributes)
                    y += lineHeight + 5
                }

                draw("Placa", checklist.placa)
                draw("Funcionário", checklist.funcionario)
                draw("Data", DateFormatter.localizedString(from: checklist.dataRegistro, dateStyle: .short, timeStyle: .none))
                draw("Hora", checklist.horaRegistro)
                draw("Combustível", String(format: "%.2f", checklist.combustivel))
                draw("Observações", checklist.observacoes)

                y += 20
                draw("Assinatura:", "")

                if let image = SignatureCapture.image(from: assinatura.drawing) {
                    let rect = CGRect(x: 20, y: y + 10, width: 300, height: 100)
                    UIColor.white.setFill()
                    context.cgContext.fill(rect)
                    image.draw(in: rect.insetBy(dx: 4, dy: 4))
                }
            }
            
            return url
            
        } catch {
            print("Erro ao gerar PDF: \(error)")
            return nil
        }
    }
}
