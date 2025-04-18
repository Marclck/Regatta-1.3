//
//  RegattaWidgetExtension.swift
//  RegattaWidgetExtension
//
//  Created by Chikai Lai on 24/11/2024.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), lastUsedTime: 5, themeColor: SharedDefaults.getTheme())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let lastUsedTime = SharedDefaults.getLastUsedTime()
        let theme = SharedDefaults.getTheme()
        let entry = SimpleEntry(date: Date(), lastUsedTime: lastUsedTime, themeColor: theme)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let lastUsedTime = SharedDefaults.getLastUsedTime()
        let theme = SharedDefaults.getTheme()
        let entry = SimpleEntry(date: Date(), lastUsedTime: lastUsedTime, themeColor: theme)
        
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}


struct SimpleEntry: TimelineEntry {
    let date: Date
    let lastUsedTime: Int
    let themeColor: ColorTheme
}

struct RegattaWidgetExtensionEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
        ZStack {
            Gauge(value: Double(entry.lastUsedTime), in: 0...30) {
                Text("min")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
            } currentValueLabel: {
                Text(String(format: "%02d", entry.lastUsedTime))
                    .font(.zenithBeta(size: 18))
            }
            .gaugeStyle(.accessoryCircular)
            .tint(Gradient(colors: [
                Color(hex: entry.themeColor.rawValue).opacity(0.5),
                Color(hex: entry.themeColor.rawValue),
                Color(hex: entry.themeColor.rawValue),
                Color(hex: entry.themeColor.rawValue).opacity(0.5)
            ]))
            .containerBackground(.clear, for: .widget)
        }
        .frame(minWidth: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .background()
        .backgroundStyle(.linearGradient(colors: [
            .clear,
            .clear,
            .clear, //conditional
            Color(hex: entry.themeColor.rawValue).opacity(0.3),
            Color(hex: entry.themeColor.rawValue),
            Color(hex: entry.themeColor.rawValue)
        ], startPoint: .top, endPoint: .bottom))
    }
}

@main
struct RegattaWidgetExtension: Widget {
    let kind: String = "RegattaWidgetExtension"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            RegattaWidgetExtensionEntryView(entry: entry)
        }
        .configurationDisplayName("Last Used Time")
        .description("Shows the last countdown time used")
        .supportedFamilies([.accessoryCircular])
    }
}

#Preview(as: .accessoryCircular) {
    RegattaWidgetExtension()
} timeline: {
    SimpleEntry(date: .now, lastUsedTime: 5, themeColor: .ultraBlue)
    SimpleEntry(date: .now, lastUsedTime: 15, themeColor: .ultraBlue)
}
