//
//  RAGStore.swift
//  homework-copilot
//
//  Manages PDF slide documents for RAG: storage, persistence, and retrieval.
//

import Foundation
import PDFKit

// MARK: - Models

struct SlideChunk: Codable, Identifiable {
    let id: String
    let documentId: String
    let documentName: String
    let pageIndex: Int  // 0-based
    let text: String
}

struct StoredDocument: Codable, Identifiable {
    let id: String
    let fileName: String
    let addedAt: Date
    var chunks: [SlideChunk]
}

// MARK: - RAG Store

final class RAGStore: ObservableObject {
    static let shared = RAGStore()
    
    @Published private(set) var documents: [StoredDocument] = []
    
    private let fileManager = FileManager.default
    private let storageFileName = "rag_documents.json"
    private let slidesDirectoryName = "RAGSlides"
    
    private var storageURL: URL? {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent(Bundle.main.bundleIdentifier ?? "homework-copilot", isDirectory: true)
            .appendingPathComponent(storageFileName)
    }
    
    private var slidesDirectoryURL: URL? {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent(Bundle.main.bundleIdentifier ?? "homework-copilot", isDirectory: true)
            .appendingPathComponent(slidesDirectoryName, isDirectory: true)
    }
    
    private init() {
        load()
    }
    
    // MARK: - Persistence
    
    private func ensureAppSupportDirectory() {
        guard let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first,
              let bundleId = Bundle.main.bundleIdentifier else { return }
        let dir = base.appendingPathComponent(bundleId, isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        guard let slidesDir = slidesDirectoryURL else { return }
        try? fileManager.createDirectory(at: slidesDir, withIntermediateDirectories: true)
    }
    
    func load() {
        ensureAppSupportDirectory()
        guard let url = storageURL, fileManager.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([StoredDocument].self, from: data)
            documents = decoded
        } catch {
            print("RAGStore load error: \(error)")
        }
    }
    
    func save() {
        guard let url = storageURL else { return }
        ensureAppSupportDirectory()
        do {
            let data = try JSONEncoder().encode(documents)
            try data.write(to: url)
        } catch {
            print("RAGStore save error: \(error)")
        }
    }
    
    // MARK: - Add / Remove
    
    /// Add a PDF from a file URL (e.g. from drag-and-drop). Copies into App Support and extracts text.
    func addPDF(from sourceURL: URL) throws {
        guard sourceURL.pathExtension.lowercased() == "pdf" else {
            throw NSError(domain: "RAGStore", code: -1, userInfo: [NSLocalizedDescriptionKey: "File must be a PDF"])
        }
        guard let slidesDir = slidesDirectoryURL else {
            throw NSError(domain: "RAGStore", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not create storage directory"])
        }
        
        let docId = UUID().uuidString
        let fileName = sourceURL.lastPathComponent
        let destURL = slidesDir.appendingPathComponent("\(docId).pdf")
        
        if fileManager.fileExists(atPath: destURL.path) {
            try fileManager.removeItem(at: destURL)
        }
        try fileManager.copyItem(at: sourceURL, to: destURL)
        
        let chunks = PDFProcessor.extractChunks(from: destURL, documentId: docId, documentName: fileName)
        let doc = StoredDocument(id: docId, fileName: fileName, addedAt: Date(), chunks: chunks)
        documents.append(doc)
        save()
    }
    
    func removeDocument(id: String) {
        documents.removeAll { $0.id == id }
        if let slidesDir = slidesDirectoryURL {
            let pdfURL = slidesDir.appendingPathComponent("\(id).pdf")
            try? fileManager.removeItem(at: pdfURL)
        }
        save()
    }
    
    func removeAll() {
        if let slidesDir = slidesDirectoryURL {
            try? fileManager.contentsOfDirectory(at: slidesDir, includingPropertiesForKeys: nil).forEach { try? fileManager.removeItem(at: $0) }
        }
        documents.removeAll()
        save()
    }
    
    // MARK: - Retrieval
    
    /// Returns context string to inject into the LLM prompt (all chunks, with a character limit).
    func retrievedContext(for query: String, maxCharacters: Int = 12_000) -> String {
        var allChunks: [(chunk: SlideChunk, order: Int)] = []
        for doc in documents {
            for (idx, chunk) in doc.chunks.enumerated() where !chunk.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                allChunks.append((chunk, idx))
            }
        }
        guard !allChunks.isEmpty else { return "" }
        
        var parts: [String] = []
        var total = 0
        for (chunk, _) in allChunks {
            let block = "--- Slide \(chunk.pageIndex + 1) (\(chunk.documentName)) ---\n\(chunk.text)"
            if total + block.count > maxCharacters { break }
            parts.append(block)
            total += block.count
        }
        guard !parts.isEmpty else { return "" }
        return "Reference material from your slides:\n\n" + parts.joined(separator: "\n\n")
    }
    
    var hasContent: Bool {
        !documents.isEmpty && documents.contains { !$0.chunks.isEmpty }
    }
}

// MARK: - PDF Processor

enum PDFProcessor {
    /// Extract one chunk per page (slide).
    static func extractChunks(from url: URL, documentId: String, documentName: String) -> [SlideChunk] {
        guard let doc = PDFDocument(url: url) else { return [] }
        var chunks: [SlideChunk] = []
        for pageIndex in 0..<doc.pageCount {
            guard let page = doc.page(at: pageIndex) else { continue }
            let text = page.string ?? ""
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let chunk = SlideChunk(
                id: "\(documentId)-\(pageIndex)",
                documentId: documentId,
                documentName: documentName,
                pageIndex: pageIndex,
                text: trimmed
            )
            chunks.append(chunk)
        }
        return chunks
    }
}
