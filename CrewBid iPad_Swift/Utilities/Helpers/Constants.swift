//
//  Constants.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 25/03/25.
//

import Foundation
import UIKit

//crew type
enum BICrewPositionType : Int {
    case Captain
    case FirstOfficer
    case FlightAttendant
}

//timezones
enum CBTimeZoneSetting : Int {
    case herbTime
    case localTime
}

//overnight bulk cell color codes
enum ColorType : Int {
    case red = 1
    case green = 2
    case nocolor = 3
}

enum ClassType : Int {
    case parent
    case child
}

//login screen type
enum LoginType : Int {
    case newBid = 0
    case historicBid = 1
    case bidSubmission = 2
}

//CBSwaptimizerStatus
enum CBSwaptimizerStatus : Int {
    case notChecked
    case checked
    case notApplicable      // Either not a pilot or doesn't have vacay
    case noAccount           // Has vacation but no account
    case dataNotAvailable    // Has vacay and account, but data not available
    case statusError
    case enabled              // Data loaded
}

enum BIFaVacationStatus : Int {
    case notProcessed
    case enteredProcessing
    case noVacation
    case enabled
}


enum TextFileType: String {
    case seniorityList
    case coverLetter
    case awardText
    case faMemo
    case tripText
    case lineText
    case bidReceipt
}
enum AwardType: String {
    case showAward
    case addAwardLineToCal
}
enum BidActionType: String {
    case BidActions
    case ShowFile
    case Vacation
    case ShowReceipt
}

enum BIBidFileDownloadType : Int {
    case biBidDataDownloadType
    case biBidSubmissionDownloadType
    case biBidAwardsDownloadType
    case biLoginChecking
}

let FromAppNumber = "14"
var rawData : String = ""

var hideHud : [String: Any] = ["hideHud" : true]
var authFailed : [String: Any] = ["authFailed" : true]
var noUserAccount : [String: Any] = ["noUserAccount" : true]

let LineValueViewTag = 10000

var LiveServiceURL : String {
    var url = "https://www.auth.wbidmax.com/WBidCoreService/api/"
    if UserDefaults.standard.bool(forKey: "isTestDBSelected") == true {
        url = "https://www.auth.wbidmax.com/WBidCoreServiceTestDBQA/api/"
    }
    return url
}

let DevUserID = "21221"
let DevUserPassword = "Vofox2025@2$"

let kCBEmployeeNumberDefaultKey = "Employee Number"
let kCBCrewBaseDefaultKey = "Crew Base"
let kCBCrewPositionTypeDefaultKey = "Crew Position"
let kCBBidDocumentLastBidDateKey = "Last Bid Date"
let kCBDefaultLineValuesKey = "Default Line Values"
let kCBRound2DefaultLineValuesKey = "Round 2 Default Line Values"
let kCBSwaptimizerLineValuesKey = "Swaptimizer Line Values"
let kCBFaVacationLineValuesKey = "FA Vacation Line Values"
let kCBHideVacationKey = "CBHideVacation"
let kCBDefaultCommutingTimesKey = "Default Commuting Times"
let kCBDefaultsCommutingNoMidKey = "DefaultsNoMidKey"
let kCBVacationOverlapTripDisplayOption = "VacationOverlapTripDisplayOption"


let kCBInternationalCitiesList = "CBInternationalCitiesList"
let kCBNonConusCitiesList = "CBNonConusCitiesList"
let kCBWestCoastCitiesList = "CBWestCoastCitiesList"
let kCBEastCoastCitiesList = "CBEastCoastCitiesList"
let kCBAllCitiesList = "CBAllCitiesList"
let kCBSelectedInternationalCities = "CBSelectedInternationalCities"
let kCBSelectedNonConusCities = "CBSelectedNonConusCities"
let kCBSelectedWestCoastCities = "CBSelectedWestCoastCities"
let kCBSelectedEastCoastCities = "CBSelectedEastCoastCities"
let kCBSelectedAllCities = "CBSelectedAllCities"
let kCBHawaiiCitiesList = "CBHawaiiCitiesList"
let kCBSelectedHawaiiCities = "CBSelectedHawaiiAllCities"


