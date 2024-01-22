//
//  Testings.swift
//  MatcheChatApp
//
//  Created by Andre Maytorena on 31/12/2023.
//

import SwiftUI

struct BackButtonView: View {
    var body: some View {
        
        Circle()
            .frame(height: 30)
            .foregroundStyle(.clear)
            .overlay {
                Image(systemName: "chevron.backward")
                    .resizable()
                    .scaledToFit() // Maintain original aspect ratio
                    .frame(width: 15, height: 20) // Adjust the frame size as needed
                    .foregroundStyle(.black)
                    .offset(x:-1)
            }
//            .padding(.leading, 10)
    }
}

//
//ZStack(alignment: .bottomTrailing) {
//    TextField("Message...", text: $messageText, axis: .vertical)
//        .padding(12)
//        .padding(.trailing, 48)
//        .background(Color(.systemGroupedBackground))
//        .clipShape(RoundedRectangle(cornerRadius: 25))
//        .font(.subheadline)
//    
//    if messageText != "" {
//        Button {
//            
//        } label: {
//            RoundedRectangle(cornerRadius: 25)
//                .frame(width: 55, height: 35)
//                .foregroundColor(Color(hex: 0xD4AF37))
//                .overlay {
//                    Image(systemName: "paperplane.fill")
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 20)
//                        .foregroundColor(.white)
//                }
//        }
//        .padding(.trailing, 5)
//        .padding(.bottom, 5)
//    }
//}
//.animation(.easeInOut(duration: 0.1), value: messageText)
//.padding(.horizontal, 5)
//.padding(.bottom, 10)
