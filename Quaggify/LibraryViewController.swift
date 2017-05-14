//
//  LibraryViewController.swift
//  Quaggify
//
//  Created by Jonathan Bijos on 31/01/17.
//  Copyright © 2017 Quaggie. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class LibraryViewController: ViewController, SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate {
    
    private func addReceivedSongToPlaylist(trackResponse: Track) {
        thePlayer.needToReact = false
        let playlistId = UserDefaults.standard.value(forKey: "playlistId")
        let ownerid = User.current.id
        let owner = User(JSON: ["id": ownerid])
        var soundwichPlaylist = Playlist(JSON: ["id": UserDefaults.standard.value(forKey: "playlistId")])
        soundwichPlaylist?.owner = owner
        API.addTrackToPlaylist(track: trackResponse, playlist: soundwichPlaylist) {(string: String?, error: Error?) in
            NotificationCenter.default.post(name: .onUserPlaylistUpdate, object: soundwichPlaylist)
        }
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didStopPlayingTrack trackUri: String!) {
        print("braddd")
        var trackName = "spotify:track:"
        if (thePlayer.needToReact) {
            thePlayer.nowPlaying?.playSong()
            return
        }
        API.checkQueue() { [weak self] (response) in
            guard let strongSelf = self else {
                return
            }
            print(response)
            let randomNumber = arc4random_uniform(100)
            let response = response as [String:Any]
            let chanceOfQueue = 100 as UInt32
            if response["queued"] as! Bool && randomNumber < chanceOfQueue {
                thePlayer.needToReact = true
                let data = response["data"] as! [String:Any]
                let songid = data["songid"] as! String
                let time = data["time"] as! String
                let tomember = data["tomember"] as! String
                let frommember = data["frommember"] as! String
                trackName += songid
                thePlayer.nowPlaying?.track?.id = songid
                API.fetchTrack(track: thePlayer.nowPlaying?.track) { [weak self] (trackResponse, error) in
                    guard let strongSelf = self else {
                        return
                    }
                    if let error = error {
                        print(error)
                        Alert.shared.show(title: "Error", message: "Error communicating with the server")
                    } else if let trackResponse = trackResponse {
                        let alertController = UIAlertController(title: "Soundwich", message: "React to this song \(frommember) sent.", preferredStyle: UIAlertControllerStyle.alert)
                        alertController.addAction(UIAlertAction(title: "💩", style: UIAlertActionStyle.default, handler: {[weak self] (alert: UIAlertAction!) in
                            API.reactToSong(reaction: "💩", time: time, username: UserDefaults.standard.value(forKey: "username") as! String, to: tomember)
                            self?.addReceivedSongToPlaylist(trackResponse: trackResponse)
                        }))
                        alertController.addAction(UIAlertAction(title: "😂", style: UIAlertActionStyle.default, handler: {[weak self] (alert: UIAlertAction!) in
                            API.reactToSong(reaction: "😂", time: time, username: UserDefaults.standard.value(forKey: "username") as! String, to: tomember)
                            self?.addReceivedSongToPlaylist(trackResponse: trackResponse)
                        }))
                        alertController.addAction(UIAlertAction(title: "😡", style: UIAlertActionStyle.default, handler: {[weak self] (alert: UIAlertAction!) in
                            API.reactToSong(reaction: "😡", time: time, username: UserDefaults.standard.value(forKey: "username") as! String, to: tomember)
                            self?.addReceivedSongToPlaylist(trackResponse: trackResponse)
                        }))
                        alertController.addAction(UIAlertAction(title: "😎", style: UIAlertActionStyle.default, handler: {[weak self] (alert: UIAlertAction!) in
                            API.reactToSong(reaction: "😎", time: time, username: UserDefaults.standard.value(forKey: "username") as! String, to: tomember)
                            self?.addReceivedSongToPlaylist(trackResponse: trackResponse)
                        }))
                        thePlayer.nowPlaying?.track = trackResponse
//                        if present {
//                            self?.presentedViewController?.dismiss(animated: false, completion: {
                                DispatchQueue.main.async {
                                    thePlayer.nowPlaying?.present(alertController, animated: true)
                                }
//                            })
//                        } else {
//                            DispatchQueue.main.async {
//                                thePlayer.nowPlaying?.present(alertController, animated: true)
//                            }
//                        }
                    }
                }
            } else {
                thePlayer.indeX += 1
                if thePlayer.indeX == thePlayer.trackList?.total {
                    thePlayer.indeX = 0
                }
                thePlayer.nowPlaying?.track = thePlayer.trackList?.items?[thePlayer.indeX].track      //safe:                
            }
        }
    }
    
    
    var auth = SPTAuth.defaultInstance()!
    var session:SPTSession!
    var ACCESS_TOKEN: String? {
        return UserDefaults.standard.string(forKey: "ACCESS_TOKEN_KEY")
    }
    
    func initializePlayer() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: [])
            
            
            
            self.becomeFirstResponder()
            
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                print("AVAudioSession is Active")
            } catch let error as NSError {
                print(error.localizedDescription)
                
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        print("here")
        if thePlayer.spotifyPlayer == nil {
            thePlayer.spotifyPlayer = SPTAudioStreamingController.sharedInstance()
            thePlayer.spotifyPlayer!.playbackDelegate = self
            thePlayer.spotifyPlayer!.delegate = self
            try! thePlayer.spotifyPlayer!.start(withClientId: auth.clientID)
            thePlayer.spotifyPlayer!.login(withAccessToken: ACCESS_TOKEN)
        }
    }
    
    
    
    
    
    
    var spotifyObject: SpotifyObject<Playlist>?
    var playlists: [Playlist] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    
    lazy var logoutButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logout))
        button.tintColor = ColorPalette.white
        return button
    }()
    
    var limit = 20
    var offset = 0
    var isFetching = false
    
    let lineSpacing: CGFloat = 16
    let interItemSpacing: CGFloat = 8
    let contentInset: CGFloat = 8
    
    lazy var refreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(refreshPlaylists), for: .valueChanged)
        return rc
    }()
    
    lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        flowLayout.minimumLineSpacing = self.lineSpacing
        flowLayout.minimumInteritemSpacing = self.interItemSpacing
        let cv = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        cv.addSubview(self.refreshControl)
        cv.keyboardDismissMode = .onDrag
        cv.alwaysBounceVertical = true
        cv.showsVerticalScrollIndicator = false
        cv.contentInset = UIEdgeInsets(top: self.contentInset, left: self.contentInset, bottom: self.contentInset, right: self.contentInset)
        cv.backgroundColor = .clear
        cv.delegate = self
        cv.dataSource = self
        cv.register(PlaylistCell.self, forCellWithReuseIdentifier: PlaylistCell.identifier)
        cv.register(LoadingFooterView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: LoadingFooterView.identifier)
        return cv
    }()
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        addListeners()
        fetchPlaylists()
        //addCreateNewPlaylistCell()
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    // MARK: Layout
    override func setupViews() {
        super.setupViews()
        initializePlayer()
        navigationItem.title = "Your Playlists".uppercased()
        navigationItem.rightBarButtonItem = logoutButton
        
        view.addSubview(collectionView)
        collectionView.anchor(view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 0)
    }
}

