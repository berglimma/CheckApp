//
//  CanvasView.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import SwiftUI
import UIKit

/// Controla o pad de assinatura (limpar / exportar). Compatível com ScrollView.
final class SignaturePadController: ObservableObject {
    fileprivate weak var inkView: SignatureInkView?
    
    var hasInk: Bool {
        inkView?.hasInk == true
    }
    
    func clear() {
        inkView?.clear()
        objectWillChange.send()
    }
    
    func makeImage() -> UIImage? {
        inkView?.exportImage()
    }
    
    func pngData() -> Data? {
        makeImage()?.pngData()
    }
    
    fileprivate func attach(_ view: SignatureInkView) {
        inkView = view
    }
}

/// Canvas de assinatura por toque — não usa PencilKit (evita conflito com ScrollView).
struct CanvasView: UIViewRepresentable {
    @ObservedObject var controller: SignaturePadController
    
    func makeCoordinator() -> Coordinator {
        Coordinator(controller: controller)
    }
    
    func makeUIView(context: Context) -> SignatureInkView {
        let view = SignatureInkView()
        controller.attach(view)
        context.coordinator.installScrollLock(on: view)
        return view
    }
    
    func updateUIView(_ uiView: SignatureInkView, context: Context) {
        controller.attach(uiView)
        context.coordinator.installScrollLock(on: uiView)
    }
    
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private let controller: SignaturePadController
        private weak var installedOn: SignatureInkView?
        private var probe: UILongPressGestureRecognizer?
        
        init(controller: SignaturePadController) {
            self.controller = controller
        }
        
        func installScrollLock(on view: SignatureInkView) {
            guard installedOn !== view else { return }
            
            if let probe, let old = installedOn {
                old.removeGestureRecognizer(probe)
            }
            
            let recognizer = UILongPressGestureRecognizer(
                target: self,
                action: #selector(handleProbe(_:))
            )
            recognizer.minimumPressDuration = 0
            recognizer.allowableMovement = .greatestFiniteMagnitude
            recognizer.cancelsTouchesInView = false
            recognizer.delaysTouchesBegan = false
            recognizer.delaysTouchesEnded = false
            recognizer.delegate = self
            view.addGestureRecognizer(recognizer)
            
            probe = recognizer
            installedOn = view
            configureEnclosingScrollViews(from: view)
        }
        
        @objc private func handleProbe(_ gesture: UILongPressGestureRecognizer) {
            switch gesture.state {
            case .began:
                setParentScrollEnabled(false, from: gesture.view)
            case .ended, .cancelled, .failed:
                setParentScrollEnabled(true, from: gesture.view)
            default:
                break
            }
        }
        
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }
        
        private func setParentScrollEnabled(_ enabled: Bool, from view: UIView?) {
            var current = view?.superview
            while let node = current {
                if let scrollView = node as? UIScrollView {
                    scrollView.isScrollEnabled = enabled
                    scrollView.canCancelContentTouches = enabled
                    scrollView.delaysContentTouches = false
                }
                current = node.superview
            }
        }
        
        private func configureEnclosingScrollViews(from view: UIView) {
            var current: UIView? = view.superview
            while let node = current {
                if let scrollView = node as? UIScrollView {
                    scrollView.delaysContentTouches = false
                    scrollView.canCancelContentTouches = true
                }
                current = node.superview
            }
        }
    }
}

/// Desenho por toque com UIKit puro.
final class SignatureInkView: UIView {
    private var strokes: [[CGPoint]] = []
    private var currentStroke: [CGPoint] = []
    
    var hasInk: Bool {
        !strokes.isEmpty || currentStroke.count > 1
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        isOpaque = true
        isMultipleTouchEnabled = false
        isUserInteractionEnabled = true
        layer.cornerRadius = AWTheme.radiusM
        clipsToBounds = true
        layer.borderWidth = 1
        layer.borderColor = UIColor.black.withAlphaComponent(0.08).cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func clear() {
        strokes.removeAll()
        currentStroke.removeAll()
        setNeedsDisplay()
    }
    
    func exportImage() -> UIImage? {
        guard hasInk, bounds.width > 1, bounds.height > 1 else { return nil }
        
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale = UIScreen.main.scale
        
        let renderer = UIGraphicsImageRenderer(size: bounds.size, format: format)
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(bounds)
            drawStrokes(in: ctx.cgContext)
        }
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        UIColor.white.setFill()
        context.fill(bounds)
        drawStrokes(in: context)
    }
    
    private func drawStrokes(in context: CGContext) {
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(3)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        for stroke in strokes + (currentStroke.isEmpty ? [] : [currentStroke]) {
            guard let first = stroke.first else { continue }
            context.beginPath()
            context.move(to: first)
            for point in stroke.dropFirst() {
                context.addLine(to: point)
            }
            context.strokePath()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        currentStroke = [point]
        setNeedsDisplay()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        currentStroke.append(point)
        setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        finishStroke()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        finishStroke()
    }
    
    private func finishStroke() {
        if currentStroke.count > 1 {
            strokes.append(currentStroke)
        }
        currentStroke.removeAll()
        setNeedsDisplay()
    }
}
