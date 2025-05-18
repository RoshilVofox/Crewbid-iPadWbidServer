//
//  CBDefaultEmployeeViewModel.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 18/05/25.
//

import Foundation

class CBDefaultEmployeeViewModel{

    var onAuthSuccess: ((AuthResult) -> Void)?
    var onAuthFailure: ((NetworkError) -> Void)?
    

    func checkAuthentication(empID: String){
        let jsonBody = buildAuthPayload(empID: empID)
        APIService.shared.checkAuthentication(bodyData: jsonBody, completion: { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let authResult):
                    self?.onAuthSuccess?(authResult)
                case .failure(let error):
                    self?.onAuthFailure?(error)
                }
            }
        })
    }
    
    private func buildAuthPayload(empID: String) -> [String: Any] {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return ["RequestType": "6",
            "Version": appVersion,
            "BidRound": "0",
            "Position": "",
            "EmployeeNumber": empID,
            "FromAppNumber": "5",
            "OperatingSystem": "iPad OS",
            "Month": "0",
            "Base": "",
            "Platform": "iPad"]
    }
}
