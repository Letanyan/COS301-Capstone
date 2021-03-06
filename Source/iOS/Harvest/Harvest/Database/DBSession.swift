//
//  DBSession.swift
//  Harvest
//
//  Created by Letanyan Arumugam on 2018/04/20.
//  Copyright © 2018 Letanyan Arumugam. All rights reserved.
//

import Firebase

extension HarvestDB {
  static func getSessions(_ completion: @escaping ([Session]) -> Void) {
    let sref = ref.child(Path.sessions)
    sref.observeSingleEvent(of: .value) { (snapshot) in
      var sessions = [Session]()
      for _child in snapshot.children {
        guard let child = _child as? DataSnapshot else {
          continue
        }
        
        guard let session = child.value as? [String: Any] else {
          continue
        }
        
        let s = Session(json: session, id: child.key)
        sessions.append(s)
      }
      completion(sessions)
    }
  }
  
  static func getSession(id: String, _ completion: @escaping (Session) -> Void) {
    let sref = ref.child(Path.sessions + "/" + id)
    sref.observeSingleEvent(of: .value) { (snapshot) in
      guard let session = snapshot.value as? [String: Any] else {
        return
      }
      
      let s = Session(json: session, id: snapshot.key)
      completion(s)
    }
  }
  
  static func watchSessions(_ completion: @escaping ([Session]) -> Void) {
    let sref = ref.child(Path.sessions)
    sref.observe(.value) { (snapshot) in
      var sessions = [Session]()
      for _child in snapshot.children {
        guard let child = _child as? DataSnapshot else {
          continue
        }
        
        guard let session = child.value as? [String: Any] else {
          continue
        }
        
        let s = Session(json: session, id: child.key)
        sessions.append(s)
      }
      completion(sessions)
    }
  }
  
  static func save(session: Session) {
    let sessions = ref.child(Path.sessions)
    if session.id == "" {
      session.id = sessions.childByAutoId().key
    }
    let update = session.json()
    sessions.updateChildValues(update)
  }
  
  static func delete(
    session: Session,
    completion: @escaping (Error?, DatabaseReference) -> Void
  ) {
    let sessions = ref.child(Path.sessions)
    guard session.id != "" else {
      return
    }
    sessions.child(session.id).removeValue(completionBlock: { (err, ref) in
      completion(err, ref)
    })
  }
}
