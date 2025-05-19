//
//  APIService.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 18/05/25.
//

import Foundation

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case unauthorized
    case timeout
    case other(Error)
}
extension NetworkError {
    var localizedDescriptionString: String {
        switch self {
        case .invalidURL:
            return "Invalid URL."
        case .noData:
            return "No data received."
        case .decodingError:
            return "Failed to decode the response."
        case .unauthorized:
            return "Unauthorized request."
        case .timeout:
            return "Request timed out."
        case .other(let err):
            return err.localizedDescription
        }
    }
}
struct AuthResult{
    let isSomehowSubscribed:Bool
    let message:String?
}

class APIService{
    
    static let shared = APIService()
    private init() {}
    
    //MARK: Auth check for EmpID
    func checkAuthentication(bodyData: [String:Any],completion: @escaping (Result<AuthResult, NetworkError>) ->Void){
        guard let url = URL(string: EndPoint.shared.GetCrewBidAuthorization) else {
            completion(.failure(.invalidURL))
            return}
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        guard let jsonData = try? JSONSerialization.data(withJSONObject: bodyData, options: []),
        let jsonString = String(data: jsonData, encoding: .utf8),
        let jsonBody = jsonString.data(using: .utf8) else {
            completion(.failure(.decodingError))
            return}
        request.httpBody = jsonBody
        URLSession.shared.dataTask(with: request){ data, response, error in
            if let error = error{
                completion(.failure(.other(error)))
                return}
            guard let data = data, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(.failure(.noData))
                return}
            do{
                if let dict = try JSONSerialization.jsonObject(with: data) as? [String:Any]{
                    let isSomehowSubscribed = [
                        dict["IsCBMonthlySubscribed"] as? Bool,
                        dict["IsCBYearlySubscribed"] as? Bool,
                        dict["IsFree"] as? Bool,
                        dict["IsMonthlySubscribed"] as? Bool,
                        dict["IsYearlySubscribed"] as? Bool
                    ].compactMap { $0 }.contains(true)
                    let message = dict["Message"] as? String
                    let result = AuthResult(isSomehowSubscribed: isSomehowSubscribed, message: message)
                    completion(.success(result))
                }else{
                    completion(.failure(.decodingError))
                }
            }catch{
                completion(.failure(.decodingError))
            }
        }.resume()
    }
    
    //MARK: Get prelogon key
    func getPreLogonCredential(from urlString: String, completion: @escaping (Result<String, NetworkError>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return}
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(.other(error)))
                return}
            guard let data = data else {
                completion(.failure(.noData))
                return}
            if let responseString = String(data: data, encoding: .utf8) {
                completion(.success(responseString))
            } else {
                completion(.failure(.decodingError))
            }
        }.resume()
    }
    
    //MARK: Get Session key
    func getSessionCredential(urlString: String,credentials: String,userID: String,password: String,completion: @escaping (Result<String, NetworkError>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return}
        guard let escapedPwd = password.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            completion(.failure(.decodingError))
            return}
        let postString = "CREDENTIALS=\(credentials)&REQUEST=LOGON&UID=\(userID)&PWD=\(escapedPwd)"
        guard let postData = postString.data(using: .utf8, allowLossyConversion: true) else {
            completion(.failure(.decodingError))
            return}
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(String(postData.count), forHTTPHeaderField: "Content-Length")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = postData
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(.other(error)))
                return}
            if let error = error as? URLError, error.code == .timedOut {
                completion(.failure(.timeout))
                return}
            guard let data = data, let responseString = String(data: data, encoding: .utf8) else {
                completion(.failure(.noData))
                return}
            if responseString.contains("BADCREDENTIALS") ||
                        responseString.uppercased().contains("LOGIN FAILED") ||
                        responseString.contains("AUTHENTICATION FAILED") {
                        completion(.failure(.unauthorized))
                    } else {
                        completion(.success(responseString))
                    }
        }.resume()
    }
    //MARK: Downloas Bid Files
    
}
