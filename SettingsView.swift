//
//  SettingsView.swift
//  homework-copilot
//
//  Created by Martin Wong on 2025-11-25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("apiKey") private var apiKey = ""
    @AppStorage("selectedModel") private var selectedModel = "meta/meta-llama-3.1-70b-instruct"
    @AppStorage("customPrompt") private var customPrompt = """
    On the first line, output ONLY the final answer in bold using two asterisks on each side, like this: **The answer is option A**. Do not include any other text on that line. After that, write a 1-2 sentence explanation. Always use bold by wrapping text in double asterisks. No preamble, no extra lines before the answer.
    """
    @State private var showingSaved = false
    
    let models = [
        ModelOption(
            name: "Claude 3.7 Sonnet (Best)",
            value: "anthropic/claude-3.7-sonnet",
            description: "Most capable - Excellent reasoning"
        ),
        ModelOption(
            name: "Llama 3.1 70B (Fast)",
            value: "meta/meta-llama-3.1-70b-instruct:fbfb20b472b2f3bdd101412a9f70a0ed4fc0ced78a77ff00970ee7a2383c575d",
            description: "Fast & capable"
        ),
        ModelOption(
            name: "Mistral 7B (Fastest)",
            value: "mistralai/mistral-7b-instruct-v0.2:f5701ad84de5715051cb99d550239719f8a754bad37e3bc06d7e2cef97f83923",
            description: "Quick responses"
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
                
                // API Key Section
                VStack(alignment: .leading, spacing: 8) {
                    Label("Replicate API Token", systemImage: "key.fill")
                        .font(.headline)
                    
                    SecureField("r8_...", text: $apiKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    HStack {
                        Image(systemName: "info.circle")
                            .font(.caption)
                        Text("Get your API token from: replicate.com/account/api-tokens")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 5)
                
                Divider()
                
                // Model Selection
                VStack(alignment: .leading, spacing: 12) {
                    Label("LLM Model", systemImage: "cpu")
                        .font(.headline)
                    
                    ForEach(models, id: \.value) { model in
                        Button(action: {
                            selectedModel = model.value
                        }) {
                            HStack {
                                Image(systemName: selectedModel == model.value ? "largecircle.fill.circle" : "circle")
                                    .foregroundStyle(selectedModel == model.value ? .blue : .gray)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(model.name)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    Text(model.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(10)
                            .background(selectedModel == model.value ? Color.blue.opacity(0.1) : Color.clear)
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("OCR: Apple Vision (free, fast, offline)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 5)
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
        .frame(width: 550, height: 650)
        .onChange(of: apiKey) {
            showingSaved = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showingSaved = false
            }
        }
        .onChange(of: selectedModel) {
            showingSaved = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showingSaved = false
            }
        }
        .onChange(of: customPrompt) {
            showingSaved = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showingSaved = false
            }
        }
    }
}

struct ModelOption {
    let name: String
    let value: String
    let description: String
}
