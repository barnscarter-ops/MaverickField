import SwiftUI
import EventKit

struct FieldToolsView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var selectedTool: FieldTool? = nil

    enum FieldTool: String, CaseIterable, Identifiable {
        case breaker = "Breaker Counter"
        case receptacle = "Receptacle Tracker"
        case fixture = "Fixture Counter"
        case gfci = "GFCI Troubleshooter"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .breaker:    return "bolt.circle.fill"
            case .receptacle: return "powerplug.fill"
            case .fixture:    return "lightbulb.fill"
            case .gfci:       return "exclamationmark.triangle.fill"
            }
        }
        var color: Color {
            switch self {
            case .breaker:    return .yellow
            case .receptacle: return .cyan
            case .fixture:    return Color(hex: "#d9a441")
            case .gfci:       return .red
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0a0d14").ignoresSafeArea()
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(FieldTool.allCases) { tool in
                            ToolCard(tool: tool) { selectedTool = tool }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Field Tools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "#0e1320"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $selectedTool) { tool in
                toolSheet(for: tool)
            }
        }
    }

    @ViewBuilder
    private func toolSheet(for tool: FieldTool) -> some View {
        switch tool {
        case .breaker:    BreakerCounterView()
        case .receptacle: ReceptacleTrackerView()
        case .fixture:    FixtureCounterView()
        case .gfci:       GFCITroubleshooterView()
        }
    }
}

struct ToolCard: View {
    let tool: FieldToolsView.FieldTool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 14) {
                Image(systemName: tool.icon)
                    .font(.system(size: 36))
                    .foregroundColor(tool.color)
                Text(tool.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "#e8ebf2"))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color(hex: "#0e1320"))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(tool.color.opacity(0.25), lineWidth: 1))
        }
    }
}

// MARK: - Breaker Counter

struct BreakerCounterView: View {
    @State private var items: [CounterItem] = [
        CounterItem(name:"20A Single Pole", count: 0),
        CounterItem(name:"15A Single Pole", count: 0),
        CounterItem(name:"30A Double Pole", count: 0),
        CounterItem(name:"40A Double Pole", count: 0),
        CounterItem(name:"50A Double Pole", count: 0),
        CounterItem(name:"AFCI Breaker", count: 0),
        CounterItem(name:"GFCI Breaker", count: 0),
        CounterItem(name:"Tandem Breaker", count: 0),
    ]
    @State private var shareText = ""
    @State private var showShare = false
    @Environment(\.dismiss) private var dismiss

    var total: Int { items.reduce(0) { $0 + $1.count } }

    var body: some View {
        sheetContainer(title: "Breaker Counter", icon: "bolt.circle.fill", color: .yellow) {
            counterList
        } footer: {
            HStack {
                Text("Total: \(total) breakers")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color(hex: "#8b93a7"))
                Spacer()
                Button("Reset") { items = items.map { CounterItem(name:$0.name, count: 0) } }
                    .foregroundColor(.red)
                    .font(.system(size: 13))
                shareButton
            }
        }
    }

    private var counterList: some View {
        ForEach($items) { $item in
            CounterRow(item: $item)
        }
    }

    private var shareButton: some View {
        Button {
            shareText = "Breaker Count\n" + items.filter { $0.count > 0 }
                .map { "  \($0.name): \($0.count)" }.joined(separator: "\n")
                + "\n  Total: \(total)"
            showShare = true
        } label: {
            Image(systemName: "square.and.arrow.up")
                .foregroundColor(Color(hex: "#d9a441"))
        }
        .sheet(isPresented: $showShare) {
            ShareSheet(items: [shareText])
        }
    }
}

// MARK: - Receptacle Tracker

struct ReceptacleTrackerView: View {
    @State private var items: [CounterItem] = [
        CounterItem(name:"Standard Duplex", count: 0),
        CounterItem(name:"GFCI Receptacle", count: 0),
        CounterItem(name:"USB Receptacle", count: 0),
        CounterItem(name:"20A Receptacle", count: 0),
        CounterItem(name:"Decora Switch", count: 0),
        CounterItem(name:"3-Way Switch", count: 0),
        CounterItem(name:"Dimmer Switch", count: 0),
        CounterItem(name:"Outlet (220V)", count: 0),
    ]
    @State private var shareText = ""
    @State private var showShare = false

