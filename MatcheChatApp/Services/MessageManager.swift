//
//  MessagingService.swift
//  Matché
//
//  Created by Andre Maytorena on 05/01/2024.
//

import SwiftUI

class MessageManager: ObservableObject {
    
    static let shared = MessageManager()
    
    @Published var conversation: [Messages] = []
    @Published var conversation_id = ""
    
    @Published var serverError = false
        
    @Published var unread_messages: [UnreadMessages] = []
    
    func retriveUnreadMessages(
        completion: @escaping (Bool) -> Void
    ) {
        
        guard let url = URL(string: Constants.baseURL + "/api/ios/messages/fetch_unread_messages") else {
            self.serverError = true
            completion(false)
            return
        }
        
        NetworkService.shared.request(url: url, httpMethod: "GET", useAuthToken: true) { [weak self] (result: Result<[UnreadMessages], NetworkError>) in
            switch result {
                case .success(let unreadMessages):
                    self?.unread_messages = unreadMessages
                    print(unreadMessages)
                    completion(true)
                case .failure(let error):
                print(error.localizedDescription)
                    self?.serverError = true
                    completion(false)
            }
        }
    }
    
    func syncConversations(
        timestamp: String,
        completion: @escaping (Result<[Conversation], Error>) -> Void
    ) {
        
        guard let url = URL(string: Constants.baseURL + "/api/ios/messages/sync_conversations") else {
            self.serverError = true
            print("failed 1")
            completion(.failure(NetworkError.badURL))
            return
        }
        
        let parameters: [String: Any] = [
            "timestamp": timestamp,
        ]
                
        NetworkService.shared.request(url: url, httpMethod: "POST", parameters: parameters, useAuthToken: true) { [weak self] (result: Result<[Conversation], NetworkError>) in
            switch result {
                case .success(let conversations):
                    completion(.success(conversations))
                case .failure(let error):
                print(error.localizedDescription)
                    self?.serverError = true
                    print("failed 2")
                    completion(.failure(error))
            }
        }
    }
    
    func changeMessageReadStatus(conversation_id: String) {
        if let index = unread_messages.firstIndex(where: { $0.conversation_id == conversation_id }) {
            unread_messages.remove(at: index)
        }
    }
    
    func retrieveAllConversationsRestructured(
//        completion: @escaping (Result<[[String: Any]], Error>) -> Void
        completion: @escaping (Result<[Conversation], Error>) -> Void
    ) {
        
        let authToken = ""
        
        let url = URL(string: Constants.baseURL + "/api/ios/messages/all_conversations_restructured")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(authToken, forHTTPHeaderField: "Authorization")
                
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard error == nil else {
                print("Error: \(error!.localizedDescription)")
                completion(.failure(error!))
                return
            }
            
            guard let data = data else {
                print("No data returned")
                completion(.failure(NetworkError.noData))
                return
            }
            
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                    if jsonArray.isEmpty {
                        DispatchQueue.main.async {
                            completion(.success([]))
                        }
                    } else {
                        let conv = try JSONDecoder().decode([Conversation].self, from: data)
                        DispatchQueue.main.async {
                            completion(.success(conv))
                        }
                    }
                }

            } catch {
                print("Error parsing JSON: \(error)")
                completion(.failure(error))
            }

        }.resume()
    }
    
    func retrieveAllMessagesRestructured(
        completion: @escaping (Result<[Messages], Error>) -> Void
    ) {
        
        let authToken = ""

        let url = URL(string: Constants.baseURL + "/api/ios/messages/all_messages_restructured")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(authToken, forHTTPHeaderField: "Authorization")
                
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard error == nil else {
                print("Error: \(error!.localizedDescription)")
                completion(.failure(error!))
                return
            }
            
            guard let data = data else {
                print("No data returned")
                completion(.failure(NetworkError.noData))
                return
            }
            
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                    if jsonArray.isEmpty {
                        DispatchQueue.main.async {
                            completion(.success([]))
                        }
                    } else {
                        let messages = try JSONDecoder().decode([Messages].self, from: data)
                        DispatchQueue.main.async {
                            print(messages)
                            completion(.success(messages))
                        }
                    }
                }

            } catch {
                print("Error parsing JSON: \(error)")
                completion(.failure(error))
            }

        }.resume()
    }
    
    func syncMessages(
        timestamp: String,
        completion: @escaping (Result<[Messages], Error>) -> Void
    ) {
        
        guard let url = URL(string: Constants.baseURL + "/api/ios/messages/sync_messages") else {
            self.serverError = true
            completion(.failure(NetworkError.badURL))
            return
        }
        
        let parameters: [String: Any] = [
            "timestamp": timestamp,
        ]
                
        NetworkService.shared.request(url: url, httpMethod: "POST", parameters: parameters, useAuthToken: true) { [weak self] (result: Result<[Messages], NetworkError>) in
            switch result {
                case .success(let messages):
                    completion(.success(messages))
                case .failure(let error):
                print(error.localizedDescription)
                    self?.serverError = true
                    print("failed 2")
                    completion(.failure(error))
            }
        }
    }
    
    func findConversation(
        participant_id: String,
        completion: @escaping (Result<Conversation, Error>) -> Void
    ) {
        
        guard let url = URL(string: Constants.baseURL + "/api/ios/messages/find_conversation") else {
            self.serverError = true
            completion(.failure(NetworkError.badURL))
            return
        }
                
        let parameters: [String: Any] = [
            "participant_id": participant_id,
        ]
        
        NetworkService.shared.request(url: url, httpMethod: "POST", parameters: parameters, useAuthToken: true) { [weak self] (result: Result<Conversation, NetworkError>) in
            switch result {
                case .success(let conversation):
                    print(conversation)
                completion(.success(conversation))
                case .failure(let convo):
                    print("error converastion")
                    self?.serverError = true
                    completion(.failure(convo))
            }
        }
    }
    
}

