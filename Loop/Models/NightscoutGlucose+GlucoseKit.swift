//
//  NightscoutGlucose+GlucoseKit.swift
//  Loop
//
//  Created by Pete Schwamb on 7/25/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import Foundation
import HealthKit
import LoopKit


extension NightscoutGlucose: GlucoseValue {
    public var startDate: NSDate {
        return timestamp
    }
    
    public var quantity: HKQuantity {
        return HKQuantity(unit: HKUnit.milligramsPerDeciliterUnit(), doubleValue: Double(glucose))
    }
}