let kCBTimeZoneSetting = "CBTimeZoneSetting"
let kCBTimeZoneCitiesList = "CBTimeZoneCitiesList"
let kCBInternationalCitiesDict = "CBInternationalCitiesDict"
let kCBDisplayedExpandedBidListInstructions = "CBDisplayedExpandedBidListInstructions"

let ReloadCollectionView = "ReloadCollectionView"
let BIBidPeriodEntityName = "BidPeriod"


let kCBHelpVideoURL = "HelpVideoURL"
let kCBHelpVideotitles = "HelpVideotitles"


let kCBIsPresetModified = "kCBIsPresetModified"
let kCBPresetSyncReload = "CBPresetSyncReload"
let KCBIsSyncEnabled = "KCBIsSyncEnabled"
let KCBCustomizedHerbValue = "KCBCustomizedHerbValue"


//Bid download
let KCBSelectedBase = "KCBSelectedBase"
let KCBHistoricSelectedYear = "HistoricSelectedYear"
let KCBHistoricSelectedMonth = "HistoricSelectedMonth"
let KCBSelectedPosition = "SelectedPosition"
let KCBSelectedRound = "KCBSelectedRound"
let KCBEmpNumWithPrefix = "KCBEmpNumWithPrefix"

let KCBopenExpandedViewNotification = "KCBopenExpandedViewNotification"
let KCBOpenCoverletter = "KCBOpenCoverletter"
let KCBOpenSeniority = "KCBOpenSeniority"
let KCBOpenLatestNews = "KCBOpenLatestNews"
let KCBOpenAwardData = "KCBOpenAwardData"
let KCBOpenretrieveAwardDownloadPage = "KCBOpenretrieveAwardDownloadPage"
let KCBOpenLineImporter = "KCBOpenLineImporter"
let KCBOpenShowCAP = "KCBOpenShowCAP"
let KCBOpenAwardEmpValidationVC = "KCBOpenAwardEmpValidationVC"
let KCBOpenAwardEmpValidationVCForAddToCal = "KCBOpenAwardEmpValidationVCForAddToCal"
let KCBOpenLineText = "KCBOpenLineText"
let KCBOpenTripText = "KCBOpenTripText"
let KCBOpenFAMemo = "KCBOpenFAMemo"
let BIDayInfoEntityName = "DayInfo"
let BIDayEntityName = "Day"

let kCBPdfSize: CGRect = CGRect(x: 20, y: 20, width: 816, height: 1056)

//-------------------------------------------------------------------------------------//
// alerts
let Crewbid = "CrewBid 2"
let Warning = "Warning !"
let AppNum = 14
let LoginFailed : String = "The combination of your employee number and password was not recognized by the company\nOnly pilots and flight attandents of Southwest Airlines will be authorized to use this app.\nCheck your employee number and CWA password and try again."
let InvalidEmployyeNumber : String = "Please enter valid employee number."
let enterEmployeeNumber : String = "Please enter employee number."
let InvalidPassword : String = "Please enter valid password."
let NetworkNotAvailable : String = "There is no internet connection"
let CWALoginFailed : String = "We cannot validate you as an employee!\n\nYour login failed . You can try again, but CWA will lock you out after 3 attempts.\n\nIf you try again, insure you are using your employee number and your SwaLife password."
let ResponceZero : String = "Something went wrong. Please try again ."
let invalidAccount : String = "We checked, but no previous account exists for you.\n\nThe next view will let you create your account."
let PositionNotSelected : String = "Please select any position to continue."
let RoundNotSelected : String = "Please select any round to continue."
let BaseNotSelected : String = "Please select any base to continue."
let MonthNotSelected : String = "Please select any month to continue."
let YearNotSelected = "Please select any year to continue."
let UpdatePasswordSuccess = "You have saved password successfully."
let UpdatePasswordFailure = "Password update is failed, Please try again."
let VerifyPassword = "Incorrect Password, Please try again"
let EmailValidFormat = "Please enter email with valid format"
let AccountExisting = "Found Existing Account"
let FirstName = "Please enter first name"
let ValidFirstName = "Please enter valid first name"
let LastName = "Please enter last name"
let ValidLastName = "Please enter valid last name"
let Email = "Please enter email address"
let ConfirmEmail = "Please enter Confirm Email address"
let Cellphone = "Please enter cell phone number"
let CellphoneFormat = "Invalid Cell Number eg: xxx-xxx-xxxx format."
let EmployeeNo = "Please enter Employee number"
let ValidEmployeeNo = "Please enter valid employee number"
let Cellcarrier = "Please select cell carrier"
let AcceptTerms = "You have to accept the terms and condition in order to use CrewBid 2 App"
let CreatePassword = "Please create the password"
let ViaSmsSuccess = "Password sent via sms"
let ViaMailSuccess = "Password sent via email,Please check your mail."
let ViaSiteSuccess = "Password sent via wnco.com."
let PasswordSentFail = "We are unable to send your password,Please contact Administrator."
let PasswordLength = "Password must be 6 to 12 characters."
let DataNotAvailable = "User account not available. Please login in CrewBid with your employee number"
let InvalidCellPhoneFormat = "Invalid Cell Number eg:xxx-xxx-xxxx format"
let EnterPassword = "Please enter password"
let EnterNewPassword = "Please enter new password"
let ReEnterPassword = "Please re-enter password"
let EmailNotMatching = "Email Not Matching"
let PasswordMismatch = "Please repeat same password"

