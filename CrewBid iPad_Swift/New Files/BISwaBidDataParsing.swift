//
//  BISwaBidDataParsing.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 14/11/25.
//

import Foundation
import CoreData


class BISwaBidDataParsing{
    
    var dataSource:BIBidInfoDataSource?
    var urlInfo:String?
    var bidInfo:String = ""
    var bidPeriod:BIBidPeriod?
    var calendarData = BICalendarData()
    var thanksgivingDay: UInt?
    var includeDroppedTrips:Bool?
    var intlCities:NSDictionary?
    var readError:Error?
    var linesData: [Any]?
    var tripsData: [Any]?
    
    init?(dataSource:BIBidInfoDataSource = GlobalBidInfo.shared) {
        
        guard !dataSource.base.isEmpty,
              dataSource.month > 0,
              dataSource.year > 0,
              dataSource.round > 0
        else {
            return nil
        }
        self.dataSource = dataSource
        
        let formattedMonth = String(format: "%02d", dataSource.month)
        let positionShort = CBUtils.shortName(for: dataSource.position)
        
        self.bidInfo = "\(dataSource.base)\(positionShort)\(dataSource.year)\(formattedMonth)\(dataSource.round)"
        self.urlInfo = "\(dataSource.base)\(dataSource.year)\(formattedMonth)\(dataSource.round)"

    }




    func parseAndSaveBidData(completion: @escaping ((Result<Void, Error>)) -> Void) {
        let container = CoreDataManager.shared.persistentContainer
        let moc = container.newBackgroundContext()
        moc.perform {
            self.setupBidPeriodEntity(moc: moc)
            
            var lineFileName = "\(self.bidInfo)-lines.json"
            var tripFileName = "\(self.bidInfo)-pairings.json"
            
            if AppState.shared.isHistoricBid {
                // Historic filenames are fixed
                lineFileName = "SWALineFile"
                tripFileName = "SWATripFile"
                
                self.linesData = CBUtils.readJSONStringFromFileForArray(lineFileName)
                self.tripsData = CBUtils.readJSONStringFromFileForArray(tripFileName)
                
            } else {
                
                if let lineDict = CBUtils.readJSONString(fromFile:lineFileName),
                   let tripDict = CBUtils.readJSONString(fromFile:tripFileName) {
                    
                    if let embedded = lineDict["_embedded"] as? [String: Any],
                       let lines = embedded["LinesLines"] as? [Any] {
                        self.linesData = lines
                    }else{
                        let err = NSError(domain: "BISwaBidParsing",
                                          code: 1003,
                                          userInfo: [NSLocalizedDescriptionKey: "Lines data missing in JSON"])
                        completion(.failure(err))
                        return
                    }
                    
                    if let embedded = tripDict["_embedded"] as? [String: Any],
                       let trips = embedded["LinesPairings"] as? [Any] {
                        self.tripsData = trips
                    }else{
                        let err = NSError(domain: "BISwaBidParsing",
                                          code: 1004,
                                          userInfo: [NSLocalizedDescriptionKey: "Trips data missing in JSON"])
                        completion(.failure(err))
                        return
                    }
                }
            }
            
            
            self.bidPeriod?.bidByEmpID = self.dataSource?.employeeNumber
            self.bidPeriod?.isSwaAPI = 1
            
            // Parse bid data
            let success = self.parseBidData(moc: moc)
            assert(self.bidPeriod?.managedObjectContext === moc)
            assert(self.calendarData.bidPeriod === self.bidPeriod)
            assert(self.calendarData.bidPeriod?.objectID == self.bidPeriod?.objectID)
            if success{
                do{
                    try moc.save()
                    container.viewContext.perform {
                        container.viewContext.mergeChanges(fromContextDidSave:
                                                            Notification(
                                                                name: .NSManagedObjectContextDidSave,
                                                                object: moc
                                                            )
                        )
                    }
                    CBUtils.deleteFile(withName: lineFileName)
                    CBUtils.deleteFile(withName: tripFileName)
                    CBGlobalMethods.shared.selectedBidPeriod = self.bidPeriod
                    NotificationCenter.default.post(
                        name: Notification.Name("BidParsingCompleted"),
                        object: nil
                    )
                    
                    completion(.success(()))
                }catch{
                    print("Error saving new data: %@", error.localizedDescription)
                    completion(.failure(error))
                    return
                }
            }else{
                let err = NSError(domain: "BISwaBidParsing",
                                  code: 1005,
                                  userInfo: [NSLocalizedDescriptionKey: "parseBidData() returned false"])
                completion(.failure(err))
                return
            }
        }
    }
    
    
    private func postParsingProgress(currentIndex: Int, total: Int) {
        let parsingStart: Double = 0.60     // Parsing begins at 60%
        let parsingEnd: Double   = 1.00     // Parsing ends at 100%

        if total == 0 { return }

        if currentIndex == 0 {
            // Force EXACT 60% on first update
            NotificationCenter.default.post(
                name: Notification.Name("UpdateProgress"),
                object: nil,
                userInfo: ["progress": Float(parsingStart)]
            )
            return
        }

        let percent = Double(currentIndex) / Double(total)
        let progress = parsingStart + (percent * (parsingEnd - parsingStart))

        NotificationCenter.default.post(
            name: Notification.Name("UpdateProgress"),
            object: nil,
            userInfo: ["progress": Float(progress)]
        )
        
        if progress >= 0.8 {
            NotificationCenter.default.post(
                name: Notification.Name("ReadingTrips"),
                object: nil
            )
        }
        if progress >= 0.98{
            NotificationCenter.default.post(
                name: Notification.Name("ReadingLines"),
                object: nil
            )
        }
        
    }
    
