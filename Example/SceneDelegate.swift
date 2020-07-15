//
//  SceneDelegate.swift
//  Example
//
//  Created by Johan Sellström on 2020-06-07.
//  Copyright © 2020 Svipe AB. All rights reserved.
//

import UIKit
import DeepLinkKit



class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func handleDeepLinkUrl(_ url: URL?) -> Bool {

        guard let url = url else {return false}
        print("handleDeepLinkUrl \(url) ")
        var resultText = ""

        guard let str = url.absoluteString.removingPercentEncoding, let components = URLComponents(string: str) else {
            return false
        }

        print("components.queryItems \(components.queryItems)")
        if let items = components.queryItems {
            print("items \(items)")
            for item in items {
                var value = ""
                if let v = item.value {
                    value = v
                }
                resultText += item.name + "=" + value + "\n"
            }
        }
        print("resultText \(resultText)")
        if let viewController = window?.rootViewController as? ViewController {
            viewController.resultText.text = resultText
            viewController.loginButton.isHidden = true
        }

        return true
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        print("SceneDelegate 1")
        handleDeepLinkUrl(connectionOptions.urlContexts.first?.url)
        handleDeepLinkUrl(connectionOptions.userActivities.first?.webpageURL)

    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        print("SceneDelegate 2")
        let handled = handleDeepLinkUrl(URLContexts.first?.url)
        print("handled \(handled)")
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        print("SceneDelegate 3")
        let handled = handleDeepLinkUrl(userActivity.webpageURL)
        print("handled \(handled)")


    }
}