//-------------------------------------------------------------------------------------//
let kCBUserInfoDictionaryKey = "UserInfoDictionary"
let kCBExpirationDateFormat = "dd/MM/yyyy HH:mm:ss"
let kCBIncludeDroppedTripsInProcessingKey = "CBIncludeDroppedTripsInProcessing"

let kCBUserInfoEncryptedWbidExpirationDateKey = "UserInfoEncryptedWbidExpirationDateKey"
let kCBUserInfoUserParseIDKey = "UserInfoUserParseIDKey"
let kCBUserInfoParseObjectIDKey = "UserInfoParseObjectIDKey"
let kCBUserInfoUserEmailKey = "UserInfoUserEmail"
let kCBUserInfoEncryptedExpirationDateKey = "UserInfoEncryptedExpirationDateKey"
let kCBUserInfoPurchaseTypesKey = "UserInfoPurchaseTypesKey"
let kCBUserInfoParseClassName = "UserInfo"
let kCBUserInfoPositionKey = "Position"
let kCBUserInfoDecryptedExpirationDateKey = "UserInfoDecryptedExpirationDateKey"
let kCBUserInfoDecryptedWbidExpirationDateKey = "UserInfoDecryptedWbidExpirationDateKey"
let kCBUserInfoMarchMadnessKey = "UserInfoMarchMadnessKey"
let kCBUserInfoMostRecentPurchaseDateKey = "MostRecentPurchaseDate"
let kParseUserSubscriptionExpirationDate = "SubscriptionExpirationDate"

let openSubscriptionPageNotification = "openSubscriptionPageNotification"

let refreshLines = "refreshLines"
let kCBFaBuddyBidsKey = "FaBuddyBids"
let kCBFoAvoidanceBidsKey = "FoAvoidanceBids"
//let kCBIncludeDroppedTripsInProcessingKey = "CBIncludeDroppedTripsInProcessing"

public enum HTTPStatusCode: Int {
    case `continue` = 100,
    switchingProtocols = 101
    
    case ok = 200,
    created = 201,
    accepted = 202,
    nonAuthoritativeInformation = 203,
    noContent = 204,
    resetContent = 205,
    partialContent = 206
    
    case multipleChoices = 300,
    movedPermanently = 301,
    found = 302,
    seeOther = 303,
    notModified = 304,
    useProxy = 305,
    unused = 306,
    temporaryRedirect = 307
    
