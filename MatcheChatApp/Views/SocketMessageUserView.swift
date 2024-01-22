//
//  WebSocketUserView.swift
//  Matche
//
//  Created by Andre Maytorena on 08/01/2024.
//

import SwiftUI
import SocketIO
import UIKit
import CryptoKit
import Combine
import SwiftData

struct InnerHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct SocketMessageUserView: View, KeyboardReadable {
    
    @Environment(\.modelContext) var context
    
    @ObservedObject var socketManager = SocketConnecterManager.shared
    @ObservedObject var userDataManager = UserDataManager.shared
    @ObservedObject var messageManager = MessageManager.shared
        
    @Environment(\.presentationMode) var presentationMode
    @State private var screenWidth = UIScreen.main.bounds.width
        
    var CHAT_API_KEY = "Y4RdRnh^5c@K7TcZtQcZ%3*rF#5&zp8#"
    
    @State var showActionSheet = false
    @State private var displayMatchSheet = false
    @State private var sheetHeight: CGFloat = .zero
    
    @State private var selectedSport = ""
    
    @State private var messageText = ""
        
    @State private var dragDistance: CGFloat = 0
    @State private var isReplyActive: Bool = false
    @State private var replyMessage = ""
    @State private var replyMessageId = ""
    @State private var replyMessageName = ""
    
    @State private var isKeyboardVisible = false
    
    @State private var loadingState = false
            
    @State private var current_conversation: Conversation
    @State private var current_conversation_id: String = ""
    
    var other_participant_id: String = ""
    var other_participant_name: String = ""
    var other_participant_profile_picture: String = ""
    
    @State private var newConversation = false
    
    var conversation: Conversation
    
    
    
    init(conversation: Conversation, other_participant_id: String, other_participant_name: String, other_participant_profile_picture: String) {
        self.conversation = conversation
        _current_conversation_id = State(initialValue: conversation.conversation_id)
        _current_conversation = State(initialValue: conversation)
            
        self.other_participant_id = other_participant_id
        self.other_participant_name = other_participant_name
        self.other_participant_profile_picture = other_participant_profile_picture
    }
        
