import SwiftUI

// MARK: - Data

struct NECTable: Identifiable {
    let id = UUID()
    let title: String
    let reference: String
    let sections: [NECSection]
}

struct NECSection: Identifiable {
    let id = UUID()
    let heading: String?
    let rows: [NECRow]
}

struct NECRow: Identifiable {
    let id = UUID()
    let cols: [String]
}

// MARK: - NEC Data

private let necTables: [NECTable] = [
    ampacityTable,
    aluminumAmpacityTable,
    conduitFillTable,
    boxFillTable,
    groundWireTable,
    breakerSizesTable,
    minCoverTable,
    loadCalcTable,
]

private let ampacityTable = NECTable(
    title: "Wire Ampacity — Copper",
    reference: "NEC 310.12",
    sections: [
        NECSection(heading: "60°C / 140°F (older wiring, THHN in conduit < 3 wires)", rows: [
            NECRow(cols: ["14 AWG", "15 A"]),
            NECRow(cols: ["12 AWG", "20 A"]),
            NECRow(cols: ["10 AWG", "30 A"]),
            NECRow(cols: ["8 AWG",  "40 A"]),
            NECRow(cols: ["6 AWG",  "55 A"]),
            NECRow(cols: ["4 AWG",  "70 A"]),
            NECRow(cols: ["3 AWG",  "85 A"]),
            NECRow(cols: ["2 AWG",  "95 A"]),
            NECRow(cols: ["1 AWG",  "110 A"]),
            NECRow(cols: ["1/0 AWG","125 A"]),
            NECRow(cols: ["2/0 AWG","145 A"]),
            NECRow(cols: ["3/0 AWG","165 A"]),
            NECRow(cols: ["4/0 AWG","195 A"]),
            NECRow(cols: ["250 kcmil","215 A"]),
            NECRow(cols: ["300 kcmil","240 A"]),
            NECRow(cols: ["350 kcmil","260 A"]),
            NECRow(cols: ["400 kcmil","280 A"]),
            NECRow(cols: ["500 kcmil","320 A"]),
        ]),
        NECSection(heading: "75°C / 167°F (THWN-2, common residential/commercial)", rows: [
            NECRow(cols: ["14 AWG", "20 A"]),
            NECRow(cols: ["12 AWG", "25 A"]),
            NECRow(cols: ["10 AWG", "35 A"]),
            NECRow(cols: ["8 AWG",  "50 A"]),
            NECRow(cols: ["6 AWG",  "65 A"]),
            NECRow(cols: ["4 AWG",  "85 A"]),
            NECRow(cols: ["3 AWG",  "100 A"]),
            NECRow(cols: ["2 AWG",  "115 A"]),
            NECRow(cols: ["1 AWG",  "130 A"]),
            NECRow(cols: ["1/0 AWG","150 A"]),
            NECRow(cols: ["2/0 AWG","175 A"]),
            NECRow(cols: ["3/0 AWG","200 A"]),
            NECRow(cols: ["4/0 AWG","230 A"]),
            NECRow(cols: ["250 kcmil","255 A"]),
            NECRow(cols: ["300 kcmil","285 A"]),
            NECRow(cols: ["350 kcmil","310 A"]),
            NECRow(cols: ["400 kcmil","335 A"]),
            NECRow(cols: ["500 kcmil","380 A"]),
        ]),
        NECSection(heading: "90°C / 194°F (THHN dry, derating base only)", rows: [
            NECRow(cols: ["14 AWG", "25 A"]),
            NECRow(cols: ["12 AWG", "30 A"]),
            NECRow(cols: ["10 AWG", "40 A"]),
            NECRow(cols: ["8 AWG",  "55 A"]),
            NECRow(cols: ["6 AWG",  "75 A"]),
            NECRow(cols: ["4 AWG",  "95 A"]),
            NECRow(cols: ["3 AWG",  "115 A"]),
            NECRow(cols: ["2 AWG",  "130 A"]),
            NECRow(cols: ["1 AWG",  "145 A"]),
            NECRow(cols: ["1/0 AWG","170 A"]),
            NECRow(cols: ["2/0 AWG","195 A"]),
            NECRow(cols: ["3/0 AWG","225 A"]),
            NECRow(cols: ["4/0 AWG","260 A"]),
            NECRow(cols: ["250 kcmil","290 A"]),
            NECRow(cols: ["300 kcmil","320 A"]),
            NECRow(cols: ["350 kcmil","350 A"]),
            NECRow(cols: ["400 kcmil","380 A"]),
            NECRow(cols: ["500 kcmil","430 A"]),
        ]),
    ]
)

