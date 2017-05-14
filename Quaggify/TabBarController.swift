//
//  TabBarController.swift
//  Quaggify
//
//  Created by Jonathan Bijos on 31/01/17.
//  Copyright © 2017 Quaggie. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController {
  
  var previousViewController: UIViewController?
  
  var didLogin = false
  
  // MARK: Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    delegate = self
    
    UITabBar.appearance().tintColor = ColorPalette.white
    UITabBar.appearance().isTranslucent = false
    UITabBar.appearance().barTintColor = ColorPalette.gray
    //thePlayer.nowPlaying = TrackViewController()
    // Fetching updated user
    if !didLogin {
      if let user = User.getFromDefaults() {
        User.current = user
      }
      API.fetchCurrentUser { (user, error) in
        if let user = user {
          User.current = user
          User.current.saveToDefaults()
        }
      }
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    let homeViewController = NavigationController(rootViewController: LibraryViewController())
    let homeIcon = #imageLiteral(resourceName: "tab_icon_browse").withRenderingMode(.alwaysTemplate)
    let homeIconFilled = #imageLiteral(resourceName: "tab_icon_browse_filled").withRenderingMode(.alwaysTemplate)
    homeViewController.tabBarItem = UITabBarItem(title: "Home", image: homeIcon, selectedImage: homeIconFilled)
    homeViewController.tabBarItem.tag = 0
    
    if previousViewController == nil {
      previousViewController = homeViewController
    }
    
    let searchViewController = NavigationController(rootViewController: SearchViewController())
    let searchIcon = #imageLiteral(resourceName: "tab_icon_search").withRenderingMode(.alwaysTemplate)
    searchViewController.tabBarItem = UITabBarItem(title: "Send", image: searchIcon, tag: 1)
    
    let newsFeedControler = NavigationController(rootViewController: newsFeedController())
    let feedIcon = #imageLiteral(resourceName: "tab_icon_library").withRenderingMode(.alwaysTemplate)
    let feedIconFilled = #imageLiteral(resourceName: "tab_icon_library_filled").withRenderingMode(.alwaysTemplate)
    newsFeedControler.tabBarItem = UITabBarItem(title: "Newsfeed", image: feedIcon, selectedImage: feedIconFilled)
    newsFeedControler.tabBarItem.tag = 2
    
   // if(thePlayer.nowPlaying?.track?.id == nil){
     //  thePlayer.nowPlaying = TrackViewController()
   // }
    let nowPlaying = NavigationController(rootViewController: TrackViewController())
       // nowPlaying.pushViewController(thePlayer.nowPlaying!, animated:true)
        let npIcon = #imageLiteral(resourceName: "playicon_filled").withRenderingMode(.alwaysTemplate)
        let npIconFilled = #imageLiteral(resourceName: "playicon").withRenderingMode(.alwaysTemplate)
        nowPlaying.tabBarItem = UITabBarItem(title: "Player", image: npIcon, selectedImage: npIconFilled)
        nowPlaying.tabBarItem.tag = 3
        viewControllers = [homeViewController, searchViewController, newsFeedControler, nowPlaying]
    
  }
  
}

extension TabBarController: UITabBarControllerDelegate {
  func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
     if let navController = viewController as? NavigationController {
            if let npVC = navController.topViewController as? TrackViewController {
                if(thePlayer.start && thePlayer.nowPlayingBug == 0){
                        thePlayer.nowPlayingBug = 1
                       navController.pushViewController(thePlayer.nowPlaying!, animated:false)
                }
        }
    }

    if previousViewController == viewController {
      if let navController = viewController as? NavigationController {
        if let homeVC = navController.topViewController as? HomeViewController {
          homeVC.scrollToTop()
        }
        if let searchVC = navController.topViewController as? SearchViewController {
          searchVC.scrollToTop()
        }
       if let feedVC = navController.topViewController as? newsFeedController {
          feedVC.scrollToTop()
        }
      /* if let npVC = navController.topViewController as? NowPlayingViewController {
            navController.pushViewController(thePlayer.nowPlaying!, animated:true)
        }*/
      }
    }
    previousViewController = viewController
  }
}















