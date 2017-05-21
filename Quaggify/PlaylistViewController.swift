//
//  PlaylistViewController.swift
//  Quaggify
//
//  Created by Jonathan Bijos on 05/02/17.
//  Copyright © 2017 Quaggie. All rights reserved.
//

import UIKit

class PlaylistViewController: ViewController {
  
  var playlist: Playlist? {
    didSet {
      guard let playlist = playlist else {
        return
      }
      if let name = playlist.name {
        navigationItem.title = name
      }
      collectionView.reloadData()
    }
  }
  
  var spotifyObject: SpotifyObject<PlaylistTrack>?
  
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
    cv.contentInset = UIEdgeInsets(top: self.contentInset, left: self.contentInset, bottom: self.contentInset, right: self.contentInset)
    cv.backgroundColor = ColorPalette.black
    cv.delegate = self
    cv.dataSource = self
    cv.register(TrackCell.self, forCellWithReuseIdentifier: TrackCell.identifier)
    cv.register(PlaylistHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: PlaylistHeaderView.identifier)
    return cv
  }()
 
  override func viewDidLoad() {
    super.viewDidLoad()
    setupViews()
    fetchTracks()
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

// MARK: Actions
extension PlaylistViewController {
  func fetchTracks () {
    isFetching = true
    print("Fetching tracks offset(\(offset)) ")
    
    API.fetchPlaylistTracks(playlist: playlist, limit: limit, offset: offset) { [weak self] (spotifyObject, error) in
      guard let strongSelf = self else {
        return
      }
      strongSelf.isFetching = false
      strongSelf.offset += strongSelf.limit
      
      if let error = error {
        print(error)
        Alert.shared.show(title: "Error", message: "Error communicating with the server")
      } else if let spotifyObject = spotifyObject, let items = spotifyObject.items {
        if strongSelf.spotifyObject == nil {
          strongSelf.spotifyObject = spotifyObject
        } else {
          strongSelf.spotifyObject?.items?.append(contentsOf: items)
          strongSelf.spotifyObject?.next = spotifyObject.next
          strongSelf.spotifyObject?.total = spotifyObject.total
        }
        strongSelf.collectionView.reloadData()
        
        //save the spotifyobject to globals
        
        
        //print(spotifyObject?.items?[1].track?.id)
        /* print((self?.playlist?.uri)!)
         //print(strongSelf.spotifyObject?.href)
         print("made it here playlistt")
         var trackName = (self?.playlist?.uri)!
         trackName += ":autoplay:true"
         /*var trackName = "spotify:"
         trackName += (User.current.id)!
         trackName += ":playlist:"
         trackName += (self?.playlist?.id)!
         trackName += ":tracks:autoplay:true"*/
         // print(trackName)*/
      /*  var trackName = "spotify:track:"
        trackName += (spotifyObject?.items?[1].track?.id)!
        print (trackName)
        thePlayer.spotifyPlayer?.playSpotifyURI(trackName, startingWith: 0, startingWithPosition: 0, callback: { (error) in
            if (error != nil) {
                print("playing!")
            }
        })*/
      }
    }
  }
  
    
  
  func removeFromPlaylist (track: Track?, position: Int?) {
    print("Removing track \(track?.name ?? "(Null)") on position \(position ?? 0)")
    API.removePlaylistTrack(track: track, position: position, playlist: playlist) { [weak self] (snapshotId, error) in
      guard let strongSelf = self else {
        return
      }
      if let error = error {
        print(error)
        Alert.shared.show(title: "Error", message: "Error communicating with the server")
      } else if let snapshotId = snapshotId {
        
        strongSelf.playlist?.snapshotId = snapshotId
        if let position = position {
          strongSelf.spotifyObject?.items?.remove(at: position)
          if let total = strongSelf.playlist?.tracks?.total {
            strongSelf.playlist?.tracks?.total = total - 1
          }
        }
        strongSelf.collectionView.reloadData()
      }
    }
  }
}

// MARK: UICollectionViewDelegate
extension PlaylistViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    thePlayer.PP = true
    thePlayer.trackList = spotifyObject
    thePlayer.indeX = indexPath.item
    if(!thePlayer.start){
        thePlayer.nowPlaying = TrackViewController()
    }
    thePlayer.nowPlaying?.track = spotifyObject?.items?[safe: indexPath.item]?.track
    navigationController?.tabBarController?.selectedIndex =  1
    //if(!thePlayer.start){
   // }
    }
}

// MARK: UICollectionViewDataSource
extension PlaylistViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return spotifyObject?.items?.count ?? 0
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TrackCell.identifier, for: indexPath) as? TrackCell {
      let track = spotifyObject?.items?[safe: indexPath.item]?.track
      cell.track = track
      cell.position = indexPath.item        
      if let totalItems = spotifyObject?.items?.count, indexPath.item == totalItems - 1, spotifyObject?.next != nil {
        if !isFetching {
          fetchTracks()
        }
      }
      return cell
    }
    return UICollectionViewCell()
  }
    
  
  func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    switch kind {
    case UICollectionElementKindSectionHeader:
      if let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: PlaylistHeaderView.identifier, for: indexPath) as? PlaylistHeaderView {
        headerView.playlist = playlist
        return headerView
      }
    default: break
    }
    return UICollectionReusableView()
  }
}

// MARK: UICollectionViewDelegateFlowLayout
extension PlaylistViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(width: view.frame.width - (contentInset * 2), height: 72)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
    return CGSize(width: view.frame.width, height: 320)
  }
}


















