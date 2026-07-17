//
//  ReportPDFService.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import Foundation
import UIKit
import SwiftUI
import SwiftData

struct ReportSnapshot: Codable, Identifiable {
    var id: UUID
    var tipo: String
    var titulo: String
    var cliente: String
    var placa: String
    var funcionario: String
    var dataRegistro: Date
    var horaRegistro: String
    var campos: [String: String]
    var observacoes: String
    var ownerId: String
    var itensInspecao: [InspectionToggleItem]
    var signatureJPEGBase64: String?
    
    init(
        id: UUID = UUID(),
        tipo: String,
        titulo: String,
        cliente: String,
        placa: String,
        funcionario: String,
        dataRegistro: Date,
        horaRegistro: String,
        campos: [String: String] = [:],
        observacoes: String = "",
        ownerId: String,
        itensInspecao: [InspectionToggleItem] = [],
        signatureJPEGBase64: String? = nil
    ) {
        self.id = id
        self.tipo = tipo
        self.titulo = titulo
        self.cliente = cliente
        self.placa = placa
        self.funcionario = funcionario
        self.dataRegistro = dataRegistro
        self.horaRegistro = horaRegistro
        self.campos = campos
        self.observacoes = observacoes
        self.ownerId = ownerId
        self.itensInspecao = itensInspecao
        self.signatureJPEGBase64 = signatureJPEGBase64
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        tipo = try c.decode(String.self, forKey: .tipo)
        titulo = try c.decode(String.self, forKey: .titulo)
        cliente = try c.decode(String.self, forKey: .cliente)
        placa = try c.decode(String.self, forKey: .placa)
        funcionario = try c.decode(String.self, forKey: .funcionario)
        dataRegistro = try c.decode(Date.self, forKey: .dataRegistro)
        horaRegistro = try c.decode(String.self, forKey: .horaRegistro)
        campos = try c.decodeIfPresent([String: String].self, forKey: .campos) ?? [:]
        observacoes = try c.decodeIfPresent(String.self, forKey: .observacoes) ?? ""
        ownerId = try c.decode(String.self, forKey: .ownerId)
        itensInspecao = try c.decodeIfPresent([InspectionToggleItem].self, forKey: .itensInspecao) ?? []
        signatureJPEGBase64 = try c.decodeIfPresent(String.self, forKey: .signatureJPEGBase64)
    }
    
    mutating func attachSignature(_ image: UIImage?) {
        guard let image else { return }
        let prepared = SignatureCapture.withWhiteBackground(image)
        // PNG preserva melhor o traço; o campo mantém o nome por compatibilidade.
        guard let data = prepared.pngData() else { return }
        signatureJPEGBase64 = data.base64EncodedString()
    }
    
    var signatureImage: UIImage? {
        guard let signatureJPEGBase64,
              let data = Data(base64Encoded: signatureJPEGBase64),
              let image = UIImage(data: data) else { return nil }
        return SignatureCapture.withWhiteBackground(image)
    }
}

enum ReportPDFService {
    
