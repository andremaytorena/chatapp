//
//  MessageInboxView.swift
//  Matché
//
//  Created by Andre Maytorena on 05/01/2024.
//

import SwiftUI
import CryptoKit
import SwiftData

struct MessageInboxView: View {
    
    @Environment(\.modelContext) var context
        
    @ObservedObject var socketManager = SocketConnecterManager.shared
        
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var userDataManager = UserDataManager.shared
        
    @ObservedObject var messageManager = MessageManager.shared
    
    @State private var searchNewUserSheet = false
    @State private var redirectToNewConversation = false
    @State private var createdNewConvo: Bool = false
    @State private var chosen_user_id = ""
    @State private var chosen_full_name = ""
    @State private var chosen_username = ""
    @State private var chosen_profile_picture = ""
    
    @State private var loadingStatus = false
    
    @State private var last_message_read = false
    
    var conversations: [Conversation]
    
    @State private var firstLoad = false
    
    @State private var searchText = ""
    
    @State private var filteredConversations: [Conversation] = []
    
    func filterConversations() {
           filteredConversations = conversations.filter { convo in
               // Find if any participant (other than the user) matches the search text
               return convo.participant_ids.contains(where: { (participantID, participant) in
                   participantID != userDataManager.userData.user_id && participant.name.localizedCaseInsensitiveContains(searchText)
               })
           }
       }


    var body: some View {
        
        NavigationView {
            ZStack {
                Color("BackgroundColor").ignoresSafeArea()
                VStack {
                    
                    if !loadingStatus && conversations.isEmpty {
                        NoMessagesSent()
                    }
                                            
                    if loadingStatus {
                        Spacer()
                        Text("Loading..")
                    } else {
                        if searchText == "" {
                            ScrollView {
                                ForEach(conversations, id: \.self) { convo in
                                    
                                    NavigationLink {
                                        SocketMessageUserView(conversation: convo, other_participant_id: "",
                                                              other_participant_name: "",
                                                              other_participant_profile_picture: "")
                                        .navigationBarBackButtonHidden(true)
                                    } label: {
                                        InboxRowViewRestructure(convo: convo)
                                    }
                                }
                            }
                        } else {
                            ScrollView {
                                ForEach(filteredConversations, id: \.self) { convo in
                                    
                                    NavigationLink {
                                        SocketMessageUserView(conversation: convo, other_participant_id: "",
                                                              other_participant_name: "",
                                                              other_participant_profile_picture: "")
                                        .navigationBarBackButtonHidden(true)
                                    } label: {
                                        InboxRowViewRestructure(convo: convo)
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .searchable(text: $searchText, placement: .automatic) //
            .onChange(of: searchText) { searchText, new in
                filterConversations()
            }
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        searchNewUserSheet.toggle()
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25)
                            .bold()
                    }
//                    .disabled(!authManager.isLoggedIn)
                }
            }
        }
    }
    
    func dismissedSearchUser() {
        if createdNewConvo == true {
            redirectToNewConversation = true
        }
        createdNewConvo = false
    }
    
    @ViewBuilder
    func NoMessagesSent() -> some View {
        
        VStack {
            
            Spacer()
            
            Image(systemName: "message")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .bold()
            
            Text("Message your friends and coaches")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color("TextColor"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 75)
                .padding(.top, 5)
            
            Text("Tap the + icon to send a message or setup a group.")
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(Color("TextColor"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 50)
                .padding(.top, 1)
        }.padding(.top, 30)
        
    }
    
}

struct InboxRowViewRestructure: View {
    
    var convo: Conversation
    
    var CHAT_API_KEY = "Y4RdRnh^5c@K7TcZtQcZ%3*rF#5&zp8#"
    
    @ObservedObject var userDataManager = UserDataManager.shared
        
    var body: some View {
        
        HStack(alignment: .top, spacing: 12) {
            
            getProfilePicture()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(getConversationNames(convo: convo))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("GoldAccentColor"))
                
                HStack {
                    
                    if !getMessageReadStatus() {
                        Circle()
                            .foregroundColor(.blue)
                            .frame(width: 5, height: 5)
                    }
                    
                    let keyData = Data(CHAT_API_KEY.utf8)
                    let key = SymmetricKey(data: keyData)
                    
                    if let decryptedMessage = decrypt(encryptedMessage: convo.last_message, usingKey: key) {
                        Text(decryptedMessage)
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                            .lineLimit(2)
                            .frame(maxWidth: UIScreen.main.bounds.width - 100, alignment: .leading)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            
            HStack {
                let dayString = dayStringFromTimestamp(currentTime: Date().timeIntervalSince1970, timestamp: Double(convo.last_message_timestamp) ?? 0.0)

                Text(dayString)
                Image(systemName: "chevron.right")
            }
            .font(.footnote)
            .foregroundColor(.gray)
        }
        .frame(height: 72)
        .padding(.horizontal)
    }
    
    func getConversationNames(convo: Conversation) -> String {
        if convo.participant_ids.count == 2 {
            for (participantID, participant) in convo.participant_ids {
                if participantID != userDataManager.userData.user_id {
                    let otherParticipantName = participant.name
                    return otherParticipantName
                }
            }
            return ""
        } else {
            var otherParticipantNames = ""
            for (participantID, participant) in convo.participant_ids {
                if participantID != userDataManager.userData.user_id {
                    if otherParticipantNames == "" {
                        otherParticipantNames += participant.name
                    } else {
                        otherParticipantNames += ", " + participant.name
                    }
                }
            }
            return otherParticipantNames
        }
    }
    
    func getProfilePicture() -> some View {
        if convo.participant_ids.count == 2 {
            for (participantID, participant) in convo.participant_ids {
                if participantID != userDataManager.userData.user_id {
                    let otherParticipantProfilePicture = participant.profile_picture
                                        
                    return AnyView(
                        AsyncImage(url: URL(string: otherParticipantProfilePicture)) { image in
                            image.resizable()
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 64, height: 64)
                                .foregroundColor(Color(.systemGray4))
                        }
                        .frame(width: 64, height: 64)
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                        .clipShape(
                            Circle()
                        )
                    )
                }
            }
        }
        return AnyView(
            Image(systemName: "person.2.circle.fill")
                .resizable()
                .frame(width: 64, height: 64)
                .foregroundColor(Color(.systemGray4))
            )
    }
    
    func getMessageReadStatus() -> Bool {
        if convo.last_message_from == userDataManager.userData.user_id {
            return true
        } else {
            return convo.last_message_read[userDataManager.userData.user_id] ?? true
        }
    }
    
    func dayStringFromTimestamp(currentTime: TimeInterval, timestamp: TimeInterval) -> String {
        let targetDate = Date(timeIntervalSince1970: timestamp)

        let calendar = Calendar.current

        if calendar.isDateInToday(targetDate) {
                return "Today"
            } else if calendar.isDateInYesterday(targetDate) {
                return "Yesterday"
            } else {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "EEEE"  // Day name format (e.g., Monday, Tuesday, etc.)
                return dateFormatter.string(from: targetDate)
            }
    }
}

#Preview {
    MainActor.assumeIsolated {
        ContentView()
            .modelContainer(for: [SyncedTimes.self, Conversation.self, Messages.self])
    }
}
