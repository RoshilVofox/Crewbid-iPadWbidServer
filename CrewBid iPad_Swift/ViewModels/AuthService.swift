//
//  AuthService.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 18/05/25.
//

import Foundation

final class AuthService {
    static let shared = AuthService()
    private init() {}

    func checkAuthentication(empID: String,
                             onSuccess: @escaping (AuthResult) -> Void,
                             onFailure: @escaping (Errors) -> Void) {
        
        let jsonBody = buildAuthPayload(empID: empID)
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonBody, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8),
              let jsonBodyData = jsonString.data(using: .utf8) else {
            onFailure(.decodingError)
            return
        }
        
        APIService.shared.fetch(
            urlString: EndPoint.shared.GetCrewBidAuthorization,
            method: .POST,
            body: jsonBodyData,
            headers: ["Content-Type": "application/x-www-form-urlencoded"],
            parse: { data in
                guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    throw Errors.decodingError
                }
                let isAuthorized = (dict["IsAuthorized"] as? Bool) ?? false
                let isSomehowSubscribed = [
                    dict["IsCBMonthlySubscribed"] as? Bool,
                    dict["IsCBYearlySubscribed"] as? Bool,
                    dict["IsFree"] as? Bool,
                    dict["IsMonthlySubscribed"] as? Bool,
                    dict["IsYearlySubscribed"] as? Bool
                ].compactMap { $0 }.contains(true)
                
                let message = dict["Message"] as? String
                let firstname = dict["FirstName"] as? String ?? ""
                let lastname = dict["LastName"] as? String ?? ""
                let name = "\(firstname) \(lastname)"
                
                return AuthResult(isAuthorized: isAuthorized,
                                  isSomehowSubscribed: isSomehowSubscribed,
                                  message: message,
                                  empName: name)
            },
            completion: { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let authResult): onSuccess(authResult)
                    case .failure(let error):onFailure(error)
                    }
                }
            }
        )
    }
    
    private func buildAuthPayload(empID: String) -> [String: Any] {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return [
            "RequestType": "6",
            "Version": appVersion,
            "BidRound": "0",
            "Position": "",
            "EmployeeNumber": empID,
            "FromAppNumber": "5",
            "OperatingSystem": "iPad OS",
            "Month": "0",
            "Base": "",
            "Platform": "iPad"
        ]
    }
}
