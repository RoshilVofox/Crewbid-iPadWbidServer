//
//  BISwaBidDataDownload.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 21/08/25.
//

import Foundation

class BISwaBidDataDownload{
    
    var urlInfo: String?
    var bidInfo: String?
    var pageSize: String?
    
    init() {
        let dataSource = GlobalBidInfo.shared
        let base = dataSource.base
        let year = dataSource.year
        let month = dataSource.month
        let round = dataSource.round
        let position = CBUtils.shortName(for: dataSource.position)
        
        self.urlInfo = "\(base)\(year)\(month)\(round)"
        self.bidInfo = "\(base)\(position)\(year)\(month)\(round)"
        self.pageSize = "200"
    }
    
    
}
