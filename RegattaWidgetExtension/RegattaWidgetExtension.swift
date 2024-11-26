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
        SimpleEntry(date: Date(), lastUsedTime: 5)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let lastUsedTime = UserDefaults.standard.integer(forKey: "lastUsedTime")
        let entry = SimpleEntry(date: Date(), lastUsedTime: lastUsedTime)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let lastUsedTime = UserDefaults.standard.integer(forKey: "lastUsedTime")
        let entry = SimpleEntry(date: Date(), lastUsedTime: lastUsedTime)
        
        // Update timeline when app changes the time
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let lastUsedTime: Int
}

struct RegattaWidgetExtensionEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        Gauge(value: Double(entry.lastUsedTime), in: 0...30) {
            Text("min")
                .font(.system(.caption, design: .rounded))
        } currentValueLabel: {
            Text(String(format: "%02d", entry.lastUsedTime))
                .font(.system(.body, design: .monospaced))
        }
        .gaugeStyle(.accessoryCircular)
        .tint(Gradient(colors: [.orange, .cyan]))
        .containerBackground(.clear, for: .widget)
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
    SimpleEntry(date: .now, lastUsedTime: 5)
    SimpleEntry(date: .now, lastUsedTime: 15)
}
