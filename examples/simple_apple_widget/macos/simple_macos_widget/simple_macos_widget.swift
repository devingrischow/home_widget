//
//  simple_macos_widget.swift
//  simple_macos_widget
//
//  Created by Devin Grischow on 9/16/25.
//

import WidgetKit
import SwiftUI

private let widgetGroupId = "4DZJGNL44Y.example.widget_group"
private let countKey = "count";

let widgetName = "HomeWidgetExampleProvider"

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), count: "0")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        print("Getting Snapshot")
        let prefs = UserDefaults.init(suiteName: widgetGroupId)
        let counterValue = prefs?.string(forKey: countKey) ?? "0"
        print("Counter Values: \(counterValue)")
        let entry = SimpleEntry(date: Date(), count: counterValue)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        print("Getting New TimeLine")
        
        getSnapshot(in: context) { (entry) in
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        }
        
    }

//    func relevances() async -> WidgetRelevances<Void> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let count: String
}

struct simple_macos_widgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text("Pressed")
            Text(entry.count)
            Text("Times")

            
        }
        .widgetURL(URL(string: "\(widgetName)://count?count=\(entry.count)&homeWidget"))
    }
}

struct simple_macos_widget: Widget {
    let kind: String = "simple_macos_widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            simple_macos_widgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}
