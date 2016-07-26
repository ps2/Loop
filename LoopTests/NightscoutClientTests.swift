//
//  NightscoutClientTests.swift
//  Loop
//
//  Created by Pete Schwamb on 7/25/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import XCTest
import HealthKit
@testable import Loop

extension XCTestCase {
    public var bundle: NSBundle {
        return NSBundle(forClass: self.dynamicType)
    }
    
    public func loadFixture<T>(resourceName: String) -> T {
        let path = bundle.pathForResource(resourceName, ofType: "json")!
        return try! NSJSONSerialization.JSONObjectWithData(NSData(contentsOfFile: path)!, options: []) as! T
    }
}

public typealias JSONDictionary = [String: AnyObject]

class NightscoutClientTests: XCTestCase {
    
    
    func testParsingSGVsFromShareBridge() throws {
        let fixture: [JSONDictionary] = loadFixture("nightscout_share_bridge_sgvs")
        
        do {
            let glucose = try NightscoutClient.decodeEntries(fixture)
            
            XCTAssertEqual(glucose.count, 10)
            
            let entry1 = glucose[0]
            XCTAssertEqual(entry1.glucose, 192)
            
            // "2016-07-25T02:54:57.000Z"
            XCTAssertEqual(entry1.timestamp.description, "2016-07-25 02:54:57 +0000")
            
        } catch {
                XCTFail("decode entries threw error \(error)")
        }
    }
    
    func testParsingSGVsFromXDrip() throws {
        let fixture: [JSONDictionary] = loadFixture("nightscout_xdrip_sgvs")
        
        do {
            let glucose = try NightscoutClient.decodeEntries(fixture)
            
            XCTAssertEqual(glucose.count, 10)
            
            let entry1 = glucose[0]
            XCTAssertEqual(entry1.glucose, 83)
            
            // "2016-07-25T09:14:09.384-0400"
            XCTAssertEqual(entry1.timestamp.description, "2016-07-25 13:14:09 +0000")
            
        } catch {
            XCTFail("decode entries threw error \(error)")
        }
    }

}