    private func buildTripLookup() -> [String: [[String:Any]]] {
        var lookup: [String: [[String:Any]]] = [:]

        guard let trips = self.tripsData as? [[String:Any]] else { return lookup }

        for trip in trips {
            if let key = trip["pairingKey"] as? [String:Any],
               let num = key["pairingNumber"] as? String,
               let date = key["pairingDate"] as? String {

                let lookupKey = "\(num)|\(date)"
                lookup[lookupKey, default: []].append(trip)
            }
        }
        return lookup
    }
    
    private func parseBidData(moc:NSManagedObjectContext) -> Bool{
//        guard let moc = dataSource?.managedObjectContext else { return false}
        let tripLookup = buildTripLookup()
        var dataParseCompleted = true
        
        let bidInfoReader = BIBidInfoReader()
        bidInfoReader.bidPeriod = self.bidPeriod
        bidInfoReader.calendarData = self.calendarData
        bidInfoReader.includeDroppedTrips = UserDefaults.standard.bool(forKey: kCBIncludeDroppedTripsInProcessingKey)
        bidInfoReader.intlCities = UserDefaults.standard.object(forKey: kCBInternationalCitiesDict) as? [String : Any] ?? [:]
        
        
        if let lines = self.linesData as? [[String: Any]] {
            for line in lines {
                if let missionType = line["missionType"] as? String,
                   missionType == "ET" {
                    bidPeriod?.isEtopsLinesContainsInBid = true
                    break
                }
            }
        }
        
        var shouldStop = false
        var missingTripText = ""
        
        if let linesData = self.linesData as? [[String: Any]] {
            for i in 0..<linesData.count where !shouldStop {
                
                self.postParsingProgress(currentIndex: i, total: linesData.count)
                
                let lineData = linesData[i]
                
                // lineType
                let lineType = lineData["lineType"] as? String ?? ""
                let isReserveLine = lineType.contains("RESERVE")
                
                // seatPositions
                let rawPositionArray = (lineData["lineKey"] as? [String: Any])?["seatPositions"]
                
                var positionArray: [String] = []
                
                if let array = rawPositionArray as? [String] {
                    positionArray = array
                } else if rawPositionArray is NSNull {
                    positionArray = [""]
                }
                
                for position in positionArray{
                    
                    let line = BILine(context: moc)

                    if let context = line.managedObjectContext,
                       let bpObjectID = self.bidPeriod?.objectID,
                       let bidPeriod = try? context.existingObject(with: bpObjectID) as? BIBidPeriod {
                        
                        line.bidPeriod = bidPeriod
                        
                        // Line Number
                        if let lineKey = lineData["lineKey"] as? [String: Any],
                            let lineNumber = lineKey["lineNumber"]
                        {
                            line.number = CBUtils.nsNumber(from: lineNumber)
                        }
                        
                        line.faPosition = CBUtils.getTripPositionNumber(position)
                        
                        let linePay = CBUtils.nsNumber(from: lineData["totalLineCredit"])
                        
                        line.pay = linePay
                        line.actualPay = linePay
                        line.tripTfp = linePay
                        
                        // Mapping trips with line data
                        
                        var linePairingArray = lineData["linePairings"] as? [Any] ?? []
                        
                        for i in 0..<linePairingArray.count{
                            
                            guard let linePairing = linePairingArray[i] as? [String: Any] else { continue }
                            
                            let pairingKey = linePairing["pairingKey"] as? [String: Any]
                            let lineTripNumber = pairingKey?["pairingNumber"] as? String ?? ""
                            let lineTripDate   = pairingKey?["pairingDate"]   as? String ?? ""
                            let positionArray = pairingKey?["seatPositions"] as? [String] ?? []
                            let position = positionArray.first ?? "NA"
                            
//                            if let tripsData = self.tripsData as? [[String:Any]]{
//                                for tripDict in tripsData {
//
//                                    let pairingKey = tripDict["pairingKey"] as? [String: Any]
//                                    let pairingTripNum  = pairingKey?["pairingNumber"] as? String ?? ""
//                                    let pairingTripDate = pairingKey?["pairingDate"]   as? String ?? ""
//
//                                    if (lineTripNumber == pairingTripNum) && (lineTripDate == pairingTripDate) {
//
//                                        linePairingArray[i] = NSNull()
//                                        if isReserveLine {
//                                            self.readTripsForReserve(line: line, tripDict: tripDict, moc: moc)
//                                        } else {
//                                            self.readTrips(line: line, tripDict: tripDict, position: position, moc: moc)
//                                        }
//                                    } else {
//                                        continue
//                                    }
//                                }
//                            }
                            let lookupKey = "\(lineTripNumber)|\(lineTripDate)"
                            if let tripArray = tripLookup[lookupKey] {

                                for tripDict in tripArray {

                                    linePairingArray[i] = NSNull()

                                    if isReserveLine {
                                        self.readTripsForReserve(
                                            line: line,
                                            tripDict: tripDict,
                                            moc: moc
                                        )
                                    } else {
                                        self.readTrips(
                                            line: line,
                                            tripDict: tripDict,
                                            position: position,
                                            moc: moc
                                        )
                                    }
                                    break   // IMPORTANT: matches Obj-C behavior
                                }
                            }
//                            if let tripDict = tripLookup[lookupKey] {
//
//                                linePairingArray[i] = NSNull()
//
//                                if isReserveLine {
//                                    self.readTripsForReserve(line: line,tripDict: tripDict,moc: moc)
//                                } else {
//                                    self.readTrips(line: line,tripDict: tripDict,position: position,moc: moc)
//                                }
//                            }
                        }
                        
                        // Code for checking the Missing trip
                        let hasNonNull = linePairingArray.contains { $0 is [String: Any] }
                        
                        if hasNonNull{
                            print("Missing trip for Line -- \(line.number ?? 0)")
                            
                            for case let linePairing as [String: Any] in linePairingArray {
                                if let pairingKey = linePairing["pairingKey"] as? [String: Any] {
                                    let lineTripNumber = pairingKey["pairingNumber"] as? String ?? ""
                                    let lineTripDate = pairingKey["pairingDate"] as? String ?? ""
                                    print("\(lineTripNumber) -- \(lineTripDate)")
                                    
                                    // Set missing trip message
                                    missingTripText = "The Bid Data is missing trip information. We will not be able to display the bid data. We have contacted Southwest regarding this problem."
                                    
                                    self.readError = BIBidInfoError.error(for: .managedObjectContextSaveFailed, underlyingReason: missingTripText)

                                    
                                    shouldStop = true
                                    dataParseCompleted = false
                                    break
                                }
                            }
                        }
                        
                        // Line Type
                        self.setLineType(for: line, data: lineData, bidPeriod: self.bidPeriod!)
                        
                        // Update the startDate & endDate as fixed value for 2nd Round FA Reserve lines
                        
                        if self.bidPeriod!.isSecondRoundBid(){
                            self.setStartEndDateForReserveTrips(line: line)
                        }
                        
                        // Remove redundant trips with same number and start date
                        var uniqueTrips = Set<String>()
                        let tripsToKeep = NSMutableSet()

                        for case let trip as BITrip in line.trips ?? [] {
                            let key = "\(trip.startDate?.description ?? "")_\(trip.number ?? "")"
                            
                            if !uniqueTrips.contains(key) {
                                uniqueTrips.insert(key)
                                tripsToKeep.add(trip)
                            }
                        }

                        // Assign the filtered trips back
//                        line.trips = NSSet(set: tripsToKeep)
                        if let existingTrips = line.trips as? Set<BITrip> {
                            for trip in existingTrips {
                                let key = "\(trip.startDate?.description ?? "")_\(trip.number ?? "")"
                                if !uniqueTrips.contains(key) {
                                    moc.delete(trip)
                                }
                            }
                        }

                        // Block minutes
                        let lineBlockMin = CBUtils.nsNumber(from: lineData["totalBlockTime"])
                        line.blockMinutes = lineBlockMin
                        line.actualBlockMinutes = lineBlockMin

                        // Reset FA position so it can be re-evaluated
                        line.faPosition = nil

                        // Recalculate derived properties
                        bidInfoReader.initDerivedPropertiesForLine(line: line, isReprocessing: false)
                        
                        
                    }
                }
            }

        }

//        if moc.hasChanges{
//            do{
//                try moc.save()
//            }catch{
//                let errReason = "\(BIBidInfo().dataFilenameBase()) unable to save managed object context after reading trips and lines files."
//                self.readError = BIBidInfoError.error(for: .managedObjectContextSaveFailed, underlyingReason: errReason)
//            }
//        }
        assert(self.bidPeriod?.managedObjectContext === moc)
        bidInfoReader.addDefaultFilterRules(context: moc)
        bidInfoReader.calculateWorkBlockDetails()
        
        return dataParseCompleted
    }
    
