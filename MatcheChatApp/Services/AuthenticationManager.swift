//
//  AuthenticationManager.swift
//  Matché
//
//  Created by Andre Maytorena on 05/01/2024.
//

import SwiftUI

class AuthenticationManager: ObservableObject {
    
    // -1 = loading
    // 0 static
    // 1 found
    // 2 error
    
    @Published var isLoggedIn = false
    
    @Published var checkAccountExistsErrorMessage = ""
    
    @Published var validEmail = true
    
    //loginService
    @Published var incorrectPassword = false
    @Published var loginErrorMessage = ""
    
    @Published var addAdditionalUserData = false
    
    //create account service
    @Published var createdAccount = false
    @Published var createAccountErrorMessage = ""
    @Published var userNameAvailable = true
    
    @Published var createAccountMode = false
    @Published var loginMode = false
    
    @Published var serverError = false
    
    // Perform login actions
    func login() {
        DispatchQueue.main.async {
            self.isLoggedIn = true
        }
    }

    // Perform logout actions
    func logout() {
        DispatchQueue.main.async {
            self.isLoggedIn = false
        }
    }
        
}


class AuthenticationModel: ObservableObject {
    
    @State private var authToken = UserDefaults.standard.string(forKey: "jwtToken")
    
    @Published var authenticationResult: String? = nil
    @Published var userId: String = ""
    
    func authenticationRequest(completion: @escaping (String?) -> Void) {
        let url = URL(string: Constants.baseURL + "/api/ios/auth/verify_token")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(authToken ?? "", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard error == nil else {
                print("Error: \(error!.localizedDescription)")
                return
            }
            guard let data = data else {
                print("No data returned")
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let status = json["status"] as? String, let user_id = json["user_id"] as? String, status == "authorized" {
                        self?.userId = user_id
                        self?.saveUserId()
                        completion("authorized")
                    } else {
                        UserDefaults.standard.removeObject(forKey: "jwtToken")
                        completion("unauthorized")
                    }
                }
            }
            catch {
                print("Error parsing JSON: \(error)")
                completion("unauthorized")
            }
        }.resume()
    }
    
    func saveUserId() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(userId, forKey: "userId")
    }
}