private let aluminumAmpacityTable = NECTable(
    title: "Wire Ampacity — Aluminum",
    reference: "NEC 310.12",
    sections: [
        NECSection(heading: "75°C (USE-2, XHHW-2 — service entrance typical)", rows: [
            NECRow(cols: ["12 AWG", "20 A"]),
            NECRow(cols: ["10 AWG", "30 A"]),
            NECRow(cols: ["8 AWG",  "40 A"]),
            NECRow(cols: ["6 AWG",  "50 A"]),
            NECRow(cols: ["4 AWG",  "65 A"]),
            NECRow(cols: ["2 AWG",  "90 A"]),
            NECRow(cols: ["1 AWG",  "100 A"]),
            NECRow(cols: ["1/0 AWG","120 A"]),
            NECRow(cols: ["2/0 AWG","135 A"]),
            NECRow(cols: ["3/0 AWG","155 A"]),
            NECRow(cols: ["4/0 AWG","180 A"]),
            NECRow(cols: ["250 kcmil","205 A"]),
            NECRow(cols: ["300 kcmil","230 A"]),
            NECRow(cols: ["350 kcmil","250 A"]),
            NECRow(cols: ["400 kcmil","270 A"]),
            NECRow(cols: ["500 kcmil","310 A"]),
        ]),
    ]
)

private let conduitFillTable = NECTable(
    title: "Conduit Fill — THHN/THWN",
    reference: "NEC Annex C / 310.15",
    sections: [
        NECSection(heading: "Max conductors (40% fill, same size)", rows: [
            NECRow(cols: ["Conduit", "12 AWG", "10 AWG", "8 AWG", "6 AWG"]),
            NECRow(cols: ["½\" EMT",  "9",  "5",  "3",  "2"]),
            NECRow(cols: ["¾\" EMT",  "16", "10", "5",  "4"]),
            NECRow(cols: ["1\" EMT",  "26", "16", "9",  "6"]),
            NECRow(cols: ["1¼\" EMT", "43", "26", "14", "10"]),
            NECRow(cols: ["1½\" EMT", "58", "36", "20", "14"]),
            NECRow(cols: ["2\" EMT",  "96", "60", "33", "23"]),
            NECRow(cols: ["½\" PVC Sch40", "8",  "5",  "3",  "2"]),
            NECRow(cols: ["¾\" PVC Sch40", "14", "9",  "5",  "4"]),
            NECRow(cols: ["1\" PVC Sch40",  "24", "15", "9",  "6"]),
        ]),
        NECSection(heading: "Wire area (THHN sq in) for manual calc", rows: [
            NECRow(cols: ["14 AWG", "0.0097 in²"]),
            NECRow(cols: ["12 AWG", "0.0133 in²"]),
            NECRow(cols: ["10 AWG", "0.0211 in²"]),
            NECRow(cols: ["8 AWG",  "0.0366 in²"]),
            NECRow(cols: ["6 AWG",  "0.0507 in²"]),
            NECRow(cols: ["4 AWG",  "0.0824 in²"]),
            NECRow(cols: ["2 AWG",  "0.1333 in²"]),
            NECRow(cols: ["1/0 AWG","0.1901 in²"]),
            NECRow(cols: ["2/0 AWG","0.2223 in²"]),
            NECRow(cols: ["3/0 AWG","0.2679 in²"]),
            NECRow(cols: ["4/0 AWG","0.3237 in²"]),
        ]),
    ]
)