    private func setupBidPeriodEntity(moc: NSManagedObjectContext){
        let bidPeriod = BIBidPeriod(context: moc)
        self.bidPeriod = bidPeriod
        bidPeriod.isHistoric = NSNumber(value: AppState.shared.isHistoricBid)
        bidPeriod.year = NSNumber(value: self.dataSource?.year ?? 0)
        bidPeriod.base = self.dataSource?.base
        bidPeriod.month = NSNumber(value: self.dataSource?.month ?? 0)
        bidPeriod.positionType = NSNumber(value: self.dataSource?.position.rawValue ?? 0)
        bidPeriod.round = NSNumber(value: self.dataSource?.round ?? 0)
        bidPeriod.appVersion = CBUtils.AppVersion()
        bidPeriod.created = Date()
        
        if let empNumString = self.dataSource?.employeeNumber,
            let empNum = Int(empNumString) {
            bidPeriod.crewIdentifier = NSNumber(value: empNum)
        }
        
        if let fullId = self.dataSource?.swaptimizerID {
            let trimmed = String(fullId.dropFirst())
            bidPeriod.swaptimizerIdentifier = NSNumber(value: Int(trimmed) ?? 0)
        }
        
        bidPeriod.isAllLinesTrashed = false
        bidPeriod.lastTrashedDetails = NSMutableArray()

        let calendar = BICalendarData()
        calendar.bidPeriod = self.bidPeriod
        self.calendarData = calendar
        self.calendarData = calendar.initWithBidPeriod(bidPeriod: bidPeriod)!
        
        self.thanksgivingDay = CBUtils.thanksgivingDay(for: bidPeriod.year?.intValue ?? 0)
        self.includeDroppedTrips = UserDefaults.standard.bool(forKey: kCBIncludeDroppedTripsInProcessingKey)
        self.intlCities = UserDefaults.standard.object(forKey: kCBInternationalCitiesDict) as? NSDictionary
        
        if !AppState.shared.isHistoricBid {
            let seniorityList = self.parseAndSaveSeniorityData(context: moc)
            bidPeriod.seniorityList = seniorityList as NSSet
            bidPeriod.coverLetterFileName = "\(self.bidInfo)-cover-letter.pdf"
            let buddyBids = self.parseAndSaveBuddyBids(context: moc)
            bidPeriod.buddyBid = buddyBids as NSSet
            self.getMetaData()
        }
    }
    
