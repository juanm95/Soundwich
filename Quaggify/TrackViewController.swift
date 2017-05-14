//
//  TrackViewController.swift
//  Quaggify
//
//  Created by Jonathan Bijos on 05/02/17.
//  Copyright © 2017 Quaggie. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class TrackViewController: ViewController, SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate{
    
    var track: Track? {
        didSet {
            guard let track = track else {
                return
            }
            DispatchQueue.main.async {
            if let name = track.name {
                self.titleLabel.text = name
            }
            if let artists = track.artists {
                let names = artists.map { $0.name ?? "Unknown Artist" }.joined(separator: ", ")
                self.subTitleLabel.text = names
                self.navigationItem.title = names
            }
            if let smallerImage = track.album?.images?[safe: 1], let imgUrlString = smallerImage.url, let url = URL(string: imgUrlString) {
                self.imageView.kf.setImage(with: url, placeholder: #imageLiteral(resourceName: "placeholder"), options: [.transition(.fade(0.2))])
            } else if let smallerImage = track.album?.images?[safe: 0], let imgUrlString = smallerImage.url, let url = URL(string: imgUrlString) {
                self.imageView.kf.setImage(with: url, placeholder: #imageLiteral(resourceName: "placeholder"), options: [.transition(.fade(0.2))])
            } else {
                self.imageView.image = #imageLiteral(resourceName: "placeholder")
            }
               
            }
            self.presentedViewController?.loadView()
            if(thePlayer.paused){
                self.pauseSong()
            }
            self.playSong()
        }
    }
    
    var titleLabel: UILabel = {
        let label = UILabel()
        label.font = Font.montSerratBold(size: 20)
        label.textColor = ColorPalette.white
        label.textAlignment = .center
        return label
    }()
    
    var subTitleLabel: UILabel = {
        let label = UILabel()
        label.font = Font.montSerratRegular(size: 18)
        label.textColor = ColorPalette.lightGray
        label.textAlignment = .center
        return label
    }()
    
    /* Used to Send Song to Friend */
    lazy var addToPlaylistButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.tintColor = ColorPalette.white
        btn.titleLabel?.font = Font.montSerratRegular(size: 30)
        btn.setTitle("Send", for: .normal)
        btn.addTarget(self, action: #selector(addToPlaylist), for: .touchUpInside)
        return btn
    }()
    
    lazy var pauseSongButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(named: "pausebutton")?.withRenderingMode(.alwaysOriginal), for: .normal)
        btn.addTarget(self, action: #selector(pauseSong), for: .touchUpInside)
        return btn
    }()
  
    lazy var nextSongButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(named: "next")?.withRenderingMode(.alwaysOriginal), for: .normal)
        btn.addTarget(self, action: #selector(nextSong), for: .touchUpInside)
        return btn
    }()
    
    
    lazy var previousSongButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(named: "previous")?.withRenderingMode(.alwaysOriginal), for: .normal)
        btn.addTarget(self, action: #selector(previousSong), for: .touchUpInside)
        return btn
    }()
    
    
    
  var imageView: UIImageView = {
    let iv = UIImageView()
    iv.contentMode = .scaleAspectFit
    iv.clipsToBounds = true
    return iv
  }()
  
  let stackView: UIStackView = {
    let sv = UIStackView()
    sv.alignment = .fill
    sv.axis = .vertical
    sv.distribution = .fillEqually
    sv.backgroundColor = .clear
    sv.spacing = 8
    return sv
  }()
  
  let containerView: UIView = {
    let v = UIView()
    v.backgroundColor = .clear
    return v
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    setupViews()
    let commandCenter = MPRemoteCommandCenter.shared()
    commandCenter.nextTrackCommand.addTarget(self, action:#selector(thePlayer.nowPlaying?.nextSong))
    commandCenter.previousTrackCommand.addTarget(self, action:#selector(thePlayer.nowPlaying?.previousSong))
    commandCenter.pauseCommand.addTarget(self, action:#selector(thePlayer.nowPlaying?.pauseSong))
    if #available(iOS 9.1, *) {
        commandCenter.changePlaybackPositionCommand.addTarget(self, action:#selector(thePlayer.nowPlaying?.onChangePlaybackPositionCommand))
    } else {
        // Fallback on earlier versions
    }
    commandCenter.playCommand.addTarget(self, action:#selector(thePlayer.nowPlaying?.pauseSong))
//    fetchTrack()
  }
  
  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    
    switch UIApplication.shared.statusBarOrientation {
    case .portrait: fallthrough
    case .portraitUpsideDown: fallthrough
    case .unknown:
      setPortraitLayout()
      break
    case .landscapeLeft: fallthrough
    case .landscapeRight:
      setLandscapeLayout()
      break
    }
    view.layoutIfNeeded()
  }
  
 override func setupViews() {
    super.setupViews()
    view.addSubview(stackView)
    view.addSubview(imageView)
    view.addSubview(containerView)
    view.addSubview(titleLabel)
    view.addSubview(subTitleLabel)
    view.addSubview(addToPlaylistButton)
    view.addSubview(pauseSongButton)
    view.addSubview(nextSongButton)
    view.addSubview(previousSongButton)
    view.backgroundColor = ColorPalette.black
    stackView.addArrangedSubview(imageView)
    stackView.addArrangedSubview(containerView)
        stackView.anchor(topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, topConstant: 8, leftConstant: 8, bottomConstant: 8, rightConstant: 8, widthConstant: 0, heightConstant: 0)
        
        titleLabel.anchor(containerView.topAnchor, left: containerView.leftAnchor, bottom: nil, right: containerView.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 24)
        
        subTitleLabel.anchor(titleLabel.bottomAnchor, left: containerView.leftAnchor, bottom: nil, right: containerView.rightAnchor, topConstant: 8, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 24)
    
    
      pauseSongButton.anchor(subTitleLabel.bottomAnchor, left: containerView.leftAnchor, bottom: nil, right: containerView.rightAnchor, topConstant: 8, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 70)
    
    nextSongButton.anchor(subTitleLabel.bottomAnchor, left: containerView.leftAnchor, bottom: nil, right: containerView.rightAnchor, topConstant: 8, leftConstant: 200, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 70)
    
    previousSongButton.anchor(subTitleLabel.bottomAnchor, left: containerView.leftAnchor, bottom: nil, right: containerView.rightAnchor, topConstant: 8, leftConstant: 0, bottomConstant: 0, rightConstant: 200, widthConstant: 0, heightConstant: 70)
    
    

    
        addToPlaylistButton.anchor(subTitleLabel.bottomAnchor, left: containerView.leftAnchor, bottom: containerView.bottomAnchor, right: containerView.rightAnchor, topConstant: 8, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 0)
    }
}

extension TrackViewController {
    func setPortraitLayout () {
        stackView.axis = .vertical
    }
    
    func setLandscapeLayout () {
        stackView.axis = .horizontal
    }
}


extension TrackViewController {
    func addToPlaylist () {
        let trackOptionsVC = TrackOptionsViewController()
        trackOptionsVC.track = track
        let trackOptionsNav = NavigationController(rootViewController: trackOptionsVC)
        trackOptionsNav.modalPresentationStyle = .overCurrentContext
        tabBarController?.present(trackOptionsNav, animated: true, completion: nil)
    }
    
    func onChangePlaybackPositionCommand (_ event: MPChangePlaybackPositionCommandEvent){
        thePlayer.spotifyPlayer?.seek(to: event.positionTime, callback: { (error) in
            if (error != nil) {
            }
        })
    }
    
    func nextSong(){
        print("next")
        thePlayer.indeX += 1
        if thePlayer.indeX >= (thePlayer.trackList?.total)! {
            thePlayer.indeX = 0
        }
        self.track = thePlayer.trackList?.items?[safe: thePlayer.indeX]?.track
    }
    
    
    func previousSong(){
        print("prev")
        thePlayer.indeX -= 1
        if thePlayer.indeX <= -1 {
            thePlayer.indeX = 0
        }
        self.track = thePlayer.trackList?.items?[safe: thePlayer.indeX]?.track
    }
    
    func pauseSong(){
         MPNowPlayingInfoCenter.default().nowPlayingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = thePlayer.spotifyPlayer?.playbackState.position
        if(thePlayer.paused){
            thePlayer.paused = false
            pauseSongButton.setImage(UIImage(named: "pausebutton")?.withRenderingMode(.alwaysOriginal), for: .normal)
            MPNowPlayingInfoCenter.default().nowPlayingInfo![MPNowPlayingInfoPropertyPlaybackRate] = 1
            thePlayer.spotifyPlayer?.setIsPlaying(true, callback: { (error) in
                if (error != nil) {
                    print("what")
                    //  print(error)
                }
            })
        } else {
            thePlayer.paused = true
            pauseSongButton.setImage(UIImage(named: "play-button")?.withRenderingMode(.alwaysOriginal), for: .normal)
            MPNowPlayingInfoCenter.default().nowPlayingInfo![MPNowPlayingInfoPropertyPlaybackRate] = 0
            thePlayer.spotifyPlayer?.setIsPlaying(false, callback: { (error) in
                if (error != nil) {
                    print("hello")
                    //  print(error)
                }
            })
        }
    }
    
 
    
    func playSong() {
        var trackName = "spotify:track:"
        trackName += (track?.id)!
        print("here - playsong")
        thePlayer.spotifyPlayer?.playSpotifyURI(trackName, startingWith: 0, startingWithPosition: 0, callback: { (error) in
            if (error != nil) {
              //  print(error)
            }
        })
        let imageURLString = URL(string: (self.track?.album?.images?[0].url)!)
        let imageData = try! Data(contentsOf:imageURLString!)
        let image2 = UIImage(data:imageData)
        let newSize = CGSize(width:(self.track?.album?.images?[0].width)!,height:(self.track?.album?.images?[0].height)!)
        if let image = image2 ?? UIImage(named: "No Album Artwork"), #available(iOS 10.0, *) {
            let albumArt = MPMediaItemArtwork(boundsSize:newSize, requestHandler: { (size) -> UIImage in return image})
            let nowPlayingInfo : [String:Any] =  [
                MPMediaItemPropertyTitle: self.track?.name! ?? "Unknown Song",
                MPMediaItemPropertyArtist: self.track?.artists?[0].name! ?? "Unknown Artist",
                MPMediaItemPropertyAlbumTitle: self.track?.album?.name! ?? "Unknown Album",
                MPMediaItemPropertyPlaybackDuration: (self.track?.durationMS)!/1000,
                MPNowPlayingInfoPropertyPlaybackRate: 1,
                MPMediaItemPropertyArtwork: albumArt
            ]
            let infoCenter = MPNowPlayingInfoCenter.default()
            infoCenter.nowPlayingInfo = nowPlayingInfo
            //infoCenter.nowPlayingInfo.MPMediaItemPropertyArtwork = albumArt
        }
    }
    
    
    func fetchTrack () {
        API.fetchTrack(track: track) { [weak self] (trackResponse, error) in
            guard let strongSelf = self else {
                return
            }
            if let error = error {
                print(error)
                Alert.shared.show(title: "Error", message: "Error communicating with the server")
            } else if let trackResponse = trackResponse {
                
                strongSelf.track = trackResponse
              //  print("--- FETCHED TRACK ---")
               // print(trackResponse)
            }
        }
    }
}
