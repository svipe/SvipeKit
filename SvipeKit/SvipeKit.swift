//
//  SvipeKit.swift
//  SvipeKit
//
//  Created by Johan Sellström on 2020-06-06.
//  Copyright © 2020 Svipe AB. All rights reserved.
//

import Foundation
import SwiftyBeaver

public let Log = SwiftyBeaver.self

public class Svipe {
    
    // Check integrity and return status
    public static func initialize() -> Bool {
        
        let console = ConsoleDestination()  // log to Xcode Console
        console.minLevel = .debug
        let file = FileDestination()  // log to default swiftybeaver.log file
        //file.logFileURL = URL(string: "/tmp/swiftybeaver.log")
        file.minLevel = .debug
        let cloud = SBPlatformDestination(appID: "o8QedN",
                                          appSecret: "njzwg6czsa1pgnfifobsem3JBjpua5gl",
                                          encryptionKey: "ivjqkvcti1laspgtm1Vqfb4ywHntylld") // to cloud
        cloud.minLevel = .debug
        Log.addDestination(cloud)
        Log.addDestination(console)
        Log.addDestination(file)
         // Security first
        Log.info("Checking if device is jailbroken")
        return true
    }
    
}
