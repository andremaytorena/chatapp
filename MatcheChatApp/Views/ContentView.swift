//
//  MainTabBarView.swift
//  Matché
//
//  Created by Andre Maytorena on 05/01/2024.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    
    @Environment(\.scenePhase) var scenePhase
        
    @ObservedObject var socketManager = SocketConnecterManager.shared
    
    @EnvironmentObject var authenticationModel: AuthenticationModel
                
    @EnvironmentObject private var authManager: AuthenticationManager
            
    @ObservedObject var messageManager = MessageManager.shared
                    
    @Query var conversations: [Conversation]
    @Query var messages: [Messages]
    
    @Query var convos: [Conversation]
    
    @Query var last_synced_times: [SyncedTimes]
    
    init() {
        var user_id = ""
        let userDefaults = UserDefaults.standard
        if let retrievedUserId = userDefaults.string(forKey: "userId") {
            user_id = retrievedUserId
        }
        let predicate = #Predicate<Conversation> { $0.current_participant_id == user_id}
        self._conversations = Query(filter: predicate, sort: [SortDescriptor(\Conversation.last_message_timestamp, order: .reverse)])
    }
    
    @Environment(\.modelContext) var context
    
    var body: some View {
        
        ZStack {
            
            VStack {
                
                TabView {
                    TestView()
                        .tabItem {
                            Image(systemName: "house")
                            Text("Home")
                        }
                    MessageInboxView(conversations: conversations)
                        .tabItem {
                            Image(systemName: "message")
                            Text("Chats")
                        }
                    TestView()
                        .tabItem {
                            Image(systemName: "magnifyingglass")
                            Text("Search")
                        }
                }
                .accentColor(Color("GoldAccentColor"))
                .onAppear {
                    socketManager.initializeSocketConnection()
                    socketManager.setupHandlers(conversations: conversations, context: context)
                    
                    if conversations.isEmpty {
                        print("retrieving all convos")
                        messageManager.retrieveAllConversationsRestructured() { result in
                            switch result {
                            case .success(let convos):
                                print(convos.first?.conversation_id)
                                Task {
                                    do {
                                        try await cacheConversations(convos: convos)
                                    } catch {
                                        print("Error: \(error.localizedDescription)")
                                    }
                                    updateLastSyncedTime()
                                }
                            case .failure(let error):
                                print("Error: \(error.localizedDescription)")
                            }
                        }
                    } else {
                        
                        let last_time_synced = last_synced_times.first?.last_conversation_synced_timestamp ?? "1"
                        
                        messageManager.syncConversations(
                            timestamp: last_time_synced
                        ) { result in
                            switch result {
                            case .success(let convos):
                                if !convos.isEmpty {
                                    Task {
                                        do {
                                            try await updateCachedConversations(convos: convos)
                                        } catch {
                                            print("Error: \(error.localizedDescription)")
                                        }
                                    }
                                }
                                updateLastSyncedTime()
                            case .failure(let error):
                                print("Error: \(error.localizedDescription)")
                            }
                        }
                    }
                    
                    if messages.isEmpty {
                        print("messages empty")
                        messageManager.retrieveAllMessagesRestructured() { result in
                            switch result {
                            case .success(let messages):
                                Task {
                                    do {
                                        try await cacheMessages(messages: messages)
                                    } catch {
                                        print("Error: \(error.localizedDescription)")
                                    }
                                    updateLastSyncedTime()
                                }
                            case .failure(let error):
                                print("Error: \(error.localizedDescription)")
                            }
                        }
                    } else {
                        
                        let last_time_synced = last_synced_times.first?.last_messages_synced_timestamp ?? "1"

                        messageManager.syncMessages(
                            timestamp: last_time_synced
                        ) { result in
                            switch result {
                            case .success(let messages):
                                if !messages.isEmpty {
                                    Task {
                                        do {
                                            try await updateCachedMessages(messages: messages)
                                        } catch {
                                            print("Error: \(error.localizedDescription)")
                                        }
                                    }
                                }
                                updateLastSyncedTime()
                            case .failure(let error):
                                print("Error: \(error.localizedDescription)")
                            }
                        }
                    }
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    if newPhase == .inactive || newPhase == .background {
//                        socketManager.disconnect()
                    } else if newPhase == .active {
                        print("ACTIVE")
//                        socketManager.initializeSocketConnection()
//                        socketManager.setupHandlers(conversations: conversations, context: context)
                        let last_time_synced = last_synced_times.first?.last_messages_synced_timestamp ?? "1"
                        
                        print("finding messages")
                        if !messages.isEmpty {
                            messageManager.syncMessages(
                                timestamp: last_time_synced
                            ) { result in
                                switch result {
                                case .success(let messages):
                                    if !messages.isEmpty {
                                        Task {
                                            do {
                                                try await updateCachedMessages(messages: messages)
                                            } catch {
                                                print("Error: \(error.localizedDescription)")
                                            }
                                        }
                                    }
                                    updateLastSyncedTime()
                                case .failure(let error):
                                    print("Error: \(error.localizedDescription)")
                                }
                            }
                            
                            let last_time_synced = last_synced_times.first?.last_conversation_synced_timestamp ?? "1"
                            
                            messageManager.syncConversations(
                                timestamp: last_time_synced
                            ) { result in
                                switch result {
                                case .success(let convos):
                                    if !convos.isEmpty {
                                        Task {
                                            do {
                                                try await updateCachedConversations(convos: convos)
                                            } catch {
                                                print("Error: \(error.localizedDescription)")
                                            }
                                        }
                                    }
                                    updateLastSyncedTime()
                                case .failure(let error):
                                    print("Error: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                }
            }.background(Color("BackgroundColor"))
        }
    }
    
    func fetchSpecificConvo(conversation_id: String) -> Conversation? {
                        
        let fetchDescriptor = FetchDescriptor<Conversation>(predicate: #Predicate { convo in
            convo.conversation_id == conversation_id
        })
        
        do {
            let conversations = try context.fetch(fetchDescriptor)
            
            for convo in conversations {
                return convo
            }
        } catch {
            return nil
        }
        return nil
    }
    
    func cacheConversations(convos: [Conversation]) async throws {
                
        do {
            for i in 0..<(convos.count) {
                try await Task.sleep(for: .milliseconds(1))
                print(convos[i])
                context.insert(convos[i])
                
                try context.save()
            }
        } catch {
            print(error)
        }
    }
    
    func updateCachedConversations(convos: [Conversation]) async throws {
        do {
            for index in 0..<(convos.count) {
                
                try await Task.sleep(for: .milliseconds(1))
                
                if let foundConversation = conversations.first(where: { $0.conversation_id == convos[index].conversation_id }) {
                    let cached_convo = foundConversation
                    cached_convo.last_message = convos[index].last_message
                    cached_convo.last_message_timestamp = convos[index].last_message_timestamp
//                    cached_convo.last_message_read = convos[index].last_message_read
                    cached_convo.last_message_from = convos[index].last_message_from
                } else {
                    context.insert(convos[index])
                }
                
            }
        } catch {
            print(error)
        }
    }
    
    func cacheMessages(messages: [Messages]) async throws {
                
        do {
            for i in 0..<(messages.count) {
                try await Task.sleep(for: .milliseconds(1))
                context.insert(messages[i])
                
                try context.save()
            }
        } catch {
            print(error)
        }
    }
    
    func updateCachedMessages(messages: [Messages]) async throws {
                
        do {
            for i in 0..<(messages.count) {
                try await Task.sleep(for: .milliseconds(1))
                context.insert(messages[i])
                
                try context.save()
            }
        } catch {
            print(error)
        }
    }
    
    func updateLastSyncedTime() {
        
        let timestamp = "\(getCurrentTimestamp())"
        
        if last_synced_times.isEmpty {
            context.insert(
                SyncedTimes(
                    last_conversation_synced_timestamp: timestamp,
                    last_messages_synced_timestamp: timestamp
                )
            )
        } else {
            last_synced_times.first?.last_conversation_synced_timestamp = timestamp
            last_synced_times.first?.last_messages_synced_timestamp = timestamp
        }
    }
    
    func getCurrentTimestamp() -> TimeInterval {
        return Date().timeIntervalSince1970
    }
    
}

#Preview {
    MainActor.assumeIsolated {
        ContentView()
            .modelContainer(for: [SyncedTimes.self, Conversation.self, Messages.self])
    }
}


struct TestView: View {
    var body: some View {
        VStack {
            Text("hello")
        }
    }
}