    var total: Int { items.reduce(0) { $0 + $1.count } }

    var body: some View {
        sheetContainer(title: "Receptacle Tracker", icon: "powerplug.fill", color: .cyan) {
            ForEach($items) { $item in CounterRow(item: $item) }
        } footer: {
            HStack {
                Text("Total: \(total) devices")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color(hex: "#8b93a7"))
                Spacer()
                Button("Reset") { items = items.map { CounterItem(name:$0.name, count: 0) } }
                    .foregroundColor(.red).font(.system(size: 13))
                Button {
                    shareText = "Receptacle/Device Count\n" + items.filter { $0.count > 0 }
                        .map { "  \($0.name): \($0.count)" }.joined(separator: "\n")
                    showShare = true
                } label: { Image(systemName: "square.and.arrow.up").foregroundColor(Color(hex: "#d9a441")) }
                .sheet(isPresented: $showShare) { ShareSheet(items: [shareText]) }
            }
        }
    }
}

// MARK: - Fixture Counter

struct FixtureCounterView: View {
    @State private var items: [CounterItem] = [
        CounterItem(name:"Can/Recessed Light", count: 0),
        CounterItem(name:"LED Wafer Light", count: 0),
        CounterItem(name:"Ceiling Fan", count: 0),
        CounterItem(name:"Pendant Light", count: 0),
        CounterItem(name:"Vanity Bar", count: 0),
        CounterItem(name:"Exterior Fixture", count: 0),
        CounterItem(name:"Under-Cabinet Light", count: 0),
        CounterItem(name:"Exit/Emergency", count: 0),
    ]
    @State private var showShare = false
    @State private var shareText = ""

    var total: Int { items.reduce(0) { $0 + $1.count } }

    var body: some View {
        sheetContainer(title: "Fixture Counter", icon: "lightbulb.fill", color: Color(hex: "#d9a441")) {
            ForEach($items) { $item in CounterRow(item: $item) }
        } footer: {
            HStack {
                Text("Total: \(total) fixtures")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color(hex: "#8b93a7"))
                Spacer()
                Button("Reset") { items = items.map { CounterItem(name:$0.name, count: 0) } }
                    .foregroundColor(.red).font(.system(size: 13))
                Button {
                    shareText = "Fixture Count\n" + items.filter { $0.count > 0 }
                        .map { "  \($0.name): \($0.count)" }.joined(separator: "\n")
                    showShare = true
                } label: { Image(systemName: "square.and.arrow.up").foregroundColor(Color(hex: "#d9a441")) }
                .sheet(isPresented: $showShare) { ShareSheet(items: [shareText]) }
            }
        }
    }
}

// MARK: - GFCI Troubleshooter

struct GFCITroubleshooterView: View {
    @State private var step = 0
    @Environment(\.dismiss) private var dismiss

