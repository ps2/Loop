//
//  NightscoutClient.swift
//  Loop
//
//  Created by Pete Schwamb on 7/22/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import Foundation
import Crypto

public struct NightscoutGlucose {
    public let glucose: UInt16
    public let trend: NightscoutGlucoseTrend
    public let timestamp: NSDate
}

public enum NightscoutGlucoseTrend: String {
    case None
    case DoubleUp
    case SingleUp
    case FortyFiveUp
    case Flat
    case FortyFiveDown
    case SingleDown
    case DoubleDown
    case NotComputable
    case RateOutOfRange
}

public enum NightscoutClientError: ErrorType {
    case Unauthorized
    case HTTPError(status: Int, body: String)
    case EmptyResponse
    case DataError(reason: String)
    case InternalError
}

private let nightscoutEntriesPath = "/api/v1/entries.json"

public enum Either<T1, T2> {
    case Success(T1)
    case Failure(T2)
}

public class NightscoutClient {
    
    public var siteURL: NSURL
    public var APISecret: String
    
    public init(siteURL: NSURL, APISecret: String) {
        self.siteURL = siteURL
        self.APISecret = APISecret
    }
    
    public func fetchLast(n: Int, callback: (Either<[NightscoutGlucose], ErrorType>) -> Void) {
        
        let testURL = siteURL.URLByAppendingPathComponent(nightscoutEntriesPath)
        
        let request = NSMutableURLRequest(URL: testURL)
        
        request.setValue("application/json", forHTTPHeaderField:"Accept")
        request.setValue(APISecret.SHA1, forHTTPHeaderField:"api-secret")
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: {  [weak self = self] (data, response, error) in
            if let error = error {
                callback(.Failure(error))
                return
            }
            
            if let httpResponse = response as? NSHTTPURLResponse where
                httpResponse.statusCode != 200 {
                if httpResponse.statusCode == 401 {
                    callback(.Failure(NightscoutClientError.Unauthorized))
                } else {
                    let bodyStr: String
                    if let data = data {
                        bodyStr = String(data: data, encoding: NSUTF8StringEncoding) ?? ""
                    } else {
                        bodyStr = ""
                    }
                    let error = NightscoutClientError.HTTPError(status: httpResponse.statusCode, body:bodyStr)
                    callback(.Failure(error))
                }
            } else {
                if let data = data {
                    if let parsedData = self?.parseResponse(data) {
                        callback(parsedData)
                    } else {
                        callback(.Failure(NightscoutClientError.InternalError))
                    }
                } else {
                    callback(.Failure(NightscoutClientError.EmptyResponse))
                }
            }
        })
        task.resume()
    }
    
    public class func decodeEntry(sgv: Dictionary<String, AnyObject>) throws -> NightscoutGlucose {
        guard let glucose = sgv["sgv"] as? Int else {
            throw NightscoutClientError.DataError(reason: "missing sgv entry in SGV record: \(sgv)")
        }
        guard let trendNum = sgv["direction"] as? String else {
            throw NightscoutClientError.DataError(reason: "missing direction entry in SGV record: \(sgv)")
        }
        
        guard let dateStr = sgv["dateString"] as? String else {
            throw NightscoutClientError.DataError(reason: "missing dateString entry in SGV record: \(sgv)")
        }
        
        let trend = NightscoutGlucoseTrend(rawValue: trendNum) ?? .None
        
        guard let timestamp = parseDate(dateStr) else {
            throw NightscoutClientError.DataError(reason: "Could not parse date \(dateStr)")
        }
        
        return NightscoutGlucose(
            glucose: UInt16(glucose),
            trend: trend,
            timestamp: timestamp
        )
    }
    
    public class func decodeEntries(sgvs: [AnyObject]) throws -> [NightscoutGlucose] {
        var transformed: [NightscoutGlucose] = []
        for sgv in sgvs as! [Dictionary<String, AnyObject>] {
            let glucose = try decodeEntry(sgv)
            transformed.append(glucose)
        }
        return transformed
    }
    
    private func parseResponse(data: NSData) -> Either<[NightscoutGlucose], ErrorType> {
        do
        {
            if let json = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? Array<AnyObject> {
                do {
                    let transformed = try NightscoutClient.decodeEntries(json)
                    return .Success(transformed)
                } catch {
                    return .Failure(error)
                }
            } else {
                return .Failure(NightscoutClientError.DataError(reason: "Expected array in response"))
            }
        }
        catch
        {
            return .Failure(error)
        }
    }
    
    static let dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSX"
        formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        return formatter
    }()
    
    private class func parseDate(dateStr: String) -> NSDate? {
        return dateFormatter.dateFromString(dateStr)
    }
}
