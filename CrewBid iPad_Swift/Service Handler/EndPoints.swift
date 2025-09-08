//
//  EndPoint.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 18/05/25.
//

import Foundation
import UIKit


let baseURL = "http://www.wbidmax.com:8000/WBidDataDwonloadAuthService.svc/"

class EndPoint {
    static let shared = EndPoint()
    
    var thirdpartyURL: String {
        let isQATest = UserDefaults.standard.string(forKey: "isQATest")
        if isQATest == "YES" {
            return "https://www27.swalifeqa.com/webbid3pty/ThirdParty"
        } else {
            return "https://www27.swalife.com/webbid3pty/ThirdParty"
        }
    }
    var faListWB4Json = "http://www.wbidmax.com/downloads/swa/falistwb4.json"
    var crewBidUpdate = "http://www.wbidmax.com/downloads/CrewBid/CrewBidUpdate.dat"
    var flightdataJSON = "http://www.wbidmax.com/downloads/swa/FlightDataJson.zip"
    var flightDataChange = "\(baseURL)GetVacationDifferenceData"
    var soap = "\(baseURL)soap"
    var CAPData = "\(baseURL)GetCAPData"
    var logInAppStatus = "\(baseURL)LogInAppStatus"
    var logOfflineEventsRest = "\(baseURL)LogOffLineEventsRest"
    var updateWBidPaidUntilDate = "\(baseURL)UpdateWBidPaidUntilDate"
    var sendMail = "\(baseURL)SendMailRest"
    var getScrappedMissedTrips = "\(baseURL)GetScrappedMissedTrips"
    var saveSwaptimizerFileToServer = "\(baseURL)SaveSwaptimizerFileToServer"
    var getCrewBidJsonVacFile = "\(baseURL)GetCrewBidJsonVacFile"
    var getUserDetails = "\(baseURL)GetUserDetails/"
    var updateCrewBidPaidUntilDate = "\(baseURL)UpdateCrewBidPaidUntilDate"
    var logCrewBidSubmitBidDetails = "\(baseURL)LogCrewBidSubmitBidDetails/"
    var updateCrewbidUserPaidUntilDate = "\(baseURL)UpdateCrewbidUserPaidUntilDate"
    var GetCrewBidAuthorization = "\(baseURL)GetCrewBidAuthorization"
    var SaveBidSubmittedData = "\(baseURL)SaveBidSubmittedData"
    var getCurrentMonthAwardData = "\(baseURL)GetCurrentMonthAwardData"
    var getapplicationLoadDatas = "\(baseURL)GetApplicationLoadDatas"
    var getbidSubmittedData = "\(baseURL)GetBidSubmittedData"
    var getmonthlyAwardData = "\(baseURL)GetMonthlyAwardData"
    var DownloadHistoricalBidLineAll = "\(baseURL)DownloadHistoricalBidLineAll"
    var DownloadHistoricalDataRest = "\(baseURL)DownloadHistoricalDataRest"
    var GetAllSeniorityListFormatFromDB = "\(baseURL)GetAllSeniorityListFormatFromDB/"
    var getFirstRoundPaperBidVacationsAndUsers = "\(baseURL)GetFirstRoundPaperBidVacationsAndUsers"
    var addSubmittedRawDataToServer = "\(baseURL)AddSubmittedRawDataToServer"
    var VPSPing = "\(baseURL)VPSPing"
}