    case badRequest = 400,
    unauthorized = 401,
    paymentRequired = 402,
    forbidden = 403,
    notFound = 404,
    methodNotAllowed = 405,
    notAcceptable = 406,
    proxyAuthenticationRequired = 407,
    requestTimeout = 408,
    conflict = 409,
    gone = 410,
    lengthRequired = 411,
    preconditionFailed = 412,
    requestEntityTooLarge = 413,
    requestUriTooLong = 414,
    unsupportedMediaType = 415,
    requestedRangeNotSatisfiable = 416,
    expectationFailed = 417
    
    case internalServerError = 500,
    notImplemented = 501,
    badGateway = 502,
    serviceUnavailable = 503,
    gatewayTimeout = 504,
    httpVersionNotSupported = 505
    
    case invalidUrl = -1001
    
    case unknownStatus = 0
    
    init(statusCode: Int) {
        self = HTTPStatusCode(rawValue: statusCode) ?? .unknownStatus
    }
    
    public var statusDescription: String {
        get {
            switch self {
            case .continue:
                return "Continue"
            case .switchingProtocols:
                return "Switching protocols"
            case .ok:
                return "OK"
            case .created:
                return "Created"
            case .accepted:
                return "Accepted"
            case .nonAuthoritativeInformation:
                return "Non authoritative information"
            case .noContent:
                return "No content"
            case .resetContent:
                return "Reset content"
            case .partialContent:
                return "Partial Content"
            case .multipleChoices:
                return "Multiple choices"
            case .movedPermanently:
                return "Moved Permanently"
            case .found:
                return "Found"
            case .seeOther:
                return "See other Uri"
            case .notModified:
                return "Not modified"
            case .useProxy:
                return "Use proxy"
            case .unused:
                return "Unused"
            case .temporaryRedirect:
                return "Temporary redirect"
            case .badRequest:
                return "Bad request"
            case .unauthorized:
                return "Access denied"
            case .paymentRequired:
                return "Payment required"
            case .forbidden:
                return "Forbidden"
            case .notFound:
                return "Page not found"
            case .methodNotAllowed:
                return "Method not allowed"
            case .notAcceptable:
                return "Not acceptable"
            case .proxyAuthenticationRequired:
                return "Proxy authentication required"
            case .requestTimeout:
                return "Request timeout"
            case .conflict:
                return "Conflict request"
            case .gone:
                return "Page is gone"
            case .lengthRequired:
                return "Lack content length"
            case .preconditionFailed:
                return "Precondition failed"
            case .requestEntityTooLarge:
                return "Request entity is too large"
            case .requestUriTooLong:
                return "Request uri is too long"
            case .unsupportedMediaType:
                return "Unsupported media type"
            case .requestedRangeNotSatisfiable:
                return "Request range is not satisfiable"
            case .expectationFailed:
                return "Expected request is failed"
            case .internalServerError:
                return "Internal server error"
            case .notImplemented:
                return "Server does not implement a feature for request"
            case .badGateway:
                return "Bad gateway"
            case .serviceUnavailable:
                return "Service unavailable"
            case .gatewayTimeout:
                return "Gateway timeout"
            case .httpVersionNotSupported:
                return "Http version not supported"
            case .invalidUrl:
                return "Invalid url"
            default:
                return "Unknown status code"
            }
        }
    }
}


//var objServiceConnection = ServiceConnection()

var Yes: NSNumber {
    return 1
}

var No: NSNumber {
    return 0
}



@objc enum BIVacationFilterRuleType : Int {
    
