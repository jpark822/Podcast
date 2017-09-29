//
//  ViewController.swift
//  All Ears English
//
//  Created by Luis Artola on 6/19/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import UIKit
import Crashlytics
import Firebase
import MediaPlayer
import iRate

class ViewController: UIViewController {
    
    static weak var shared: ViewController?
    @IBOutlet weak var episodesContainer: UIView!
    @IBOutlet weak var browserContainer: UIView!
    var episodeNavigationController: UITabBarController?
    var browserNavigationController: UINavigationController?
    fileprivate var originalFrame: CGRect = CGRect.init(x: 0, y: 0, width: 375, height: 667)
    fileprivate let targetFrame: CGRect = CGRect.init(x: 165, y: 54, width: 314, height: 558)

    override func viewDidLoad() {
        super.viewDidLoad()
        ViewController.shared = self
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.togglePlayPauseCommand.addTarget(handler: { (event) in
            Player.shared?.togglePlayback()
            return MPRemoteCommandHandlerStatus.success
        })
        commandCenter.playCommand.addTarget(handler: { (event) in
            Player.shared?.play()
            return MPRemoteCommandHandlerStatus.success
        })
        commandCenter.pauseCommand.addTarget(handler: { (event) in
            Player.shared?.pause()
            return MPRemoteCommandHandlerStatus.success
        })
        commandCenter.stopCommand.addTarget(handler: { (event) in
            Player.shared?.pause()
            return MPRemoteCommandHandlerStatus.success
        })
        commandCenter.changePlaybackPositionCommand.addTarget(handler: { (event) in
            print("\(#function) \(event)")
            if let event = event as? MPChangePlaybackPositionCommandEvent,
               let player = Player.shared {
                print("\(event.positionTime)")
                player.seek(to:event.positionTime)
                //player.updatePlayingNowInfo()
            }
            return MPRemoteCommandHandlerStatus.success
        })
        if let rate = iRate.sharedInstance() {
            rate.messageTitle = "All Ears English"
            rate.message = "If you enjoy using All Ears English, would you mind taking a moment to rate it? Thanks for your support!"
            rate.rateButtonLabel = "Yes! I will rate it"
            rate.remindButtonLabel = "Remind Me Later"
            rate.cancelButtonLabel = "No, Thanks"
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.originalFrame = self.view.frame
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EpisodesSegue" {
            self.episodeNavigationController = segue.destination as? UITabBarController
        } else if segue.identifier == "BrowserSegue" {
            self.browserNavigationController = segue.destination as? UINavigationController
        }
    }
    
    static func doToggleMenu(_ sender: Any) {
        shared?.toggleMenu(sender)
    }
    
    static func doShareApp(_ sender: Any) {
        shared?.shareApp(sender)
    }
    
    @IBAction func toggleMenu(_ sender: Any) {
        menuVisible = !menuVisible
    }

    var menuVisible: Bool = false {
        didSet {
            if menuVisible {
                UIView.animate(withDuration: 0.15, delay: 0, options: .curveLinear, animations: {
                    self.episodesContainer.frame = self.targetFrame
                    self.browserContainer.frame = self.targetFrame
                    self.setNeedsStatusBarAppearanceUpdate()
                })
            } else {
                UIView.animate(withDuration: 0.15, delay: 0, options: .curveLinear, animations: {
                    self.episodesContainer.frame = self.originalFrame
                    self.browserContainer.frame = self.originalFrame
                    self.setNeedsStatusBarAppearanceUpdate()
                })
            }
        }
    }

    override var prefersStatusBarHidden: Bool {
        return menuVisible
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    @IBAction func shareApp(_ sender: Any) {
        let text = "Check out the All Ears English app!"
        let url = "http://www.allearsenglish.com/"
        let controller = UIActivityViewController.init(activityItems: [text, url], applicationActivities: nil)
        controller.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .print
        ]
        controller.completionWithItemsHandler = {
            (activityType, completed, returnedItems, activityError) in
            if completed {
                DispatchQueue.main.async {
                    let method = activityType?.rawValue ?? "Default"
                    self.logEventShareApp(withMethod: method)
                }
            }
        }
        menuVisible = false
        self.present(controller, animated: true)
    }

