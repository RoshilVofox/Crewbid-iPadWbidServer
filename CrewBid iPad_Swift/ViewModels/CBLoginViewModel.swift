//
//  CBLoginViewModel.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 18/05/25.
//

import Foundation

class CBLoginViewModel{

    var onLoginSuccess:((String) ->Void)?
    var onLoginFailure:((NetworkError) ->Void)?

    
    func checkLogin(userID: String, password: String, empNum: String) {

        self.saveSelectionToUserDefaults()
        APIService.shared.getPreLogonCredential(from: EndPoint.shared.thirdpartyURL) {[weak self] result in
            switch result{
            case .success(let response):
                guard let self = self else {return}
                let preLogonCredential = stringFormatter(response)
                APIService.shared.getSessionCredential(urlString: EndPoint.shared.thirdpartyURL, credentials: preLogonCredential, userID: userID, password: password){ result in
                    DispatchQueue.main.async {
                        switch result{
                        case .success(let sessionKey):
                            self.onLoginSuccess?(sessionKey)
                        case .failure(let error):
                            self.onLoginFailure?(error)
                        }
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.onLoginFailure?(error)
                }
            }
            
        }
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
