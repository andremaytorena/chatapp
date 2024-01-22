import SwiftUI
import SocketIO
import SwiftData

class SocketConnecterManager: ObservableObject {
    
    static let shared = SocketConnecterManager()
    @ObservedObject var userDataManager = UserDataManager.shared
    
    private var manager: SocketManager?
    var socket: SocketIOClient?
    private var token: String?

    @Published var other_participant_id = ""
    @Published var conversation_id = ""
    
    @Published var socketConnected = false
    
    @Published var messages: [Messages] = []
            
    func initializeSocketConnection() {
        let token = ""

        self.manager = SocketManager(socketURL: URL(string: Constants.baseURL)!, config: [.log(false), .compress, .connectParams(["token": token])])
        self.socket = self.manager?.defaultSocket

        connect()
    }
    
    func setupHandlers(conversations: [Conversation], context: ModelContext) {
        
        socket?.on(clientEvent: .connect) { [weak self] data, ack in
            print("connected to socketio")
            self?.socketConnected = true
        }
        
        socket?.on("receive_message") { data, ack in
            guard let messageDict = data.first as? [String: Any] else { return }

            do {
                let jsonData = try JSONSerialization.data(withJSONObject: messageDict, options: [])
                let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]

                if let messageJson = jsonObject?["message"] as? [String: Any], let new_conversation_received = jsonObject?["new_conversation"] as? Bool, let newConversationJson = jsonObject?["conversation_data"] as? [String: Any] {
                    let messageData = try JSONSerialization.data(withJSONObject: messageJson, options: [])
                    let message = try JSONDecoder().decode(Messages.self, from: messageData)
                    
                    print("RECEIVED MESSAGE")
                    DispatchQueue.main.async {
                        context.insert(message) // Inserts message sent/received
                    }
                    
                    if new_conversation_received {
                        print("inserting new doc")
                        let newConversationData = try JSONSerialization.data(withJSONObject: newConversationJson, options: [])
                        let conversation = try JSONDecoder().decode(Conversation.self, from: newConversationData)
                        context.insert(conversation)
                    }

                    if let conversation = conversations.first(where: { $0.conversation_id == message.conversation_id }) {
                        conversation.last_message = message.encrypted_text
                        conversation.last_message_timestamp = message.timestamp
                        conversation.last_message_from = message.sender_id
                    }
                } else {
                    print("No 'message' object found in JSON.")
                }
            } catch {
                print("Error decoding message:", error)
            }
        }
        
        socket?.on("receive_message_out_of_conversation") { data, ack in
            guard let messageDict = data.first as? [String: Any] else { return }

            do {
                let jsonData = try JSONSerialization.data(withJSONObject: messageDict, options: [])
                let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]

                if let messageJson = jsonObject?["message"] as? [String: Any], let new_conversation_received = jsonObject?["new_conversation"] as? Bool, let newConversationJson = jsonObject?["conversation_data"] as? [String: Any] {
                    let messageData = try JSONSerialization.data(withJSONObject: messageJson, options: [])
                    let message = try JSONDecoder().decode(Messages.self, from: messageData)

                    DispatchQueue.main.async {
                        context.insert(message) // Inserts message sent/received
                    }
                    
                    if new_conversation_received {
                        print("inserting new doc")
                        let newConversationData = try JSONSerialization.data(withJSONObject: newConversationJson, options: [])
                        let conversation = try JSONDecoder().decode(Conversation.self, from: newConversationData)
                        context.insert(conversation)
                    }

                    if let conversation = conversations.first(where: { $0.conversation_id == message.conversation_id }) {
                        conversation.last_message = message.encrypted_text
                        conversation.last_message_timestamp = message.timestamp
                        conversation.last_message_from = message.sender_id
                    }
                } else {
                    print("No 'message' object found in JSON.")
                }
            } catch {
                print("Error decoding message:", error)
            }
        }
        
        socket?.on("room_joined") { [weak self] data, ack in
            print("joined room")
            if let roomInfo = data.first as? [String: Any],
               let otherParticipantID = roomInfo["other_participant_id"] as? String, let conversationID = roomInfo["conversation_id"] as? String, let lastMessageReadStatus = roomInfo["lastMessageReadStatus"] as? Bool {
                self?.other_participant_id = otherParticipantID
                self?.conversation_id = conversationID
                                
                if !lastMessageReadStatus {
                    print("modifying var")
                    if let foundConversation = conversations.first(where: { $0.conversation_id == self?.conversation_id }) {
                        print("setting to true")
//                        foundConversation.last_message_read = true
                    }
                }
            }
        }

        socket?.on(clientEvent: .disconnect) { [weak self] data, ack in
            print("Socket disconnected")
            self?.socketConnected = false
            self?.handleDisconnection()
        }
        
        socket?.on(clientEvent: .error) { [weak self] data, ack in
            self?.socketConnected = false
            if let error = data.first as? Error {
                print("Socket error: \(error.localizedDescription)")
            } else {
                print("An unknown socket error occurred")
            }
            self?.handleDisconnection()
        }
    }
    
    func handleDisconnection() {
        // Implement reconnection logic here
        // For example, you might want to retry the connection after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { // 5-second delay
            self.connect()
        }
    }
    
    func connect() {
        guard self.socket != nil else {
            print("Socket is not initialized.")
            return
        }
        self.socket?.connect()
    }
    
    func disconnect() {
        guard self.socket != nil else {
            print("Socket is not initialized.")
            return
        }
        self.socket?.disconnect()
    }
    
    func joinRoom(conversationID: String, lastMessageReadStatus: Bool) {
        print("joining room")
        self.socket?.emit("join_room", ["conversation_id": conversationID, "lastMessageReadStatus": lastMessageReadStatus])
    }
    
    func leaveRoom(conversationID: String) {
        self.socket?.emit("leave_room", ["conversation_id": conversationID])
        self.conversation_id = ""
        print("left room")
    }
    
    func sendMessage(messageStructure: Messages, conversation: Conversation, senderName: String, senderId: String, newConversation: Bool) {
        
        if let conversationJSON = conversation.toJSON() {
            self.socket?.emit("send_message", [
                "message_id": messageStructure.message_id,
                "conversation_id": messageStructure.conversation_id,
                "participant_ids": conversationJSON["participant_ids"], // Extracted from JSON
                "encrypted_text": messageStructure.encrypted_text,
                "timestamp": messageStructure.timestamp,
                "replied_to": messageStructure.replied_to,
                "sender_name": senderName,
                "new_conversation": newConversation
            ])
        } else {
            print("Failed to serialize Conversation object")
        }
    }
    
    func getCurrentTimestamp() -> TimeInterval {
        return Date().timeIntervalSince1970
    }
    
}

extension Conversation {
    func toJSON() -> [String: Any]? {
        do {
            let data = try JSONEncoder().encode(self)
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            return jsonObject as? [String: Any]
        } catch {
            print("Error encoding Conversation to JSON: \(error)")
            return nil
        }
    }
}
