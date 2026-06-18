//
//  budgetappaiLiveActivity.swift
//  budgetappai
//
//  Created by user on 6/6/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct budgetappaiAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct budgetappaiLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: budgetappaiAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension budgetappaiAttributes {
    fileprivate static var preview: budgetappaiAttributes {
        budgetappaiAttributes(name: "World")
    }
}

extension budgetappaiAttributes.ContentState {
    fileprivate static var smiley: budgetappaiAttributes.ContentState {
        budgetappaiAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: budgetappaiAttributes.ContentState {
         budgetappaiAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: budgetappaiAttributes.preview) {
   budgetappaiLiveActivity()
} contentStates: {
    budgetappaiAttributes.ContentState.smiley
    budgetappaiAttributes.ContentState.starEyes
}
