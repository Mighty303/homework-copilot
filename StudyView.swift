//
//  StudyView.swift
//  homework-copilot
//
//  Simple flashcard & quiz UI backed by the RAG slide store.
//

import SwiftUI
import Foundation

private enum StudyMode: String, CaseIterable, Identifiable {
    case flashcards = "Flashcards"
    case quiz = "Quiz"
    
    var id: String { rawValue }
}

struct StudyView: View {
    @ObservedObject private var ragStore = RAGStore.shared
    
    @State private var mode: StudyMode = .flashcards
    @State private var currentIndex: Int = 0
    @State private var showAnswer: Bool = false
    @State private var revealedCardIDs: Set<String> = []
    @State private var deckOrder: [String] = []
    @State private var userAnswer: String = ""
    @State private var feedback: String?
    @State private var isCheckingWithAI: Bool = false
    @State private var quizQuestions: [String] = []
    @State private var isGeneratingQuiz: Bool = false
    
    private var allChunks: [SlideChunk] {
        ragStore.documents.flatMap { $0.chunks }
            .filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .sorted { lhs, rhs in
                if lhs.documentName == rhs.documentName {
                    return lhs.pageIndex < rhs.pageIndex
                }
                return lhs.documentName < rhs.documentName
            }
    }
    
    /// Heuristic subset of "important" slides to emphasize in the deck.
    /// Prefers slides that look like titled, content‑rich pages.
    private var importantChunks: [SlideChunk] {
        let candidates = allChunks.filter { chunk in
            let text = chunk.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard text.count > 80 else { return false } // avoid tiny slides
            let firstLine = text.split(separator: "\n").first.map(String.init) ?? ""
            let wordCount = firstLine.split(separator: " ").count
            // Treat short-ish headings as more important (2–12 words)
            return (2...12).contains(wordCount)
        }
        // If heuristic finds nothing, fall back to all chunks
        let base = candidates.isEmpty ? allChunks : candidates
        // Cap deck size to keep study set focused
        return Array(base.prefix(60))
    }
    
    /// Deck actually used by the UI (important slides if available).
    private var deck: [SlideChunk] {
        importantChunks.isEmpty ? allChunks : importantChunks
    }
    
    /// Deck ordered for display (supports shuffling).
    private var orderedDeck: [SlideChunk] {
        let map = Dictionary(uniqueKeysWithValues: deck.map { ($0.id, $0) })
        let fromOrder = deckOrder.compactMap { map[$0] }
        if fromOrder.count == deck.count {
            return fromOrder
        }
        // Fallback to natural deck order if something went out of sync
        return deck
    }
    
    /// Palette of base colors for cards.
    private let cardColors: [Color] = [
        .blue, .purple, .indigo, .teal, .orange, .pink
    ]
    
