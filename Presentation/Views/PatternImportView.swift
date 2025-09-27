import SwiftUI

struct PatternImportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var importMethod: ImportMethod = .file
    @State private var fileURL = ""
    @State private var jsonText = ""
    @State private var isImporting = false
    @State private var showImportAlert = false
    @State private var importMessage = ""
    @State private var importedPatterns: [CustomPattern] = []
    @State private var showPatternPreview = false
    
    enum ImportMethod: String, CaseIterable, Identifiable {
        case file = "From File"
        case url = "From URL"
        case paste = "Paste JSON"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Import Method Selection
                    importMethodSection
                    
                    // Import Input
                    importInputSection
                    
                    // Preview Section
                    if !importedPatterns.isEmpty {
                        previewSection
                    }
                    
                    // Import Button
                    importButton
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Import Patterns")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Import Result", isPresented: $showImportAlert) {
                Button("OK") {
                    if importMessage.contains("successfully") {
                        dismiss()
                    }
                }
            } message: {
                Text(importMessage)
            }
            .sheet(isPresented: $showPatternPreview) {
                PatternPreviewView(patterns: importedPatterns)
            }
        }
    }
    
    // MARK: - Import Method Section
    
    private var importMethodSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Import Method")
                .font(.subheadline)
                .fontWeight(.semibold)

            Picker("Method", selection: $importMethod) {
                ForEach(ImportMethod.allCases) { method in
                    Text(method.rawValue).tag(method)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    // MARK: - Import Input Section
    
    private var importInputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Import Source")
                .font(.subheadline)
                .fontWeight(.semibold)

            switch importMethod {
            case .file:
                fileImportSection
            case .url:
                urlImportSection
            case .paste:
                pasteImportSection
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private var fileImportSection: some View {
        VStack(spacing: 12) {
            Text("Select a JSON file containing pattern definitions")
                .font(.caption)
                .foregroundColor(.secondary)

            TextField("File URL or Path", text: $fileURL)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            Button(action: {
                // In a real app, this would open a file picker
                // For now, we'll use a placeholder
                fileURL = "file:///example/patterns.json"
            }) {
                Label("Browse Files", systemImage: "folder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }
    
    private var urlImportSection: some View {
        VStack(spacing: 12) {
            Text("Enter the URL of a JSON file containing patterns")
                .font(.caption)
                .foregroundColor(.secondary)

            TextField("https://example.com/patterns.json", text: $fileURL)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.URL)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
    }
    
    private var pasteImportSection: some View {
        VStack(spacing: 12) {
            Text("Paste JSON array of pattern definitions")
                .font(.caption)
                .foregroundColor(.secondary)

            TextEditor(text: $jsonText)
                .frame(height: 200)
                .border(Color.gray.opacity(0.3), width: 1)
                .cornerRadius(10)

            Button(action: validateAndPreviewJSON) {
                Label("Validate & Preview", systemImage: "eye")
            }
            .buttonStyle(.bordered)
        }
    }
    
    // MARK: - Preview Section
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Preview (\(importedPatterns.count) patterns)")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: { showPatternPreview = true }) {
                    Text("View All")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            VStack(spacing: 8) {
                ForEach(importedPatterns.prefix(3)) { pattern in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(pattern.name)
                                .font(.caption)
                                .fontWeight(.medium)

                            Text(pattern.type.rawValue)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text("Conf: \(String(format: "%.1f", pattern.confidenceThreshold))")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                    .padding(8)
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                }

                if importedPatterns.count > 3 {
                    Text("... and \(importedPatterns.count - 3) more patterns")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    // MARK: - Import Button
    
    private var importButton: some View {
        Button(action: performImport) {
            if isImporting {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                Text("Import Patterns")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(canImport ? Color.green : Color.gray)
                    .cornerRadius(10)
            }
        }
        .disabled(!canImport || isImporting)
        .padding(.top, 10)
    }
    
    // MARK: - Computed Properties
    
    private var canImport: Bool {
        switch importMethod {
        case .file, .url:
            return !fileURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .paste:
            return !jsonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !importedPatterns.isEmpty
        }
    }
    
    // MARK: - Actions
    
    private func validateAndPreviewJSON() {
        guard let data = jsonText.data(using: .utf8) else {
            importMessage = "Invalid JSON format"
            showImportAlert = true
            return
        }
        
        do {
            let patterns = try JSONDecoder().decode([CustomPattern].self, from: data)
            importedPatterns = patterns
            importMessage = "JSON validated successfully. Found \(patterns.count) patterns."
            showImportAlert = true
        } catch {
            importMessage = "JSON validation failed: \(error.localizedDescription)"
            showImportAlert = true
            importedPatterns = []
        }
    }
    
    private func performImport() {
        isImporting = true
        
        // Simulate import process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            var patternsToImport: [CustomPattern] = []
            
            switch importMethod {
            case .file, .url:
                // Simulate loading from file/URL
                patternsToImport = generateSamplePatterns()
            case .paste:
                patternsToImport = importedPatterns
            }
            
            // Save patterns
            var existingPatterns = loadSavedPatterns()
            existingPatterns.append(contentsOf: patternsToImport)
            
            if let encoded = try? JSONEncoder().encode(existingPatterns) {
                UserDefaults.standard.set(encoded, forKey: "customPatterns")
                importMessage = "Successfully imported \(patternsToImport.count) patterns!"
            } else {
                importMessage = "Failed to save imported patterns."
            }
            
            isImporting = false
            showImportAlert = true
        }
    }
    
    private func loadSavedPatterns() -> [CustomPattern] {
        if let data = UserDefaults.standard.data(forKey: "customPatterns"),
           let patterns = try? JSONDecoder().decode([CustomPattern].self, from: data) {
            return patterns
        }
        return []
    }
    
    private func generateSamplePatterns() -> [CustomPattern] {
        // Generate some sample patterns for demo purposes
        return [
            CustomPattern(
                id: UUID(),
                name: "Bullish Engulfing",
                description: "A bullish engulfing pattern indicating potential reversal",
                type: .candlestick,
                confidenceThreshold: 0.75,
                timeframes: [.m5, .m15, .h1],
                isEnabled: true,
                createdAt: Date()
            ),
            CustomPattern(
                id: UUID(),
                name: "Volume Spike",
                description: "Unusual volume activity indicating strong market interest",
                type: .volume,
                confidenceThreshold: 0.8,
                timeframes: [.m1, .m5],
                isEnabled: true,
                createdAt: Date()
            )
        ]
    }
}

// MARK: - Pattern Preview View

struct PatternPreviewView: View {
    let patterns: [CustomPattern]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List(patterns) { pattern in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(pattern.name)
                            .font(.subheadline)

                        Spacer()

                        Text(pattern.type.rawValue)
                            .font(.caption2)
                            .padding(4)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }

                    if !pattern.description.isEmpty {
                        Text(pattern.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Confidence: \(String(format: "%.1f", pattern.confidenceThreshold))")
                        Spacer()
                        Text("Timeframes: \(pattern.timeframes.map { $0.rawValue }.joined(separator: ", "))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Text("Created: \(pattern.createdAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Pattern Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Pattern Preview")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PatternImportView()
}