    func logEventShareApp(withMethod method: String) {
        let name = "All Ears English"
        let type = "app"
        let id = "1"
        let attributes: [String: Any] = [:]
        print("Logging share event: method=\(String(describing: method)) name=\(name) type=\(type) id=\(id) attributes=\(attributes)")
        Answers.logShare(
                withMethod: method,
                contentName: name,
                contentType: type,
                contentId: id,
                customAttributes: attributes
        )
        Analytics.logEvent(
                AnalyticsEventShare,
                parameters: [
                        AnalyticsParameterMedium: method as NSObject,
                        AnalyticsParameterItemName: name as NSObject,
                        AnalyticsParameterItemCategory: type as NSObject,
                        AnalyticsParameterItemID: id as NSObject
                ])
    }
    
    func setBrowserVisible(_ visible: Bool) {
        UIView.animate(withDuration: 0.15, animations: {
            self.episodesContainer.alpha = visible ? 0 : 1
            self.browserContainer.alpha = visible ? 1 : 0
        })
    }
    
    @IBAction func showEpisodesView(_ sender: Any) {
        setBrowserVisible(false)
        if let controller = self.episodeNavigationController {
            controller.selectedIndex = 0
        }
    }
    
    @IBAction func showBrowserView(_ sender: Any) {
        setBrowserVisible(true)
    }

    var browserController: BrowserViewController? {
        if let controllers = self.browserNavigationController?.childViewControllers,
           controllers.count > 0 {
            return controllers[0] as? BrowserViewController
        }
        return nil
    }

    @IBAction func freeTips(_ sender: Any) {
        menuVisible = false
        showBrowserView(sender)
        if let controller = self.browserController {
            controller.pageTitle = "Free Tips"
            controller.pageURL = URL.init(string: "http://allearsenglish.com/bridge")
        }
        self.logEventSidebar(action: "free_tips")
    }
    
    @IBAction func quickLinks(_ sender: Any) {
        menuVisible = false
        showBrowserView(sender)
        if let controller = self.browserController {
            controller.pageTitle = "Quick Links"
            controller.pageURL = URL.init(string: "https://www.allearsenglish.com/resources/")
        }
        self.logEventSidebar(action: "quick_links")
    }
    
    @IBAction func contactUs(_ sender: Any) {
        if let path = Bundle.main.path(forResource: "contactus", ofType: "html") {
            menuVisible = false
            showBrowserView(sender)
            if let controller = self.browserController {
                controller.pageTitle = "Contact Us"
                controller.pageURL = URL.init(fileURLWithPath: path)
            }
            self.logEventSidebar(action: "contact_us")
        }
    }
    
    @IBAction func aboutUs(_ sender: Any) {
        if let path = Bundle.main.path(forResource: "aboutus", ofType: "html") {
            menuVisible = false
            showBrowserView(sender)
            if let controller = self.browserController {
                controller.pageTitle = "All Ears English"
                controller.pageURL = URL.init(fileURLWithPath: path)
            }
            self.logEventSidebar(action: "about_us")
        }
    }

    @IBAction func rateApp(_ sender: Any) {
        menuVisible = false
        iRate.sharedInstance().promptForRating()
    }

    func logEventSidebar(action name: String) {
        let type = "sidebar"
        let id = name
        let attributes: [String: Any] = [:]
        print("Logging sidebar action event: name=\(name) type=\(type) id=\(id) attributes=\(attributes)")
        Answers.logContentView(withName: name, contentType: type, contentId: id)
        Analytics.logEvent(
                AnalyticsEventViewItem,
                parameters: [
                        AnalyticsParameterItemName: name as NSObject,
                        AnalyticsParameterItemCategory: type as NSObject,
                        AnalyticsParameterItemID: id as NSObject
                ])
    }
}

