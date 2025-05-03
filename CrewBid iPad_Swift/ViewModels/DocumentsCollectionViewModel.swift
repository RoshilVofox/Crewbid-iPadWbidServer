//
//  DocumentsCollectionViewModel.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 02/05/25.
//

import Foundation

class DocumentsCollectionViewModel{
    
    func initialize(){
        let arrVideoUrl = ["njTXQKbStoY", "jrZAmrE720A", "rwMDZkm73o8", "QUNmnde9X0U", "7sINWWtG_zo", "raUv3CiRhbo", "5SjKSTOC4aw"]
        let arrVideoTtiles = ["Getting Started", "Filtering Basics", "Sorting Basics", "Navigating the Bid List", "Pilot Quick Bid", "FA Quick Bid", "SWAPtimizer"]
        UserDefaults.standard.register(defaults: [kCBHelpVideoURL:arrVideoUrl])
        UserDefaults.standard.register(defaults: [kCBHelpVideotitles:arrVideoTtiles])
    }
    
}