    func refreshSeniorityFromDownloadedJSON(
        bidPeriod: BIBidPeriod,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let container = CoreDataManager.shared.persistentContainer
        let context = container.newBackgroundContext()
        context.perform {
            do {
                let localBidPeriod = try context.existingObject(
                    with: bidPeriod.objectID
                ) as! BIBidPeriod
                if let existing = localBidPeriod.seniorityList as? Set<SeniorityList> {
                    for item in existing {
                        context.delete(item)
                    }
                }
                let newSet = self.parseAndSaveSeniorityData(context: context)
                localBidPeriod.seniorityList = newSet as NSSet
                try context.save()
                completion(.success(()))

            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private func parseAndSaveSeniorityData(context:NSManagedObjectContext) -> Set<SeniorityList>{
        let fileName = String(format: "%@-SeniorityList.json", self.bidInfo)
        guard let responseDict = CBUtils.readJSONString(fromFile: fileName) else { return [] }
        
        var emp = ""
        
        if !AppState.shared.isSenioritySecretOn{
            emp = self.bidPeriod?.crewIdentifier?.stringValue ?? ""
        }else{
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                emp = appDelegate.ObjUserAccount?.LoginuserId ?? ""
            }
        }
        
        guard let embeddedDict = responseDict["_embedded"] as? [String:Any] else { return [] }
        let dictKey = self.dataSource?.round == 1 ? "IFLineBaseAuctionSeniorities" : "IFLineBaseAuctionReserveAwards"
        
        guard let seniorityArray = embeddedDict[dictKey] as? [[String:Any]] else{ return []}
        
        var senioritySet = Set<SeniorityList>()
        
        for seniorityDict in seniorityArray {
            let seniority = SeniorityList(context: context)
            seniority.bidPeriod = self.bidPeriod
            seniority.baseSeniority = seniorityDict["baseSeniority"] as? NSNumber
            seniority.legalName = seniorityDict["legalName"] as? String
            seniority.employeeId = seniorityDict["employeeId"] as? String
            
            if emp == (seniorityDict["employeeId"] as? String){
                self.bidPeriod?.seniorityNumber = seniority.baseSeniority
            }
            
            
            if self.dataSource?.round == 1{
                seniority.department = seniorityDict["department"] as? String
                seniority.legalName = seniorityDict["legalName"] as? String
                seniority.employeeId = seniorityDict["employeeId"] as? String
                seniority.base = seniorityDict["base"] as? String
                seniority.baseSeniority = seniorityDict["baseSeniority"] as? NSNumber
                seniority.companySeniority = seniorityDict["companySeniority"] as? NSNumber
                
                if let vacation = seniorityDict["vacation"], !(vacation is NSNull){
                    if let jsonData = try? JSONSerialization.data(withJSONObject: vacation),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        seniority.vacation = jsonString
                    }
                } else {
                    seniority.vacation = nil
                }
                
                if let lodo = seniorityDict["lodoQualification"], !(lodo is NSNull) {
                    if let jsonData = try? JSONSerialization.data(withJSONObject: lodo),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        seniority.lodoQualification = jsonString
                    }
                } else {
                    seniority.lodoQualification = nil
                }
            }
            senioritySet.insert(seniority)
        }
//        do {
//            try context.save()
//            CBUtils.deleteFile(withName: fileName)
//        } catch {
//            print("Save Error: \(error)")
//        }
        CBUtils.deleteFile(withName: fileName)
        return senioritySet
    }
    
    private func parseAndSaveBuddyBids(context:NSManagedObjectContext) -> Set<BuddyBids>{
        
        let fileName = String(format: "%@-BuddyBidIDs.json", self.bidInfo)
        guard let responseDict = CBUtils.readJSONString(fromFile: fileName)
              /*let context = self.dataSource?.managedObjectContext*/ else { return [] }
        
        guard let buddyArray = responseDict["buddyIds"]as? [String] else{ return []}
        
        var buddySet = Set<BuddyBids>()
        
        for buddy in buddyArray{
            let buddyBidEntity = BuddyBids(context: context)
            buddyBidEntity.buddyId = buddy
            buddyBidEntity.bidPeriod = bidPeriod
            buddySet.insert(buddyBidEntity)
        }
//        do {
//            try context.save()
//            CBUtils.deleteFile(withName: fileName)
//        } catch {
//            print("Save Error: \(error)")
//        }
        CBUtils.deleteFile(withName: fileName)
        return buddySet
    }
    
