//
//  ScreenCapturer.swift
//  homework-copilot
//
//  Created by Martin Wong on 2025-11-25.
//

import AppKit
import ScreenCaptureKit

class ScreenCapturer {
    
    func captureScreen() async throws -> NSImage {
        // Get available content
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        
        guard let display = content.displays.first else {
            throw NSError(domain: "ScreenCapture", code: -1, userInfo: [NSLocalizedDescriptionKey: "No display found"])
        }
        
        // Create filter for the entire display
        let filter = SCContentFilter(display: display, excludingWindows: [])
        
        // Configure capture settings
        let config = SCStreamConfiguration()
        config.width = display.width
        config.height = display.height
        config.scalesToFit = false
        config.showsCursor = false
        
        // Capture the screen
        let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
        
        // Convert CGImage to NSImage
        let size = NSSize(width: image.width, height: image.height)
        return NSImage(cgImage: image, size: size)
    }
    
    func captureRegion(rect: CGRect) async throws -> NSImage {
        // Get available content
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        
        guard let display = content.displays.first else {
            throw NSError(domain: "ScreenCapture", code: -1, userInfo: [NSLocalizedDescriptionKey: "No display found"])
        }
        
        // Create filter
        let filter = SCContentFilter(display: display, excludingWindows: [])
        
        // Configure capture for specific region
        let config = SCStreamConfiguration()
        config.sourceRect = rect
        config.width = Int(rect.width)
        config.height = Int(rect.height)
        config.scalesToFit = false
        config.showsCursor = false
        
        // Capture the region
        let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
        
        let size = NSSize(width: image.width, height: image.height)
        return NSImage(cgImage: image, size: size)
    }
}
