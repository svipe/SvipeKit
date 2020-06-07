//
//  Types.swift
//  SwipeIdKit
//
//  Created by Johan Sellström on 2019-09-12.
//  Copyright © 2019 Johan Sellström. All rights reserved.
//

import Foundation
import Contacts

public struct SignedMessage: Codable, Equatable {
    public var value: String
    public var signature: String
    public init(value: String, signature: String) {
        self.value = value
        self.signature = signature
    }
}

public struct LabeledValue: Codable, Equatable {
    public var label: String
    public var value: String
    public init(label: String, value: String) {
        self.label = label
        self.value = value
    }
}

@objc // We subclass for sole purpose of adding conformance to Codable.
public class PostalAddress: CNMutablePostalAddress, Codable {}

public struct Disclosure: Codable {
    public var did : String?
    public var personalNumber : String?
    public var documentNumber : String?
    public var documentExpiryDate : String?
    public var firstName : String?
    public var lastName : String?
    public var dateOfBirth : String?
    public var age: Int?
    public var gender : String?
    public var nationality : String?
    public var photoURL : URL?
    public var uuid: String?
    public var messagingNumbers = [LabeledValue]()
    public var phoneNumbers = [LabeledValue]()
    public var emailAddresses = [LabeledValue]()
    public var address: PostalAddress?
    public var facebook: String?
    public var twitter: String?
    public var signedMessage: SignedMessage?
    public var signatures: [String]?
    public var response: String?

    public init() {

    }
}

public enum SIDKAttribute: String, Codable {
    // semi static properties
    case documentNumber
    case personalNumber
    case name
    case dateOfBirth
    case gender
    case nationality
    // dynamic properties
    case photo
    case email
    case mobile
    // actions
    case sign
    case login
}

public enum SIDKAuthentication: String, Codable {
    case claim
    case chip
    case face
    case chipandface
}

public struct SIDKRequest: Codable {

    let authentication: SIDKAuthentication
    let requests: [String]
    let optionalRequests: [String]?

    let payload: String? // like a satement to be signed

    public init(requests: [SIDKAttribute], require authentication: SIDKAuthentication = .claim, payload: String? = nil, optionalRequests: [SIDKAttribute]? = nil) {
        var arr = [String]()
        for request in requests {
            arr.append(request.rawValue)
        }
       
        if let optionalRequests = optionalRequests, !optionalRequests.isEmpty  {
            var arr2 = [String]()
            for request in optionalRequests {
                arr2.append(request.rawValue)
            }
            self.optionalRequests = arr2
        } else {
            self.optionalRequests = nil
        }
        
        //self.init()
        self.requests = arr
        
        self.authentication = authentication
        self.payload = payload
    }
}

