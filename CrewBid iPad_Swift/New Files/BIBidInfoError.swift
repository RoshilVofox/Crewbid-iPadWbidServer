//
//  BIBidInfoError.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 11/05/25.
//

import Foundation

enum BIBidInfoErrorCode: Int {
    case downloadDirectoryCreation = 1
    case bidDataDownload
    case bidDataReading
    case bidSubmissionFailed
    case awardsRetrievalFailed
    case login
    case thirdPartyServer
    case dataWriteFailed
    case unzipFailed
    case underlyingReason = 100
    case linesDataFileNotFound = 200
    case linesDataFileUnreadable
    case linesDataMalformed
    case tripsDataFileNotFound
    case tripsDataFileUnreadable
    case tripsDataMalformed
    case tripMissing
    case tripsTextFileNotFound
    case textFileReadFailed
    case managedObjectContextSaveFailed
    case unknown = 999
}

let BIBidInfoErrorDomain = "BidInfo Error Domain"
let BIBidInfoFilenameKey = "filename"


class BIBidInfoError{    
    
    static func error(for errorCode: BIBidInfoErrorCode) -> NSError {
        return NSError(domain: BIBidInfoErrorDomain,code: errorCode.rawValue,userInfo: [NSLocalizedDescriptionKey: localizedDescription(for: errorCode)]
        )
    }
    static func error(for errorCode: BIBidInfoErrorCode, underlyingError: NSError) -> NSError {
        return NSError(
            domain: BIBidInfoErrorDomain,
            code: errorCode.rawValue,
            userInfo: [NSUnderlyingErrorKey: underlyingError]
        )
    }
    static func error(for errorCode: BIBidInfoErrorCode, underlyingReason: String) -> NSError {
        return NSError(
            domain: BIBidInfoErrorDomain,
            code: errorCode.rawValue,
            userInfo: [NSLocalizedDescriptionKey: underlyingReason]
        )
    }
    static func setError(_ error: inout NSError?, for errorCode: BIBidInfoErrorCode, underlyingError: NSError?) {
        let localizedDescription = localizedDescription(for: errorCode)
        
        var userInfo: [String: Any] = [
            NSLocalizedDescriptionKey: localizedDescription
        ]
        
        if let underlying = underlyingError {
            userInfo[NSUnderlyingErrorKey] = underlying
        }
        
        error = NSError(
            domain: BIBidInfoErrorDomain,
            code: errorCode.rawValue,
            userInfo: userInfo
        )
    }
    static func alertTitle(for error: NSError) -> String {
        var errorCode = BIBidInfoErrorCode(rawValue: error.code) ?? .unknown

        // If it's a login error, prefer the underlying error's code
        if error.code == BIBidInfoErrorCode.login.rawValue,
           let underlying = error.userInfo[NSUnderlyingErrorKey] as? NSError {
            errorCode = BIBidInfoErrorCode(rawValue: underlying.code) ?? .unknown
        }

        switch errorCode {
        case .bidDataDownload:
            return NSLocalizedString("Bid Download Failed", tableName: "Error", comment: "Alert title for bid info download error.")
        case .bidSubmissionFailed:
            return NSLocalizedString("Bid Submission Failed", tableName: "Error", comment: "Alert title for bid submission error.")
        case .awardsRetrievalFailed:
            return NSLocalizedString("Awards Retrieval Failed", tableName: "Error", comment: "Alert title for bid awards retrieval error.")
        default:
            return "Unknown Error"
        }
    }
    static func alertMessage(for error: NSError) -> String {
        // Default message
        var alertMessage = "Unknown error."

        // Attempt to get the failure reason
        var failureReason = error.userInfo[NSLocalizedFailureReasonErrorKey] as? String

        // If failure reason is nil, check underlying error
        if failureReason == nil,
           let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
            failureReason = underlyingError.localizedDescription
        }

        // Combine failure reason with recovery suggestion if available
        if let reason = failureReason {
            let suggestion = error.userInfo[NSLocalizedRecoverySuggestionErrorKey] as? String ?? ""
            alertMessage = "\(reason)\n\n\(suggestion)"
        }

        return alertMessage
    }
    static func localizedDescription(for errorCode: BIBidInfoErrorCode) -> String {
        switch errorCode {
        case .downloadDirectoryCreation:
            return "Could not create directory for file download."
        case .login:
            return "Login failed."
        case .bidDataDownload:
            return "Bid Download Failed."
        case .bidSubmissionFailed:
            return "Bid Submission Failed."
        case .awardsRetrievalFailed:
            return "Awards Retrieval Failed."
        case .dataWriteFailed:
            return "Could not write downloaded data to file."
        case .unzipFailed:
            return "Could not unzip downloaded file."
        case .linesDataFileNotFound:
            return "Could not find lines data file."
        case .linesDataFileUnreadable:
            return "Could not create string from lines data."
        case .linesDataMalformed:
            return "Error reading lines data."
        case .tripsDataFileNotFound:
            return "Trips data file not found."
        case .tripsDataFileUnreadable:
            return "Could not create string from trips data."
        case .tripsDataMalformed:
            return "Error reading trips data."
        case .tripMissing:
            return "Missing trip for pilot first round."
        case .tripsTextFileNotFound:
            return "Could not find trips text file."
        case .textFileReadFailed:
            return "Could not read text file."
        case .managedObjectContextSaveFailed:
            return "Error saving bid info data."
        default:
            return "Unknown error."
        }
    }
}
