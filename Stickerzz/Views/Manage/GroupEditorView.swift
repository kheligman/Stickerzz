import SwiftUI
import SwiftData

struct GroupEditorView: View {
    var existing: HabitGroup? = nil

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \HabitGroup.sortOrder) private var groups: [HabitGroup]

    @State private var name: String = ""
    @State private var selectedHex: String = HabitGroup.paletteHexes[0]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Morning Routine", text: $name)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(HabitGroup.paletteHexes, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex) ?? .gray)
                                .frame(height: 40)
                                .overlay(
                                    Circle().stroke(
                                        selectedHex == hex ? Color.primary : .clear,
                                        lineWidth: 3
                                    )
                                )
                                .onTapGesture { selectedHex = hex }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(existing == nil ? "New Routine" : "Edit Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let g = existing {
                    name = g.name
                    selectedHex = g.colorHex
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let g = existing {
            g.name = trimmed
            g.colorHex = selectedHex
        } else {
            let g = HabitGroup(name: trimmed, colorHex: selectedHex, sortOrder: groups.count)
            context.insert(g)
        }
        dismiss()
    }
}
