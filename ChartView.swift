import SwiftUI
import Charts

struct ChartView: View {
    let data: [MarketData]

    var body: some View {
        if #available(iOS 16.0, *) {
            Chart(data) { item in
                LineMark(
                    x: .value("Time", item.timestamp),
                    y: .value("Price", item.price)
                )
            }
            .frame(height: 200)
        } else {
            // Fallback for older iOS versions
            VStack {
                Text("Chart visualization requires iOS 16.0 or later")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(height: 200)
        }
    }
}