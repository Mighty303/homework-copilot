//
//  SettingsView.swift
//  homework-copilot
//
//  Created by Martin Wong on 2025-11-25.
//

import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct SettingsView: View {
    @AppStorage("apiKey") private var apiKey = ""
    @AppStorage("selectedModel") private var selectedModel = "anthropic/claude-4.5-sonnet"
    @AppStorage("aiProvider") private var aiProvider = "replicate"
    @AppStorage("claudeApiKey") private var claudeApiKey = ""
    @AppStorage("claudeModel") private var claudeModel = "claude-sonnet-4-6"
    @AppStorage("customPrompt") private var customPrompt = """
    On the first line, output ONLY the final answer in bold using two asterisks on each side, like this: **The answer is option A**. Do not include any other text on that line. After that, write a 1-2 sentence explanation. Always use bold by wrapping text in double asterisks. No preamble, no extra lines before the answer.
    """
    @State private var showingSaved = false
    @ObservedObject private var ragStore = RAGStore.shared
    @State private var dropTargeted = false
    @State private var ragError: String?
    @State private var ragProcessing = false
    
    let models = [
        ModelOption(
            name: "Claude 4.5 Sonnet",
            value: "anthropic/claude-4.5-sonnet",
            description: "Vision-capable - Latest & most capable"
        )
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 40))
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading) {
                        Text("Homework Copilot")
                            .font(.title2)
                            .bold()
                        Text("Settings")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.bottom, 10)
                
                Divider()

                // AI Provider Section
                VStack(alignment: .leading, spacing: 12) {
                    Label("AI Provider", systemImage: "network")
                        .font(.headline)

                    Picker("Provider", selection: $aiProvider) {
                        Text("Replicate").tag("replicate")
                        Text("Claude Direct").tag("claude")
                    }
                    .pickerStyle(.segmented)

                    if aiProvider == "replicate" {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Replicate API Token")
                                .font(.subheadline).foregroundColor(.secondary)
                            SecureField("r8_...", text: $apiKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            HStack {
                                Image(systemName: "info.circle").font(.caption)
                                Text("Get your token from: replicate.com/account/api-tokens")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Model")
                                .font(.subheadline).foregroundColor(.secondary)
                            ForEach(models, id: \.value) { model in
                                HStack {
                                    Image(systemName: "largecircle.fill.circle").foregroundStyle(.blue)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(model.name).font(.subheadline).foregroundColor(.primary)
                                        Text(model.description).font(.caption).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(10)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Anthropic API Key")
                                .font(.subheadline).foregroundColor(.secondary)
                            SecureField("sk-ant-...", text: $claudeApiKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            HStack {
                                Image(systemName: "info.circle").font(.caption)
                                Text("Get your key from: console.anthropic.com")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Model")
                                .font(.subheadline).foregroundColor(.secondary)
                            Picker("Claude Model", selection: $claudeModel) {
                                Text("Claude Sonnet 4.6").tag("claude-sonnet-4-6")
                                Text("Claude Opus 4.6 (Most capable)").tag("claude-opus-4-6")
                                Text("Claude Sonnet 4.5").tag("claude-sonnet-4-5")
                                Text("Claude Haiku 4.5 (Fast)").tag("claude-haiku-4-5-20251001")
                            }
                            .pickerStyle(.radioGroup)
                            HStack {
                                Image(systemName: "eye.fill").foregroundColor(.purple).font(.caption)
                                Text("Supports text (OCR) and direct image vision — no polling")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.vertical, 5)
                
                Divider()
                
                // Custom Prompt Section
                VStack(alignment: .leading, spacing: 8) {
                    Label("Custom Prompt Instructions", systemImage: "text.bubble")
                        .font(.headline)
                    
                    TextEditor(text: $customPrompt)
                        .frame(height: 120)
                        .font(.system(size: 12))
                        .padding(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    
                    HStack {
                        Image(systemName: "info.circle")
                            .font(.caption)
                        Text("Use **text** for bold formatting. Customize how the AI responds.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Reset to Default") {
                        customPrompt = """
                        On the first line, output ONLY the final answer in bold using two asterisks on each side, like this: **The answer is option A**. Do not include any other text on that line. After that, write a 1–2 sentence explanation. Always use bold by wrapping text in double asterisks. No preamble, no extra lines before the answer.
                        """
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding(.vertical, 5)
                
                Divider()
                
                // Slides / RAG Section
                VStack(alignment: .leading, spacing: 12) {
                    Label("Slides (RAG)", systemImage: "doc.richtext")
                        .font(.headline)
                    
                    Text("Drop PDF slides here. The AI will use them as reference when answering questions.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(dropTargeted ? Color.accentColor : Color.gray.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [8]))
                            .background(RoundedRectangle(cornerRadius: 12).fill(dropTargeted ? Color.accentColor.opacity(0.08) : Color.gray.opacity(0.06)))
                            .frame(height: 80)
                        
                        VStack(spacing: 6) {
                            if ragProcessing {
                                ProgressView()
                                    .scaleEffect(0.9)
                                Text("Processing PDF…")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Image(systemName: "doc.badge.plus")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                Text("Drop PDF files here or click to browse")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onTapGesture {
                        openPDFFilePicker()
                    }
                    .onDrop(of: [.pdf, .fileURL], isTargeted: $dropTargeted) { providers in
                        handlePDFDrop(providers: providers)
                    }
                    
                    if let err = ragError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(err)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .onTapGesture { ragError = nil }
                    }
                    
                    if !ragStore.documents.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Added documents (\(ragStore.documents.count))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            ForEach(ragStore.documents) { doc in
                                HStack {
                                    Image(systemName: "doc.fill")
                                        .foregroundColor(.blue)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(doc.fileName)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                        Text("\(doc.chunks.count) slides")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Button(role: .destructive) {
                                        ragStore.removeDocument(id: doc.id)
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                            if ragStore.documents.count > 1 {
                                Button("Clear all slides") {
                                    ragStore.removeAll()
                                }
                                .font(.caption)
                                .foregroundColor(.red)
                            }
                        }
                    }
                }
                .padding(.vertical, 5)
                
                Divider()
                
                // Hotkeys Section
                VStack(alignment: .leading, spacing: 12) {
                    Label("Keyboard Shortcuts", systemImage: "keyboard")
                        .font(.headline)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("⌘⇧S")
                                .font(.system(.body, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(6)
                            Text("Capture screenshot and solve")
                                .font(.subheadline)
                            Spacer()
                        }
                        
                        HStack {
                            Text("⌘⇧C")
                                .font(.system(.body, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(6)
                            Text("Hide/show answer window")
                                .font(.subheadline)
                            Spacer()
                        }
                        
                        HStack {
                            Text("⌘⇧T")
                                .font(.system(.body, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(6)
                            Text("Send selected text to AI")
                                .font(.subheadline)
                            Spacer()
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("⌥↑")
                                .font(.system(.title3, design: .monospaced))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(6)
                            Text("Capture & OCR → Text mode")
                                .font(.subheadline)
                            Spacer()
                        }
                        
                        HStack {
                            Text("→")
                                .font(.system(.title3, design: .monospaced))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.2))
                                .cornerRadius(6)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Capture & send image → Vision mode")
                                    .font(.subheadline)
                                Text("Best for diagrams, handwriting, complex layouts")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        
                        HStack {
                            Text("⌥←")
                                .font(.system(.title3, design: .monospaced))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(6)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Capture region & OCR (500px)")
                                    .font(.subheadline)
                                Text("Fast, focused capture around cursor")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        
                        HStack {
                            Text("↓")
                                .font(.system(.title3, design: .monospaced))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(6)
                            Text("Toggle answer visibility")
                                .font(.subheadline)
                            Spacer()
                        }
                    }
                }
                .padding(.vertical, 5)
                
                if showingSaved {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Settings saved automatically")
                            .foregroundColor(.green)
                            .font(.subheadline)
                    }
                    .padding(.top, 10)
                }
                
                Spacer()
            }
            .padding()
        }
        .frame(width: 550, height: 780)
        .onChange(of: apiKey) {
            showingSaved = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showingSaved = false }
        }
        .onChange(of: claudeApiKey) {
            showingSaved = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showingSaved = false }
        }
        .onChange(of: aiProvider) {
            showingSaved = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showingSaved = false }
        }
        .onChange(of: claudeModel) {
            showingSaved = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showingSaved = false }
        }
        .onChange(of: selectedModel) {
            showingSaved = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showingSaved = false }
        }
        .onChange(of: customPrompt) {
            showingSaved = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showingSaved = false }
        }
    }
    
    private func openPDFFilePicker() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.title = "Select PDF Slides"
        panel.prompt = "Add"
        
        // Ensure we're on the main thread and have a proper window context
        DispatchQueue.main.async {
            // Use beginSheetModal if we have a window, otherwise use begin
            if let window = NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first {
                panel.beginSheetModal(for: window) { response in
                    self.handlePDFSelection(response: response, urls: panel.urls)
                }
            } else {
                // Fallback to begin if no window available
                panel.begin { response in
                    self.handlePDFSelection(response: response, urls: panel.urls)
                }
            }
        }
    }
    
    private func handlePDFSelection(response: NSApplication.ModalResponse, urls: [URL]) {
        guard response == .OK else { return }
        
        ragError = nil
        ragProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            var errors: [String] = []
            for url in urls {
                do {
                    try RAGStore.shared.addPDF(from: url)
                } catch {
                    errors.append("\(url.lastPathComponent): \(error.localizedDescription)")
                }
            }
            
            DispatchQueue.main.async {
                ragProcessing = false
                if !errors.isEmpty {
                    ragError = errors.joined(separator: "\n")
                }
            }
        }
    }
    
    private func handlePDFDrop(providers: [NSItemProvider]) -> Bool {
        ragError = nil
        for provider in providers {
            guard provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) else { continue }
            DispatchQueue.main.async { ragProcessing = true }
            provider.loadFileRepresentation(forTypeIdentifier: UTType.pdf.identifier) { url, error in
                guard let url = url, error == nil else {
                    DispatchQueue.main.async {
                        ragProcessing = false
                        if let error = error {
                            ragError = error.localizedDescription
                        }
                    }
                    return
                }
                // URL from loadFileRepresentation is temporary; copy to a permanent location before async
                let tempCopy = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                try? FileManager.default.removeItem(at: tempCopy)
                try? FileManager.default.copyItem(at: url, to: tempCopy)
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        try RAGStore.shared.addPDF(from: tempCopy)
                        try? FileManager.default.removeItem(at: tempCopy)
                        DispatchQueue.main.async { ragProcessing = false }
                    } catch {
                        DispatchQueue.main.async {
                            ragProcessing = false
                            ragError = error.localizedDescription
                        }
                    }
                }
            }
            return true
        }
        return false
    }
}

struct ModelOption {
    let name: String
    let value: String
    let description: String
}
