//
//  AppState.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 05/06/25.
//

import Foundation
final class AppState {
    static let shared = AppState()

    var isHistoricBid: Bool = false
    var isMockData: Bool = false
    var jsonSecretIsOn:Bool = false
    var isSenioritySecretOn:Bool = false
    var mockDataYear: Int?
    var mockDataMonth: Int?
    var missingTripInfo:[String:Any]?
    private init() {}
}