    case BIVacationFilterRuleTypeTotalPay
    //0
    case BIVacationFilterRuleTypeFlyPay
    //1
    case BIVacationFilterRuleTypeVacationPay
    //2
    case BIVacationFilterRuleTypePayPerBlock
    //3
    case BIVacationFilterRuleTypePayPerDay
    //4
    case BIVacationFilterRuleTypeCarryOutPay
    //5
    case BIVacationFilterRuleTypeBlockTime
    //6
    case BIVacationFilterRuleTypeDaysOff
    //7
    case BIVacationFilterRuleTypeEffectiveVacationLength
    //8
    case BIVacationFilterRuleTypeVacayCarryOutPay
    // 9
    case BIVacationFilterRuleTypeCarryOutVoPay
    // 10
    case BIVacationFilterRuleTypeFrontVoPay
    // 11
    case BIVacationFilterRuleTypeBackVoPay
    //12
    case BIVacationFilterRuleTypeBLongestBlockofDaysOff

    
    func name () -> Int {
        switch self
        {
        case .BIVacationFilterRuleTypeTotalPay: return 0
        case .BIVacationFilterRuleTypeFlyPay: return 1
        case .BIVacationFilterRuleTypeVacationPay: return 2
        case .BIVacationFilterRuleTypePayPerBlock: return 3
        case .BIVacationFilterRuleTypePayPerDay: return 4
        case .BIVacationFilterRuleTypeCarryOutPay: return 5
        case .BIVacationFilterRuleTypeBlockTime: return 6
        case .BIVacationFilterRuleTypeDaysOff: return 7
        case .BIVacationFilterRuleTypeEffectiveVacationLength: return 8
        case .BIVacationFilterRuleTypeVacayCarryOutPay: return 9
        case .BIVacationFilterRuleTypeCarryOutVoPay: return 10
        case .BIVacationFilterRuleTypeFrontVoPay: return 11
        case .BIVacationFilterRuleTypeBackVoPay: return 12
        case .BIVacationFilterRuleTypeBLongestBlockofDaysOff: return 13
        }
    }
}



var BIFilterRuleEntityName: String = "FilterRule"
var BIFilterRuleValueVariablesKey: String = "VALUE"
var BIFilterRuleCityVariablesKey: String = "CITY"
var BIFilterRuleRangeStartVariablesKey: String = "RANGESTART"
var BIFilterRuleRangeEndVariablesKey: String = "RANGEEND"
var BIFilterRuleSunDepartTimeVariablesKey: String = "SUN_DEPART"
var BIFilterRuleSunReturnTimeVariablesKey: String = "SUN_RETURN"
var BIFilterRuleMonThursDepartTimeVariablesKey: String = "MON_THURS_DEPART"
var BIFilterRuleMonThursReturnTimeVariablesKey: String = "MON_THURS_RETURN"
var BIFilterRuleFriDepartTimeVariablesKey: String = "FRI_DEPART"
var BIFilterRuleFriReturnTimeVariablesKey: String = "FRI_RETURN"
var BIFilterRuleSatDepartTimeVariablesKey: String = "SAT_DEPART"
var BIFilterRuleSatReturnTimeVariablesKey: String = "SAT_RETURN"

var BIFilterRuleReportVariablesKey = "reportValue"
var BIFilterRuleReleaseVariablesKey = "releaseValue"
var BIFilterRuleCheckStateReportVariablesKey = "checkStateReport"
var BIFilterRuleCheckstateReleaseVariablesKey = "checkstateRelease"
var BIFilterRuleSelectedDaysVariablesKey = "SELECTED_DATES"
var BIFilterRuleNoMidCheckStateVariablesKey = "NoMidCheckState"

var BIFilterRuleCheckStateIsFirstVariablesKey = "isFirst"
var BIFilterRuleCheckstateIsLastVariablesKey = "isLast"
var BIFilterRuleCheckstateIsNoMidVariablesKey = "isNoMid"



@objc  enum BIFilterRuleCategory : Int {
    
    case BITypeFilterRuleCategory
    // 0
    
    case BIAmPmFilterRuleCategory
    // 1
    
    case BIFaReserveFilterRuleCategory
    // 2
    
    case BIPositionFilterRuleCategory
    // 3
    
    case BIDaysOfWeekFilterRuleCategory
    // 4
    
    case BITripLengthFilterRuleCategory
    // 5
    
    case BIAircraftChangesFilterRuleCategory
    // 6
    
    case BIAircraftTypeFilterRuleCategory
    // 7
    
    case BIBlockOfDaysOffFilterRuleCategory
    // 8
    
    case BIBlockTimeFilterRuleCategory
    // 9
    
    case BICitiesFilterRuleCategory
    // 10
    
    case BICommutesRequiredFilterRuleCategory
    // 11
    
    case BICommutingFilterRuleCategory
    // 12
    
