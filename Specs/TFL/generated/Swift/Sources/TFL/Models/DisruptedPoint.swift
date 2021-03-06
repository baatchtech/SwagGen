//
// Generated by SwagGen
// https://github.com/yonaskolb/SwagGen
//

import Foundation
import JSONUtilities

public class DisruptedPoint: JSONDecodable, JSONEncodable, PrettyPrintable {

    public var additionalInformation: String?

    public var appearance: String?

    public var atcoCode: String?

    public var commonName: String?

    public var description: String?

    public var fromDate: Date?

    public var mode: String?

    public var stationAtcoCode: String?

    public var toDate: Date?

    public var type: String?

    public init(additionalInformation: String? = nil, appearance: String? = nil, atcoCode: String? = nil, commonName: String? = nil, description: String? = nil, fromDate: Date? = nil, mode: String? = nil, stationAtcoCode: String? = nil, toDate: Date? = nil, type: String? = nil) {
        self.additionalInformation = additionalInformation
        self.appearance = appearance
        self.atcoCode = atcoCode
        self.commonName = commonName
        self.description = description
        self.fromDate = fromDate
        self.mode = mode
        self.stationAtcoCode = stationAtcoCode
        self.toDate = toDate
        self.type = type
    }

    public required init(jsonDictionary: JSONDictionary) throws {
        additionalInformation = jsonDictionary.json(atKeyPath: "additionalInformation")
        appearance = jsonDictionary.json(atKeyPath: "appearance")
        atcoCode = jsonDictionary.json(atKeyPath: "atcoCode")
        commonName = jsonDictionary.json(atKeyPath: "commonName")
        description = jsonDictionary.json(atKeyPath: "description")
        fromDate = jsonDictionary.json(atKeyPath: "fromDate")
        mode = jsonDictionary.json(atKeyPath: "mode")
        stationAtcoCode = jsonDictionary.json(atKeyPath: "stationAtcoCode")
        toDate = jsonDictionary.json(atKeyPath: "toDate")
        type = jsonDictionary.json(atKeyPath: "type")
    }

    public func encode() -> JSONDictionary {
        var dictionary: JSONDictionary = [:]
        if let additionalInformation = additionalInformation {
            dictionary["additionalInformation"] = additionalInformation
        }
        if let appearance = appearance {
            dictionary["appearance"] = appearance
        }
        if let atcoCode = atcoCode {
            dictionary["atcoCode"] = atcoCode
        }
        if let commonName = commonName {
            dictionary["commonName"] = commonName
        }
        if let description = description {
            dictionary["description"] = description
        }
        if let fromDate = fromDate?.encode() {
            dictionary["fromDate"] = fromDate
        }
        if let mode = mode {
            dictionary["mode"] = mode
        }
        if let stationAtcoCode = stationAtcoCode {
            dictionary["stationAtcoCode"] = stationAtcoCode
        }
        if let toDate = toDate?.encode() {
            dictionary["toDate"] = toDate
        }
        if let type = type {
            dictionary["type"] = type
        }
        return dictionary
    }

    /// pretty prints all properties including nested models
    public var prettyPrinted: String {
        return "\(Swift.type(of: self)):\n\(encode().recursivePrint(indentIndex: 1))"
    }
}