private let boxFillTable = NECTable(
    title: "Box Fill Calculation",
    reference: "NEC 314.16(B)",
    sections: [
        NECSection(heading: "Volume per conductor (in³)", rows: [
            NECRow(cols: ["14 AWG", "2.00 in³"]),
            NECRow(cols: ["12 AWG", "2.25 in³"]),
            NECRow(cols: ["10 AWG", "2.50 in³"]),
            NECRow(cols: ["8 AWG",  "3.00 in³"]),
            NECRow(cols: ["6 AWG",  "5.00 in³"]),
        ]),
        NECSection(heading: "Count rules", rows: [
            NECRow(cols: ["Each current-carrying conductor entering box", "1 conductor"]),
            NECRow(cols: ["All EGC(s) combined", "1 conductor (largest EGC size)"]),
            NECRow(cols: ["All clamps combined (internal)", "1 conductor (largest wire in box)"]),
            NECRow(cols: ["Each device (switch, outlet)", "2 conductors (largest attached wire)"]),
            NECRow(cols: ["Conductors passing through unbroken", "1 each"]),
            NECRow(cols: ["Pigtails entirely inside box", "0"]),
        ]),
        NECSection(heading: "Common box volumes", rows: [
            NECRow(cols: ["2×4 single-gang plastic (standard)", "18 in³"]),
            NECRow(cols: ["2×4 single-gang deep (2⅛\")", "21 in³"]),
            NECRow(cols: ["2×4 double-gang", "30.3 in³"]),
            NECRow(cols: ["4\" square 1½\" deep", "21 in³"]),
            NECRow(cols: ["4\" square 2⅛\" deep", "30.3 in³"]),
            NECRow(cols: ["4-11/16\" square 1½\" deep", "29.5 in³"]),
            NECRow(cols: ["4-11/16\" square 2⅛\" deep", "42 in³"]),
            NECRow(cols: ["Octagon 4\" × 1½\" deep", "15.5 in³"]),
        ]),
    ]
)

private let groundWireTable = NECTable(
    title: "Equipment Grounding Conductor",
    reference: "NEC 250.122",
    sections: [
        NECSection(heading: "Minimum EGC size based on OCPD rating", rows: [
            NECRow(cols: ["OCPD Rating", "Copper EGC", "Aluminum EGC"]),
            NECRow(cols: ["15 A",  "14 AWG", "12 AWG"]),
            NECRow(cols: ["20 A",  "12 AWG", "10 AWG"]),
            NECRow(cols: ["30 A",  "10 AWG", "8 AWG"]),
            NECRow(cols: ["40 A",  "10 AWG", "8 AWG"]),
            NECRow(cols: ["60 A",  "10 AWG", "8 AWG"]),
            NECRow(cols: ["100 A", "8 AWG",  "6 AWG"]),
            NECRow(cols: ["200 A", "6 AWG",  "4 AWG"]),
            NECRow(cols: ["300 A", "4 AWG",  "2 AWG"]),
            NECRow(cols: ["400 A", "3 AWG",  "1 AWG"]),
            NECRow(cols: ["500 A", "2 AWG",  "1/0 AWG"]),
            NECRow(cols: ["600 A", "1 AWG",  "2/0 AWG"]),
            NECRow(cols: ["800 A", "1/0 AWG","3/0 AWG"]),
            NECRow(cols: ["1000 A","2/0 AWG","4/0 AWG"]),
            NECRow(cols: ["1200 A","3/0 AWG","250 kcmil"]),
            NECRow(cols: ["1600 A","4/0 AWG","350 kcmil"]),
            NECRow(cols: ["2000 A","250 kcmil","400 kcmil"]),
        ]),
    ]
)

