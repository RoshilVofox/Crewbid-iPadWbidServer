//
//  EndPoint.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 18/05/25.
//

import Foundation
import UIKit


let baseURL = "https://www.auth.wbidmax.com/WBidDataDwonloadAuthService.svc/Rest/"

class EndPoint {
    static let shared = EndPoint()
    
    var thirdpartyURL: String {
        let isQATest = UserDefaults.standard.string(forKey: "isQATest")
        if isQATest == "1" {
            return "https://www27.swalifeqa.com/webbid3pty/ThirdParty"
        } else {
            return "https://www27.swalife.com/webbid3pty/ThirdParty"
        }
    }
    
    var kCBSwaServiceURL: String{
        let env = UserDefaults.standard.string(forKey: "SwaApiEnv")
        var baseURL = ""
        if env == "Dev"{
            baseURL = "https://itest.service.east.0.crewbid.dev.swalife.com"
        }else if env == "QA"{
            baseURL = "https://service.east.0.crewbid.qa.swalife.com/itest"
        }else{
            baseURL = "https://service.crewbid.swalife.com/golden"
        }
        return baseURL
    }
    
//    var faListWB4Json = "https://www.wbidmax.com/downloads/swa/falistwb4.json"
    var crewBidUpdate = "https://www.wbidmax.com/downloads/CrewBid/CrewBidUpdate.dat"
    var flightdataJSON = "https://www.wbidmax.com/downloads/swa/FlightDataJson.zip"
    var latestNews = "https://www.wbidmax.com/downloads/CrewBid/LatestNews.pdf"
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
    var saveCrashedPresetToServer = "\(baseURL)SaveCrashedPresetToServer"
    var getCrashedCBPresetFromServer = "\(baseURL)GetCrashedCBPresetFromServer"
    var saveConvertedPresetToServer = "\(baseURL)SaveConvertedPresetToServer"
    var getCBServerStateandPresetVersionNumber = "\(baseURL)GetCBServerStateandPresetVersionNumber"
    var saveCBAppStateAndPresetToServer = "\(baseURL)SaveCBAppStateAndPresetToServer"
    var getCBAppStateAndPresetFromServer = "\(baseURL)GetCBAppStateAndPresetFromServer"
    var getCAPData = "\(baseURL)GetCAPData"
    var checkValidSubscriptionForEmployeesRest = "\(baseURL)CheckValidSubscriptionForEmployeesRest"
}

