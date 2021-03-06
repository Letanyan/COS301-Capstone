import Foundation

enum HarvestDB {
  enum Path {
    static let parent = "xFBNcNmiuON8ACbAHzH0diWcFQ43"
  }
}

enum HarvestCloud {
//  static let baseURL = "http://localhost:5000/harvest-ios-1522082524457/us-central1/"
  static let baseURL = "https://us-central1-harvest-ios-1522082524457.cloudfunctions.net/"
  
  static func component(onBase base: String, withArgs args: [(String, String)]) -> String {
    guard let first = args.first else {
      return base
    }
    
    let format: ((String, String)) -> String = { kv in
      return kv.0 + "=" + kv.1
    }
    
    var result = base + "?" + format(first)
    
    for kv in args.dropFirst() {
      result += "&" + format(kv)
    }
    
    return result
  }
  
  static func makeBody(withArgs args: [(String, String)]) -> String {
    guard let first = args.first else {
      return ""
    }
    
    let format: ((String, String)) -> String = { kv in
      return kv.0 + "=" + kv.1
    }
    
    var result = format(first)
    
    for kv in args.dropFirst() {
      result += "&" + format(kv)
    }
    
    return result
  }
  
  enum Identifiers {
    static let shallowSessions = "flattendSessions"
    static let sessionsWithDates = "sessionsWithinDates"
    static let expectedYield = "expectedYield"
    static let orchardCollections = "orchardCollectionsWithinDate"
    static let timeGraphSessions = "timedGraphSessions"
  }
  
  static func runTask(withQuery query: String, completion: @escaping (Any) -> Void) {
    let furl = URL(string: baseURL + query)!
    print(furl)
    let task = URLSession.shared.dataTask(with: furl) { data, _, error in
      if let error = error {
        print(error)
        return
      }
      
      guard let data = data else {
        completion(Void())
        return
      }
      
      guard let jsonSerilization = try? JSONSerialization.jsonObject(with: data, options: []) else {
        completion(Void())
        return
      }
      
      completion(jsonSerilization)
    }
    
    task.resume()
  }
  
  static func runTask(_ task: String, withBody body: String, completion: @escaping (Any) -> Void) {
    let furl = URL(string: baseURL + task)!
    var request = URLRequest(url: furl)
    
//    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    request.httpMethod = "POST"
    request.httpBody = body.data(using: .utf8)
    
    print(furl)
    
    let task = URLSession.shared.dataTask(with: request) { data, _, error in
      if let error = error {
        print(error)
        return
      }
      
      guard let data = data else {
        completion(Void())
        return
      }
      
      guard let jsonSerilization = try? JSONSerialization.jsonObject(with: data, options: []) else {
        completion(Void())
        return
      }
      
      completion(jsonSerilization)
    }
    
    task.resume()
  }
  
  static func getExpectedYield(orchardId: String, date: Date, completion: @escaping (Double) -> Void) {
    let query = component(onBase: Identifiers.expectedYield, withArgs: [
      ("orchardId", orchardId),
      ("date", date.timeIntervalSince1970.description),
      ("uid", HarvestDB.Path.parent)
    ])
    
    print(date.timeIntervalSince1970.description)
    
    runTask(withQuery: query) { (serial) in
      guard let json = serial as? [String: Any] else {
        completion(.nan)
        return
      }
      
      guard let expected = json["expected"] as? Double else {
        completion(.nan)
        return
      }
      
      completion(expected)
    }
  }
  
  static func orchardCollections(
    orchardIds: [String], 
    startDate: Date, 
    endDate: Date, 
    completion: @escaping ([Any]) -> Void
  ) {
    var args = [
      ("startDate", startDate.timeIntervalSince1970.description),
      ("endDate", endDate.timeIntervalSince1970.description),
      ("uid", HarvestDB.Path.parent)
    ]
    
    for (i, o) in orchardIds.enumerated() {
      args.append(("orchardId\(i)", o))
    }
    
    let body = makeBody(withArgs: args)
    
    runTask(Identifiers.orchardCollections, withBody: body) { (serial) in
      guard let json = serial as? [Any] else {
        return
      }
      
      completion(json)
    }
  }
  