private let breakerSizesTable = NECTable(
    title: "Standard Breaker Sizes",
    reference: "NEC 240.6(A)",
    sections: [
        NECSection(heading: "Standard ampere ratings", rows: [
            NECRow(cols: ["15, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80, 90, 100"]),
            NECRow(cols: ["110, 125, 150, 175, 200, 225, 250, 300, 350, 400, 450, 500"]),
            NECRow(cols: ["600, 700, 800, 1000, 1200, 1600, 2000, 2500, 3000, 4000, 5000, 6000"]),
        ]),
        NECSection(heading: "Common residential breaker wire pairings", rows: [
            NECRow(cols: ["Breaker", "Min Wire (Cu)", "Typical Use"]),
            NECRow(cols: ["15 A",  "14 AWG", "Lighting, general circuits"]),
            NECRow(cols: ["20 A",  "12 AWG", "Kitchen, bath, garage, outdoor"]),
            NECRow(cols: ["30 A",  "10 AWG", "Dryer, water heater, A/C"]),
            NECRow(cols: ["40 A",  "8 AWG",  "Range/oven"]),
            NECRow(cols: ["50 A",  "6 AWG",  "Range, EV charger (L2)"]),
            NECRow(cols: ["60 A",  "6 AWG",  "Sub-panel feed, hot tub"]),
            NECRow(cols: ["100 A", "4 AWG Cu / 2 AWG Al", "Sub-panel"]),
            NECRow(cols: ["200 A", "2/0 AWG Cu / 4/0 AWG Al", "Service entrance"]),
        ]),
    ]
)

private let minCoverTable = NECTable(
    title: "Minimum Cover Requirements",
    reference: "NEC 300.5",
    sections: [
        NECSection(heading: "Direct burial depth (inches)", rows: [
            NECRow(cols: ["Wiring Method", "General", "Under Slab", "Under Street"]),
            NECRow(cols: ["UF cable",          "24\"", "18\"", "24\""]),
            NECRow(cols: ["RMC / IMC",          "6\"",  "6\"",  "24\""]),
            NECRow(cols: ["PVC Sch 40 (NM ok)", "18\"", "12\"", "24\""]),
            NECRow(cols: ["THWN in PVC",        "18\"", "12\"", "24\""]),
            NECRow(cols: ["THWN in RMC",        "6\"",  "6\"",  "24\""]),
            NECRow(cols: ["120V ≤20A GFCI (resi)","12\"","6\"", "24\""]),
        ]),
    ]
)

private let loadCalcTable = NECTable(
    title: "Residential Load Calc",
    reference: "NEC 220.82 — Optional Method",
    sections: [
        NECSection(heading: "General lighting & receptacle load", rows: [
            NECRow(cols: ["First 3000 VA", "100%"]),
            NECRow(cols: ["Next 3001–120,000 VA", "35%"]),
            NECRow(cols: ["Over 120,000 VA", "25%"]),
            NECRow(cols: ["Unit: 3 VA per sq ft of living area", ""]),
        ]),
        NECSection(heading: "Small appliance & laundry circuits", rows: [
            NECRow(cols: ["2 small appliance circuits × 1500 VA", "= 3000 VA"]),
            NECRow(cols: ["1 laundry circuit × 1500 VA", "= 1500 VA"]),
        ]),
        NECSection(heading: "Fixed appliances (use nameplate VA)", rows: [
            NECRow(cols: ["Dryer", "5000 VA min or nameplate"]),
            NECRow(cols: ["Range / oven", "8000 VA (or 80% nameplate if >12 kW)"]),
            NECRow(cols: ["A/C vs heat", "Use larger of A/C or heating load"]),
            NECRow(cols: ["Heat pump", "100% of largest motor + 65% others"]),
        ]),
        NECSection(heading: "Service size formula", rows: [
            NECRow(cols: ["Total VA ÷ 240V = Amps required"]),
            NECRow(cols: ["Round up to next standard breaker size (240.6)"]),
        ]),
        NECSection(heading: "Derating — conduit fill > 3 current-carrying", rows: [
            NECRow(cols: ["4–6 conductors",  "80% of table ampacity"]),
            NECRow(cols: ["7–9 conductors",  "70%"]),
            NECRow(cols: ["10–20 conductors","50%"]),
            NECRow(cols: ["21–30 conductors","45%"]),
            NECRow(cols: ["31–40 conductors","40%"]),
            NECRow(cols: ["41+ conductors",  "35%"]),
        ]),
    ]
)

// MARK: - View

struct NECTablesView: View {
    @State private var search = ""
    @State private var selected: NECTable? = nil

