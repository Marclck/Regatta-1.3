//
//  LineChartManager.swift
//  Regatta
//
//  Created by Chikai Lai on 26/11/2024.
//
//  A shared chart manager for Regatta Timer app and its widgets
//

import Foundation
import SwiftUI
import WidgetKit
import Charts

// MARK: - Data Models
public struct TimerDataPoint: Identifiable {
    public let id = UUID()
    public let position: Double
    public let minutes: Double
    
    public init(position: Double, minutes: Double) {
        self.position = position
        self.minutes = minutes
    }
}

public struct TimerData {
    public let lastUsedTime: Double
    public let lastFinishTime: Double
    
    public init(lastUsedTime: Double, lastFinishTime: Double) {
        self.lastUsedTime = lastUsedTime
        self.lastFinishTime = lastFinishTime
    }
    
    public var dataPoints: [TimerDataPoint] {
        [
            .init(position: 0, minutes: 0),
            .init(position: 2, minutes: lastUsedTime),
            .init(position: 4, minutes: lastFinishTime)
        ]
    }
    
    public static let preview = TimerData(lastUsedTime: 3, lastFinishTime: 5)
}

// MARK: - Chart View
@available(iOS 17.0, watchOS 10.0, *)
public struct RegattaChartView: View {
     let dataPoints: [TimerDataPoint]
     let isCircular: Bool
    
    public init(dataPoints: [TimerDataPoint], isCircular: Bool) {
        self.dataPoints = dataPoints
        self.isCircular = isCircular
    }
    
    private let gradientColors = Gradient(colors: [
        .cyan,
        .orange
    ])
    
    private var maxX: Double {
        (dataPoints.map(\.position).max() ?? 3) + 0.5
    }
    
    public var body: some View {
        Chart {
            // Gradient area
            ForEach(dataPoints) { point in
                AreaMark(
                    x: .value("Position", point.position),
                    y: .value("Minutes", point.minutes)
                )
                .interpolationMethod(.cardinal)
                .foregroundStyle(
                    LinearGradient(
                        gradient: gradientColors,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .opacity(0.3)
                )
            }
            
            // Line
            ForEach(dataPoints) { point in
                LineMark(
                    x: .value("Position", point.position),
                    y: .value("Minutes", point.minutes)
                )
                .interpolationMethod(.cardinal)
                .foregroundStyle(.clear)
                .lineStyle(StrokeStyle(lineWidth: 10))
            }
            
            // Points
            ForEach(dataPoints) { point in
                PointMark(
                    x: .value("Position", point.position),
                    y: .value("Minutes", point.minutes)
                )
                .foregroundStyle(.cyan)
                .symbol(.circle.strokeBorder(lineWidth: 100))
                .symbolSize(100)
            }
            
            // Vertical grid lines for rectangular view only
            if !isCircular {
                RuleMark(x: .value("O", 0))
                    .foregroundStyle(.gray.opacity(0.3))
                
                RuleMark(x: .value("C", 2))
                    .foregroundStyle(.gray.opacity(0.3))
                
                RuleMark(x: .value("S", 3))
                    .foregroundStyle(.gray.opacity(0.3))
            }
        }
        .chartXScale(domain: isCircular ? -0.2...4.2 : 0...maxX)
        .chartYScale(domain: 0...6)
        .chartLegend(.hidden)
        .chartXAxis {
            if !isCircular {
                AxisMarks(values: [1, 2, 3]) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        switch value.index {
                        case 0: Text("O")
                        case 1: Text("C")
                        case 2: Text("S")
                        default: Text("")
                        }
                    }
                }
            }
        }
        .chartYAxis {
            if !isCircular {
                AxisMarks { value in
                    AxisGridLine()
                    //                    AxisTick()
                    //                    if let minutes = value.as(Double.self) {
                    //                        AxisValueLabel {
                    //                            Text("\(Int(minutes))")
                    //                        }
                    //                    }
                }
            }
        }
        .aspectRatio(2, contentMode: .fill)
    }
}

// MARK: - Widget Views
public struct RegattaCircularView<Entry>: View {
    private let dataPoints: [TimerDataPoint]
    private let lastUsedTime: Double
    
