//
//  AppDelegate.swift
//  Example
//
//  Created by Johan Sellström on 2020-06-07.
//  Copyright © 2020 Svipe AB. All rights reserved.
//

import UIKit
import DeepLinkKit



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func handleDeepLinkUrl(_ url: URL?) -> Bool {
        guard let url = url else {return false}
        print("handleDeepLinkUrl \(url) ")
        return true
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity,
     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        print("AppDelegate 1")
        return handleDeepLinkUrl(userActivity.webpageURL)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool{
    //first launch after install
        print("AppDelegate 2")
        return handleDeepLinkUrl(url)
    }

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool{
    //first launch after install for older iOS version
        print("AppDelegate 3")
        return handleDeepLinkUrl(url)
    }
}