    case BIDaysOfMonthFilterRuleCategory
    // 13
    
    case BIDaysOffFilterRuleCategory
    // 14
    
    case BIDeadheadsFilterRuleCategory
    // 15
    
    case BIDutyTimeFilterRuleCategory
    // 16
    
    case BIEarliestDepartureFilterRuleCategory
    // 17
    
    case BILatestArrivalFilterRuleCategory
    // 18
    
    case BINumLegsFilterRuleCategory
    // 19
    
    case BIMaxLegsFilterRuleCategory
    // 20
    
    case BIOverlapFilterRuleCategory
    // 21
    
    case BIOvernightsInBaseFilterRuleCategory
    // 22
    
    case BIPassesThruBaseFilterRuleCategory
    // 23
    
    case BIPayFilterRuleCategory
    // 24
    
    case BITafbTimeFilterRuleCategory
    // 25
    
    case BINumTripsFilterRuleCategory
    // 26
    
    case BIWorkDaysFilterRuleCategory
    // 27
    
    case BIOvernightLengthFilterRuleCategory
    // 28
    
    case BIVacationFilterRuleCategory
    // 29
    
    case BIRedeyesFilterRuleCategory
    // 30
    
    case BIFaVacationFilterRuleCategory
    // 31
    
    case BIUserFlagFilterRuleCategory
    // 32
    
    case BICommutabilityFilterRuleCategory
    //33
    
    case BIOvernightCitiesBulkRuleCategory
    //34
    
    case BIEtopsFilterRuleCategory
    //35
    
    case BIModifiedTypeFilterCategory
    //36
    
    case BIReportReleaseFilterCategory
    //37
    
    case BIEtopsResFilterRuleCategory
    //38
    
    case BIWorkBlockRuleCategory
    //39
    
    case BIWorkBlockCountCategory
    //40
    case BIGTmaxFilterRuleCategory
    //41
    case BIGTavgFilterRuleCategory
    //42
    case BIOvAvgFilterRuleCategory
    //43
    case BI1or2OFFFilterRuleCategory
    //44
    case BIReserveOffDaysFilterRuleCategory
    //45
    case BIRedEyeTripsFilterRuleCategory
    //46
    
    func name () -> Int {
        switch self
        {
        case .BITypeFilterRuleCategory: return 0
      
        case .BIAmPmFilterRuleCategory: return 1
       
        case .BIFaReserveFilterRuleCategory: return 2
       
        case .BIPositionFilterRuleCategory: return 3
        
        case .BIDaysOfWeekFilterRuleCategory: return 4
        
        case .BITripLengthFilterRuleCategory: return 5
        
        case .BIAircraftChangesFilterRuleCategory: return 6
        
        case .BIAircraftTypeFilterRuleCategory: return 7
        
        case .BIBlockOfDaysOffFilterRuleCategory: return 8
        
        case .BIBlockTimeFilterRuleCategory: return 9
        
        case .BICitiesFilterRuleCategory: return 10
        
        case .BICommutesRequiredFilterRuleCategory: return 11
        
        case .BICommutingFilterRuleCategory: return 12
        
        case .BIDaysOfMonthFilterRuleCategory: return 13
        
        case .BIDaysOffFilterRuleCategory: return 14
        
        case .BIDeadheadsFilterRuleCategory: return 15
        
        case .BIDutyTimeFilterRuleCategory: return 16
        
        case .BIEarliestDepartureFilterRuleCategory: return 17
        
        case .BILatestArrivalFilterRuleCategory: return 18
        
        case .BINumLegsFilterRuleCategory: return 19
        
        case .BIMaxLegsFilterRuleCategory: return 20
        
        case .BIOverlapFilterRuleCategory: return 21
        
        case .BIOvernightsInBaseFilterRuleCategory: return 22
        
        case .BIPassesThruBaseFilterRuleCategory: return 23
        
        case .BIPayFilterRuleCategory: return 24
        
        case .BITafbTimeFilterRuleCategory: return 25
        
        case .BINumTripsFilterRuleCategory: return 26
        
        case .BIWorkDaysFilterRuleCategory: return 27
        
        case .BIOvernightLengthFilterRuleCategory: return 28
        
        case .BIVacationFilterRuleCategory: return 29
        
        case .BIRedeyesFilterRuleCategory: return 30
        
        case .BIFaVacationFilterRuleCategory: return 31
        
        case .BIUserFlagFilterRuleCategory: return 32
        
        case .BICommutabilityFilterRuleCategory: return 33
        
        case .BIOvernightCitiesBulkRuleCategory: return 34
            
        case .BIEtopsFilterRuleCategory: return 35
            
        case .BIModifiedTypeFilterCategory: return 36
            
        case .BIReportReleaseFilterCategory: return 37
          
        case .BIEtopsResFilterRuleCategory: return 38
   
        case .BIWorkBlockRuleCategory: return 39
            
        case .BIWorkBlockCountCategory: return 40
        case .BIGTmaxFilterRuleCategory: return 41
        case .BIGTavgFilterRuleCategory: return 42
        case .BIOvAvgFilterRuleCategory: return 43
        case .BI1or2OFFFilterRuleCategory: return 44
        case .BIReserveOffDaysFilterRuleCategory: return 45
        case .BIRedEyeTripsFilterRuleCategory: return 46
        }
    }
    
}

