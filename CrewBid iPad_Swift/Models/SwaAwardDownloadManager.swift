//
//  SwaAwardDownloadManager.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 02/03/26.
//


import Foundation



struct AwardDownloadResult {
    let lineAwardDetails: [String: Any]?
    let mrtAwardDetails: [String: Any]?
    let jobshareAwardDetails: [String: Any]?
    let reserveAwardDetails: [String: Any]?
}

enum AwardError: LocalizedError {
    case invalidBidPeriod
    case invalidToken
    case other(Error)

    var errorDescription: String? {
        switch self {
        case .invalidBidPeriod:
            return "Invalid Bid Period"
        case .invalidToken:
            return "Token expired"
        case .other(let error):
            return error.localizedDescription
        }
    }}
final class SwaAwardDownloadManager {

    static let shared = SwaAwardDownloadManager()
    private init() {}

    // MARK: - Public API

    func retrieveAwards(
        bidPeriod: BIBidPeriod?,
        downloader: BISwaBidDataDownload?,
        completion: @escaping (Result<AwardDownloadResult, Error>) -> Void
    ) {

        guard let bidPeriod = bidPeriod else {
            completion(.failure(AwardError.invalidBidPeriod))
            return
        }

        var lineAwardDetails: [String: Any]?
        var mrtAwardDetails: [String: Any]?
        var jobshareAwardDetails: [String: Any]?
        var reserveAwardDetails: [String: Any]?
        var awardError: Error?

        let group = DispatchGroup()

        // MARK: Line Awards
        group.enter()
        downloader?.getAwards { result in
            switch result {
            case .success(let response):
                if self.isTokenExpiredResponse(response) {
                    awardError = AwardError.invalidToken
                } else {
                    lineAwardDetails = response
                }
            case .failure(let error):
                awardError = AwardError.other(error)
            }
            group.leave()
        }

        // MARK: Additional Awards (Skip for 2nd Round)
        if !(bidPeriod.isSecondRoundBid()) {

            // MRT
            group.enter()
            downloader?.getMrtAwards { result in
                switch result {
                case .success(let response):
                    if self.isTokenExpiredResponse(response) {
                        awardError = AwardError.invalidToken
                    } else {
                        mrtAwardDetails = response
                    }
                case .failure(let error):
                    awardError = AwardError.other(error)
                }
                group.leave()
            }

            // Job Share
            group.enter()
            downloader?.getJobShareAwards { result in
                switch result {
                case .success(let response):
                    if self.isTokenExpiredResponse(response) {
                        awardError = AwardError.invalidToken
                    } else {
                        jobshareAwardDetails = response
                    }
                case .failure(let error):
                    awardError = AwardError.other(error)
                }
                group.leave()
            }

            // Reserve
            group.enter()
            downloader?.getReserveDataForAward { result in
                switch result {
                case .success(let response):
                    if self.isTokenExpiredResponse(response) {
                        awardError = AwardError.invalidToken
                    } else {
                        reserveAwardDetails = response
                    }
                case .failure(let error):
                    awardError = AwardError.other(error)
                }
                group.leave()
            }
        }

        // MARK: Completion
        group.notify(queue: .main) {

            if let error = awardError {
                completion(.failure(error))
                return
            }

            let result = AwardDownloadResult(
                lineAwardDetails: lineAwardDetails,
                mrtAwardDetails: mrtAwardDetails,
                jobshareAwardDetails: jobshareAwardDetails,
                reserveAwardDetails: reserveAwardDetails
            )

            completion(.success(result))
        }
    }
    
    private func isTokenExpiredResponse(_ response: [String: Any]) -> Bool {
        let status = response["status"] as? Int
        let error = (response["error"] as? String)?.lowercased()
        let message = (response["message"] as? String)?.lowercased() ?? ""

        return status == 401 ||
               error == "invalid_token" ||
               message.contains("token expired") ||
               message.contains("token not valid")
    }
}
