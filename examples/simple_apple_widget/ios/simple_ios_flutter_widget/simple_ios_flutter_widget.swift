//
//  simple_ios_flutter_widget.swift
//  simple_ios_flutter_widget
//
//  Created by Devin Grischow on 9/16/25.
//

import WidgetKit
import SwiftUI
import home_widget

private let widgetGroupId = "group.example.widget_group"
let countKey = "count";

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), count: "0")
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let prefs = UserDefaults.init(suiteName: widgetGroupId)
        let counterValue = prefs?.string(forKey: countKey) ?? "0"
        
        let entry = SimpleEntry(date: Date(), count: counterValue)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        
        getSnapshot(in: context) { (entry) in
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        }
        
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let count: String
}

struct simple_ios_flutter_widgetEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack {
            Text("Pressed")
            Text(entry.count)
            Text("Times")
            
            if #available(iOSApplicationExtension 17, *){
                //Big Iteractible Button
                Button(intent:  BackgroundIntent(
                    url: URL(string: "homeWidgetExample://incrementPressed"),
                    appGroup: widgetGroupId)
                ){
                    Text("+")
                }
            }
            
        }
    }
}

struct simple_ios_flutter_widget: Widget {
    let kind: String = "simple_ios_flutter_widget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            simple_ios_flutter_widgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

//#Preview(as: .systemSmall) {
//    simple_ios_flutter_widget()
//} timeline: {
//    SimpleEntry(date: .now, emoji: "😀")
//    SimpleEntry(date: .now, emoji: "🤩")
//}
