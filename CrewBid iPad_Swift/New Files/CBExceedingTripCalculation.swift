//
//  CBExceedingTripCalculation.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 21/05/25.
//

import Foundation

class CBExceedingTripCalculation{
    
    func calculateExceedingTripRig(line: BILine, calendarData: BICalendarData, minRig: Float) -> Float {
        guard let trips = line.trips?.allObjects as? [BITrip], !trips.isEmpty else {
            return minRig
        }

        var startDateLastTrip = trips[0].startDate
        var tripLength = trips[0].info?.days?.count ?? 1

        for i in 1..<trips.count {
            let trip = trips[i]
            if let startDate = trip.startDate, let lastStart = startDateLastTrip, lastStart.compare(startDate) == .orderedAscending {
                startDateLastTrip = startDate
                tripLength = trip.info?.days?.count ?? 1
            }
        }

        guard let startDate = startDateLastTrip else {
            return minRig
        }

        let endDateLastTrip = Calendar.current.date(byAdding: .day, value: tripLength - 1, to: startDate)!

        guard let bidPeriod = line.bidPeriod,
              let monthInt = bidPeriod.month?.intValue,
              let year = bidPeriod.year else {
            return minRig
        }

        let monthString = String(format: "%02d", monthInt)
        let lineEndDateString = "\(calendarData.daysInMonth)/\(monthString)/\(year) 11:59:59 PM"

        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy hh:mm:ss a"
        formatter.timeZone = TimeZone(abbreviation: "UTC") // or use appropriate TZ

        guard let lineEndDate = formatter.date(from: lineEndDateString) else {
            return minRig
        }

        return endDateLastTrip < lineEndDate ? minRig : minRig
    }
}
