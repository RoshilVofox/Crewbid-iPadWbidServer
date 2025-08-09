//
//  CBBidLineCalendarCollectionView.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 01/08/25.
//

import UIKit

class CBBidLineCalendarCollectionView: UICollectionView{
    
    var tripButtons: NSMutableArray?
    var vacationButtons: NSMutableArray?
    var fvVacationButtons: NSMutableArray?
    var cfvVacationButtons: NSMutableArray?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutTripButtons()
        layoutVacationButtons()
    }
    
    func layoutTripButtons() {
        let flowlayout = collectionViewLayout as? UICollectionViewFlowLayout
        let count: Int = (tripButtons?.count)!
        for i in 0..<count {
            let tripButton = tripButtons?[i] as? UIButton
            if tripButton != nil {
                var frame: CGRect? = tripButton?.frame
                let layout: UICollectionViewLayoutAttributes? = flowlayout?.layoutAttributesForItem(at: IndexPath(item: i, section: 0))
                frame?.origin.x = (layout?.frame.origin.x)!
                frame?.origin.y = (layout?.frame.origin.y)!
                tripButton?.frame = frame!
            }
        }
    }
    
    func layoutVacationButtons() {
        let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout
        if vacationButtons != nil {
            let count1: Int = vacationButtons!.count
            for i in 0..<count1 {
                let vacationButton = vacationButtons?[i] as? UIImageView
                if vacationButton != nil {
                    var frame: CGRect? = vacationButton?.frame
                    let layout: UICollectionViewLayoutAttributes? = flowLayout?.layoutAttributesForItem(at: IndexPath(item: i, section: 0))
                    frame?.origin.x = (layout?.frame.origin.x)!
                    frame?.origin.y = (layout?.frame.origin.y)!
                    vacationButton?.frame = frame!
                }
            }
        }
    }
    
    func layoutfvVacationButtons() {
        let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout
        if fvVacationButtons != nil {
            let count1: Int = fvVacationButtons!.count
            for i in 0..<count1 {
                let vacationButton = fvVacationButtons?[i] as? UIImageView
                if vacationButton != nil {
                    var frame: CGRect? = vacationButton?.frame
                    let layout: UICollectionViewLayoutAttributes? = flowLayout?.layoutAttributesForItem(at: IndexPath(item: i, section: 0))
                    frame?.origin.x = (layout?.frame.origin.x)!
                    frame?.origin.y = (layout?.frame.origin.y)!
                    vacationButton?.frame = frame!
                }
            }
        }
    }
    
    func layoutCfvVacationButtons() {
        let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout
        if cfvVacationButtons != nil {
            let count1: Int = cfvVacationButtons!.count
            for i in 0..<count1 {
                let vacationButton = cfvVacationButtons?[i] as? UIImageView
                if vacationButton != nil {
                    var frame: CGRect? = vacationButton?.frame
                    let layout: UICollectionViewLayoutAttributes? = flowLayout?.layoutAttributesForItem(at: IndexPath(item: i, section: 0))
                    frame?.origin.x = (layout?.frame.origin.x)!
                    frame?.origin.y = (layout?.frame.origin.y)!
                    vacationButton?.frame = frame!
                }
            }
        }
    }
    
}
