
import SwiftUI

enum NetworkError: Error {
    case authenticationError
    case noData
    case badURL
    case randError
    case serverError
}


class NetworkService {

    static let shared = NetworkService()

    private init() {}

    func request<T: Decodable>(
        url: URL,
        httpMethod: String = "GET",
        parameters: [String: Any]? = nil,
        useAuthToken: Bool,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        if let parameters = parameters, httpMethod == "POST" {
            request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        }
        
        if useAuthToken {
            
//            guard let authToken = JWTTokenManager.shared.authToken else {
//                completion(.failure(NetworkError.authenticationError))
//                return
//            }
            
            let authToken = ""
            
            request.addValue(authToken, forHTTPHeaderField: "Authorization")
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard error == nil else {
                    completion(.failure(.noData))
                    print("failed 3")
                    return
                }

                guard let data = data else {
                    completion(.failure(.noData))
                    return
                }

                do {
                    let decodedObject = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(decodedObject))
                } catch {
                    print(error)
                    print(url)
                    completion(.failure(.noData))
                }
            }
        }.resume()
    }
}