// MARK: Actions
extension LibraryViewController {
    func addCreateNewPlaylistCell () {
        /*if let createNewPlaylistItem = Playlist(JSON: ["name": "Create new playlist"]) {
         playlists.append(createNewPlaylistItem)
         }*/
    }
    
    func logout () {
        SpotifyService.shared.logout()
    }
    
    func addListeners () {
        NotificationCenter.default.addObserver(self, selector: #selector(onUserPlaylistUpdate), name: .onUserPlaylistUpdate, object: nil)
    }
    
    func onUserPlaylistUpdate (notification: Notification) {
        guard let playlist = notification.object as? Playlist else {
            return
        }
        if playlists[safe: 1] != nil {
            playlists.insert(playlist, at: 1)
            collectionView.reloadData()
        }
    }
    
    func fetchPlaylists () {
        isFetching = true
        print("Fetching albums offset(\(offset)) ")
        
        API.fetchCurrentUsersPlaylists(limit: limit, offset: offset) { [weak self] (spotifyObject, error) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.isFetching = false
            strongSelf.refreshControl.endRefreshing()
            strongSelf.offset += strongSelf.limit
            
            if let error = error {
                print(error)
                Alert.shared.show(title: "Error", message: "Error communicating with the server")
            } else if let items = spotifyObject?.items {
                strongSelf.playlists.append(contentsOf: items)
                strongSelf.spotifyObject = spotifyObject
            }
        }
    }
    
    func refreshPlaylists () {
        if isFetching {
            return
        }
        isFetching = true
        print("Refreshing playlists")
        
        API.fetchCurrentUsersPlaylists(limit: limit, offset: 0) { [weak self] (spotifyObject, error) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.isFetching = false
            strongSelf.refreshControl.endRefreshing()
            strongSelf.offset = strongSelf.limit
            
            if let error = error {
                print(error)
                Alert.shared.show(title: "Error", message: "Error communicating with the server")
            } else if let items = spotifyObject?.items {
                strongSelf.playlists.removeAll()
                strongSelf.addCreateNewPlaylistCell()
                strongSelf.playlists.append(contentsOf: items)
                strongSelf.spotifyObject = spotifyObject
            }
        }
    }
    
    func showNewPlaylistModal () {
        /*let alertController = UIAlertController(title: "Create new Playlist".uppercased(), message: nil, preferredStyle: .alert)
         alertController.addTextField { textfield in
         textfield.placeholder = "Playlist name"
         textfield.addTarget(self, action: #selector(self.textDidChange(textField:)), for: .editingChanged)
         }
         
         let cancelAction = UIAlertAction(title: "Cancel".uppercased(), style: .destructive, handler: nil)
         let createAction = UIAlertAction(title: "Create".uppercased(), style: .default) { _ in
         if let textfield = alertController.textFields?.first, let playlistName = textfield.text {
         API.createNewPlaylist(name: playlistName) { [weak self] (playlist, error) in
         if let error = error {
         print(error)
         // Showing error message
         Alert.shared.show(title: "Error", message: "Error communicating with the server")
         } else if let playlist = playlist {
         if self?.playlists[safe: 1] != nil {
         self?.collectionView.performBatchUpdates({
         self?.playlists.insert(playlist, at: 1)
         self?.collectionView.insertItems(at: [IndexPath(item: 1, section: 0)])
         }, completion: nil)
         }
         }
         }
         }
         }
         createAction.isEnabled = false
         alertController.addAction(cancelAction)
         alertController.addAction(createAction)
         present(alertController, animated: true, completion: nil)
         }
         
         func textDidChange (textField: UITextField) {
         if let topVc = UIApplication.topViewController() as? UIAlertController, let createAction = topVc.actions[safe: 1] {
         if let text = textField.text, text != "" {
         createAction.isEnabled = true
         } else {
         createAction.isEnabled = false
         }
         } */
    }
    
}

// MARK: UICollectionViewDelegate
extension LibraryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let playlistVC = PlaylistViewController()
        playlistVC.playlist = playlists[safe: indexPath.item]
        navigationController?.pushViewController(playlistVC, animated: true)
    }
}

