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
import Mixpanel
import Foundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate  {

    var window: UIWindow?
    let gcmMessageIDKey = "gcm.message_id"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        
        //Fabric
        Fabric.with([Crashlytics.self])

        //Firebase
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        let token = Messaging.messaging().fcmToken
        print("printing initial FCM token: \(token ?? "")")
        
        //Mixpanel
        Mixpanel.sharedInstance(withToken: "d69005ea7336e8f91b42b4ed3b777962")
        
        // KochavaTracker
        var trackerParametersDictionary: [AnyHashable: Any] = [:]
        trackerParametersDictionary[kKVAParamAppGUIDStringKey] = "koall-ears-english-sh0kpjhzk"
        trackerParametersDictionary[kKVAParamLogLevelEnumKey] = kKVALogLevelEnumInfo
        KochavaTracker.shared.configure(withParametersDictionary: trackerParametersDictionary, delegate: nil)
        
//        Bugfender.activateLogger("TEIeuDIEm2Ts4FAyBRY13ZAwWE9eSehJ")

        self.setInitialView()
        self.promptOrRemindForPushNotifications()
        
        return true
    }
    
    func setInitialView() {
        UITabBar.appearance().isTranslucent = false
//        UITabBar.appearance().tintColor = UIColor.blue
        UITabBar.appearance().barTintColor = UIColor.white
        UITabBar.appearance().backgroundColor = UIColor.white
        
        UINavigationBar.appearance().titleTextAttributes = [NSFontAttributeName:UIFont(name: "PTSans-Regular", size: 17.0)!]
        UINavigationBar.appearance().barTintColor = UIColor.AEEYellow
        UINavigationBar.appearance().tintColor = UIColor.darkGray
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
        Cache.shared.copyPreloadedEpiosdesToCache()
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = initialViewController
        self.window?.makeKeyAndVisible()
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

    
    
    //MARK: - Push notifications
    func promptOrRemindForPushNotifications() {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            print("settings \(settings)")
            
            switch settings.authorizationStatus {
            case .notDetermined:
                self.requestPushNotificationAuthorization()
                break
                
            case .authorized:
                //do nothing, we're good
                break
                
            case .denied:
                //do nothing, for now. show reminder dialogue later
                break
            case .provisional:
                break
            }
            
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
            
        }
    }
    
    //show the 1 time user dialogue asking for permissions
    func requestPushNotificationAuthorization() {
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            print("granted: \(granted)")
            
            if (granted) {
                self.registerForRemoteNotifications()
            }
            
            self.registerForRemoteNotifications()
        }
    }
    
    //register with remote server. called after user approves dialogue
    func registerForRemoteNotifications() {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            print("settings \(settings)")
            
            guard settings.authorizationStatus == .authorized else {
                return
            }
            
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    //MARK: push notification delegate methods
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        
        let token = tokenParts.joined()
        print("Device Token: \(token)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
    }
    
// is never called in iOS 10
//    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
//        print("notification received: didReceiveRemoteNotification")
//        // If you are receiving a notification message while your app is in the background,
//        // this callback will not be fired till the user taps on the notification launching the application.
//        // TODO: Handle data of notification
//
//        // With swizzling disabled you must let Messaging know about the message, for Analytics
//         Messaging.messaging().appDidReceiveMessage(userInfo)
//
//        // Print message ID.
//        if let messageID = userInfo[gcmMessageIDKey] {
//            print("Message ID: \(messageID)")
//        }
//
//        // Print full message.
//        print("didReceivRemoteNotification regular \(userInfo)")
//    }
    
    //only used if background modes and remote notification entitlements are enabled. Note: only fire in the background for notifications with the content-available = 1.
//    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
//                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
//        print("notification received: didReceiveRemoteNotificationFetchHandler")
//
//        //send anayltics
//         Messaging.messaging().appDidReceiveMessage(userInfo)
//
//        // Print message ID.
//        if let messageID = userInfo[gcmMessageIDKey] {
//            print("Message ID: \(messageID)")
//        }
//
//        // Print full message.
//        print("didReceivRemoteNotification background \(userInfo)")
//
//        completionHandler(UIBackgroundFetchResult.newData)
//    }

}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        print("Firebase registration token didRefreshToken. current token: \(fcmToken)")
        
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
}

extension AppDelegate : UNUserNotificationCenterDelegate {
    
    //fires when you receive a notification in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("notification received: willPresent")
        
        //print payload
        let userInfo = notification.request.content.userInfo
        print("userNotificationCenter willpresent notification  \(userInfo)")
        
        //send analytics
        Messaging.messaging().appDidReceiveMessage(userInfo)
        
        //choose to display message and play sound
        completionHandler([.alert, .sound])
    }
    
    //called when the user taps into a notification from anywhere
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("notification received: didReceiveResponse")
        
        let userInfo = response.notification.request.content.userInfo
        print("userNotificationCenter  did receive response \(userInfo)")
        Messaging.messaging().appDidReceiveMessage(userInfo)
        
        if let rootTabBarController = self.window?.rootViewController as? MainTabBarController,
            let episodeType = userInfo["episodeType"] as? String {
            
            DispatchQueue.main.async {
                rootTabBarController.dismiss(animated: true)
                if episodeType == "bonus" {
                    rootTabBarController.selectedIndex = MainTabBarController.ViewControllerIndex.bonus.rawValue
                    
                    if let bonusViewControllerControllers = rootTabBarController.viewControllers,
                        let bonusNavController = bonusViewControllerControllers[MainTabBarController.ViewControllerIndex.bonus.rawValue] as? UINavigationController,
                        let bonusListVC = bonusNavController.viewControllers[0] as? BonusEpisodesTableViewController {
                        bonusListVC.fetchData()
                        bonusListVC.tableView.scrollToTop()
                    }
                }
                else {
                    rootTabBarController.selectedIndex = MainTabBarController.ViewControllerIndex.episodes.rawValue
                    
                    if let episodeViewControllerControllers = rootTabBarController.viewControllers,
                        let episodeNavController = episodeViewControllerControllers[MainTabBarController.ViewControllerIndex.episodes.rawValue] as? UINavigationController,
                        let episodeListVC = episodeNavController.viewControllers[0] as? EpisodeListTableViewController {
                        episodeListVC.fetchData()
                        episodeListVC.tableView.scrollToTop()
                    }
                }
            }
        }
        
        completionHandler()
    }
}

