//
//  OverlayView.swift
//  homework-copilot
//
//  Created by Martin Wong on 2025-11-25.
//

import AppKit

class OverlayWindow: NSPanel {
    let textField = NSTextField()
    let scrollView = NSScrollView()
    let visualEffectView = NSVisualEffectView()
    
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 100),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isFloatingPanel = true
        self.hidesOnDeactivate = false
        self.title = "Homework Copilot"
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = true
        self.isOpaque = false
        self.backgroundColor = .clear
        self.appearance = NSAppearance(named: .darkAqua)
        
        setupContent()
        
        if let screen = NSScreen.main {
            let x = (screen.frame.width - 400) / 2
            let y = 100.0
            self.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
    
    func setupContent() {
        guard let contentView = self.contentView else { return }
        
        // Visual effect view
        visualEffectView.frame = contentView.bounds
        visualEffectView.autoresizingMask = [.width, .height]
        visualEffectView.material = .hudWindow
        visualEffectView.state = .active
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.cornerRadius = 12
        
        // Scroll view
        let padding: CGFloat = 16
        scrollView.frame = NSRect(
            x: padding,
            y: padding,
            width: visualEffectView.bounds.width - (padding * 2),
            height: visualEffectView.bounds.height - (padding * 2)
        )
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.autohidesScrollers = true
        
        // Simple text field with wrapping
        textField.frame = scrollView.bounds
        textField.autoresizingMask = [.width]
        textField.isBordered = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.isEditable = false
        textField.isSelectable = true
        textField.textColor = .white
        textField.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        textField.lineBreakMode = .byWordWrapping
        textField.maximumNumberOfLines = 0  // No limit
        textField.preferredMaxLayoutWidth = scrollView.bounds.width - 20
        textField.cell?.wraps = true
        textField.cell?.isScrollable = false
        textField.alignment = .left
        
        scrollView.documentView = textField
        visualEffectView.addSubview(scrollView)
        contentView.addSubview(visualEffectView)
    }
    
    func showWindow(with text: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Clean up text
            var cleanedText = text
                .replacingOccurrences(of: "**", with: "")
                .replacingOccurrences(of: "*", with: "")
                .replacingOccurrences(of: "#", with: "")
            
            // Normalize spacing
            let lines = cleanedText.components(separatedBy: CharacterSet.newlines)
            cleanedText = lines
                .map { line in
                    line.components(separatedBy: CharacterSet.whitespaces)
                        .filter { !$0.isEmpty }
                        .joined(separator: " ")
                }
                .filter { !$0.isEmpty }
                .joined(separator: "\n")
            
            self.textField.stringValue = cleanedText
            
            // Update preferred width for proper wrapping
            self.textField.preferredMaxLayoutWidth = self.scrollView.bounds.width - 20
            
            // Force layout update
            self.textField.invalidateIntrinsicContentSize()
            self.textField.needsLayout = true
            self.textField.layoutSubtreeIfNeeded()
            
            // Adjust text field height to fit content
            let size = self.textField.sizeThatFits(NSSize(
                width: self.scrollView.bounds.width - 20,
                height: CGFloat.greatestFiniteMagnitude
            ))
            self.textField.frame = NSRect(x: 10, y: 0, width: self.scrollView.bounds.width - 20, height: max(size.height, self.scrollView.bounds.height))
            
            self.orderFront(nil)
            self.makeKey()
        }
    }
}
