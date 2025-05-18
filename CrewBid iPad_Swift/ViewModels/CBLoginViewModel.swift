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
    var formatter:((String) ->String)?
    
    func checkLogin(userID: String, password: String, empNum: String, month: Int, year: Int, round: Int) {
        GlobalBidInfo.shared.userid = userID
        GlobalBidInfo.shared.password = password
        GlobalBidInfo.shared.employeeNumber = empNum
        GlobalBidInfo.shared.month = month
        GlobalBidInfo.shared.year = year
        GlobalBidInfo.shared.round = round
        
        APIService.shared.getPreLogonCredential(from: EndPoint.shared.thirdpartyURL) {[weak self] result in
            switch result{
            case .success(let response):
                guard let self = self else {return}
                guard let formatter = self.formatter else {
                    return
                }
                let preLogonCredential = formatter(response)
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
}
