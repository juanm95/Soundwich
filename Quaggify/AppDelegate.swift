//
//  AppDelegate.swift
//  Quaggify
//
//  Created by Jonathan Bijos on 31/01/17.
//  Copyright © 2017 Quaggie. All rights reserved.
//

import UIKit
import Flurry_iOS_SDK
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    
    // enable push notifications
    
    print("enable")
    registerForRemoteNotification()
    
    
    // anayltics
    Flurry.startSession("JSZXMGRDMQ69QZHN3N9M", with: FlurrySessionBuilder
        .init()
        .withCrashReporting(true)
        .withLogLevel(FlurryLogLevelAll))
    
    window = UIWindow(frame: UIScreen.main.bounds)
    
    window?.makeKeyAndVisible()
    if SpotifyService.shared.isLoggedIn {
      window?.rootViewController = TabBarController()
    } else {
      window?.rootViewController = LoginViewController()
    }
      
    return true
  }
    
  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    
    print("got in didregister")
    print("REGISTERINGKS LJFLS FJLSKJ LKSLKFFJ L")
    let chars = (deviceToken as NSData).bytes.bindMemory(to: CChar.self, capacity: deviceToken.count)
    var token = ""
    
    for i in 0..<deviceToken.count {
        token += String(format: "%0.2.2hhx", arguments: [chars[i]])
    }
    UserDefaults.standard.set(token, forKey: "token")
//    self.strDeviceToken = token
//    SSCurrentUser.sharedInstacne.apnsToken = token;
  }
    
    func registerForRemoteNotification() {
        
        print("in register remot notifications")
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            center.requestAuthorization(options: [.sound, .alert, .badge]) { (granted, error) in
                if error == nil {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        } else {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.sound, .alert, .badge], categories: nil))
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
  
  func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
    if let code = url.queryItemValueFor(key: "code") {
      API.requestToken(code: code) { [weak self] (error) in
        if let error = error {
          print(error)
          Alert.shared.show(title: "Error", message: error.localizedDescription)
        } else {
          API.fetchCurrentUser { (user, err) in
            if let err = err {
              Alert.shared.show(title: "Error", message: err.localizedDescription)
            } else if let user = user {
              User.current = user
              User.current.saveToDefaults()
                if UserDefaults.standard.value(forKey: "playlistId") == nil {
                    let playlistName = "Received on Soundwich"
                    API.createNewPlaylist(name: playlistName) { [weak self] (playlist, error) in
                        if let error = error {
                            print(error)
                            // Showing error message
                            Alert.shared.show(title: "Error", message: "Error communicating with the server")
                        } else if let playlist = playlist {
                            // Adding track to palylist
                            //                        API.addTrackToPlaylist(track: track, playlist: playlist) { [weak self] (snapshotId, error) in
                            //                            if let error = error {
                            //                                print(error)
                            //                                // Showing error message
                            //                                Alert.shared.show(title: "Error", message: "Error communicating with the server")
                            //                            } else if let _ = snapshotId {
                            //                                self?.dismiss(animated: true) {
                            Alert.shared.show(title: "Success!", message: "Playlist \(playlistName) created")
                            // Message to update library tab
                            NotificationCenter.default.post(name: .onUserPlaylistUpdate, object: playlist)
                            //                                }
                            UserDefaults.standard.set(playlist.id, forKey: "playlistId")
                        }
                    }
                }
              let tabBarVC = TabBarController()
              tabBarVC.didLogin = true
              self?.window?.rootViewController = tabBarVC
            }
          }
        }
      }
    } else if let error = url.queryItemValueFor(key: "error") {
      print(error)
      Alert.shared.show(title: "Error", message: error)
    }
    return true
  }
    
    //Called when a notification is delivered to a foreground app.
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("User Info = ",notification.request.content.userInfo)
        let info: [AnyHashable : Any] = notification.request.content.userInfo
        //        let message = info["messageFrom"] as! String
//        let typeInt = info["type"] as! Int
//        var type: NotificationType = .other
//        switch typeInt {
//        case 1:
//            type = .acceptTeacher
//        default:
//            type = .other
//        }
//        if (type == .acceptTeacher){
//        let notificationName = Notification.Name(LEARNING_ACCEPTED_NOTIFICATION)
        let notificationName = Notification.Name("Hello")
        NotificationCenter.default.post(name: notificationName, object: nil)
//        }
        
        completionHandler([.alert, .badge, .sound])
    }
    
    //Called to let your app know which action was selected by the user for a given notification.
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("User Info = ",response.notification.request.content.userInfo)
        completionHandler()
    }
    
}

