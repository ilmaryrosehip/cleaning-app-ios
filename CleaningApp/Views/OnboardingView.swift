import SwiftUI
import SwiftData

// MARK: - FloorPlanPreset

struct FloorPlanPreset: Identifiable {
    let id: String
    let name: String
    let description: String
    let slots: [RoomSlot]
}

struct RoomSlot: Identifiable {
    let id: String
    let defaultName: String
    let defaultIcon: String
    let isRequired: Bool
}

extension FloorPlanPreset {
    static let presets: [FloorPlanPreset] = [
        FloorPlanPreset(id: "1r", name: "1R / 1K", description: "一人暮らし向けのシンプルな間取り", slots: [
            RoomSlot(id: "living",   defaultName: "リビング・寝室", defaultIcon: "sofa",                isRequired: true),
            RoomSlot(id: "kitchen",  defaultName: "キッチン",       defaultIcon: "fork.knife",          isRequired: true),
            RoomSlot(id: "bath",     defaultName: "バスルーム",     defaultIcon: "shower",              isRequired: true),
            RoomSlot(id: "toilet",   defaultName: "トイレ",         defaultIcon: "toilet",              isRequired: true),
            RoomSlot(id: "entrance", defaultName: "玄関",           defaultIcon: "door.left.hand.open", isRequired: false),
        ]),
        FloorPlanPreset(id: "1ldk", name: "1LDK", description: "一人暮らし〜カップル向け", slots: [
            RoomSlot(id: "living",   defaultName: "リビング",   defaultIcon: "sofa",                isRequired: true),
            RoomSlot(id: "bedroom",  defaultName: "寝室",       defaultIcon: "bed.double",          isRequired: true),
            RoomSlot(id: "kitchen",  defaultName: "キッチン",   defaultIcon: "fork.knife",          isRequired: true),
            RoomSlot(id: "bath",     defaultName: "バスルーム", defaultIcon: "shower",              isRequired: true),
            RoomSlot(id: "toilet",   defaultName: "トイレ",     defaultIcon: "toilet",              isRequired: true),
            RoomSlot(id: "entrance", defaultName: "玄関",       defaultIcon: "door.left.hand.open", isRequired: false),
        ]),
        FloorPlanPreset(id: "2ldk", name: "2LDK", description: "ファミリー・シェアハウス向け", slots: [
            RoomSlot(id: "living",   defaultName: "リビング",   defaultIcon: "sofa",                isRequired: true),
            RoomSlot(id: "bedroom1", defaultName: "寝室1",      defaultIcon: "bed.double",          isRequired: true),
            RoomSlot(id: "bedroom2", defaultName: "寝室2",      defaultIcon: "bed.double",          isRequired: true),
            RoomSlot(id: "kitchen",  defaultName: "キッチン",   defaultIcon: "fork.knife",          isRequired: true),
            RoomSlot(id: "bath",     defaultName: "バスルーム", defaultIcon: "shower",              isRequired: true),
            RoomSlot(id: "toilet",   defaultName: "トイレ",     defaultIcon: "toilet",              isRequired: true),
            RoomSlot(id: "entrance", defaultName: "玄関",       defaultIcon: "door.left.hand.open", isRequired: false),
            RoomSlot(id: "storage",  defaultName: "収納",       defaultIcon: "archivebox",          isRequired: false),
        ]),
        FloorPlanPreset(id: "3ldk", name: "3LDK以上", description: "大家族・広めの住まい向け", slots: [
            RoomSlot(id: "living",   defaultName: "リビング",   defaultIcon: "sofa",                isRequired: true),
            RoomSlot(id: "dining",   defaultName: "ダイニング", defaultIcon: "fork.knife",          isRequired: true),
            RoomSlot(id: "bedroom1", defaultName: "寝室1",      defaultIcon: "bed.double",          isRequired: true),
            RoomSlot(id: "bedroom2", defaultName: "寝室2",      defaultIcon: "bed.double",          isRequired: true),
            RoomSlot(id: "bedroom3", defaultName: "寝室3",      defaultIcon: "bed.double",          isRequired: false),
            RoomSlot(id: "kitchen",  defaultName: "キッチン",   defaultIcon: "fork.knife",          isRequired: true),
            RoomSlot(id: "bath",     defaultName: "バスルーム", defaultIcon: "shower",              isRequired: true),
            RoomSlot(id: "toilet",   defaultName: "トイレ",     defaultIcon: "toilet",              isRequired: true),
            RoomSlot(id: "entrance", defaultName: "玄関",       defaultIcon: "door.left.hand.open", isRequired: false),
            RoomSlot(id: "study",    defaultName: "書斎",       defaultIcon: "books.vertical",      isRequired: false),
        ]),
        FloorPlanPreset(id: "custom", name: "カスタム", description: "自分で部屋をゼロから設定する", slots: []),
    ]
}

