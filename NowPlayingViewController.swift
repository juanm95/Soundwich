//
//  NowPlayingViewController.swift
//  Quaggify
//
//  Created by Jesse Candido on 5/13/17.
//  Copyright © 2017 Quaggie. All rights reserved.
//

import Foundation

class NowPlayingViewController: ViewController {
    
    var tC: TrackViewController? {
        didSet {
            guard let tC = tC else {
                return
            }
            self.presentedViewController?.loadView()
        }
    }

    
    
    func scrollToTop(){
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
     
     /*   if(thePlayer.nowPlaying?.track?.id != nil){
            
        }*/
       // navigationController?.pushViewController(thePlayer.nowPlaying!, animated: true)
      /*  let nowPlaying = NavigationController(rootViewController: NowPlayingViewController())
        nowPlaying.pushViewController(thePlayer.nowPlaying!, animated:true)*/
        setupViews()
       
    }
    
    override func setupViews() {
        super.setupViews()
        
    }
}

extension NowPlayingViewController: UICollectionViewDelegate {
   /* func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        navigationController?.pushViewController(thePlayer.nowPlaying!, animated: true)
    }*/
}























