//
//  SignatureCapture.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import UIKit
import PencilKit

enum SignatureCapture {
    
    /// Gera imagem da assinatura com fundo branco (evita retângulo preto no PDF/JPEG).
    static func image(from drawing: PKDrawing) -> UIImage? {
        guard !drawing.bounds.isEmpty else { return nil }
        
        let padding: CGFloat = 20
        let bounds = drawing.bounds.insetBy(dx: -padding, dy: -padding)
        guard bounds.width > 1, bounds.height > 1 else { return nil }
        
        let scale: CGFloat = 3
        let ink = drawing.image(from: bounds, scale: scale)
        let size = CGSize(width: max(bounds.width * scale, 1), height: max(bounds.height * scale, 1))
        
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale = 1
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            ink.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    static func image(from controller: SignaturePadController) -> UIImage? {
        guard let image = controller.makeImage() else { return nil }
        return withWhiteBackground(image)
    }
    
    /// Garante fundo branco mesmo em imagens antigas salvas com transparência convertida em preto.
    static func withWhiteBackground(_ image: UIImage) -> UIImage {
        let size = image.size
        guard size.width > 1, size.height > 1 else { return image }
        
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale = image.scale
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
