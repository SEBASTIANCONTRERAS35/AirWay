//
//  WatchConnector.swift
//  AirWay
//
//  Created by Emilio Cruz Vargas on 05/10/25.
//

import Foundation

import WatchConnectivity

class WatchConnector: NSObject, WCSessionDelegate {
    let session: WCSession
    
    init(session: WCSession = .default) {
        self.session = session
        super.init()
        self.session.delegate = self
        self.session.activate()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
}

