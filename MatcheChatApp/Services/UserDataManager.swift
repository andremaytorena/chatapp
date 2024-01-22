
import SwiftUI
import CoreLocation

struct UserData: Codable {
    var status: String
    var user_id: String
    var email: String
    var username: String
    var profile_picture: String
    var full_name: String
    var phone_number: String
    var country: String
    var city: String
    var postcode: String
    var coachStatus: Bool
    var coachApplicationStatus: String
    var coachProfileCreated: Bool
}

class UserDataManager: ObservableObject {
    
    static let shared = UserDataManager()
    
    @Published var userDataRetrieved = false
    
    @Published var userData = UserData(
        status: "success",
        user_id: "testinguserid",
        email: "andremayto@gmail.com",
        username: "andremaytorena",
        profile_picture: "",
        full_name: "Andre Maytorena",
        phone_number: "7484885533",
        country: "United Kingdom",
        city: "London",
        postcode: "W9 1EE",
        coachStatus: false,
        coachApplicationStatus: "",
        coachProfileCreated: false
    )
    
    // I have functions here to retrieve a user's data
}

