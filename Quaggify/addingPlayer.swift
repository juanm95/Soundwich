//
//  addingPlayer.swift
//  Quaggify
//
//  Created by Caroline Amy Debs on 5/10/17.
//  Copyright © 2017 Quaggie. All rights reserved.
//

import Foundation
import MediaPlayer

class thePlayer {
    static var spotifyPlayer: SPTAudioStreamingController?
    static var trackList: SpotifyObject<PlaylistTrack>?
    static var albumTrackList: SpotifyObject<Track>?
    static var indeX: Int = 0
    static var nowPlaying: TrackViewController?
    static var paused: Bool = false
    static var needToReact: Bool = false
    static var injected: Bool = false
    static var start: Bool = false
    static var PP: Bool = false
}