// MARK: UICollectionViewDataSource
extension LibraryViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return playlists.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PlaylistCell.identifier, for: indexPath) as? PlaylistCell {
            let playlist = playlists[safe: indexPath.item]
            cell.playlist = playlist
            
            // Create ne playlist
            /*if indexPath.item == 0 {
             cell.imageView.image = #imageLiteral(resourceName: "icon_add_playlist").withRenderingMode(.alwaysTemplate)
             cell.subTitleLabel.isHidden = true
             cell.imageView.tintColor = ColorPalette.white
             }*/
            
            if let totalItems = spotifyObject?.items?.count, indexPath.item == totalItems - 1, spotifyObject?.next != nil {
                if !isFetching {
                    fetchPlaylists()
                }
            }
            
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionFooter:
            if let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter, withReuseIdentifier: LoadingFooterView.identifier, for: indexPath) as? LoadingFooterView {
                return footerView
            }
        default: break
        }
        return UICollectionReusableView()
    }
}

// MARK: UICollectionViewDelegateFlowLayout
extension LibraryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width - (contentInset * 2), height: 72)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if spotifyObject?.next != nil {
            return CGSize(width: view.frame.width, height: 36)
        }
        return .zero
    }
}

extension LibraryViewController: ScrollDelegate {
    func scrollToTop() {
        if spotifyObject?.items?.count ?? 0 > 0 {
            collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
        }
    }
}



