    private let steps: [(question: String, tip: String, choices: [String])] = [
        (
            question: "Where is the GFCI tripped?",
            tip: "GFCI protection can be fed from another GFCI or breaker, not always local.",
            choices: ["Won't reset / TEST-RESET failed", "Outlet works but no power downstream", "Breaker trips when I reset GFCI"]
        ),
        (
            question: "Is the TEST/RESET button loose or sunken?",
            tip: "A sunken button often means an internal fault — the device needs replacement.",
            choices: ["Button is flush, won't reset", "Button is sunken/broken", "Button pops out on TEST but won't stay on RESET"]
        ),
        (
            question: "Is moisture or water present?",
            tip: "Even residual moisture can hold a GFCI in trip state. Dry the box thoroughly.",
            choices: ["Yes — wet box or fixture", "No — dry location", "Recently worked on / wires disturbed"]
        ),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0a0d14").ignoresSafeArea()
                VStack(spacing: 0) {
                    // Progress
                    HStack(spacing: 6) {
                        ForEach(0..<steps.count, id: \.self) { i in
                            Capsule()
                                .fill(i <= step ? Color.red : Color(hex: "#252d40"))
                                .frame(height: 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            if step < steps.count {
                                let s = steps[step]
                                Text("Step \(step + 1) of \(steps.count)")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(.red)

                                Text(s.question)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color(hex: "#e8ebf2"))

                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(Color(hex: "#d9a441"))
                                        .font(.system(size: 12))
                                    Text(s.tip)
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "#8b93a7"))
                                }
                                .padding(12)
                                .background(Color(hex: "#1c2436"))
                                .cornerRadius(10)

                                VStack(spacing: 10) {
                                    ForEach(s.choices, id: \.self) { choice in
                                        Button {
                                            if step < steps.count - 1 { step += 1 }
                                        } label: {
                                            HStack {
                                                Text(choice)
                                                    .font(.system(size: 14))
                                                    .foregroundColor(Color(hex: "#e8ebf2"))
                                                    .multilineTextAlignment(.leading)
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(Color(hex: "#5a6275"))
                                            }
                                            .padding(14)
                                            .background(Color(hex: "#0e1320"))
                                            .cornerRadius(12)
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#252d40")))
                                        }
                                    }
                                }
                            } else {
                                diagnosisView
                            }
                        }
                        .padding(20)
                    }

                    if step > 0 {
                        Button("← Back") { step -= 1 }
                            .foregroundColor(Color(hex: "#8b93a7"))
                            .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("GFCI Troubleshooter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "#d9a441"))
                }
            }
            .toolbarBackground(Color(hex: "#0e1320"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var diagnosisView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Common Causes & Fixes")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(hex: "#e8ebf2"))

            ForEach(diagnoses, id: \.title) { d in
                VStack(alignment: .leading, spacing: 8) {
                    Text(d.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.red)
                    Text(d.body)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#c5cad8"))
                }
                .padding(14)
                .background(Color(hex: "#0e1320"))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#252d40")))
            }

            Button("Start Over") { step = 0 }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "#d9a441"))
                .padding(.top, 8)
        }
    }

    private let diagnoses = [
        (title: "GFCI Device Failed", body: "If the device won't reset and there's no load fault, the GFCI itself is bad. Replace the receptacle — they fail after ~10 years or after multiple trips."),
        (title: "Ground Fault on Load Side", body: "Something plugged in or wired on the LOAD terminals is leaking current. Disconnect all load-side wiring, reset the GFCI. If it holds, reconnect devices one at a time to isolate the fault."),
        (title: "Miswired — Hot/Neutral Reversed", body: "A reversed hot/neutral on LINE or LOAD terminals can prevent reset. Check with a plug-in tester. Correct polarity before resetting."),
        (title: "Moisture / Water Intrusion", body: "Moisture in the box or fixture causes a ground fault. Dry everything out, use a heat gun if needed. If outdoors, verify the cover is rated 'in-use' (bubble cover)."),
        (title: "Upstream GFCI or Breaker", body: "This outlet may be protected by a GFCI elsewhere. Check other bathrooms, garage, exterior outlets, and the panel for a GFCI breaker. Reset the upstream device first."),
    ]
}

// MARK: - Shared helpers

func sheetContainer<Content: View, Footer: View>(
    title: String, icon: String, color: Color,
    @ViewBuilder content: @escaping () -> Content,
    @ViewBuilder footer: @escaping () -> Footer
) -> some View {
    _SheetContainer(title: title, icon: icon, color: color, content: content, footer: footer)
}

struct _SheetContainer<Content: View, Footer: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: () -> Content
    let footer: () -> Footer
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0a0d14").ignoresSafeArea()
                VStack(spacing: 0) {
                    List {
                        content()
                            .listRowBackground(Color(hex: "#0e1320"))
                            .listRowSeparatorTint(Color(hex: "#1c2436"))
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)

                    footer()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#0e1320"))
                        .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "#1c2436")), alignment: .top)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(Color(hex: "#d9a441"))
                }
            }
            .toolbarBackground(Color(hex: "#0e1320"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

struct CounterRow: View {
    @Binding var item: CounterItem

    var body: some View {
        HStack {
            Text(item.name)
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "#e8ebf2"))
            Spacer()
            HStack(spacing: 16) {
                Button {
                    if item.count > 0 { item.count -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(item.count > 0 ? Color(hex: "#d9a441") : Color(hex: "#3d4557"))
                }
                Text("\(item.count)")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: "#e8ebf2"))
                    .frame(width: 32, alignment: .center)
                Button {
                    item.count += 1
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: "#d9a441"))
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - UIActivityViewController wrapper

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