    private func getMetaData(){
        let bidDownload = BISwaBidDataDownload()
        
        bidDownload?.downloadMetaData(urlInfo: self.urlInfo!){result in
            switch result{
            case .success(let dict):
                
                guard let bidPeriod = self.bidPeriod,
                      let context = bidPeriod.managedObjectContext else {
                    print("Missing bidPeriod or its managedObjectContext")
                    return
                }


                context.perform {

                    let metaData = MetaData(context: context)

                    metaData.abcPositions  = Int32(dict["abcPositions"] as? Int ?? 0)
                    metaData.abcdPositions = Int32(dict["abcdPositions"] as? Int ?? 0)
                    metaData.aPositions    = Int32(dict["apositions"] as? Int ?? 0)
                    metaData.dPositions    = Int32(dict["dpositions"] as? Int ?? 0)
                    metaData.bcPositions   = Int32(dict["bcPositions"] as? Int ?? 0)

                    bidPeriod.addToMetaData(metaData)

//                    do {
//                        try context.save()
//                    } catch {
//                        print("Save Error:", error)
//                    }
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func readTripsForReserve(line: BILine,tripDict: [String: Any],moc: NSManagedObjectContext) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")

//        let baseContext = /*self.dataSource?.managedObjectContext ??*/ moc

        //Trip Info
        let tripInfo = BITripInfo(context: moc)

        let pairingKey = tripDict["pairingKey"] as? [String: Any]
        tripInfo.number = pairingKey?["pairingNumber"] as? String

        if let tripPay = tripDict["tripPay"] as? [String: Any] {
            tripInfo.faPay = CBUtils.nsNumber(from: tripPay["totalTripForPay"])
        } else {
            tripInfo.faPay = 0
        }
        tripInfo.briefMinutes = 60
        tripInfo.debriefMinutes = 30
        tripInfo.calendarDaysCount = 1
        tripInfo.dutyPeriodsCount = 0

        if let reportUTC = tripDict["reportDateTimeUTC"] as? String,
           let reportDate = dateFormatter.date(from: reportUTC) {
            let converted = CBUtils.convertToHerb(fromUTC: reportDate)!
            tripInfo.departTime = CBUtils.convertMinsToHHMM(CBUtils.getMinutes(from: converted)) as NSNumber
        }

        if let releaseUTC = tripDict["releaseDateTimeUTC"] as? String,
           let releaseDate = dateFormatter.date(from: releaseUTC) {
            let converted = CBUtils.convertToHerb(fromUTC: releaseDate)!
            tripInfo.returnTime = CBUtils.convertMinsToHHMM(CBUtils.getMinutes(from: converted)) as NSNumber
        }

        // AM / PM flag
        if (tripInfo.departTime?.intValue ?? 0) < 800 {
            tripInfo.amPM = BIAMPMTripType.AMTrip.rawValue as NSNumber
        } else {
            tripInfo.amPM = BIAMPMTripType.PMTrip.rawValue as NSNumber
        }

        // Trip
        let trip = BITrip(context: moc)
        trip.line = line
        trip.info = tripInfo
        trip.number = tripInfo.number
        trip.isReserveFa = true
        tripInfo.calendarDaysCount = 1
        tripInfo.faPay = 6.5
        trip.position = BIFaPosition.FaPositionNA.rawValue as NSNumber
        trip.positionString = CBUtils.getTripPosition(BIFaPosition.FaPositionNA)

        // Trip Start Date
        if let dateString = pairingKey?["pairingDate"] as? String {
            let dateFmt = DateFormatter()
            dateFmt.dateFormat = "yyyy-MM-dd"
            if let date = dateFmt.date(from: dateString) {
                trip.startDate = self.calendarData.dateForDate(date: date)
                tripInfo.startDate = trip.startDate

                trip.tripStartDay = CBUtils.getDay(from: trip.startDate ?? Date())
                trip.startDay = CBUtils.getDateOnly(from: trip.startDate ?? Date())
                trip.startDate = calendarData.dateForDayOfMonth(dayOfMonth: trip.startDay!.intValue)

                let dayCount = tripInfo.orderedDays().count
                let endDay = (trip.startDay?.intValue ?? 0) + (dayCount - 1)
                trip.endDate = self.calendarData.dateForDayOfMonth(dayOfMonth: endDay)
            }
        }

        // Day Info
        let dayInfo = BIDayInfo(context: moc)
        dayInfo.dutyPeriodNumber = 1
        dayInfo.trip = tripInfo
        tripInfo.firstDay = dayInfo

        // Leg Info
        let legInfo = BILegInfo(context: moc)
        legInfo.departMinutes = 720
        legInfo.arriveMinutes = 720
        legInfo.flight = tripInfo.number
        legInfo.departCity = self.bidPeriod?.base
        legInfo.arriveCity = self.bidPeriod?.base
        legInfo.day = tripInfo.firstDay
        legInfo.pay = 6.5
        legInfo.equipment = "3"

        // Line Type
        line.type = BILineType.ReserveLine.rawValue as NSNumber

        // ETOPS Check
        
        line.isETOPSRES = false
        if let mission = tripDict["missionType"] as? String, mission == "ET" {
            legInfo.isEtopsFlight = true
            tripInfo.isETOPS = true
            line.isETOPS = true
        } else {
            if line.isETOPS?.intValue != 1 {
                line.isETOPS = false
            }
            legInfo.isEtopsFlight = false
        }
    }
    
    private func readTrips(line: BILine,tripDict: [String: Any],position: String,moc: NSManagedObjectContext)
    {
       
        var dayInfo: BIDayInfo? = nil
        var prevDayInfo:BIDayInfo? = nil
        
        var legInfo:BILegInfo? = nil
        var prevLegInfo:BILegInfo? = nil
        
        // TripInfo
        let tripInfo = BITripInfo(context: moc)
        tripInfo.number = ((tripDict["pairingKey"] as? [String: Any])?["pairingNumber"] as? String) ?? ""

        if let tripPay = (tripDict["tripPay"] as? [String: Any])?["totalTripForPay"] {
            tripInfo.faPay = CBUtils.nsNumber(from: tripPay)
        }

        tripInfo.briefMinutes   = 60
        tripInfo.debriefMinutes = 30

        // Date formatter (UTC)
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        df.timeZone = TimeZone(abbreviation: "UTC")

        var firstDayDate: Date?
        var firstDayReportMin = 0

        var firstLegDate: Date?
        var firstLegDepartMin = 0

        // Parse duties array
        let daysData = tripDict["duties"] as? [[String: Any]] ?? []

        for i in 0..<daysData.count {
            let dayData = daysData[i]

            dayInfo = BIDayInfo(context: moc)
            dayInfo?.dutyPeriodNumber = CBUtils.nsNumber(from: dayData["dutyPeriodNumber"])
            dayInfo?.trip = tripInfo
            dayInfo?.dutyMinutes = CBUtils.nsNumber(from: dayData["dutyMinutes"])
            dayInfo?.blockMinutes = CBUtils.nsNumber(from: dayData["totalBlockMinutes"])
            
            let reportDate = CBUtils.convertToHerb(
                fromUTC: df.date(from: dayData["reportDateTimeUTC"] as? String ?? "") ?? Date()
            )

            let releaseDate = CBUtils.convertToHerb(
                fromUTC: df.date(from: dayData["releaseDateTimeUTC"] as? String ?? "") ?? Date()
            )
            
            if firstDayDate == nil, let rep = reportDate {
                firstDayDate = rep
                firstDayReportMin = CBUtils.getMinutes(from: rep)
            }
            
            if let firstDayDate = firstDayDate, let reportDate = reportDate {
                let deltaMinutes = Int(reportDate.timeIntervalSince(firstDayDate) / 60)
                let dayReportTime = firstDayReportMin + deltaMinutes
                dayInfo?.reportTime = NSNumber(value: dayReportTime)
            }
            
            if let firstDayDate = firstDayDate, let releaseDate = releaseDate {
                let deltaMinutes = Int(releaseDate.timeIntervalSince(firstDayDate) / 60)
                let dayReleaseTime = firstDayReportMin + deltaMinutes
                dayInfo?.releaseTime = NSNumber(value: dayReleaseTime)
            }
            
            if i == 0 {
                tripInfo.firstDay = dayInfo
                prevDayInfo = nil
            }

            dayInfo?.previousDay = prevDayInfo
            prevDayInfo = dayInfo

            let legsData = dayData["flightLegs"] as? [[String: Any]] ?? []
            for j in 0..<legsData.count {
                
                let legData = legsData[j]
                
                legInfo = BILegInfo(context:moc)
                
                legInfo?.legNumber = CBUtils.nsNumber(from: legData["legNumber"])
                legInfo?.isRedEyeFlight = CBUtils.nsNumber(from: legData["redeye"])
                
                if let flightLegKey = legData["flightLegKey"] as? [String: Any] {
                    legInfo?.flight = flightLegKey["flightNumber"] as? String
                    legInfo?.departCity = flightLegKey["departureAirportIATACode"] as? String
                    legInfo?.arriveCity = flightLegKey["arrivalAirportIATACode"] as? String
                }
                
                legInfo?.isDeadhead = CBUtils.nsNumber(from: legData["deadhead"])
                
                if let equipment = legData["equipment"] as? [String: Any] {
                    legInfo?.equipment = CBUtils.getEquipmentType(equipment["equipmentLegCode"] as? String)
                }
                
                legInfo?.isAircraftChange = CBUtils.nsNumber(from: legData["aircraftChange"])
                legInfo?.pay = CBUtils.nsNumber(from: legData["tripForPay"])
                
                let departureDate = CBUtils.convertToHerb(
                    fromUTC: df.date(from: legData["departureDateTimeUTC"] as? String ?? "") ?? Date()
                )
                
                let arrivalDate = CBUtils.convertToHerb(
                    fromUTC: df.date(from: legData["arrivalDateTimeUTC"] as? String ?? "") ?? Date()
                )
                
                if firstLegDate == nil, let dep = departureDate {
                    firstLegDate = dep
                    firstLegDepartMin = CBUtils.getMinutes(from: dep)
                }
                
                var offset = 0
                
                // Calculate departure minutes
                if let depDate = departureDate, let firstDate = firstLegDate {
                    offset = CBUtils.dstMinuteAdjustment(from: firstDate, to: depDate)
                    let departMinutes = firstLegDepartMin + Int(depDate.timeIntervalSince(firstDate) / 60)
                    legInfo?.departMinutes = NSNumber(value: departMinutes  + offset)
                }
                // Calculate arrival minutes
                if let arrDate = arrivalDate, let firstDate = firstLegDate {
                    let arriveMinutes = firstLegDepartMin + Int(arrDate.timeIntervalSince(firstDate) / 60)
                    legInfo?.arriveMinutes = NSNumber(value: arriveMinutes  + offset)
                }
                
                
                if i == 0 && j == 0 {
                    tripInfo.departTime = NSNumber(value: CBUtils.convertMinsToHHMMFor24Hrs(legInfo?.departMinutes?.intValue ?? 0))
                    
                    // AM - PM setup
                    let herbValueStr = UserDefaults.standard.string(forKey: KCBCustomizedHerbValue)
                    let herbValue: Int
                    if let herbValueStr = herbValueStr, !herbValueStr.isEmpty, let hv = Int(herbValueStr) {
                        herbValue = hv
                    } else {
                        herbValue = 1200
                    }
                    
                    if tripInfo.departTime?.intValue ?? 0 < herbValue {
                        tripInfo.amPM = NSNumber(value: BIAMPMTripType.AMTrip.rawValue)
                    } else {
                        tripInfo.amPM = NSNumber(value: BIAMPMTripType.PMTrip.rawValue)
                    }
                    
                    self.bidPeriod?.currentAmPmHerb = NSNumber(value: herbValue)
                }
                
                if j == 0 {
                    dayInfo?.firstLeg = legInfo
                }
                
                legInfo?.day = dayInfo
                legInfo?.previousLeg = prevLegInfo
                prevLegInfo?.nextLeg = legInfo
                prevLegInfo = legInfo
                
                if (i == daysData.count - 1){
                    legInfo?.isDutyBreak = NSNumber(booleanLiteral: true)
                }
                
                dayInfo?.city = legInfo?.arriveCity
                
                
                // ETOPS
                
                line.isETOPSRES = false
                
                if let mission = tripDict["missionType"] as? String, mission == "ET" {
                    legInfo?.isEtopsFlight = true
                    tripInfo.isETOPS = true
                    line.isETOPS = true
                } else {
                    if line.isETOPS?.intValue != 1 {
                        line.isETOPS = false
                    }
                    legInfo?.isEtopsFlight = false
                }

                if let arriveCity = legInfo?.arriveCity,
                   let _ = self.intlCities?[arriveCity] {
                    line.type = BILineType.HardNonConUS.rawValue as NSNumber
                }
            }
        }
        
        
        tripInfo.blockMinutes = (tripDict["operationalInfo"] as? [String: Any])?["totalBlockMinutes"] as? NSNumber
        tripInfo.dutyMinutes = (tripDict["operationalInfo"] as? [String: Any])?["totalDutyMinutes"] as? NSNumber

        tripInfo.calendarDaysCount = NSNumber(value: daysData.count)
        tripInfo.dutyPeriodsCount = NSNumber(value: daysData.count)

        if let arrMins = legInfo?.arriveMinutes?.intValue {
            let hhmm = CBUtils.convertMinsToHHMM(arrMins) % 2400
            tripInfo.returnTime = NSNumber(value: hhmm)
        }
        
        // Assigning BITrip Entity
        
        let trip = BITrip(context: moc)
        trip.line = line
        trip.number = tripInfo.number
        trip.info = tripInfo
        
        if let pairingKey = tripDict["pairingKey"] as? [String: Any],
           let dateString = pairingKey["pairingDate"] as? String {

            df.dateFormat = "YYYY-MM-dd"

            if let tripDate = df.date(from: dateString) {
                trip.startDate = calendarData.dateForDate(date: tripDate)
                trip.startDay = CBUtils.getDateOnly(from: trip.startDate ?? Date())
                trip.startDate = calendarData.dateForDayOfMonth(dayOfMonth: trip.startDay!.intValue)
                tripInfo.startDate = trip.startDate
            }
        }

        // Start day and date properties
        trip.tripStartDay = CBUtils.getDay(from: trip.startDate ?? Date())
        trip.startDay = CBUtils.getDateOnly(from: trip.startDate ?? Date())

        // endDate = startDay + orderedDays.count - 1
        if let startDay = trip.startDay?.intValue {
            let offset = (trip.info?.orderedDays().count ?? 1) - 1
            trip.endDate = calendarData.dateForDayOfMonth(dayOfMonth: startDay + offset)
        }

        trip.isReserveFa = false

        if let faPosition = line.faPosition,
           faPosition != NSNumber(value: BIFaPosition.FaPositionNA.rawValue) {

            if let enumPos = BIFaPosition(rawValue: faPosition.intValue) {
                trip.positionString = CBUtils.getTripPosition(enumPos)
            } else {
                trip.positionString = ""
            }

            trip.position = faPosition

        } else {
            
            let posNumber = CBUtils.getTripPositionNumber(position)
            trip.position = posNumber

            if let enumPos = BIFaPosition(rawValue: posNumber.intValue) {
                trip.positionString = CBUtils.getTripPosition(enumPos)
            } else {
                trip.positionString = ""
            }
        }
        
    }
    
    private func setLineType(for line: BILine, data: [String: Any], bidPeriod: BIBidPeriod) {
        
        let type = data["lineType"] as? String ?? ""
        
        // Basic line type
        if type == "HARD" {
            line.type = BILineType.HardConUS.rawValue as NSNumber
        }
        
        // International check
        let isInternational = CBUtils.nsNumber(from: data["international"]).boolValue
        if isInternational {
            line.type = NSNumber(value: BILineType.HardNonConUS.rawValue)
        }
        
        // Language check
        if let language = data["language"] as? String, !language.isEmpty, language != "EN" {
            if line.faPosition?.intValue == 1 {
                line.type = BILineType.BILineTypeLoDo.rawValue as NSNumber
                line.isLODO = true
            }
        }
        
        // Reserve lines
        if type.contains("RESERVE") {
            line.faReserveLineType = BILineType.ReserveLine.rawValue as NSNumber
            
            switch type {
            case "SENIOR_AM_RESERVE":      line.faReserveLineType = BIFaReserveLineType.SnrAMres.rawValue as NSNumber
            case "JUNIOR_AM_RESERVE":      line.faReserveLineType = BIFaReserveLineType.JnrAMres.rawValue as NSNumber
            case "SENIOR_PM_RESERVE":      line.faReserveLineType = BIFaReserveLineType.SnrPMres.rawValue as NSNumber
            case "JUNIOR_PM_RESERVE":      line.faReserveLineType = BIFaReserveLineType.JnrPMres.rawValue as NSNumber
            case "JUNIOR_LATE_RESERVE":    line.faReserveLineType = BIFaReserveLineType.JnrLateRes.rawValue as NSNumber
            case "READY_RESERVE":          line.faReserveLineType = BIFaReserveLineType.ReadyRes.rawValue as NSNumber
            default: break
            }
        }
        
        // ETOPS adjustments
        if bidPeriod.isEtopsLinesContainsInBid?.intValue == 1 {
            
            if bidPeriod.isSecondRoundBid(),
               line.isETOPS?.intValue == 1,
               line.type?.intValue != BILineType.ReserveLine.rawValue {
                line.type = BILineType.NonReserveEtops.rawValue as NSNumber
            }
            
            if bidPeriod.isSecondRoundBid(),
               line.type?.intValue == BILineType.ReserveLine.rawValue,
               line.isETOPS?.intValue == 0 {
                line.type = BILineType.NonEtopsReserve.rawValue as NSNumber
            }
            
            if line.type?.intValue == BILineType.HardConUS.rawValue,
               line.isETOPS?.intValue == 0 {
                line.type = BILineType.NonEtopsConUS.rawValue as NSNumber
            }
            
            if line.type?.intValue == BILineType.HardNonConUS.rawValue,
               line.isETOPS?.intValue == 0 {
                line.type = BILineType.NonEtopsNonConUS.rawValue as NSNumber
            }
            
            if bidPeriod.isFirstRoundBid(),
               line.isETOPS?.intValue == 1 {
                line.type = BILineType.EtopsFAFirstRound.rawValue as NSNumber
            }
        }
    }
    
    private func setStartEndDateForReserveTrips(line: BILine){
        for case let trip as BITrip in line.trips ?? []{
            let timeZoneStr = CBUtils.rawTimeZoneString(forAirportCode: (bidPeriod?.base)!)
            
            // --- DEPART TIME ---
            if let departHHMM = BITrip.staticTimeForFAReserveType(trip: trip, line: line, key: "depart", timeZone: timeZoneStr!){
                
                if let updatedStart = CBUtils.date(bySettingHHMM: departHHMM, to: trip.startDate) {
                    trip.startDate = updatedStart
                    trip.info?.startDate = updatedStart
                }
                
                trip.info?.departTime = NSNumber(value: Int(departHHMM) ?? 0)
            }
            
            // --- ARRIVE TIME ---
            if let arriveHHMM = BITrip.staticTimeForFAReserveType(trip: trip,
                                                                  line: line,
                                                                  key: "arrive",
                                                                  timeZone: timeZoneStr!) {
                
                if let updatedEnd = CBUtils.date(bySettingHHMM: arriveHHMM, to: trip.endDate) {
                    trip.endDate = updatedEnd
                }
                
                trip.info?.returnTime = NSNumber(value: Int(arriveHHMM) ?? 0)
                
                // If endDate < startDate → add 1 day
                if let start = trip.startDate, let end = trip.endDate, end < start {
                    var calendar = Calendar(identifier: .gregorian)
                    calendar.locale = Locale.current
                    calendar.timeZone = TimeZone(identifier: "GMT")!

                    if let nextDay = calendar.date(byAdding: .day, value: 1, to: end) {
                        trip.endDate = nextDay
                    }
                }
            }
        }
    }
    
}
