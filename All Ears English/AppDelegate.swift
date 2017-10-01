//
//  AppDelegate.swift
//  All Ears English
//
//  Created by Luis Artola on 6/19/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics
import Firebase
import UserNotifications


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Fabric.with([Crashlytics.self])

        FirebaseApp.configure()

        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                    options: authOptions,
                    completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                    UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
            if let notification = launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] as? [String: Any] {
                processRemoteNotification(notification)
            }
        }
        application.registerForRemoteNotifications()

        self.setInitialView()

        return true
    }
    
    func setInitialView() {
        UITabBar.appearance().isTranslucent = false
//        UITabBar.appearance().tintColor = UIColor.blue
        UITabBar.appearance().barTintColor = UIColor.white
        UITabBar.appearance().backgroundColor = UIColor.white
        
//        UINavigationBar.appearance().titleTextAttributes = [NSFontAttributeName:UIFont.helveticaRegularFontWithSize(18)]
        UINavigationBar.appearance().isTranslucent = false
//        UINavigationBar.appearance().tintColor = UIColor.materiallTeal()
        
        let viewed = UserDefaults.standard.bool(forKey: "splash.viewed");
        if viewed {
            let initialVC = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "MainTabBarControllerId") as! MainTabBarController
            self.window?.rootViewController = initialVC
            self.window?.makeKeyAndVisible()
            return
        }
        
        UserDefaults.standard.set(true, forKey: "splash.viewed")

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let initialViewController = storyboard.instantiateViewController(withIdentifier: "SplashViewController")
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = initialViewController
        self.window?.makeKeyAndVisible()
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        var token = ""
        for i in 0..<deviceToken.count {
            token = token + String(format: "%02.2hhx", arguments: [deviceToken[i]])
        }
        print("Remote notifications device token: \(token)")
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Remote notification support is unavailable due to error: \(error.localizedDescription)")
    }
    

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        UIApplication.shared.applicationIconBadgeNumber = 0
    }


    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        completionHandler([.alert, .sound])
        
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        print("title: \(response.notification.request.content.title)")
        if let data = response.notification.request.content.userInfo["aee"] as? [String: Any] {
            if let deepLink = data["deepLink"] as? String {
                print("deepLink: \(deepLink)")
                Player.shared?.open(deepLink)
            }
        }
        completionHandler()
    }
    
    @available(iOS, deprecated:10.0)
    func processRemoteNotification(_ notification: [String: Any]?) {
        if let data = notification?["aee"] as? [String: Any] {
            if let deepLink = data["deepLink"] as? String {
                print("deepLink: \(deepLink)")
                Player.shared?.open(deepLink)
            }
        }
    }
    

}

