//
//  MatcheChatAppApp.swift
//  MatcheChatApp
//
//  Created by Andre Maytorena on 21/12/2023.
//

import SwiftUI
import RealmSwift

let realmApp = RealmSwift.App(id: "application-0-dotyc")

@main
struct MatcheChatAppApp: SwiftUI.App {

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