    static func generate(
        snapshot: ReportSnapshot,
        photos: [UIImage] = [],
        signature: UIImage? = nil
    ) -> URL? {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 36
        
        let safeName = snapshot.tipo
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "/", with: "-")
        let fileName = "AutoWize-\(safeName)-\(snapshot.id.uuidString.prefix(8)).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        // Remove arquivo anterior com mesmo nome, se existir
        try? FileManager.default.removeItem(at: url)
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextCreator as String: "Auto Wize",
            kCGPDFContextAuthor as String: "Auto Wize",
            kCGPDFContextTitle as String: snapshot.titulo
        ]
        
        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight),
            format: format
        )
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "pt_BR")
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        let resolvedSignature = signature ?? snapshot.signatureImage
        
        do {
            try renderer.writePDF(to: url) { context in
                context.beginPage()
                var y: CGFloat = margin
                
                func ensureSpace(_ needed: CGFloat) {
                    if y + needed > pageHeight - margin {
                        context.beginPage()
                        y = margin
                    }
                }
                
                func draw(_ text: String, bold: Bool = false, size: CGFloat = 12, color: UIColor = .black) {
                    let paragraph = NSMutableParagraphStyle()
                    paragraph.lineBreakMode = .byWordWrapping
                    
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: bold ? UIFont.boldSystemFont(ofSize: size) : UIFont.systemFont(ofSize: size),
                        .foregroundColor: color,
                        .paragraphStyle: paragraph
                    ]
                    
                    let maxWidth = pageWidth - margin * 2
                    let bounding = (text as NSString).boundingRect(
                        with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
                        options: [.usesLineFragmentOrigin, .usesFontLeading],
                        attributes: attrs,
                        context: nil
                    )
                    let height = max(ceil(bounding.height), size + 4)
                    ensureSpace(height + 8)
                    
                    (text as NSString).draw(
                        in: CGRect(x: margin, y: y, width: maxWidth, height: height),
                        withAttributes: attrs
                    )
                    y += height + 8
                }
                
                draw("Auto Wize — Relatório", bold: true, size: 20)
                draw(snapshot.titulo, bold: true, size: 16)
                y += 4
                draw("Tipo: \(snapshot.tipo)")
                draw("Cliente: \(snapshot.cliente.isEmpty ? "-" : snapshot.cliente)")
                draw("Placa / ID: \(snapshot.placa.isEmpty ? "-" : snapshot.placa)")
                draw("Funcionário: \(snapshot.funcionario.isEmpty ? "-" : snapshot.funcionario)")
                draw("Data: \(dateFormatter.string(from: snapshot.dataRegistro)) \(snapshot.horaRegistro)")
                y += 6
                
                draw("Detalhes", bold: true, size: 14)
                let sortedKeys = snapshot.campos.keys.sorted()
                if sortedKeys.isEmpty {
                    draw("Sem detalhes adicionais.")
                } else {
                    for key in sortedKeys {
                        let value = snapshot.campos[key]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        draw("\(key): \(value.isEmpty ? "-" : value)")
                    }
                }
                
                if !snapshot.itensInspecao.isEmpty {
                    y += 6
                    draw("Inspeção (\(snapshot.itensInspecao.count) itens)", bold: true, size: 14)
                    let okCount = snapshot.itensInspecao.filter(\.isOK).count
                    let nokCount = snapshot.itensInspecao.count - okCount
                    draw("Resumo: \(okCount) OK · \(nokCount) NOK", size: 11, color: .darkGray)
                    for item in snapshot.itensInspecao {
                        let mark = item.isOK ? "OK" : "NOK"
                        let color: UIColor = item.isOK
                            ? UIColor(red: 0.15, green: 0.55, blue: 0.30, alpha: 1)
                            : UIColor(red: 0.75, green: 0.18, blue: 0.18, alpha: 1)
                        draw("[\(mark)] \(item.title)", size: 11, color: color)
                    }
                }
                
                if !snapshot.observacoes.isEmpty {
                    y += 4
                    draw("Observações", bold: true, size: 14)
                    draw(snapshot.observacoes)
                }
                
                if let resolvedSignature, resolvedSignature.size.width > 1, resolvedSignature.size.height > 1 {
                    y += 8
                    draw("Assinatura", bold: true, size: 14)
                    let sigRect = CGRect(x: margin, y: y, width: 260, height: 100)
                    ensureSpace(sigRect.height + 8)
                    UIColor.white.setFill()
                    context.cgContext.fill(sigRect)
                    UIColor(white: 0.85, alpha: 1).setStroke()
                    context.cgContext.setLineWidth(0.5)
                    context.cgContext.stroke(sigRect)
                    let prepared = SignatureCapture.withWhiteBackground(resolvedSignature)
                    prepared.draw(in: sigRect.insetBy(dx: 4, dy: 4))
                    y += sigRect.height + 10
                }
                
                if !photos.isEmpty {
                    y += 8
                    draw("Fotos (\(photos.count))", bold: true, size: 14)
                    let size: CGFloat = 150
                    var x = margin
                    for photo in photos {
                        ensureSpace(size + 12)
                        if x + size > pageWidth - margin {
                            x = margin
                            y += size + 12
                            ensureSpace(size + 12)
                        }
                        photo.draw(in: CGRect(x: x, y: y, width: size, height: size))
                        x += size + 10
                    }
                    y += size + 12
                }
                
                y += 10
                draw(
                    "Gerado em \(dateFormatter.string(from: Date())) pelo Auto Wize",
                    size: 10,
                    color: .gray
                )
            }
            
            // Garante que o arquivo existe e tem conteúdo
            let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
            let size = attrs[.size] as? NSNumber
            guard let size, size.intValue > 0 else {
                print("Erro PDF: arquivo vazio")
                return nil
            }
            
            return url
        } catch {
            print("Erro PDF: \(error)")
            return nil
        }
    }
    
    /// Apresenta o share sheet no view controller mais no topo (iPhone/iPad).
    static func share(url: URL) {
        DispatchQueue.main.async {
            let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            activity.completionWithItemsHandler = { _, _, _, _ in }
            
            guard let root = topViewController() else {
                print("Erro PDF share: nenhum view controller")
                return
            }
            
            if let popover = activity.popoverPresentationController {
                popover.sourceView = root.view
                popover.sourceRect = CGRect(
                    x: root.view.bounds.midX,
                    y: root.view.bounds.midY,
                    width: 1,
                    height: 1
                )
                popover.permittedArrowDirections = []
            }
            
            root.present(activity, animated: true)
        }
    }
    
    private static func topViewController(
        base: UIViewController? = nil
    ) -> UIViewController? {
        let base = base ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
        
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}

/// Item identificável para sheet de compartilhamento SwiftUI.
struct PDFShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

/// Host que apresenta o share sheet de forma confiável (iPhone e iPad).
struct PDFShareSheet: UIViewControllerRepresentable {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PDFShareHostController {
        let host = PDFShareHostController()
        host.url = url
        host.onFinished = { dismiss() }
        return host
    }
    
    func updateUIViewController(_ uiViewController: PDFShareHostController, context: Context) {
        uiViewController.url = url
        uiViewController.onFinished = { dismiss() }
    }
}

final class PDFShareHostController: UIViewController {
    var url: URL?
    var onFinished: (() -> Void)?
    private var didPresent = false
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didPresent, let url else { return }
        didPresent = true
        
        let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activity.completionWithItemsHandler = { [weak self] _, _, _, _ in
            DispatchQueue.main.async {
                self?.onFinished?()
            }
        }
        
        if let popover = activity.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(
                x: view.bounds.midX,
                y: view.bounds.midY,
                width: 1,
                height: 1
            )
            popover.permittedArrowDirections = []
        }
        
        present(activity, animated: true)
    }
}
