import SwiftUI
import SharedCoreModels

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
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Create Custom Pattern")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
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
                .font(.subheadline)
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
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    // MARK: - Configuration Section
    
    private var configurationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Configuration")
                .font(.subheadline)
                .fontWeight(.semibold)

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confidence Threshold: \(String(format: "%.1f", confidenceThreshold))")
                        .font(.caption)
                        .fontWeight(.medium)

                    Slider(value: $confidenceThreshold, in: 0.1...1.0, step: 0.1)
                        .accentColor(.blue)

                    Text("Minimum confidence level required to trigger this pattern")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    // MARK: - Timeframe Section
    
    private var timeframeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Active Timeframes")
                .font(.subheadline)
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
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    // MARK: - Parameters Section
    
    private var parametersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pattern Parameters")
                .font(.subheadline)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                Text("Advanced parameters will be available based on pattern type.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Placeholder for future parameter controls
                HStack {
                    Image(systemName: "gear")
                        .foregroundColor(.gray)
                    Text("Parameters configuration coming soon")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray5))
                .cornerRadius(10)
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        Button(action: saveCustomPattern) {
            Text("Save Custom Pattern")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(canSave ? Color.blue : Color.gray)
                .cornerRadius(10)
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

public struct CustomPattern: Codable, Identifiable {
    public let id: UUID
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
