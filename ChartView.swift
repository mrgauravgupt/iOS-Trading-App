import SwiftUI
import Charts

struct ChartView: View {
    let data: [MarketData]

    var body: some View {
        Chart(data) { item in
            LineMark(
                x: .value("Time", item.timestamp),
                y: .value("Price", item.price)
            )
        }
        .frame(height: 200)
    }
}