@objc enum BITripLengthFilterRuleType : Int {
    case BITripLengthCompoundType
    case BITurnsTripLengthType
    case BITwoDaysTripLengthType
    case BIThreeDaysTripLengthType
    case BIFourDaysTripLengthType
    
    func name () -> Int {
        switch self
        {
        
        case .BITripLengthCompoundType: return 0
        case .BITurnsTripLengthType: return 1
        case .BITwoDaysTripLengthType: return 2
        case .BIThreeDaysTripLengthType: return 3
        case .BIFourDaysTripLengthType: return 4
        }
    }
}

enum AssetsColor {
   case bid_actions
   case BlackLabelColor
   case color_13
   case CrewbidOrange
   case custom_2
   case custom_colour
   case firsttriptextview_colour
   case HomeBackGround
   case LightGrey
   case LightOrangeColor
   case preset_label
   case PurpleColor
   case RedViewColor
   case reptreleasebutton
   case TopViewColor
   case WhiteLabelColor
   case contentBgColor
   case lightTextColor
   case purpleColor
   case homeContentBackGround
   case crewbidOrange_1
}

extension UIColor {

    static func appColor(_ name: AssetsColor) -> UIColor? {
        switch name {
        case .bid_actions:
            return UIColor(named: "bid_actions")
        case .BlackLabelColor:
            return UIColor(named: "BlackLabelColor")
        case .color_13:
            return UIColor(named: "color_13")
        case .CrewbidOrange:
            return UIColor(named: "CrewbidOrange")
        case .custom_2:
            return UIColor(named: "custom_2")
        case .custom_colour:
            return UIColor(named: "custom_colour")
        case .firsttriptextview_colour:
            return UIColor(named: "firsttriptextview_colour")
        case .HomeBackGround:
            return UIColor(named: "HomeBackGround")
        case .LightGrey:
            return UIColor(named: "LightGrey")
        case .LightOrangeColor:
            return UIColor(named: "LightOrangeColor")
        case .preset_label:
            return UIColor(named: "preset_label")
        case .PurpleColor:
            return UIColor(named: "PurpleColor")
        case .RedViewColor:
            return UIColor(named: "RedViewColor")
        case .reptreleasebutton:
            return UIColor(named: "reptreleasebutton")
        case .TopViewColor:
            return UIColor(named: "TopViewColor")
        case .WhiteLabelColor:
            return UIColor(named: "WhiteLabelColor")
        case .contentBgColor:
            return UIColor(named: "contentBgColor")
        case .lightTextColor:
            return UIColor(named: "lightTextColor")
        case .purpleColor:
            return UIColor(named: "PurpleColor")
        case .homeContentBackGround:
            return UIColor(named: "HomeContentBackGround")
        case .crewbidOrange_1:
            return UIColor(named: "CrewbidOrange_1")
        }
    }
}