    var body: some View {
        
        NavigationView {
            
            ZStack {
                
                Color("BackgroundColor").ignoresSafeArea()
                
                VStack {
                    
                    if loadingState {
                        Text("Loading")
                    } else {
                        ScrollMessagesView(conversation: current_conversation, replyMessage: $replyMessage, replyMessageId: $replyMessageId, replyMessageName: $replyMessageName)
                    }
            
                    Spacer()
                    
                    if replyMessage != "" {
                        replyToBoxMessage(message: replyMessage)
                    }
                    
                    HStack(alignment: .center, spacing: 0) {

                        TextField("Message...", text: $messageText, axis: .vertical)
                            .padding(.vertical, 10)
                            .padding(.leading, 15)
                            .background(Color(.systemGroupedBackground))
                            .cornerRadius(30)
                            .padding(.leading, 10)
                            .padding(.trailing, messageText != "" ? 5 : 10)
                            .font(.subheadline)
                            .onReceive(keyboardPublisher) { newIsKeyboardVisible in
                                print("Is keyboard visible? ", newIsKeyboardVisible)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) {
                                    isKeyboardVisible = newIsKeyboardVisible
                                }
                            }
                        
                        if messageText != "" {
                            Button {
                                sendMessage()
                            } label: {
                                RoundedRectangle(cornerRadius: 25)
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(messageText != "" ? Color(hex: 0xD4AF37) : Color(hex: 0xD4AF37).opacity(0.5))
                                    .overlay {
                                        Image(systemName: "paperplane.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 20)
                                            .foregroundColor(.white)
                                    }
                            }
                            .padding(.trailing, 10)
                            .disabled(messageText == "")
                        }
                    }
                    .padding(.bottom, 10)
                    .animation(.easeInOut(duration: 0.1), value: messageText)
                    
                }
            }
            .onChange(of: socketManager.socketConnected) { oldValue, newValue in
                print("STILL CHECKING CHANGES")
                if newValue {
                    self.socketManager.joinRoom(conversationID: current_conversation_id, lastMessageReadStatus: true)
                }
            }
            .onAppear {
                if socketManager.socket == nil {
                    print("socket is nil")
                }
                if current_conversation_id != "" {
                    self.socketManager.joinRoom(conversationID: current_conversation_id, lastMessageReadStatus: true)
                } else {
                    loadingState = true
                    messageManager.findConversation(participant_id: other_participant_id) { result in
                        switch result {
                        case .success(let conversation):
                            self.current_conversation = conversation
                            self.current_conversation_id = conversation.conversation_id
                            self.socketManager.joinRoom(conversationID: current_conversation_id, lastMessageReadStatus: true)
                            loadingState = false
                        case .failure(let error):
                                                        
                            let conversation_id = UUID().uuidString
                            
                            self.current_conversation_id = conversation_id
                            
                            self.socketManager.joinRoom(conversationID: current_conversation_id, lastMessageReadStatus: true)
                                                        
                            let participant_ids = [
                                userDataManager.userData.user_id : Participant(name: userDataManager.userData.full_name, profile_picture: ""), other_participant_id : Participant(name: other_participant_name, profile_picture: other_participant_profile_picture)
                            ]
                       
                            self.current_conversation = Conversation(
                                conversation_id: conversation_id,
                                current_participant_id: userDataManager.userData.user_id,
                                participant_ids: participant_ids,
                                last_message: "",
                                last_message_timestamp: "",
                                last_message_read: [userDataManager.userData.user_id : true, other_participant_id: false],
                                last_message_from: ""
                            )
                            newConversation = true
                            loadingState = false
                            print("Error: \(error.localizedDescription)")
                        }
                    }
                }
            }
            .onDisappear {
                socketManager.leaveRoom(conversationID: current_conversation_id)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            BackButtonView()
                        }
                        
                        getProfilePicture(frameSize: 30)
                        Text(getConversationNames())
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }
    
    func sendMessage() {
                
        let keyData = Data(CHAT_API_KEY.utf8)
        let key = SymmetricKey(data: keyData)
        
        let timestamp = "\(getCurrentTimestamp())"
                                
        if let encryptedMessage = encrypt(message: messageText, usingKey: key) {
            let messageStructure = Messages(
                message_id: UUID().uuidString,
                conversation_id: current_conversation_id,
                sender_id: userDataManager.userData.user_id,
                encrypted_text: encryptedMessage,
                timestamp: timestamp,
                replied_to: replyMessageId
            )
            
            socketManager.sendMessage(
                messageStructure: messageStructure,
                conversation: current_conversation,
                senderName: userDataManager.userData.full_name,
                senderId: userDataManager.userData.user_id,
                newConversation: newConversation
            )
        }
        messageText = ""
        replyMessage = ""
        replyMessageId = ""
        replyMessageName = ""
    }
    
    @ViewBuilder
    func replyToBoxMessage(message: String) -> some View {
        
        let transition = AnyTransition.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .bottom)).combined(with: .opacity)
        
        HStack {
            Rectangle()
                .frame(width: 5, height: 50)
                .foregroundColor(Color("GoldAccentColor"))
            VStack(alignment: .leading) {
                Text(replyMessageName)
                    .font(.system(size: 17, weight: .medium))
                Text(message)
                    .font(.system(size: 16, weight: .regular))
            }
            Spacer()
            
            Button {
                withAnimation() {
                    self.replyMessage = ""
                    self.replyMessageId = ""
                    self.replyMessageName = ""
                }
            } label: {
                Image(systemName: "xmark")
                    .padding(.trailing, 10)
                    .foregroundColor(Color("TextColor"))
            }
        }
        .padding(.leading, 0)
        .transition(transition)
    }
    
    func getCurrentTimestamp() -> TimeInterval {
        return Date().timeIntervalSince1970
    }
    
    func findLastMessageReadStatus(conversationId: String, in matches: [UnreadMessages]) -> Bool? {
        return matches.first(where: { $0.conversation_id == conversationId })?.last_message_read
    }
    
    func findLastMessageFromUserId(conversationId: String, in matches: [UnreadMessages]) -> String? {
        return matches.first(where: { $0.conversation_id == conversationId })?.last_message_from
    }
    

