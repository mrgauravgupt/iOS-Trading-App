import SwiftUI
import Charts

/// View for displaying market data charts
struct ChartView: View {
    let data: [MarketData]
    var chartType: ChartType = .line

    /// Types of charts that can be displayed
    enum ChartType {
        case line, candlestick, bar
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            SectionCard("Price Chart") {
                Chart(data) { item in
                    switch chartType {
                    case .line:
                        LineMark(
                            x: .value("Time", item.timestamp),
                            y: .value("Price", item.price)
                        )
                        .foregroundStyle(Color.kiteBlue)
                    case .bar:
                        BarMark(
                            x: .value("Time", item.timestamp),
                            y: .value("Price", item.price)
                        )
                        .foregroundStyle(.green)
                    case .candlestick:
                        // Simplified candlestick representation
                        RectangleMark(
                            x: .value("Time", item.timestamp),
                            yStart: .value("Low", item.price * 0.99),
                            yEnd: .value("High", item.price * 1.01)
                        )
                        .foregroundStyle(.orange)
                    }
                }
                .frame(height: 300)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .hour, count: 1)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.hour())
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
            }
        } else {
            // Fallback for older iOS versions
            VStack {
                Text("Chart visualization requires iOS 16.0 or later")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(height: 300)
        }
    }
}

#Preview {
    ChartView(data: [
        MarketData(symbol: "NIFTY", price: 18000, volume: 1000, timestamp: Date()),
        MarketData(symbol: "NIFTY", price: 18100, volume: 1200, timestamp: Date().addingTimeInterval(3600)),
        MarketData(symbol: "NIFTY", price: 17950, volume: 900, timestamp: Date().addingTimeInterval(7200))
    ])
}