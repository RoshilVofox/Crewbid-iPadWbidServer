//
//  CBLoginViewModel.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 18/05/25.
//

import Foundation

class CBLoginViewModel{

//    var onLoginSuccess:((String) ->Void)?
//    var onLoginFailure:((NetworkError) ->Void)?
//
//    
//    func checkLogin(userID: String, password: String) {
//
//        self.saveSelectionToUserDefaults()
//        APIService.shared.getPreLogonCredential(from: EndPoint.shared.thirdpartyURL) {[weak self] result in
//            switch result{
//            case .success(let response):
//                guard let self = self else {return}
//                let preLogonCredential = stringFormatter(response)
//                APIService.shared.getSessionCredential(urlString: EndPoint.shared.thirdpartyURL, credentials: preLogonCredential, userID: userID, password: password){ result in
//                    DispatchQueue.main.async {
//                        switch result{
//                        case .success(let sessionKey):
//                            self.onLoginSuccess?(sessionKey)
//                        case .failure(let error):
//                            self.onLoginFailure?(error)
//                        }
//                    }
//                }
//            case .failure(let error):
//                DispatchQueue.main.async {
//                    self?.onLoginFailure?(error)
//                }
//            }
//            
//        }
//    }
    
    var onLoginSuccess: ((String) -> Void)?
    var onLoginFailure: ((Errors) -> Void)?

    func checkLogin(userID: String, password: String) {
        saveSelectionToUserDefaults()
        // 1. Get PreLogon Credential
        APIService.shared.fetch(
            urlString: EndPoint.shared.thirdpartyURL,
            parse: { data in
                guard let responseString = String(data: data, encoding: .utf8) else {
                    throw Errors.decodingError
                }
                return self.stringFormatter(responseString)
            },
            completion: { [weak self] result in
                switch result {
                case .success(let preLogonCredential):
                    // 2. Use PreLogon Credential to request Session Key
                    self?.requestSessionKey(
                        userID: userID,
                        password: password,
                        credentials: preLogonCredential
                    )
                case .failure(let error):
                    DispatchQueue.main.async {
                        self?.onLoginFailure?(error)
                    }
                }
            }
        )
    }

    private func requestSessionKey(userID: String, password: String, credentials: String) {
        guard let escapedPwd = stringByAddingPercentEscapes(to: password) else {
            onLoginFailure?(.decodingError)
            return
        }
        let postString = "CREDENTIALS=\(credentials)&REQUEST=LOGON&UID=\(userID)&PWD=\(escapedPwd)"
        guard let postData = postString.data(using: .utf8, allowLossyConversion: true) else {
            onLoginFailure?(.decodingError)
            return
        }
        APIService.shared.fetch(
            urlString: EndPoint.shared.thirdpartyURL,
            method: .POST,
            body: postData,
            headers: ["Content-Type": "application/x-www-form-urlencoded",
                        "Content-Length": String(postData.count)],
            parse: { data in
                guard let responseString = String(data: data, encoding: .utf8) else {
                    throw Errors.noData
                }
                if responseString.contains("BADCREDENTIALS")
                    || responseString.uppercased().contains("LOGIN FAILED")
                    || responseString.contains("AUTHENTICATION FAILED") {
                    throw Errors.unauthorized
                }
                return responseString
            },
            completion: { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let sessionKey):
                        self?.onLoginSuccess?(sessionKey)
                    case .failure(let error):
                        self?.onLoginFailure?(error)
                    }
                }
            }
        )
    }
    // MARK: - Helpers
    private func stringByAddingPercentEscapes(to unescapedString: String) -> String? {
        let allowedCharacterSet = CharacterSet(charactersIn: ";/?:@&=+$,").inverted
        return unescapedString.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)
    }
    
    
    
    private func stringFormatter(_ string: String) -> String {
        var encodedString = string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        encodedString = encodedString.replacingOccurrences(of: "+", with: "%2B")
        return encodedString
    }
    
    private func saveSelectionToUserDefaults(){
        UserDefaults.standard.set(GlobalBidInfo.shared.base, forKey: kCBCrewBaseDefaultKey)
        UserDefaults.standard.set(GlobalBidInfo.shared.position.rawValue, forKey: kCBCrewPositionTypeDefaultKey)
        UserDefaults.standard.set(GlobalBidInfo.shared.employeeNumber, forKey: kCBEmployeeNumberDefaultKey)
        UserDefaults.standard.set(GlobalBidInfo.shared.round, forKey: kCBCrewRoundTypeDefaultKey)
    }
}
