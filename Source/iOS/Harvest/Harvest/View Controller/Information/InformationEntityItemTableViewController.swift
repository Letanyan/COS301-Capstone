//
//  InformationEntityItemTableViewController.swift
//  Harvest
//
//  Created by Letanyan Arumugam on 2018/04/19.
//  Copyright © 2018 Letanyan Arumugam. All rights reserved.
//

import UIKit

class InformationEntityItemTableViewController: UITableViewController {
  var listnerId: Int?
  var selectedEntity: EntityItem?
  var kind: EntityItem.Kind = .none {
    didSet {
      navigationItem.rightBarButtonItem?.isEnabled = kind != .session
    }
  }
  
  var items: SortedDictionary<String, EntityItem>? {
    return Entities.shared.items(for: kind)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    refreshControl = UIRefreshControl()
    refreshControl?.addTarget(self,
                             action: #selector(refreshList(_:)),
                             for: .valueChanged)
    
    tableView.addSubview(refreshControl!)
    
    if listnerId == nil {
      listnerId = Entities.shared.listen { self.tableView.reloadData() }
    }
  }
  
  @objc func refreshList(_ refreshControl: UIRefreshControl) {
    Entities.shared.getOnce(kind) { (_) in
      self.refreshControl?.endRefreshing()
      self.tableView.reloadData()
    }
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(true)
    if let id = listnerId {
      listnerId = nil
      Entities.shared.deregister(listner: id)
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    if let sel = tableView.indexPathForSelectedRow {
      tableView.deselectRow(at: sel, animated: false)
    }
    if listnerId == nil {
      listnerId = Entities.shared.listen { self.tableView.reloadData() }
    }
    tableView.reloadData()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  @IBAction func newButtonTouchUp(_ sender: UIBarButtonItem) {
    switch kind {
    case .farm:
      let farm = Farm(json: [:], id: "")
      selectedEntity = .farm(farm)
      performSegue(withIdentifier: "EntitiesToDetail", sender: self)
    case .worker:
      let worker = Worker(json: [:], id: "")
      selectedEntity = .worker(worker)
      performSegue(withIdentifier: "EntitiesToDetail", sender: self)
    case .orchard:
      let orchard = Orchard(json: [:], id: "")
      selectedEntity = .orchard(orchard)
      performSegue(withIdentifier: "EntitiesToDetail", sender: self)
      
    case .session:
      break
      
    case .shallowSession:
      break
      
    case .user:
      break
      
    case .none:
      break
    }
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    return kind == .session ? Entities.shared.sessionDates().count : 1
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return kind == .session
      ? Entities.shared.sessionsFor(day: Entities.shared.sessionDates()[section]).count
      : (items?.count ?? 0)
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "informationEntityItemCell", for: indexPath)
    
    guard kind != .session else {
      let items = Entities.shared.sessionsFor(day: Entities.shared.sessionDates()[indexPath.section])
      cell.textLabel?.text = items[indexPath.row].foreman.description
      return cell
    }
    
    guard let item = items?[indexPath.row] else {
      return cell
    }
    
    switch item {
    case let .worker(w):
      cell.textLabel?.text = w.firstname + " " + w.lastname
    case let .orchard(o):
      cell.textLabel?.text = o.description
    case let .farm(f):
      cell.textLabel?.text = f.name
    case let .session(s):
      cell.textLabel?.text = s.foreman.description
    case .shallowSession:
      break
    case .user:
      cell.textLabel?.text = ""
    }
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
    guard kind != .session else {
      let items = Entities.shared.sessionsFor(day: Entities.shared.sessionDates()[indexPath.section])
      selectedEntity = .session(items[indexPath.row])
      return indexPath
    }
    
    selectedEntity = items?[indexPath.row]
    return indexPath
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    let dates = Entities.shared.sessionDates()
    guard dates.count > 0 else {
      return nil
    }
    
    let date = dates[section]
    
    return kind == .session ? formatter.string(from: date)  : nil
  }
  
  override func tableView(
    _ tableView: UITableView,
    editingStyleForRowAt indexPath: IndexPath
  ) -> UITableViewCellEditingStyle {
    return UITableViewCellEditingStyle.none
  }

  // MARK: - Navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    let vc = segue.destination
    
    if let entityViewController = vc as? EntityViewController {
      entityViewController.entity = selectedEntity
      entityViewController.title = selectedEntity?.name
    }
  }
  
}