    public init(dataPoints: [TimerDataPoint], lastUsedTime: Double) {
        self.dataPoints = dataPoints
        self.lastUsedTime = lastUsedTime
    }
    
    public var body: some View {
        ZStack {
            RegattaChartView(
                dataPoints: dataPoints,
                isCircular: true
            )
            .padding(2)
            
            VStack {
                Spacer()
                Text("\(Int(lastUsedTime)) min")
                    .font(.system(.body, design: .rounded))
                    .bold()
                    .foregroundColor(.white)
                    .padding(.bottom, 8)
            }
        }
        .containerBackground(.black, for: .widget)
    }
}

public struct RegattaRectangularView<Entry>: View {
    private let dataPoints: [TimerDataPoint]
    private let lastUsedTime: Double
    
    public init(dataPoints: [TimerDataPoint], lastUsedTime: Double) {
        self.dataPoints = dataPoints
        self.lastUsedTime = lastUsedTime
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            RegattaChartView(
                dataPoints: dataPoints,
                isCircular: false
            )
            .gridCellAnchor(.center) //make the chart centered.
            .frame(maxWidth: .infinity)
            
            Text("\(Int(lastUsedTime)) min")
                .font(.system(.title2, design: .rounded))
                .bold()
                .foregroundColor(.white)
                .padding(.trailing, 8)
        }
        .padding(.horizontal, 4)
        .containerBackground(.black, for: .widget)
    }
}

// MARK: - Data Manager
public class RegattaDataManager {
    public static let shared = RegattaDataManager()
    
    private init() {}
    
    public func saveTimerData(_ timerData: TimerData) {
        // Use SharedDefaults instead of direct UserDefaults
        SharedDefaults.setLastUsedTime(Int(timerData.lastUsedTime))
        SharedDefaults.setLastFinishTime(timerData.lastFinishTime)
        
        print("📊 Chart Manager: Saved data - LastUsedTime: \(timerData.lastUsedTime), LastFinishTime: \(timerData.lastFinishTime)")
    }
    
    public func getTimerData() -> TimerData {
        // Use SharedDefaults to get values
        let lastUsedTime = Double(SharedDefaults.getLastUsedTime())
        let lastFinishTime = SharedDefaults.getLastFinishTime()
        
        print("📊 Chart Manager: Retrieved data - LastUsedTime: \(lastUsedTime), LastFinishTime: \(lastFinishTime)")
        
        return TimerData(lastUsedTime: lastUsedTime, lastFinishTime: lastFinishTime)
    }
    
    
}

// MARK: - Previews
#if DEBUG
struct RegattaChartPreview: View {
    static let sampleData: [TimerDataPoint] = [
        TimerDataPoint(position: 1, minutes: 0),
        TimerDataPoint(position: 3, minutes: 3),
        TimerDataPoint(position: 5, minutes: 5)
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Regatta Timer Charts")
                .font(.title)
                .foregroundColor(.white)
            
            RegattaChartView(
                dataPoints: Self.sampleData,
                isCircular: false
            )
            .frame(width: 300, height: 160)
            
            RegattaChartView(
                dataPoints: Self.sampleData,
                isCircular: true
            )
            .frame(width: 180, height: 180)
            .clipShape(Circle())
        }
        .padding()
        .background(Color.black)
    }
}

struct RegattaChartView_Previews: PreviewProvider {
    static let sampleData: [TimerDataPoint] = [
        TimerDataPoint(position: 0, minutes: 5),
        TimerDataPoint(position: 2, minutes: 3),
        TimerDataPoint(position: 6, minutes: 10)
    ]
    
    static var previews: some View {
        Group {
            // Rectangular Preview
            RegattaChartView(dataPoints: sampleData, isCircular: false)
                .frame(width: 300, height: 160)
                .background(Color.black)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Rectangular Chart")
            
            // Circular Preview
            RegattaChartView(dataPoints: sampleData, isCircular: true)
                .frame(width: 160, height: 160)
                .background(Color.black)
                .clipShape(Circle())
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Circular Chart")
            
            // Dark Mode Preview
            RegattaChartView(dataPoints: sampleData, isCircular: false)
                .frame(width: 300, height: 160)
                .background(Color.black)
                .previewLayout(.sizeThatFits)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}

#Preview {
    RegattaChartPreview()
}
#endif