// MARK: - OnboardingView

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @State private var step = 0
    @State private var homeName = ""
    @State private var selectedPreset: FloorPlanPreset? = nil
    @State private var slotNames:   [String: String] = [:]
    @State private var slotIcons:   [String: String] = [:]
    @State private var slotEnabled: [String: Bool]   = [:]

    var body: some View {
        NavigationStack {
            Group {
                if step == 0 {
                    StepHomeNameView(homeName: $homeName) { step = 1 }
                } else if step == 1 {
                    StepFloorPlanView(selectedPreset: $selectedPreset,
                                      onNext: { initSlots(); step = 2 },
                                      onBack: { step = 0 })
                } else {
                    StepRoomAssignView(
                        preset: selectedPreset ?? FloorPlanPreset.presets[0],
                        slotNames: $slotNames, slotIcons: $slotIcons, slotEnabled: $slotEnabled,
                        onDone: saveHome, onBack: { step = 1 }
                    )
                }
            }
            .animation(.easeInOut(duration: 0.2), value: step)
        }
    }

    private func initSlots() {
        guard let preset = selectedPreset else { return }
        slotNames   = Dictionary(uniqueKeysWithValues: preset.slots.map { ($0.id, $0.defaultName) })
        slotIcons   = Dictionary(uniqueKeysWithValues: preset.slots.map { ($0.id, $0.defaultIcon) })
        slotEnabled = Dictionary(uniqueKeysWithValues: preset.slots.map { ($0.id, $0.isRequired) })
    }

    private func saveHome() {
        let home = Home(name: homeName.isEmpty ? "我が家" : homeName)
        context.insert(home)
        guard let preset = selectedPreset else { try? context.save(); return }
        for (sortOrder, slot) in preset.slots.enumerated() {
            guard slotEnabled[slot.id] == true else { continue }
            let room = Room(
                name: slotNames[slot.id] ?? slot.defaultName,
                icon: slotIcons[slot.id] ?? slot.defaultIcon,
                sortOrder: sortOrder
            )
            room.home = home
            context.insert(room)
        }
        try? context.save()
    }
}

private struct StepHomeNameView: View {
    @Binding var homeName: String
    let onNext: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader(icon: "house.fill", title: "お家を設定しましょう", subtitle: "まずはお家の名前を入力してください")
            Form { Section("家の名前") { TextField("例: 我が家", text: $homeName) } }
            Spacer()
            OnboardingNextButton(label: "次へ：間取りを選ぶ", action: onNext)
                .padding(.horizontal, 24).padding(.bottom, 32)
        }
        .navigationBarBackButtonHidden()
    }
}

private struct StepFloorPlanView: View {
    @Binding var selectedPreset: FloorPlanPreset?
    let onNext: () -> Void
    let onBack: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader(icon: "square.split.2x2", title: "間取りを選んでください", subtitle: "近い間取りを選ぶと部屋が自動で設定されます")
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(FloorPlanPreset.presets) { preset in
                        Button {
                            selectedPreset = preset
                        } label: {
                            HStack(spacing: 14) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(preset.name).font(.headline).foregroundStyle(selectedPreset?.id == preset.id ? .teal : .primary)
                                    Text(preset.description).font(.subheadline).foregroundStyle(.secondary)
                                    if !preset.slots.isEmpty {
                                        Text(preset.slots.filter { $0.isRequired }.map { $0.defaultName }.joined(separator: "・"))
                                            .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                    }
                                }
                                Spacer()
                                if selectedPreset?.id == preset.id {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.teal).font(.title3)
                                }
                            }
                            .padding(16)
                            .background(selectedPreset?.id == preset.id ? Color.teal.opacity(0.08) : Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(selectedPreset?.id == preset.id ? Color.teal : Color(.systemGray4),
                                        lineWidth: selectedPreset?.id == preset.id ? 1.5 : 0.5))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20).padding(.vertical, 12)
            }
            OnboardingNextButton(label: "次へ：部屋を設定する", action: onNext)
                .disabled(selectedPreset == nil)
                .padding(.horizontal, 24).padding(.bottom, 32)
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { onBack() } label: { Label("戻る", systemImage: "chevron.left") }
            }
        }
    }
}