    private func gradient(for chunk: SlideChunk) -> LinearGradient {
        let hash = abs(chunk.id.hashValue)
        let base = cardColors[hash % cardColors.count]
        let lighter = base.opacity(0.85)
        let darker = base.opacity(0.55)
        return LinearGradient(
            gradient: Gradient(colors: [lighter, darker]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Study Deck")
                    .font(.title2)
                    .bold()
                Spacer()
                if mode == .quiz {
                    Button {
                        Task {
                            quizQuestions = []
                            await generateQuizQuestionsIfNeeded()
                        }
                    } label: {
                        Text("Generate Quiz")
                    }
                    .buttonStyle(.bordered)
                }
                Button {
                    shuffleDeck()
                } label: {
                    Image(systemName: "shuffle")
                        .imageScale(.medium)
                }
                .help("Shuffle card order")
                .buttonStyle(.borderless)
                .padding(.trailing, 4)
                Picker("Mode", selection: $mode) {
                    ForEach(StudyMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 220)
            }
            .padding(.bottom, 4)
            
            if deck.isEmpty {
                VStack(spacing: 8) {
                    Text("No slides found")
                        .font(.headline)
                    Text("Add PDF slides in Settings, then reopen this Study window.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                content
            }
        }
        .padding()
        .frame(width: 900, height: 620)
        .onAppear {
            resetDeckOrder()
        }
        .onChange(of: deck.count) { _, _ in
            resetDeckOrder()
        }
        .onChange(of: mode) { oldMode, newMode in
            if oldMode != .quiz && newMode == .quiz {
                Task { await generateQuizQuestionsIfNeeded() }
            }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if mode == .flashcards {
            let total = orderedDeck.count
            // Colorful grid of flashcards – emphasizes a subset of important slides.
            VStack(alignment: .leading, spacing: 12) {
                Text("Showing \(total) key slides from your decks")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ScrollView {
                    let columns = [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ]
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(orderedDeck, id: \.id) { card in
                            let isRevealed = revealedCardIDs.contains(card.id)
                            
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    if isRevealed {
                                        revealedCardIDs.remove(card.id)
                                    } else {
                                        revealedCardIDs.insert(card.id)
                                    }
                                }
                            } label: {
                                ZStack(alignment: .topLeading) {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(gradient(for: card))
                                        .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Slide \(card.pageIndex + 1)")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.8))
                                        
                                        Text(frontText(for: card))
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .lineLimit(3)
                                        
                                        Spacer(minLength: 0)
                                        
                                        if isRevealed {
                                            Divider()
                                                .background(Color.white.opacity(0.4))
                                            Text(card.text)
                                                .font(.footnote)
                                                .foregroundColor(.white.opacity(0.9))
                                                .lineLimit(6)
                                        } else {
                                            Text("Tap to reveal")
                                                .font(.footnote)
                                                .foregroundColor(.white.opacity(0.9))
                                        }
                                    }
                                    .padding(12)
                                }
                                .frame(height: 190)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        } else {
            // Conceptual quiz view backed by LLM-generated questions
            if isGeneratingQuiz {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Generating quiz questions from your slides…")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if quizQuestions.isEmpty {
                VStack(spacing: 8) {
                    Text("No quiz questions yet")
                        .font(.headline)
                    Text("Click “Generate Quiz” to have the AI create conceptual questions from your slides.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    if let feedback = feedback {
                        Text(feedback)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let total = quizQuestions.count
                let index = min(max(currentIndex, 0), max(total - 1, 0))
                let question = quizQuestions[index]
                // Use slides only for styling/theme
                let styleChunk = orderedDeck[min(index, orderedDeck.count - 1)]
                
                VStack(spacing: 16) {
                    HStack {
                        Text("Question \(index + 1) of \(total)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(gradient(for: styleChunk))
                            .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text(frontText(for: styleChunk))
                                .font(.title3.bold())
                                .foregroundColor(.white)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Divider()
                                .background(Color.white.opacity(0.4))
                                .padding(.vertical, 2)
                            
                            Text("Question")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                            Text(question)
                                .font(.headline)
                                .foregroundColor(.white)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Divider()
                                .background(Color.white.opacity(0.4))
                                .padding(.vertical, 4)
                            
                            Text("Reference (hidden until reveal)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                            
                            if showAnswer {
                                ScrollView {
                                    Text(styleChunk.text)
                                        .font(.body)
                                        .foregroundColor(.white)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            } else {
                                Text("Try to answer from memory first, then press “Show Reference”.")
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.95))
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.4))
                                .padding(.vertical, 4)
                            
                            Text("Your answer")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                            
                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.08))
                                TextEditor(text: $userAnswer)
                                    .scrollContentBackground(.hidden)
                                    .font(.body)
                                    .foregroundColor(.white)
                                    .padding(4)
                            }
                            .frame(height: 120)
                            
                            if let feedback = feedback {
                                Divider()
                                    .background(Color.white.opacity(0.4))
                                    .padding(.vertical, 4)
                                
                                Text("AI feedback")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.9))
                                
                                ScrollView {
                                    Text(feedback)
                                        .font(.body)
                                        .foregroundColor(.white)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .frame(maxHeight: 140)
                            }
                        }
                        .padding(16)
                    }
                    
                    HStack {
                        Button {
                            withAnimation {
                                if currentIndex > 0 {
                                    currentIndex -= 1
                                    showAnswer = false
                                    userAnswer = ""
                                    feedback = nil
                                }
                            }
                        } label: {
                            Label("Previous", systemImage: "chevron.left")
                        }
                        .disabled(currentIndex == 0)
                        
                        Button {
                            withAnimation {
                                if currentIndex < total - 1 {
                                    currentIndex += 1
                                    showAnswer = false
                                    userAnswer = ""
                                    feedback = nil
                                }
                            }
                        } label: {
                            Label("Next", systemImage: "chevron.right")
                        }
                        .disabled(currentIndex >= total - 1)
                        
                        Spacer()
                        
                        Button(showAnswer ? "Hide Reference" : "Show Reference") {
                            withAnimation {
                                showAnswer.toggle()
                            }
                        }
                        .keyboardShortcut(.space, modifiers: [])
                        
                        Button {
                            Task {
                                await checkAnswerWithAI(for: styleChunk)
                            }
                        } label: {
                            if isCheckingWithAI {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            } else {
                                Text("Check with AI")
                            }
                        }
                        .disabled(userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCheckingWithAI)
                    }
                }
            }
        }
    }
    
    private func frontText(for chunk: SlideChunk) -> String {
        let lines = chunk.text.split(separator: "\n").map { String($0) }
        if let first = lines.first, !first.trimmingCharacters(in: .whitespaces).isEmpty {
            return first
        }
        // Fallback: truncated snippet
        return String(chunk.text.prefix(140))
    }
    
    private func resetDeckOrder() {
        deckOrder = deck.map { $0.id }
        currentIndex = 0
        showAnswer = false
        revealedCardIDs.removeAll()
    }
    
    private func shuffleDeck() {
        guard !deck.isEmpty else { return }
        deckOrder = deck.map { $0.id }.shuffled()
        currentIndex = 0
        showAnswer = false
        revealedCardIDs.removeAll()
        userAnswer = ""
        feedback = nil
    }
    
    private func generateQuizQuestionsIfNeeded() async {
        guard !deck.isEmpty else { return }
        if isGeneratingQuiz || !quizQuestions.isEmpty { return }
        isGeneratingQuiz = true
        do {
            print("🧠 Generating quiz questions from \(deck.count) slides…")
            let qs = try await StudyLLMClient.generateConceptQuestions(from: deck)
            await MainActor.run {
                self.quizQuestions = qs
                self.currentIndex = 0
                self.showAnswer = false
                self.userAnswer = ""
                self.feedback = nil
                self.isGeneratingQuiz = false
            }
        } catch {
            await MainActor.run {
                self.feedback = "Error generating quiz: \(error.localizedDescription)"
                print("❌ Quiz generation error: \(error.localizedDescription)")
                self.isGeneratingQuiz = false
            }
        }
    }
    
    private func checkAnswerWithAI(for chunk: SlideChunk) async {
        let trimmed = userAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isCheckingWithAI = true
        feedback = nil
        
        do {
            let response = try await StudyLLMClient.checkAnswer(slide: chunk, userAnswer: trimmed)
            await MainActor.run {
                self.feedback = response
                self.isCheckingWithAI = false
            }
        } catch {
            await MainActor.run {
                self.feedback = "Error checking answer: \(error.localizedDescription)"
                self.isCheckingWithAI = false
            }
        }
    }
}

// MARK: - LLM client for study feedback

private enum StudyLLMClient {
    static func checkAnswer(slide: SlideChunk, userAnswer: String) async throws -> String {
        let slideText = slide.text
        let title = slideText.split(separator: "\n").first.map(String.init) ?? "this slide"

        let prompt = """
        You are a tutor giving targeted feedback on a student's answer, based ONLY on the slide content below.

        Slide title: \(title)
        Slide text:
        \(slideText)

        Student's answer:
        \(userAnswer)

        1. Briefly say how correct the answer is overall.
        2. Point out any important misunderstandings or missing ideas.
        3. Suggest a 1–2 sentence improved answer the student could aim for.

        Be concise (max ~8 sentences total) and focus only on this slide.
        """

        let provider = UserDefaults.standard.string(forKey: "aiProvider") ?? "replicate"
        if provider == "claude" {
            return try await callClaudeDirectAPI(prompt: prompt, maxTokens: 512)
        }

        let apiKey = UserDefaults.standard.string(forKey: "apiKey") ?? "YOUR_REPLICATE_TOKEN"
        let modelVersion = UserDefaults.standard.string(forKey: "selectedModel") ?? "meta/meta-llama-3.1-70b-instruct:fbfb20b472b2f3bdd101412a9f70a0ed4fc0ced78a77ff00970ee7a2383c575d"

        let createUrl = URL(string: "https://api.replicate.com/v1/predictions")!
        var createRequest = URLRequest(url: createUrl)
        createRequest.httpMethod = "POST"
        createRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        createRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "version": modelVersion,
            "input": [
                "prompt": prompt,
                "max_tokens": 512,
                "temperature": 0.6
            ]
        ]

        createRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: createRequest)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "StudyLLMClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to start prediction"])
        }

        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        guard let urls = json["urls"] as? [String: String],
              let pollUrl = urls["get"] else {
            throw NSError(domain: "StudyLLMClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing poll URL"])
        }

        return try await pollResult(url: pollUrl, apiKey: apiKey)
    }
    
    static func generateConceptQuestions(from slides: [SlideChunk]) async throws -> [String] {
        let joined = slides.map { slide -> String in
            let title = slide.text.split(separator: "\n").first.map(String.init) ?? "Untitled"
            let snippet = String(slide.text.prefix(260))
            return "Slide \(slide.pageIndex + 1) (\(slide.documentName))\nTitle: \(title)\nContent snippet: \(snippet)"
        }.joined(separator: "\n\n")

        let prompt = """
        You are an expert instructor creating conceptual, short-answer questions based on course slides.

        Use ONLY the information in these slides:
        \(joined)

        Generate 15–25 concise, conceptual questions that test deep understanding of the material.
        Style examples: "What is point-to-point?", "Why is congestion control necessary on the Internet?", "How does X differ from Y?"

        Requirements:
        - Focus on key concepts, definitions, tradeoffs, and "why" reasoning.
        - No multiple choice, only short-answer style questions.
        - Do NOT include answers, explanations, or commentary.
        - Output as a numbered list, one question per line.
        """

        let provider = UserDefaults.standard.string(forKey: "aiProvider") ?? "replicate"
        let raw: String
        if provider == "claude" {
            raw = try await callClaudeDirectAPI(prompt: prompt, maxTokens: 600)
        } else {
            let apiKey = UserDefaults.standard.string(forKey: "apiKey") ?? "YOUR_REPLICATE_TOKEN"
            let modelVersion = UserDefaults.standard.string(forKey: "selectedModel") ?? "meta/meta-llama-3.1-70b-instruct:fbfb20b472b2f3bdd101412a9f70a0ed4fc0ced78a77ff00970ee7a2383c575d"

            let createUrl = URL(string: "https://api.replicate.com/v1/predictions")!
            var createRequest = URLRequest(url: createUrl)
            createRequest.httpMethod = "POST"
            createRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            createRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

            let body: [String: Any] = [
                "version": modelVersion,
                "input": [
                    "prompt": prompt,
                    "max_tokens": 600,
                    "temperature": 0.65
                ]
            ]
            createRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: createRequest)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw NSError(domain: "StudyLLMClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to start prediction"])
            }

            let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            guard let urls = json["urls"] as? [String: String],
                  let pollUrl = urls["get"] else {
                throw NSError(domain: "StudyLLMClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing poll URL"])
            }
            raw = try await pollResult(url: pollUrl, apiKey: apiKey)
        }
        // Parse numbered list into individual questions
        let lines = raw
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { line -> String in
                // Strip leading numbering like "1. ", "2) ", "3 - "
                let components = line.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
                if components.count == 2,
                   components[0].trimmingCharacters(in: .punctuationCharacters.union(.letters)).allSatisfy({ $0.isNumber }) {
                    return String(components[1])
                }
                return line
            }
        return lines
    }
    
    private static func callClaudeDirectAPI(prompt: String, maxTokens: Int) async throws -> String {
        let apiKey = UserDefaults.standard.string(forKey: "claudeApiKey") ?? ""
        let model = UserDefaults.standard.string(forKey: "claudeModel") ?? "claude-sonnet-4-6"

        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 60

        let body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "messages": [["role": "user", "content": prompt]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let message = (errorJson?["error"] as? [String: Any])?["message"] as? String ?? "HTTP \(httpResponse.statusCode)"
            throw NSError(domain: "ClaudeAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
        }

        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        guard let content = json["content"] as? [[String: Any]],
              let first = content.first,
              let text = first["text"] as? String else {
            throw NSError(domain: "ClaudeAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
        }
        return text
    }

    private static func pollResult(url: String, apiKey: String) async throws -> String {
        let pollUrl = URL(string: url)!
        var pollRequest = URLRequest(url: pollUrl)
        pollRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        for _ in 0..<60 {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            let (data, _) = try await URLSession.shared.data(for: pollRequest)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let status = json["status"] as? String else {
                continue
            }
            
            if status == "succeeded" {
                if let output = json["output"] as? [String] {
                    return output.joined()
                } else if let output = json["output"] as? String {
                    return output
                }
            } else if status == "failed" || status == "canceled" {
                let error = json["error"] as? String ?? "Unknown error"
                throw NSError(domain: "StudyLLMClient", code: -1, userInfo: [NSLocalizedDescriptionKey: error])
            }
        }
        
        throw NSError(domain: "StudyLLMClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Timeout waiting for result"])
    }
}

