import SwiftUI
import UIKit
import Combine
import CryptoKit

struct DragMessageView: View {
    
    var message: String
    var messageId: String
    var replied_to: String
    var fromCurrentUser: Bool
    var messages: [Messages]
    var conversation: Conversation
    @Binding var replyMessage: String
    @Binding var replyMessageId: String
    @Binding var replyMessageName: String
    @State private var dragDistance: CGFloat = 0
    
    @State private var hasFeedbackTriggered: Bool = false
    
    var CHAT_API_KEY = "Y4RdRnh^5c@K7TcZtQcZ%3*rF#5&zp8#"
    
    var body: some View {
        
        HStack {
            if fromCurrentUser {
                Spacer()
                VStack(alignment: .trailing) {
                    if let foundMessageReply = messages.first(where: { $0.message_id == self.replied_to }) {
                        
                        let keyData = Data(CHAT_API_KEY.utf8)
                        let key = SymmetricKey(data: keyData)
                        
                        if let decryptedMessage = decrypt(encryptedMessage: foundMessageReply.encrypted_text, usingKey: key) {
                            Text("You replied")
                                .font(.system(size: 14, weight: .regular))
                                .padding(.trailing, 1)
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(findParticipantName(replyMessageId: foundMessageReply.message_id))
                                        .font(.system(size: 15, weight: .medium))
                                    Text(decryptedMessage)
                                        .font(.subheadline)
                                }
                                .padding(12)
                                .background(Color(.systemGray5).opacity(0.4))
                                .foregroundColor(Color("TextColor"))
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                .frame(maxWidth: UIScreen.main.bounds.width / 1.5, alignment: .trailing)
                                
                                
                                RoundedRectangle(cornerRadius: 5)
                                    .frame(width: 5)
                                    .foregroundColor(Color("GoldAccentColor"))
                            }
                        }
                    }
                    Text(message)
                        .font(.subheadline)
                        .padding(12)
                        .background(Color(.systemBlue))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .frame(maxWidth: UIScreen.main.bounds.width / 1.5, alignment: .trailing)
                }
            } else {
                VStack {
                    
                    Text(message)
                        .font(.subheadline)
                        .padding(12)
                        .background(Color(.systemGray5))
                        .foregroundColor(Color("TextColor"))
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .frame(maxWidth: UIScreen.main.bounds.width / 1.75, alignment: .leading)
                        .offset(x: dragDistance)
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    
                                    let xOff = gesture.translation.width
                                    if xOff > 0 {
                                        let limit: CGFloat = 200        // the less the faster resistance
                                        let yOff = gesture.translation.height
                                        let dist = sqrt(xOff*xOff + yOff*yOff);
                                        let factor = 1 / (dist / limit + 1)
                                        self.dragDistance = xOff * factor
                                    }
                                    
                                    if self.dragDistance > 80 && !hasFeedbackTriggered {
                                        triggerHapticFeedback()
                                        hasFeedbackTriggered = true
                                    }
                                    
                                }
                                .onEnded { gesture in
                                    if self.dragDistance > 80 {
                                        //                                        self.isReplyActive = true
                                        withAnimation {
                                            self.replyMessage = message
                                        }
                                        self.replyMessageId = messageId
                                        self.replyMessageName = findParticipantName(replyMessageId: replyMessageId)
                                    }
                                    withAnimation(.bouncy) {
                                        self.dragDistance = 0 // Reset drag distance
                                    }
                                    self.hasFeedbackTriggered = false
                                }
                        )
                        .background(
                            HStack {
                                Image(systemName: "arrowshape.turn.up.left.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                    .opacity(Double(dragDistance / 80)) // Opacity increases as user drags
                                    .foregroundColor(.gray)
                                    .animation(.easeIn, value: dragDistance)
                                    .padding(.leading, 10)
                                Spacer()
                            }
                        )
                }
                                       
                Spacer()
            }
        }.padding(.horizontal, 8)
    }
    
    func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    func findParticipantName(replyMessageId: String) -> String {
        guard let message = messages.first(where: { $0.message_id == replyMessageId}) else {
            return "" // Message not found
        }

        let senderId = message.sender_id
        
        // 3. Find the Participant in Conversation
        if let participant = conversation.participant_ids[senderId] {
            // 4. Extract the Participant's Name
            return participant.name
        } else {
            return "" // Participant not found
        }
    }
}