private struct StepRoomAssignView: View {
    let preset: FloorPlanPreset
    @Binding var slotNames:   [String: String]
    @Binding var slotIcons:   [String: String]
    @Binding var slotEnabled: [String: Bool]
    let onDone: () -> Void
    let onBack: () -> Void
    @State private var editingSlot: RoomSlot? = nil

    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader(icon: "pencil.and.list.clipboard",
                             title: "部屋を設定してください",
                             subtitle: "タップして名前・アイコンを変更できます")
            List {
                let required = preset.slots.filter { $0.isRequired }
                let optional = preset.slots.filter { !$0.isRequired }
                if !required.isEmpty {
                    Section("必須の部屋") {
                        ForEach(required) { slot in
                            RoomSlotRow(name: slotNames[slot.id] ?? slot.defaultName,
                                        icon: slotIcons[slot.id] ?? slot.defaultIcon,
                                        isEnabled: true, canToggle: false) { editingSlot = slot }
                        }
                    }
                }
                if !optional.isEmpty {
                    Section("オプションの部屋") {
                        ForEach(optional) { slot in
                            RoomSlotRow(name: slotNames[slot.id] ?? slot.defaultName,
                                        icon: slotIcons[slot.id] ?? slot.defaultIcon,
                                        isEnabled: slotEnabled[slot.id] ?? false,
                                        canToggle: true,
                                        onToggle: { slotEnabled[slot.id] = $0 }) { editingSlot = slot }
                        }
                    }
                }
                Section {
                    Color.clear.frame(height: 72)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.insetGrouped)
            .overlay(alignment: .bottom) {
                OnboardingNextButton(label: "はじめる", action: onDone)
                    .padding(.horizontal, 24).padding(.bottom, 32)
                    .background(LinearGradient(
                        colors: [Color(.systemGroupedBackground).opacity(0), Color(.systemGroupedBackground)],
                        startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.4)
                    ))
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { onBack() } label: { Label("戻る", systemImage: "chevron.left") }
            }
        }
        .sheet(item: $editingSlot) { slot in
            RoomEditSheet(
                name: Binding(get: { slotNames[slot.id] ?? slot.defaultName }, set: { slotNames[slot.id] = $0 }),
                icon: Binding(get: { slotIcons[slot.id] ?? slot.defaultIcon }, set: { slotIcons[slot.id] = $0 }),
                title: slotNames[slot.id] ?? slot.defaultName
            )
        }
    }
}

private struct RoomSlotRow: View {
    let name: String; let icon: String; let isEnabled: Bool; let canToggle: Bool
    var onToggle: ((Bool) -> Void)? = nil
    let onEdit: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.title3)
                .foregroundStyle(isEnabled ? .teal : .secondary).frame(width: 28)
            Text(name).font(.subheadline).fontWeight(.medium)
                .foregroundStyle(isEnabled ? .primary : .secondary)
            Spacer()
            if canToggle {
                Toggle("", isOn: Binding(get: { isEnabled }, set: { onToggle?($0) }))
                    .labelsHidden().tint(.teal)
            }
            if isEnabled {
                Button { onEdit() } label: {
                    Image(systemName: "pencil").font(.caption).foregroundStyle(.secondary)
                }.buttonStyle(.plain)
            }
        }
    }
}

struct RoomEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var name: String; @Binding var icon: String; let title: String
    private let iconOptions = [
        "sofa","fork.knife","bed.double","shower","door.left.hand.open","toilet",
        "books.vertical","drop","washer","refrigerator","stove","window.horizontal",
        "archivebox","figure.walk","tv","music.note",
    ]
    var body: some View {
        NavigationStack {
            Form {
                Section("部屋名") { TextField("部屋名", text: $name) }
                Section("アイコン") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(iconOptions, id: \.self) { n in
                            Button { icon = n } label: {
                                Image(systemName: n).font(.title3).frame(width: 40, height: 40)
                                    .background(icon == n ? Color.teal.opacity(0.15) : Color(.systemGray6))
                                    .foregroundStyle(icon == n ? .teal : .secondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }.buttonStyle(.plain)
                        }
                    }.padding(.vertical, 4)
                }
            }
            .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct OnboardingHeader: View {
    let icon: String; let title: String; let subtitle: String
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 44)).foregroundStyle(.teal).padding(.top, 40)
            Text(title).font(.title2).fontWeight(.semibold)
            Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
        }.padding(.bottom, 8)
    }
}

struct OnboardingNextButton: View {
    let label: String; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label).fontWeight(.semibold).frame(maxWidth: .infinity)
                .padding(.vertical, 14).background(.teal).foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}
