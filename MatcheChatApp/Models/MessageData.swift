
import SwiftUI
import SwiftData

@Model
class SyncedTimes {
    var last_conversation_synced_timestamp: String
    var last_messages_synced_timestamp: String
    
    init(last_conversation_synced_timestamp: String, last_messages_synced_timestamp: String) {
        self.last_conversation_synced_timestamp = last_conversation_synced_timestamp
        self.last_messages_synced_timestamp = last_messages_synced_timestamp
    }
}


@Model
class Messages: Decodable {
    @Attribute(.unique) var message_id: String
    var conversation_id: String
    var sender_id: String
    var encrypted_text: String
    var timestamp: String
    var replied_to: String
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        message_id = try container.decode(String.self, forKey: .message_id)
        conversation_id = try container.decode(String.self, forKey: .conversation_id)
        sender_id = try container.decode(String.self, forKey: .sender_id)
        encrypted_text = try container.decode(String.self, forKey: .encrypted_text)
        timestamp = try container.decode(String.self, forKey: .timestamp)
        replied_to = try container.decode(String.self, forKey: .replied_to)
    }
    
    // Custom initializer can coexist if you need it for other purposes.
    init(message_id: String, conversation_id: String, sender_id: String, encrypted_text: String, timestamp: String, replied_to: String) {
        self.message_id = message_id
        self.conversation_id = conversation_id
        self.sender_id = sender_id
        self.encrypted_text = encrypted_text
        self.timestamp = timestamp
        self.replied_to = replied_to
    }

    private enum CodingKeys: String, CodingKey {
        case message_id
        case conversation_id
        case sender_id
        case encrypted_text
        case timestamp
        case replied_to
    }
}

@Model
class Conversation: Decodable, Encodable {
    @Attribute(.unique) var conversation_id: String
    var current_participant_id: String
    var participant_ids: [String: Participant]
    var last_message: String
    var last_message_timestamp: String
    var last_message_read: [String: Bool]
    var last_message_from: String
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(conversation_id, forKey: .conversation_id)
        try container.encode(current_participant_id, forKey: .current_participant_id)
        try container.encode(participant_ids, forKey: .participant_ids)
        try container.encode(last_message, forKey: .last_message)
        try container.encode(last_message_timestamp, forKey: .last_message_timestamp)
        try container.encode(last_message_read, forKey: .last_message_read)
        try container.encode(last_message_from, forKey: .last_message_from)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        conversation_id = try container.decode(String.self, forKey: .conversation_id)
        current_participant_id = try container.decode(String.self, forKey: .current_participant_id)
        participant_ids = try container.decode([String: Participant].self, forKey: .participant_ids)
        last_message = try container.decode(String.self, forKey: .last_message)
        last_message_timestamp = try container.decode(String.self, forKey: .last_message_timestamp)
        last_message_read = try container.decode([String: Bool].self, forKey: .last_message_read)
        last_message_from = try container.decode(String.self, forKey: .last_message_from)
    }
    
    // Custom initializer can coexist if you need it for other purposes.
    init(conversation_id: String, current_participant_id: String, participant_ids: [String: Participant], last_message: String, last_message_timestamp: String, last_message_read: [String: Bool], last_message_from: String) {
        self.conversation_id = conversation_id
        self.current_participant_id = current_participant_id
        self.participant_ids = participant_ids
        self.last_message = last_message
        self.last_message_timestamp = last_message_timestamp
        self.last_message_read = last_message_read
        self.last_message_from = last_message_from
    }

    private enum CodingKeys: String, CodingKey {
        case conversation_id
        case current_participant_id
        case participant_ids
        case last_message
        case last_message_timestamp
        case last_message_read
        case last_message_from
    }
}

struct Participant: Hashable, Codable {
    var name: String
    var profile_picture: String
}

struct ReadStatus: Hashable, Codable {
    var status: Bool
}

struct UnreadMessages: Hashable, Codable {
    let conversation_id: String
    var last_message_read: Bool
    let last_message_from: String
}
