//
//  CanvasView.swift
//  ChecklistApp
//
//  Created by Berg Limma on 15/06/26.
//

import SwiftUI
import PencilKit

/// Canvas de assinatura compatível com ScrollView (não deixa o scroll roubar o gesto).- BERG
struct CanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> SignatureCanvasHost {
        let host = SignatureCanvasHost()
        Self.configure(canvasView)
        host.attach(canvasView, coordinator: context.coordinator)
        return host
    }
    
    func updateUIView(_ uiView: SignatureCanvasHost, context: Context) {
        Self.configure(canvasView)
        uiView.attach(canvasView, coordinator: context.coordinator)
    }
    
    private static func configure(_ canvas: PKCanvasView) {
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .white
        canvas.isOpaque = true
        canvas.isScrollEnabled = false
        canvas.alwaysBounceVertical = false
        canvas.alwaysBounceHorizontal = false
        canvas.overrideUserInterfaceStyle = .light
        canvas.isUserInteractionEnabled = true
        canvas.tool = PKInkingTool(.pen, color: .black, width: 3)
        canvas.layer.cornerRadius = AWTheme.radiusM
        canvas.clipsToBounds = true
    }
    
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        weak var canvas: PKCanvasView?
        private weak var installedOn: PKCanvasView?
        private var probe: UILongPressGestureRecognizer?
        
        func installProbe(on canvas: PKCanvasView) {
            self.canvas = canvas
            guard installedOn !== canvas else { return }
            
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
            recognizer.delegate = self
            canvas.addGestureRecognizer(recognizer)
            
            probe = recognizer
            installedOn = canvas
        }
        
        @objc func handleProbe(_ gesture: UILongPressGestureRecognizer) {
            switch gesture.state {
            case .began:
                setParentScrollEnabled(false)
            case .ended, .cancelled, .failed:
                setParentScrollEnabled(true)
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
        
        private func setParentScrollEnabled(_ enabled: Bool) {
            var view: UIView? = canvas?.superview
            while let current = view {
                if let scrollView = current as? UIScrollView, scrollView !== canvas {
                    scrollView.isScrollEnabled = enabled
                    scrollView.canCancelContentTouches = enabled
                    scrollView.delaysContentTouches = false
                }
                view = current.superview
            }
        }
    }
}

/// Host UIKit: evita clipShape do SwiftUI (que bloqueia toques no UIViewRepresentable).
final class SignatureCanvasHost: UIView {
    private weak var canvas: PKCanvasView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        isOpaque = true
        isUserInteractionEnabled = true
        layer.cornerRadius = AWTheme.radiusM
        clipsToBounds = true
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func attach(_ canvas: PKCanvasView, coordinator: CanvasView.Coordinator) {
        if self.canvas !== canvas {
            self.canvas?.removeFromSuperview()
            self.canvas = canvas
            canvas.translatesAutoresizingMaskIntoConstraints = false
            addSubview(canvas)
            NSLayoutConstraint.activate([
                canvas.topAnchor.constraint(equalTo: topAnchor),
                canvas.bottomAnchor.constraint(equalTo: bottomAnchor),
                canvas.leadingAnchor.constraint(equalTo: leadingAnchor),
                canvas.trailingAnchor.constraint(equalTo: trailingAnchor)
            ])
        }
        
        coordinator.installProbe(on: canvas)
        configureEnclosingScrollViews()
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        configureEnclosingScrollViews()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        configureEnclosingScrollViews()
    }
    
    private func configureEnclosingScrollViews() {
        var view: UIView? = superview
        while let current = view {
            if let scrollView = current as? UIScrollView, scrollView !== canvas {
                scrollView.delaysContentTouches = false
            }
            view = current.superview
        }
    }
}
