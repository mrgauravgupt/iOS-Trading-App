import SwiftUI

struct CustomPatternCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var patternName = ""
    @State private var patternDescription = ""
    @State private var selectedPatternType: CustomPatternType = .chart
    @State private var confidenceThreshold: Double = 0.7
    @State private var timeframes: Set<Timeframe> = [.fiveMinute, .fifteenMinute]
    @State private var isEnabled = true
    @State private var showSaveAlert = false
    @State private var saveMessage = ""
    
    enum CustomPatternType: String, CaseIterable, Identifiable, Codable {
        case chart = "Chart Pattern"
        case candlestick = "Candlestick Pattern"
        case harmonic = "Harmonic Pattern"
        case volume = "Volume Pattern"
        case custom = "Custom Indicator"

        var id: String { self.rawValue }
    }
    
    // Note: Using shared Timeframe from CoreModels to avoid duplication
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Pattern Basic Info
                    basicInfoSection
                    
                    // Pattern Configuration
                    configurationSection
                    
                    // Timeframe Selection
                    timeframeSection
                    
                    // Pattern Parameters (placeholder for future expansion)
                    parametersSection
                    
                    // Save Button
                    saveButton
                }
                .padding()
            }
            .navigationTitle("Create Custom Pattern")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Pattern Saved", isPresented: $showSaveAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(saveMessage)
            }
        }
    }
    
    // MARK: - Basic Info Section
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                TextField("Pattern Name", text: $patternName)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.words)
                
                TextField("Description (Optional)", text: $patternDescription)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3)
                
                Picker("Pattern Type", selection: $selectedPatternType) {
                    ForEach(CustomPatternType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.menu)
                
                Toggle("Enable Pattern", isOn: $isEnabled)
                    .toggleStyle(.switch)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Configuration Section
    
    private var configurationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Configuration")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confidence Threshold: \(String(format: "%.1f", confidenceThreshold))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Slider(value: $confidenceThreshold, in: 0.1...1.0, step: 0.1)
                        .accentColor(.blue)
                    
                    Text("Minimum confidence level required to trigger this pattern")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Timeframe Section
    
    private var timeframeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Active Timeframes")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Timeframe.allCases, id: \.self) { timeframe in
                    Toggle(timeframe.rawValue, isOn: Binding(
                        get: { timeframes.contains(timeframe) },
                        set: { isSelected in
                            if isSelected {
                                timeframes.insert(timeframe)
                            } else {
                                timeframes.remove(timeframe)
                            }
                        }
                    ))
                    .toggleStyle(CheckboxToggleStyle())
                }
            }
            
            if timeframes.isEmpty {
                Text("Please select at least one timeframe")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Parameters Section
    
    private var parametersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pattern Parameters")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                Text("Advanced parameters will be available based on pattern type.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Placeholder for future parameter controls
                HStack {
                    Image(systemName: "gear")
                        .foregroundColor(.gray)
                    Text("Parameters configuration coming soon")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray5))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        Button(action: saveCustomPattern) {
            Text("Save Custom Pattern")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canSave ? Color.blue : Color.gray)
                .cornerRadius(12)
        }
        .disabled(!canSave)
        .padding(.top, 10)
    }
    
    // MARK: - Computed Properties
    
    private var canSave: Bool {
        !patternName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !timeframes.isEmpty
    }
    
    // MARK: - Actions
    
    private func saveCustomPattern() {
        let customPattern = CustomPattern(
            id: UUID(),
            name: patternName.trimmingCharacters(in: .whitespacesAndNewlines),
            description: patternDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            type: selectedPatternType,
            confidenceThreshold: confidenceThreshold,
            timeframes: Array(timeframes),
            isEnabled: isEnabled,
            createdAt: Date()
        )
        
        // Save to UserDefaults (in a real app, this might be Core Data or a server)
        var savedPatterns = loadSavedPatterns()
        savedPatterns.append(customPattern)
        
        if let encoded = try? JSONEncoder().encode(savedPatterns) {
            UserDefaults.standard.set(encoded, forKey: "customPatterns")
            saveMessage = "Custom pattern '\(patternName)' has been saved successfully!"
            showSaveAlert = true
        } else {
            saveMessage = "Failed to save pattern. Please try again."
            showSaveAlert = true
        }
    }
    
    private func loadSavedPatterns() -> [CustomPattern] {
        if let data = UserDefaults.standard.data(forKey: "customPatterns"),
           let patterns = try? JSONDecoder().decode([CustomPattern].self, from: data) {
            return patterns
        }
        return []
    }
}

// MARK: - Custom Pattern Model

struct CustomPattern: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String
    let type: CustomPatternCreationView.CustomPatternType
    let confidenceThreshold: Double
    let timeframes: [Timeframe]
    let isEnabled: Bool
    let createdAt: Date
}

// MARK: - Checkbox Toggle Style

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? .blue : .gray)
                .onTapGesture {
                    configuration.isOn.toggle()
                }
            
            configuration.label
        }
    }
}

#Preview {
    CustomPatternCreationView()
}
