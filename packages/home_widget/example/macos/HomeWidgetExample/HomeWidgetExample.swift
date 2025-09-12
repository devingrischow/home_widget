//
//  HomeWidgetExample.swift
//  HomeWidgetExample
//
//  Created by Devin Grischow on 9/10/25.
//

import WidgetKit
import SwiftUI

private let widgetGroupId = "group.example.widget_group"

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> ExampleEntry {
      ExampleEntry(date: Date(), title: "Placeholder Title", message: "Placeholder Message")
    }

    func getSnapshot(in context: Context, completion: @escaping (ExampleEntry) -> Void) {
      let data = UserDefaults.init(suiteName: widgetGroupId)
      let entry = ExampleEntry(
        date: Date(), title: data?.string(forKey: "title") ?? "No Title Set",
        message: data?.string(forKey: "message") ?? "No Message Set"
      )
        
      completion(entry)
    }
    
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
      getSnapshot(in: context) { (entry) in
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
      }
    }

//    func relevances() async -> WidgetRelevances<Void> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct ExampleEntry: TimelineEntry {
  let date: Date
  let title: String
  let message: String
}

struct HomeWidgetExampleEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            HStack {
                Text("Time:")
                Text(entry.date, style: .time)
            }

            Text("Emoji:")
//            Text(entry.emoji)
        }
    }
}

struct HomeWidgetExample: Widget {
    let kind: String = "HomeWidgetExample"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(macOS 14.0, *) {
                HomeWidgetExampleEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                HomeWidgetExampleEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}
