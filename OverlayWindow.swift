//
//  OverlayView.swift
//  homework-copilot
//
//  Created by Martin Wong on 2025-11-25.
//

import AppKit

class OverlayWindow: NSPanel {
    let textView = NSTextView()
    let scrollView = NSScrollView()
    
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 100),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isFloatingPanel = true
        self.hidesOnDeactivate = false
        self.isMovableByWindowBackground = false
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        
        setupContent()
        
        if let screen = NSScreen.main {
            let x = (screen.frame.width - 400) / 2
            let y = 100.0
            self.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
    
    func setupContent() {
        guard let contentView = self.contentView else { return }
        
        // Scroll view - completely transparent
        scrollView.frame = contentView.bounds
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.autohidesScrollers = true
        
        // Text view - just text, no background
        let textWidth = scrollView.bounds.width - 30  // Leave room for scroller
        textView.frame = NSRect(x: 10, y: 10, width: textWidth, height: 0)
        textView.minSize = NSSize(width: textWidth, height: 0)
        textView.maxSize = NSSize(width: textWidth, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = .width
        
        // Text container setup
        if let textContainer = textView.textContainer {
            textContainer.widthTracksTextView = true
            textContainer.containerSize = NSSize(width: textWidth, height: CGFloat.greatestFiniteMagnitude)
            textContainer.lineFragmentPadding = 0
        }
        
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textColor = .darkGray
        textView.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        textView.textContainerInset = NSSize(width: 0, height: 0)
        
        scrollView.documentView = textView
        contentView.addSubview(scrollView)
    }
    
    func showWindow(with text: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Clean up text - normalize spacing but KEEP ** for bold
            var cleanedText = text
                .replacingOccurrences(of: "#", with: "")   // Remove headers
            
            // Normalize spacing - remove multiple spaces
            while cleanedText.contains("  ") {
                cleanedText = cleanedText.replacingOccurrences(of: "  ", with: " ")
            }
            
            // Clean up lines
            let lines = cleanedText.components(separatedBy: CharacterSet.newlines)
            cleanedText = lines
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .joined(separator: "\n")
            
            // Parse and apply formatting
            let attributedString = self.parseMarkdown(cleanedText)
            self.textView.textStorage?.setAttributedString(attributedString)
            
            // Force complete layout
            if let layoutManager = self.textView.layoutManager,
               let textContainer = self.textView.textContainer {
                layoutManager.ensureLayout(for: textContainer)
            }
            
            // Update text view height based on content
            self.textView.sizeToFit()
            
            // Scroll to top
            self.textView.scroll(NSPoint.zero)
            
            // Force redraw
            self.textView.needsDisplay = true
            self.scrollView.needsDisplay = true
            
            self.orderFront(nil)
            self.makeKey()
        }
    }
    
    private func parseMarkdown(_ text: String) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        // Default paragraph style
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        
        // Split by ** to find bold sections
        let components = text.components(separatedBy: "**")
        
        for (index, component) in components.enumerated() {
            let isBold = index % 2 == 1  // Odd indices are between ** markers
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: isBold ? 
                    NSFont.systemFont(ofSize: 14, weight: .bold) : 
                    NSFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: isBold ? NSColor.black : NSColor.darkGray,
                .paragraphStyle: paragraphStyle
            ]
            
            let attributedComponent = NSAttributedString(string: component, attributes: attributes)
            result.append(attributedComponent)
        }
        
        return result
    }
}