  enum TimePeriod : CustomStringConvertible {
    case hourly
    case daily
    case weekly
    case monthly
    case yearly
    
    var description: String {
      switch self {
      case .hourly: return "hourly"
      case .daily: return "daily"
      case .weekly: return "weekly"
      case .monthly: return "monthly"
      case .yearly: return "yearly"
      }
    }
  }
  
  enum GroupBy : CustomStringConvertible {
    case worker
    case orchard
    case foreman
    
    var description: String {
      switch self {
      case .worker: return "worker"
      case .orchard: return "orchard"
      case .foreman: return "foreman"
      }
    }
  }
  
  static func timeGraphSessions(
    grouping: GroupBy,
    ids: [String],
    period: TimePeriod,
    startDate: Date,
    endDate: Date,
    completion: @escaping (Any) -> Void
  ) {
    var args = [
      ("groupBy", grouping.description),
      ("period", period.description),
      ("startDate", startDate.timeIntervalSince1970.description),
      ("endDate", endDate.timeIntervalSince1970.description),
      ("uid", HarvestDB.Path.parent)
    ]
    
    for (i, id) in ids.enumerated() {
      args.append(("id\(i)", id))
    }
    
    let body = makeBody(withArgs: args)
    
    runTask(Identifiers.timeGraphSessions, withBody: body) { (serial) in
      completion(serial)
    }
  }
}

func orchardCollection() {
  let s = Date(timeIntervalSince1970: 1529853470 * 0)
  let e = Date()

  HarvestCloud.orchardCollections(orchardIds: ["-LCEFgdMMO80LR98BzPC"], startDate: s, endDate: e) { f in
    print(f)
  }
}

func timeGraphSessionsWorker() {
  let cal = Calendar.current
  
  let wb = cal.date(byAdding: Calendar.Component.weekday, value: -7, to: Date())!.timeIntervalSince1970
  
  let s = Date(timeIntervalSince1970: wb * 0)
  let e = Date()
  let g = HarvestCloud.GroupBy.worker
  let p = HarvestCloud.TimePeriod.daily
  
  let ids = [
    "-LBykXujU0Igjzvq5giB", // Peter Parker 3
//    "-LBykZoPlQ2xkIMylBr2", // Tony Stark 4
    "-LBykabv5OJNBsdv0yl7", // Clark Kent 5
//    "-LBykcR9o5_S_ndIYHj9", // Bruce Wayne 6
  ]

  HarvestCloud.timeGraphSessions(grouping: g, ids: ids, period: p, startDate: s, endDate: e) { o in
    print(o)
  }
}

func timeGraphSessionsOrchard() {
  let cal = Calendar.current
  
  let wb = cal.date(byAdding: Calendar.Component.weekday, value: -7, to: Date())!.timeIntervalSince1970
  
  let s = Date(timeIntervalSince1970: wb)
  let e = Date()
  let g = HarvestCloud.GroupBy.orchard
  let p = HarvestCloud.TimePeriod.daily
  
  let ids = [
    "-LCEFgdMMO80LR98BzPC", // Block H
    "-LCEFoWPEw7ThnUaz07W", // Block U
    "-LCnEEUlavG3eFLCC3MI", // Maths Building
  ]

  HarvestCloud.timeGraphSessions(grouping: g, ids: ids, period: p, startDate: s, endDate: e) { o in
    print(o)
  }
}

func expectedYield() {
  HarvestCloud.getExpectedYield(orchardId: "-LCEFgdMMO80LR98BzPC", date: Date()) {
    print($0)
  }
}

timeGraphSessionsWorker()

RunLoop.main.run()