//    func getLastMessageReadStatus(for conversationId: String) -> Bool? {
//        return conversations.first { $0.conversation_id == conversationId }?.last_message_read
//    }
    
    func getConversationNames() -> String {
        if current_conversation.participant_ids.count == 2 {
            for (participantID, participant) in current_conversation.participant_ids {
                if participantID != userDataManager.userData.user_id {
                    let otherParticipantName = participant.name
                    return otherParticipantName
                }
            }
            return ""
        } else {
            var otherParticipantNames = ""
            for (participantID, participant) in current_conversation.participant_ids {
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

    func getProfilePicture(frameSize: CGFloat) -> some View {
        if current_conversation.participant_ids.count == 2 {
            for (participantID, participant) in current_conversation.participant_ids {
                if participantID != userDataManager.userData.user_id {
                    let otherParticipantProfilePicture = participant.profile_picture
                                        
                    return AnyView(
                        AsyncImage(url: URL(string: otherParticipantProfilePicture)) { image in
                            image.resizable()
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: frameSize, height: frameSize)
                                .foregroundColor(Color(.systemGray4))
                        }
                        .frame(width: frameSize, height: frameSize)
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
                .frame(width: frameSize, height: frameSize)
                .foregroundColor(Color(.systemGray4))
            )
    }
}

struct ScrollMessagesView: View, KeyboardReadable {
    
    @ObservedObject var userDataManager = UserDataManager.shared
    
    @Query var messages: [Messages]
    var conversation: Conversation
        
    init(conversation: Conversation, replyMessage: Binding<String>, replyMessageId: Binding<String>, replyMessageName: Binding<String>) {
        self.conversation = conversation
        self._replyMessage = replyMessage
        self._replyMessageId = replyMessageId
        self._replyMessageName = replyMessageName
        let internal_conversation_id = conversation.conversation_id
        
        let predicate = #Predicate<Messages> { $0.conversation_id == internal_conversation_id}
        
        self._messages = Query(filter: predicate, sort: [SortDescriptor(\Messages.timestamp, order: .forward)])
    }
    
    @State private var isKeyboardVisible = false
    var CHAT_API_KEY = "Y4RdRnh^5c@K7TcZtQcZ%3*rF#5&zp8#"
    
    @Binding var replyMessage: String
    @Binding var replyMessageId: String
    @Binding var replyMessageName: String
    
    var body: some View {
        
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                
                VStack {
                    
                    ProfileSection()
                        .padding(.top, 20)
                    
                    let keyData = Data(CHAT_API_KEY.utf8)
                    let key = SymmetricKey(data: keyData)
                    
                    ForEach(messages, id: \.self) { msg in
                        if let decryptedMessage = decrypt(encryptedMessage: msg.encrypted_text, usingKey: key) {
                            DragMessageView(message: decryptedMessage, messageId: msg.message_id, replied_to: msg.replied_to, fromCurrentUser: userDataManager.userData.user_id == msg.sender_id, messages: messages, conversation: conversation, replyMessage: $replyMessage, replyMessageId: $replyMessageId, replyMessageName: $replyMessageName)
                                .id(msg)
                                .transition(.asymmetric(insertion: .scale, removal: .opacity))
                        }
                    }
                }
            }
            .onAppear {
                proxy.scrollTo(messages.last, anchor: nil)
            }
            .onChange(of: messages) { oldValue, newValue in
                withAnimation {
                    proxy.scrollTo(messages.last, anchor: nil)
                }
            }
            .onChange(of: isKeyboardVisible) { newValue in
                print("scrolling down")
                withAnimation(Animation.easeIn(duration: 20)) {
                    proxy.scrollTo(messages.last?.id, anchor: .bottom)
                }

            }
        }
    }
    
    @ViewBuilder
    func ProfileSection() -> some View {
        
        VStack {
            getProfilePicture(frameSize: 64)
            
            Text(getConversationNames(convo: conversation))
                .font(.title3)
                .fontWeight(.semibold)
            Text("Matché")
                .font(.footnote)
                .foregroundColor(.gray)
            Text("Do not share personal information details such as debit/credit cards.")
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(.horizontal, 65)
                .padding(.top, 5)
                .multilineTextAlignment(.center)
        }
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
    
    func getProfilePicture(frameSize: CGFloat) -> some View {
        if conversation.participant_ids.count == 2 {
            for (participantID, participant) in conversation.participant_ids {
                if participantID != userDataManager.userData.user_id {
                    let otherParticipantProfilePicture = participant.profile_picture
                                        
                    return AnyView(
                        AsyncImage(url: URL(string: otherParticipantProfilePicture)) { image in
                            image.resizable()
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: frameSize, height: frameSize)
                                .foregroundColor(Color(.systemGray4))
                        }
                        .frame(width: frameSize, height: frameSize)
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
                .frame(width: frameSize, height: frameSize)
                .foregroundColor(Color(.systemGray4))
            )
    }
}

protocol KeyboardReadable {
    var keyboardPublisher: AnyPublisher<Bool, Never> { get }
}

extension KeyboardReadable {
    var keyboardPublisher: AnyPublisher<Bool, Never> {
        Publishers.Merge(
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillShowNotification)
                .map { _ in true },
            
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in false }
        )
        .eraseToAnyPublisher()
    }
}

#Preview {
    MainActor.assumeIsolated {
        ContentView()
            .modelContainer(for: [Conversation.self, SyncedTimes.self, Messages.self])
    }
}

