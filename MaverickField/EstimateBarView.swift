import SwiftUI

struct EstimateBarView: View {
    let estimate: PendingEstimate
    let isBusy: Bool
    let onBuild: () -> Void
    let onDismiss: () -> Void

    @State private var expanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Summary row
            HStack {
                Button { withAnimation { expanded.toggle() } } label: {
                    HStack(spacing: 8) {
                        Image(systemName: expanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "#d9a441"))
                        Text("📋 \(estimate.totalItems) item\(estimate.totalItems == 1 ? "" : "s") ready to push")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "#e8ebf2"))
                        if let name = estimate.customerName {
                            Text("— \(name)")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#8b93a7"))
                        }
                    }
                }
                Spacer()
                HStack(spacing: 10) {
                    Button { onDismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "#5a6275"))
                    }
                    Button {
                        onBuild()
                    } label: {
                        Text(isBusy ? "Creating…" : "⚡ BUILD IT")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isBusy ? Color(hex: "#8b93a7") : Color(hex: "#d9a441"))
                            .cornerRadius(8)
                    }
                    .disabled(isBusy)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            // Expanded line items
            if expanded {
                Divider().background(Color(hex: "#252d40"))
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(estimate.lineItems) { item in
                            LineItemRow(name: item.name, qty: item.quantity, price: item.unitPrice,
                                        total: item.total, status: statusIcon(item.type))
                        }
                        if let newItems = estimate.newPricebookItems {
                            ForEach(newItems) { item in
                                LineItemRow(name: item.name, qty: item.quantity, price: item.unitPrice,
                                            total: item.total, status: "🏠")
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
        .background(Color(hex: "#1c2436"))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "#d9a441").opacity(0.4)), alignment: .top)
    }

    private func statusIcon(_ type: String) -> String {
        switch type {
        case "matched":  return "✅"
        case "adjusted": return "⚙️"
        default:         return "⚠️"
        }
    }
}

struct LineItemRow: View {
    let name: String
    let qty: Double
    let price: Double
    let total: Double
    let status: String

    var body: some View {
        HStack {
            Text(status).frame(width: 22)
            Text(name)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#e8ebf2"))
                .lineLimit(1)
            Spacer()
            Text("\(qty, specifier: qty.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f") × $\(price, specifier: "%.2f")")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(Color(hex: "#8b93a7"))
            Text("$\(total, specifier: "%.2f")")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(Color(hex: "#d9a441"))
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .overlay(Rectangle().frame(height: 0.5).foregroundColor(Color(hex: "#252d40")), alignment: .bottom)
    }
}
