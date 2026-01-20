import SwiftUI

// MARK: - QuickPlaySetupView

/// Difficulty selection screen for Quick Play mode
struct QuickPlaySetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @State private var selectedPreset: Int = 4 // Default to Level 5
    @State private var isCustomMode: Bool = false
    @State private var hiddenMode: Bool = false

    // Custom settings
    @State private var additionEnabled: Bool = true
    @State private var subtractionEnabled: Bool = true
    @State private var multiplicationEnabled: Bool = false
    @State private var divisionEnabled: Bool = false
    @State private var addSubRange: Double = 20
    @State private var multDivRange: Double = 5
    @State private var gridRows: Int = 4
    @State private var gridCols: Int = 5

    /// Callback when starting the game
    var onStart: (DifficultySettings) -> Void

    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    private var currentPreset: DifficultySettings {
        DifficultyPresets.byLevel(selectedPreset + 1)
    }

    private var hasValidOperations: Bool {
        if isCustomMode {
            return additionEnabled || subtractionEnabled ||
                   multiplicationEnabled || divisionEnabled
        }
        return true
    }

    private var finalDifficulty: DifficultySettings {
        if isCustomMode {
            return createCustomDifficulty()
        } else {
            var preset = currentPreset
            preset.hiddenMode = hiddenMode
            return preset
        }
    }

    var body: some View {
        ZStack {
            // Background
            StarryBackground()

            if isLandscape {
                landscapeLayout
            } else {
                portraitLayout
            }
        }
        .navigationTitle("Quick Play")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                }
            }
        }
    }

    // MARK: - Portrait Layout

    private var portraitLayout: some View {
        ScrollView {
            VStack(spacing: 24) {
                difficultySelectionCard
                customSettingsCard
                hiddenModeCard
                startButton
            }
            .padding()
        }
    }

    // MARK: - Landscape Layout

    private var landscapeLayout: some View {
        HStack(alignment: .top, spacing: 16) {
            // Left column: Difficulty selection
            VStack(spacing: 12) {
                compactDifficultyCard
                Spacer()
            }
            .frame(maxWidth: .infinity)

            // Middle column: Options + Start
            VStack(spacing: 12) {
                compactHiddenModeCard
                compactCustomToggle
                Spacer()
                startButton
            }
            .frame(maxWidth: .infinity)

            // Right column: Custom settings (if enabled)
            if isCustomMode {
                VStack(spacing: 8) {
                    compactCustomSettingsCard
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Compact Cards for Landscape

    private var compactDifficultyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Difficulty")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            Menu {
                ForEach(0..<10, id: \.self) { index in
                    Button(action: { selectedPreset = index }) {
                        let preset = DifficultyPresets.byLevel(index + 1)
                        Text("Level \(index + 1): \(preset.name)")
                    }
                }
            } label: {
                HStack {
                    Text("Level \(selectedPreset + 1)")
                        .foregroundColor(isCustomMode ? AppTheme.textSecondary : .white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(isCustomMode ? AppTheme.textSecondary : .white)
                }
                .padding(10)
                .background(AppTheme.backgroundDark)
                .cornerRadius(8)
            }
            .disabled(isCustomMode)

            Text(currentPreset.name)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(12)
        .background(AppTheme.backgroundMid.opacity(0.8))
        .cornerRadius(10)
    }

    private var compactHiddenModeCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Hidden Mode")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                Text("Mistakes revealed at end")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
            Toggle("", isOn: $hiddenMode)
                .toggleStyle(SwitchToggleStyle(tint: AppTheme.accentPrimary))
                .labelsHidden()
        }
        .padding(12)
        .background(AppTheme.backgroundMid.opacity(0.8))
        .cornerRadius(10)
    }

    private var compactCustomToggle: some View {
        HStack {
            Text("Custom Settings")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            Spacer()
            Toggle("", isOn: $isCustomMode)
                .toggleStyle(SwitchToggleStyle(tint: AppTheme.accentPrimary))
                .labelsHidden()
        }
        .padding(12)
        .background(AppTheme.backgroundMid.opacity(0.8))
        .cornerRadius(10)
    }

    private var compactCustomSettingsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Operations row
            VStack(alignment: .leading, spacing: 4) {
                Text("Operations")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                HStack(spacing: 6) {
                    compactOpToggle("+", isOn: $additionEnabled)
                    compactOpToggle("−", isOn: $subtractionEnabled)
                    compactOpToggle("×", isOn: $multiplicationEnabled)
                    compactOpToggle("÷", isOn: $divisionEnabled)
                }
            }

            // Number range
            VStack(alignment: .leading, spacing: 2) {
                Text("+/− Range: \(Int(addSubRange))")
                    .font(.system(size: 11))
                    .foregroundColor(.white)
                Slider(value: $addSubRange, in: 5...100, step: 5)
                    .tint(AppTheme.accentPrimary)
            }

            // Grid size
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rows")
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                    HStack(spacing: 3) {
                        ForEach([3, 4, 5, 6], id: \.self) { n in
                            compactSizeButton(n, selected: gridRows == n) { gridRows = n }
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cols")
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                    HStack(spacing: 3) {
                        ForEach([4, 5, 6, 7], id: \.self) { n in
                            compactSizeButton(n, selected: gridCols == n) { gridCols = n }
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(AppTheme.backgroundMid.opacity(0.8))
        .cornerRadius(10)
    }

    private func compactOpToggle(_ symbol: String, isOn: Binding<Bool>) -> some View {
        Button(action: { isOn.wrappedValue.toggle() }) {
            Text(symbol)
                .font(.system(size: 16, weight: .bold))
                .frame(width: 36, height: 36)
                .background(isOn.wrappedValue ? AppTheme.accentPrimary : AppTheme.backgroundDark)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }

    private func compactSizeButton(_ value: Int, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("\(value)")
                .font(.system(size: 12, weight: .medium))
                .frame(width: 28, height: 28)
                .background(selected ? AppTheme.accentPrimary : AppTheme.backgroundDark)
                .foregroundColor(.white)
                .cornerRadius(6)
        }
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button(action: { onStart(finalDifficulty) }) {
            Text("Start Puzzle")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    hasValidOperations
                        ? AppTheme.accentPrimary
                        : Color.gray.opacity(0.5)
                )
                .cornerRadius(12)
        }
        .disabled(!hasValidOperations)
    }

    // MARK: - Subviews

    private var difficultySelectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Difficulty")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            // Difficulty Picker
            Menu {
                ForEach(0..<10, id: \.self) { index in
                    Button(action: { selectedPreset = index }) {
                        let preset = DifficultyPresets.byLevel(index + 1)
                        Text("Level \(index + 1): \(preset.name)")
                    }
                }
            } label: {
                HStack {
                    Text("Level \(selectedPreset + 1): \(currentPreset.name)")
                        .foregroundColor(isCustomMode ? AppTheme.textSecondary : .white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(isCustomMode ? AppTheme.textSecondary : .white)
                }
                .padding()
                .background(AppTheme.backgroundDark)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }
            .disabled(isCustomMode)

            // Description
            Text(getPresetDescription(currentPreset))
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding()
        .background(AppTheme.backgroundMid.opacity(0.8))
        .cornerRadius(12)
    }

    private var customSettingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Customise Settings", isOn: $isCustomMode)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .toggleStyle(SwitchToggleStyle(tint: AppTheme.accentPrimary))

            if isCustomMode {
                VStack(spacing: 20) {
                    // Operations
                    operationsSection

                    // Add/Sub Range
                    VStack(alignment: .leading, spacing: 8) {
                        Text("+/− Number Range: \(Int(addSubRange))")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                        Slider(value: $addSubRange, in: 5...100, step: 5)
                            .tint(AppTheme.accentPrimary)
                    }

                    // Mult/Div Range (if enabled)
                    if multiplicationEnabled || divisionEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("×/÷ Number Range: \(Int(multDivRange))")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                            Slider(value: $multDivRange, in: 2...12, step: 1)
                                .tint(AppTheme.accentPrimary)
                        }
                    }

                    // Grid Size
                    gridSizeSection
                }
            }
        }
        .padding()
        .background(AppTheme.backgroundMid.opacity(0.8))
        .cornerRadius(12)
    }

    private var operationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Operations")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)

            HStack(spacing: 12) {
                operationToggle("+", isOn: $additionEnabled)
                operationToggle("−", isOn: $subtractionEnabled)
                operationToggle("×", isOn: $multiplicationEnabled)
                operationToggle("÷", isOn: $divisionEnabled)
            }

            if !hasValidOperations {
                Text("At least one operation must be enabled")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.error)
            }
        }
    }

    private func operationToggle(_ symbol: String, isOn: Binding<Bool>) -> some View {
        Button(action: { isOn.wrappedValue.toggle() }) {
            Text(symbol)
                .font(.system(size: 20, weight: .bold))
                .frame(width: 48, height: 48)
                .background(isOn.wrappedValue ? AppTheme.accentPrimary : AppTheme.backgroundDark)
                .foregroundColor(.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isOn.wrappedValue ? AppTheme.accentPrimary : Color.white.opacity(0.2), lineWidth: 1)
                )
        }
    }

    private var gridSizeSection: some View {
        HStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Rows")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                HStack(spacing: 4) {
                    ForEach([3, 4, 5, 6], id: \.self) { n in
                        gridSizeButton(n, selected: gridRows == n) {
                            gridRows = n
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Columns")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                HStack(spacing: 4) {
                    ForEach([4, 5, 6, 7, 8], id: \.self) { n in
                        gridSizeButton(n, selected: gridCols == n) {
                            gridCols = n
                        }
                    }
                }
            }
        }
    }

    private func gridSizeButton(_ value: Int, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("\(value)")
                .font(.system(size: 14, weight: .medium))
                .frame(width: 36, height: 36)
                .background(selected ? AppTheme.accentPrimary : AppTheme.backgroundDark)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }

    private var hiddenModeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Hidden Mode", isOn: $hiddenMode)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .toggleStyle(SwitchToggleStyle(tint: AppTheme.accentPrimary))

            Text("Mistakes aren't revealed until the end. No lives - always reach FINISH.")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding()
        .background(AppTheme.backgroundMid.opacity(0.8))
        .cornerRadius(12)
    }

    // MARK: - Helpers

    private func getPresetDescription(_ preset: DifficultySettings) -> String {
        var ops: [String] = []
        if preset.additionEnabled { ops.append("addition") }
        if preset.subtractionEnabled { ops.append("subtraction") }
        if preset.multiplicationEnabled { ops.append("multiplication") }
        if preset.divisionEnabled { ops.append("division") }

        let opsStr: String
        if ops.count == 1 {
            opsStr = ops[0]
        } else {
            opsStr = ops.dropLast().joined(separator: ", ") + " & " + (ops.last ?? "")
        }

        return "\(opsStr.capitalized), numbers up to \(preset.addSubRange), \(preset.gridRows)×\(preset.gridCols) grid"
    }

    private func createCustomDifficulty() -> DifficultySettings {
        let rows = gridRows
        let cols = gridCols

        return DifficultySettings(
            name: "Custom",
            additionEnabled: additionEnabled,
            subtractionEnabled: subtractionEnabled,
            multiplicationEnabled: multiplicationEnabled,
            divisionEnabled: divisionEnabled,
            addSubRange: Int(addSubRange),
            multDivRange: Int(multDivRange),
            connectorMin: 5,
            connectorMax: max(Int(addSubRange), multiplicationEnabled || divisionEnabled ? Int(multDivRange) * Int(multDivRange) : Int(addSubRange)),
            gridRows: rows,
            gridCols: cols,
            minPathLength: DifficultyPresets.calculateMinPathLength(rows: rows, cols: cols),
            maxPathLength: DifficultyPresets.calculateMaxPathLength(rows: rows, cols: cols),
            weights: OperationWeights(
                addition: additionEnabled ? 30 : 0,
                subtraction: subtractionEnabled ? 30 : 0,
                multiplication: multiplicationEnabled ? 25 : 0,
                division: divisionEnabled ? 15 : 0
            ),
            hiddenMode: hiddenMode,
            secondsPerStep: 7
        )
    }
}

// MARK: - Preview

#Preview("Quick Play Setup") {
    NavigationStack {
        QuickPlaySetupView { settings in
            print("Starting with: \(settings.name)")
        }
    }
}
