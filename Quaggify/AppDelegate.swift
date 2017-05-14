//
//  AppDelegate.swift
//  Quaggify
//
//  Created by Jonathan Bijos on 31/01/17.
//  Copyright © 2017 Quaggie. All rights reserved.
//

import UIKit
import Flurry_iOS_SDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    
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
}

