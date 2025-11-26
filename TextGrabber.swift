//
//  TextGrabber.swift
//  homework-copilot
//
//  Created by Martin Wong on 2025-11-25.
//

import AppKit
import ApplicationServices

class TextGrabber {
    
    /// Gets selected text using Accessibility API (doesn't trigger copy events)
    func getSelectedTextViaAccessibility() -> String? {
        guard let focusedElement = getFocusedElement() else {
            return nil
        }
        
        var selectedText: AnyObject?
        let error = AXUIElementCopyAttributeValue(
            focusedElement,
            kAXSelectedTextAttribute as CFString,
            &selectedText
        )
        
        if error == .success, let text = selectedText as? String {
            return text
        }
        
        return nil
    }
    
    /// Gets selected text from the active application using clipboard (detectable)
    func getSelectedText() -> String? {
        // Try Accessibility API first (stealthier)
        if let text = getSelectedTextViaAccessibility(), !text.isEmpty {
            return text
        }
        
        // Fallback to clipboard method
        return getSelectedTextViaClipboard()
    }
    
    private func getSelectedTextViaClipboard() -> String? {
        // Save current clipboard
        let pasteboard = NSPasteboard.general
        let oldContents = pasteboard.string(forType: .string)
        
        // Clear clipboard
        pasteboard.clearContents()
        
        // Simulate Cmd+C to copy selected text
        let source = CGEventSource(stateID: .hidSystemState)
        
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        let cDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
        let cUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        
        cmdDown?.flags = .maskCommand
        cDown?.flags = .maskCommand
        cUp?.flags = .maskCommand
        
        cmdDown?.post(tap: .cghidEventTap)
        cDown?.post(tap: .cghidEventTap)
        cUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)
        
        // Wait for clipboard to update
        Thread.sleep(forTimeInterval: 0.1)
        
        // Get the copied text
        let selectedText = pasteboard.string(forType: .string)
        
        // Restore old clipboard contents
        pasteboard.clearContents()
        if let oldContents = oldContents {
            pasteboard.setString(oldContents, forType: .string)
        }
        
        return selectedText
    }
    
    private func getFocusedElement() -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedApp: AnyObject?
        
        let appError = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedApplicationAttribute as CFString,
            &focusedApp
        )
        
        guard appError == .success, let app = focusedApp else {
            return nil
        }
        
        var focusedElement: AnyObject?
        let elementError = AXUIElementCopyAttributeValue(
            app as! AXUIElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )
        
        if elementError == .success {
            return focusedElement as! AXUIElement?
        }
        
        return nil
    }
}
