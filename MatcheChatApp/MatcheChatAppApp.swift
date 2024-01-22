//
//  MatcheChatAppApp.swift
//  MatcheChatApp
//
//  Created by Andre Maytorena on 21/12/2023.
//

import SwiftUI

@main
struct MatcheChatAppApp: SwiftUI.App {

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [SyncedTimes.self, Conversation.self, Messages.self])
    }
}
