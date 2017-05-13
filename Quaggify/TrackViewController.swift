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
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didStopPlayingTrack trackUri: String!) {
        var trackName = "spotify:track:"
        print("carolin3")
       /* API.checkQueue() { [weak self] (response) in
            guard let strongSelf = self else {
                return
            }
            print(response)
            let response = response as [String:Any]
            if response["queued"] as! Bool {
                trackName = "spotify:track:"
                let data = response["data"] as! [String:Any]
                let songid = data["songid"] as! String
                let time = data["time"] as! String
                let tomember = data["tomember"] as! String
                let frommember = data["frommember"] as! String
                trackName += songid
                self?.track?.id = songid
                API.fetchTrack(track: self?.track) { [weak self] (trackResponse, error) in
                    guard let strongSelf = self else {
                        return
                    }
                    if let error = error {
                        print(error)
                        Alert.shared.show(title: "Error", message: "Error communicating with the server")
                    } else if let trackResponse = trackResponse {
                        strongSelf.track = trackResponse
                        let alertController = UIAlertController(title: "Soundwich", message: "React to this song \(frommember) sent.", preferredStyle: UIAlertControllerStyle.alert)
                        alertController.addAction(UIAlertAction(title: "💩", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in
                            API.reactToSong(reaction: "💩", time: time, username: UserDefaults.standard.value(forKey: "username") as! String, to: tomember)
                        }))
                        alertController.addAction(UIAlertAction(title: "😂", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in
                            API.reactToSong(reaction: "😂", time: time, username: UserDefaults.standard.value(forKey: "username") as! String, to: tomember)
                        }))
                        alertController.addAction(UIAlertAction(title: "😡", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in
                            API.reactToSong(reaction: "😡", time: time, username: UserDefaults.standard.value(forKey: "username") as! String, to: tomember)
                        }))
                        alertController.addAction(UIAlertAction(title: "😎", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in
                            API.reactToSong(reaction: "😎", time: time, username: UserDefaults.standard.value(forKey: "username") as! String, to: tomember)
                        }))
                        strongSelf.present(alertController, animated: true) { // If the user doesn't react before the song finishes, I don't really know what happens...
                            let trackVC = TrackViewController()
                            trackVC.track = strongSelf.track   //safe:
                            self?.navigationController?.pushViewController(trackVC, animated: true)
                        }
                    }
                }
            } else {*/
                thePlayer.indeX += 1
                trackName += (thePlayer.trackList?.items?[thePlayer.indeX].track?.id)!
                let trackVC = TrackViewController()
                trackVC.track = thePlayer.trackList?.items?[thePlayer.indeX].track      //safe:
                self.navigationController?.pushViewController(trackVC, animated: true)
           // }
           /* thePlayer.spotifyPlayer?.playSpotifyURI(trackName, startingWith: 0, startingWithPosition: 0, callback: { (error) in
                if (error != nil) {
                    print(error)
                }
            })*/
       // }
    }

    var track: Track? {
        didSet {
            guard let track = track else {
                return
            }
            if let name = track.name {
                titleLabel.text = name
            }
            if let artists = track.artists {
                let names = artists.map { $0.name ?? "Unknown Artist" }.joined(separator: ", ")
                subTitleLabel.text = names
                navigationItem.title = names
            }
            if let smallerImage = track.album?.images?[safe: 1], let imgUrlString = smallerImage.url, let url = URL(string: imgUrlString) {
                imageView.kf.setImage(with: url, placeholder: #imageLiteral(resourceName: "placeholder"), options: [.transition(.fade(0.2))])
            } else if let smallerImage = track.album?.images?[safe: 0], let imgUrlString = smallerImage.url, let url = URL(string: imgUrlString) {
                imageView.kf.setImage(with: url, placeholder: #imageLiteral(resourceName: "placeholder"), options: [.transition(.fade(0.2))])
            } else {
                imageView.image = #imageLiteral(resourceName: "placeholder")
            }
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
    
    lazy var playSongButton: UIButton = {
        let btn = UIButton(type: .system)
        let img = #imageLiteral(resourceName: "play-button").withRenderingMode(.alwaysTemplate)
        btn.addTarget(self, action: #selector(playSong), for: .touchUpInside)
        btn.setImage(UIImage(named: "play-button")?.withRenderingMode(.alwaysOriginal), for: .normal)
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
    fetchTrack()
    playSong()
    //initializePlayer()
  //  playSong()
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
    view.addSubview(playSongButton)
    view.backgroundColor = ColorPalette.black
    
   // initializePlayer()

    
    stackView.addArrangedSubview(imageView)
    stackView.addArrangedSubview(containerView)
        stackView.anchor(topLayoutGuide.bottomAnchor, left: view.leftAnchor, bottom: bottomLayoutGuide.topAnchor, right: view.rightAnchor, topConstant: 8, leftConstant: 8, bottomConstant: 8, rightConstant: 8, widthConstant: 0, heightConstant: 0)
        
        titleLabel.anchor(containerView.topAnchor, left: containerView.leftAnchor, bottom: nil, right: containerView.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 24)
        
        subTitleLabel.anchor(titleLabel.bottomAnchor, left: containerView.leftAnchor, bottom: nil, right: containerView.rightAnchor, topConstant: 8, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 24)
        
        playSongButton.anchor(subTitleLabel.bottomAnchor, left: containerView.leftAnchor, bottom: nil, right: containerView.rightAnchor, topConstant: 8, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 70)
        
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
    
    func playSong() {
        var trackName = "spotify:track:"
        trackName += (track?.id)!
        print("here - playsong")
        thePlayer.spotifyPlayer?.playSpotifyURI(trackName, startingWith: 0, startingWithPosition: 0, callback: { (error) in
            if (error != nil) {
                print("playSong() called")
            }
        })
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget(self, action:#selector(self.audioStreaming(_:didStopPlayingTrack:)))
        let imageURLString = URL(string: (self.track?.album?.images?[0].url)!)
        let imageData = try! Data(contentsOf:imageURLString!)
        let image2 = UIImage(data:imageData)
        let newSize = CGSize(width:(self.track?.album?.images?[0].width)!,height:(self.track?.album?.images?[0].height)!)
        if let image = image2 ?? UIImage(named: "Empty Album"), #available(iOS 10.0, *) {
            let albumArt = MPMediaItemArtwork(boundsSize:newSize, requestHandler: { (size) -> UIImage in return image})
            let nowPlayingInfo : [String:Any] =  [
                MPMediaItemPropertyTitle: self.track?.name! ?? "Unknown Song",
                MPMediaItemPropertyArtist: self.track?.artists?[0].name! ?? "Unknown Artist",
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