    private var filtered: [NECTable] {
        if search.isEmpty { return necTables }
        let q = search.lowercased()
        return necTables.filter {
            $0.title.lowercased().contains(q) ||
            $0.reference.lowercased().contains(q) ||
            $0.sections.contains { s in
                (s.heading?.lowercased().contains(q) ?? false) ||
                s.rows.contains { r in r.cols.contains { $0.lowercased().contains(q) } }
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0a0d14").ignoresSafeArea()

                if let table = selected {
                    TableDetailView(table: table, onBack: { selected = nil })
                } else {
                    tableList
                }
            }
            .navigationTitle("NEC Tables")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "#0e1320"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var tableList: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color(hex: "#5a6275"))
                    .font(.system(size: 14))
                TextField("Search tables…", text: $search)
                    .foregroundColor(Color(hex: "#e8ebf2"))
                    .font(.system(size: 15))
                if !search.isEmpty {
                    Button { search = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(hex: "#5a6275"))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(hex: "#161c2b"))
            .cornerRadius(10)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filtered) { table in
                        Button { selected = table } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(table.title)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Color(hex: "#e8ebf2"))
                                    Text(table.reference)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(Color(hex: "#d9a441"))
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color(hex: "#5a6275"))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color(hex: "#0e1320"))
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#1e2840"), lineWidth: 1))
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - Detail

struct TableDetailView: View {
    let table: NECTable
    let onBack: () -> Void
    @State private var search = ""

    private var filtered: [NECSection] {
        if search.isEmpty { return table.sections }
        let q = search.lowercased()
        return table.sections.compactMap { sec in
            let headingMatch = sec.heading?.lowercased().contains(q) ?? false
            let matchingRows = sec.rows.filter { r in r.cols.contains { $0.lowercased().contains(q) } }
            if headingMatch { return sec }
            if !matchingRows.isEmpty { return NECSection(heading: sec.heading, rows: matchingRows) }
            return nil
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Tables")
                            .font(.system(size: 15))
                    }
                    .foregroundColor(Color(hex: "#d9a441"))
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(hex: "#0e1320"))

            VStack(alignment: .leading, spacing: 2) {
                Text(table.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "#e8ebf2"))
                Text(table.reference)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color(hex: "#d9a441"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(hex: "#0e1320"))

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color(hex: "#5a6275"))
                    .font(.system(size: 13))
                TextField("Filter…", text: $search)
                    .foregroundColor(Color(hex: "#e8ebf2"))
                    .font(.system(size: 14))
                if !search.isEmpty {
                    Button { search = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(hex: "#5a6275"))
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color(hex: "#161c2b"))
            .cornerRadius(8)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(hex: "#0e1320"))

            Divider().background(Color(hex: "#1e2840"))

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(filtered) { section in
                        VStack(alignment: .leading, spacing: 0) {
                            if let heading = section.heading {
                                Text(heading)
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color(hex: "#8b93a7"))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(hex: "#10151f"))
                            }
                            ForEach(Array(section.rows.enumerated()), id: \.element.id) { idx, row in
                                NECRowView(row: row, isEven: idx % 2 == 0)
                            }
                        }
                        .background(Color(hex: "#0e1320"))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#1e2840"), lineWidth: 1))
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 14)
            }
        }
        .background(Color(hex: "#0a0d14").ignoresSafeArea())
    }
}

struct NECRowView: View {
    let row: NECRow
    let isEven: Bool

    var body: some View {
        HStack(spacing: 0) {
            if row.cols.count == 1 {
                Text(row.cols[0])
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(Color(hex: "#e8ebf2"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(Array(row.cols.enumerated()), id: \.offset) { i, col in
                    Text(col)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(i == 0 ? Color(hex: "#c5cad8") : Color(hex: "#e8ebf2"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity, alignment: i == 0 ? .leading : .leading)
                    if i < row.cols.count - 1 {
                        Divider()
                            .background(Color(hex: "#1e2840"))
                            .frame(height: 28)
                    }
                }
            }
        }
        .background(isEven ? Color(hex: "#0e1320") : Color(hex: "#111725"))
    }
}
