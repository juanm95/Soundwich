//
//  FriendsViewController.swift
//  Quaggify
//
//  Created by Jonathan Bijos on 02/02/17.
//  Copyright © 2017 Quaggie. All rights reserved.
//

import UIKit
import Flurry_iOS_SDK

class FriendsViewController: ViewController {
  
  var spotifyObject: SpotifyObject<Playlist>? {
    didSet {
      collectionView.reloadData()
    }
  }
    
    var fetchedFriends: Bool? {
        didSet {
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
  
  var sections: [[Playlist]] = [] {
    didSet {
      collectionView.reloadData()
    }
  }
  var isDismissing = false
  
  var limit = 20
  var offset = 0
  var isFetching = false
  
  let lineSpacing: CGFloat = 16
  let interItemSpacing: CGFloat = 8
  let contentInset: CGFloat = 8
  
  lazy var collectionView: UICollectionView = {
    let flowLayout = UICollectionViewFlowLayout()
    flowLayout.scrollDirection = .vertical
    flowLayout.minimumLineSpacing = self.lineSpacing
    flowLayout.minimumInteritemSpacing = self.interItemSpacing
    let cv = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
    cv.keyboardDismissMode = .onDrag
    cv.alwaysBounceVertical = true
    cv.showsVerticalScrollIndicator = false
    cv.contentInset = UIEdgeInsets(top: 0, left: self.contentInset, bottom: 0, right: self.contentInset)
    cv.backgroundColor = ColorPalette.white
    cv.delegate = self
    cv.dataSource = self
    cv.register(PlaylistCell.self, forCellWithReuseIdentifier: PlaylistCell.identifier)
    cv.register(SearchHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: SearchHeaderView.identifier)
    cv.register(LoadingFooterView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: LoadingFooterView.identifier)
    return cv
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    setupViews()
    setupNavigationBar()
    fetchPlaylists()
  }
  
  override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
    collectionView.collectionViewLayout.invalidateLayout()
  }
  
  // MARK: Layout
  override func setupViews() {
    super.setupViews()
    view.addSubview(collectionView)
    
    collectionView.anchor(view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 0)
  }
}

extension FriendsViewController {
  
  func setupNavigationBar () {
    navigationController?.navigationBar.barTintColor = ColorPalette.gray
    navigationController?.navigationBar.isOpaque = true
    navigationController?.navigationBar.isTranslucent = false
    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.add, target: self, action: #selector(addFriend))
    navigationItem.title = "Friends".uppercased()
    if let titleFont = Font.montSerratRegular(size: 16) {
      navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: titleFont, NSForegroundColorAttributeName: ColorPalette.white]
    }
  }
}

// MARK: Actions
extension FriendsViewController {
  func addFriend () {
    let alertController = UIAlertController(title: "New Friend", message: "Enter your friend's username", preferredStyle: UIAlertControllerStyle.alert)
    alertController.addTextField{ (textField : UITextField!) -> Void in
        textField.placeholder = "Enter username"
    }
    alertController.addAction(UIAlertAction(title: "Add", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in
        let friendUsername = alertController.textFields![0].text!
        API.addFriend(friend: friendUsername, username: UserDefaults.standard.value(forKey: "username") as! String) { (data: [String: AnyObject]) in
            if data["error"] as! Bool {
                Alert.shared.show(title: "Error", message: "\(friendUsername) doesn't exist, or is already in your network")
            } else {
                Alert.shared.show(title: "Success", message: "\(friendUsername) added")
                self.fetchPlaylists()
            }
        }
    }))
    
    self.present(alertController, animated: true, completion: nil)
  }
  
  func fetchPlaylists () {
    isFetching = true
    
    API.fetchFriends(username: "juan") { [weak self] (friends) in
      guard let strongSelf = self else {
        return
      }
      strongSelf.isFetching = false
        var items = [Playlist?]()
        let friendArray = friends["data"]! as! Array<String>
        for friend in friendArray {
            items.append(Playlist(JSON: ["name": friend]))
        }
        if strongSelf.sections[safe: 0] != nil {
          strongSelf.sections[0] = items as! [Playlist]
        } else {
          strongSelf.sections.append(items as! [Playlist])
        }
        strongSelf.fetchedFriends = true
    }
  }
}

// MARK: UICollectionViewDelegate
extension FriendsViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    // Dismiss modal & add track to playlist
      let playlist = sections[safe: indexPath.section]?[safe: indexPath.item]
      /*addTrackToPlaylist(playlist: playlist)*/
  }
}

extension FriendsViewController: UIScrollViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if isDismissing {
      return
    }
    let touchPoint = scrollView.contentOffset
    print(touchPoint)
    
    // Change frame if user is scrolling up
    if let navController = navigationController, let window = view.window, touchPoint.y < 0 {
      navController.view.frame = CGRect(x: 0, y: -touchPoint.y, width: window.frame.size.width, height: window.frame.size.height)
    } else {
      // Only animate if it's not already on top
      if let navController = self.navigationController, navController.view.frame.origin.y > 0 {
        // Animate to top
        UIView.animate(withDuration: 0.3) {
          navController.view.frame = CGRect(x: 0, y: 0, width: navController.view.frame.size.width, height: navController.view.frame.size.height)
        }
      }
    }
  }
}

// MARK: UICollectionViewDataSource
extension FriendsViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return sections[safe: section]?.count ?? 0
  }
  
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return sections.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PlaylistCell.identifier, for: indexPath) as? PlaylistCell {
      let section = indexPath.section
      let playlist = sections[safe: section]?[safe: indexPath.item]
      cell.playlist = playlist
      cell.titleLabel.textColor = ColorPalette.black
      
      // Only on the user's playlists
      if  section == 0 {
        if let totalItems = sections[safe: section]?.count, indexPath.item == totalItems - 1, spotifyObject?.next != nil {
          if !isFetching {
            fetchPlaylists()
          }
        }
      }
      
      return cell
    }
    return UICollectionViewCell()
  }
}

// MARK: UICollectionViewDelegateFlowLayout
extension FriendsViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(width: view.frame.width - (contentInset * 2), height: 72)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
    if section == 1 {
      return CGSize(width: view.frame.width, height: 72)
    }
    return .zero
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
    if section == 1, spotifyObject?.next != nil {
      return CGSize(width: view.frame.width, height: 36)
    }
    return .zero
  }
}



















