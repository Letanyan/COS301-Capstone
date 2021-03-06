//
//  InfoRepresentation.swift
//  Harvest
//
//  Created by Letanyan Arumugam on 2018/04/19.
//  Copyright © 2018 Letanyan Arumugam. All rights reserved.
//

// swiftlint:disable function_body_length
import Eureka
import SCLAlertView

extension UIViewController {
  func prebuiltGraph(
    title: String,
    startDate: Date,
    endDate: Date,
    period: HarvestCloud.TimePeriod,
    stat: Stat
  ) -> ButtonRow {
    return ButtonRow { row in
      row.title = title
    }.cellUpdate { cell, _ in
      cell.textLabel?.textAlignment = .left
      cell.textLabel?.textColor = .addOrchard
    }.onCellSelection { _, _ in
      guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "statsViewController") else {
        return
      }
      
      guard let svc = vc as? StatsViewController else {
        return
      }
      
      svc.startDate = startDate
      svc.endDate = endDate
      svc.period = period
      svc.stat = stat
      
      self.navigationController?.pushViewController(svc, animated: true)
    }
  }
}

extension FormViewController {
  func performanceRows(for stat: Stat) -> [ButtonRow] {
    let today = Date().today()
    let todaysPerformance = prebuiltGraph(
      title: "Todays Performance",
      startDate: today.0,
      endDate: today.1,
      period: .hourly,
      stat: stat)
    
    let yesterday = Date().yesterday()
    let yesterdaysPerformance = prebuiltGraph(
      title: "Yesterdays Performance",
      startDate: yesterday.0,
      endDate: yesterday.1,
      period: .hourly,
      stat: stat)
    
    let thisWeek = Date().thisWeek()
    let thisWeeksPerformance = prebuiltGraph(
      title: "This Weeks Performance",
      startDate: thisWeek.0,
      endDate: thisWeek.1,
      period: .daily,
      stat: stat)
    
    let lastWeek = Date().lastWeek()
    let lastWeeksPerformance = prebuiltGraph(
      title: "Last Weeks Performance",
      startDate: lastWeek.0,
      endDate: lastWeek.1,
      period: .daily,
      stat: stat)
    
    let thisMonth = Date().thisMonth()
    let thisMonthsPerformance = prebuiltGraph(
      title: "This Months Performance",
      startDate: thisMonth.0,
      endDate: thisMonth.1,
      period: .weekly,
      stat: stat)
    
    let lastMonth = Date().lastMonth()
    let lastMonthsPerformance = prebuiltGraph(
      title: "Last Months Performance",
      startDate: lastMonth.0,
      endDate: lastMonth.1,
      period: .weekly,
      stat: stat)
    
    let thisYear = Date().thisMonth()
    let thisYearsPerformance = prebuiltGraph(
      title: "This Years Performance",
      startDate: thisYear.0,
      endDate: thisYear.1,
      period: .monthly,
      stat: stat)
    
    let lastYear = Date().lastMonth()
    let lastYearsPerformance = prebuiltGraph(
      title: "Last Years Performance",
      startDate: lastYear.0,
      endDate: lastYear.1,
      period: .monthly,
      stat: stat)
    
    return [
      todaysPerformance,
      yesterdaysPerformance,
      thisWeeksPerformance,
      lastWeeksPerformance,
      thisMonthsPerformance,
      lastMonthsPerformance,
      thisYearsPerformance,
      lastYearsPerformance
    ]
  }
}

extension Worker {
  func information(for formVC: FormViewController, onChange: @escaping () -> Void) {
    let form = formVC.form
    tempory = Worker(json: json()[id] ?? [:], id: id)
    
    let orchards = Entities.shared.orchards
    
    let orchardSection = SelectableSection<ListCheckRow<Orchard>>(
      "Assigned Orchards",
      selectionType: .multipleSelection)
    
    for (_, orchard) in orchards {
      orchardSection <<< ListCheckRow<Orchard>(orchard.description) { row in
        let farmName = Entities
          .shared.farms
          .first { _, v in v.id == orchard.assignedFarm }
          .map { $0.value.name }
          ?? orchard.assignedFarm
        row.title = farmName + " " + orchard.name
        row.selectableValue = orchard
        row.value = assignedOrchards.contains(orchard.id) ? orchard : nil
      }.onChange { (row) in
        if let sel = row.value {
          guard let idx = self.tempory?.assignedOrchards.index(of: orchard.id) else {
            self.tempory?.assignedOrchards.append(orchard.id)
            onChange()
            return
          }
          self.tempory?.assignedOrchards[idx] = sel.id
          onChange()
        } else {
          guard let idx = self.tempory?.assignedOrchards.index(of: orchard.id) else {
            return
          }
          self.tempory?.assignedOrchards.remove(at: idx)
          onChange()
        }
      }
    }
    
    let firstnameRow = NameRow { row in
      row.add(rule: RuleRequired(msg: "• First name must be filled in"))
      row.validationOptions = .validatesAlways
      row.title = "Worker Name"
      row.value = firstname
      row.placeholder = "John"
    }.onChange { (row) in
      self.tempory?.firstname = row.value ?? ""
      onChange()
    }.cellUpdate { (cell, _) in
      cell.textField.clearButtonMode = .whileEditing
    }.onRowValidationChanged { (cell, row) in
      if row.validationErrors.isEmpty {
        cell.backgroundColor = .white
      } else {
        cell.backgroundColor = .invalidInput
      }
    }
    
    let lastnameRow = NameRow { row in
      row.add(rule: RuleRequired(msg: "• Surname must be filled in"))
      row.validationOptions = .validatesAlways
      row.title = "Worker Surname"
      row.value = lastname
      row.placeholder = "Appleseed"
    }.onChange { (row) in
      self.tempory?.lastname = row.value ?? ""
      onChange()
    }.cellUpdate { (cell, _) in
      cell.textField.clearButtonMode = .whileEditing
    }.onRowValidationChanged { (cell, row) in
      if row.validationErrors.isEmpty {
        cell.backgroundColor = .white
      } else {
        cell.backgroundColor = .invalidInput
      }
    }
    
    let isForemanRow = SwitchRow("isForemanTag") { row in
      row.title = "Is a foreman?"
      row.value = kind == .foreman
    }.onChange { (row) in
      self.tempory?.kind = row.value ?? true ? .foreman : .worker
      onChange()
    }
    
    let phoneRow = PhoneRow { row in
      row.hidden = Condition.function(["isForemanTag"], { form in
        return !((form.rowBy(tag: "isForemanTag") as? SwitchRow)?.value ?? false)
      })
      row.add(rule: RuleRequired(msg: "• Phone numbers must exist for foreman"))
      row.validationOptions = .validatesAlways
      row.title = "Phone Number"
      row.value = Phoney.formatted(number: phoneNumber)
      row.placeholder = Phoney.formatted(number: "0123456789")
    }.onChange { row in
      self.tempory?.phoneNumber = Phoney.formatted(number: row.value) ?? ""
      onChange()
    }.onRowValidationChanged { (cell, row) in
      if row.validationErrors.isEmpty {
        cell.backgroundColor = .white
      } else {
        cell.backgroundColor = .invalidInput
      }
    }
    
    let idRow = TextRow { row in
      row.title = "ID Number"
      row.value = idNumber
      row.placeholder = "8001011234567"
    }.onChange { row in
      self.tempory?.idNumber = row.value ?? ""
      onChange()
    }
    
    let infoRow = TextAreaRow { row in
      row.value = details
      row.placeholder = "Any extra information"
    }.onChange { row in
      self.tempory?.details = row.value ?? ""
      onChange()
    }
    
    let deleteWorkerRow = ButtonRow { row in
      row.title = "Delete Worker"
    }.onCellSelection { (_, _) in
      let alert = SCLAlertView(appearance: .warningAppearance)
      alert.addButton("Cancel", action: {})
      alert.addButton("Delete") {
        HarvestDB.delete(worker: self) { (_, _) in
          formVC.navigationController?.popViewController(animated: true)
        }
      }
      
      alert.showWarning("Are You Sure You Want to Delete \(self.name)?", subTitle: """
        You will not be able to get back any information about this worker.
        Any work done by this worker will no longer have any statistics associated with them.
        """)
    }.cellUpdate { (cell, _) in
      cell.textLabel?.textColor = .white
      cell.backgroundColor = .red
    }
    
    let performanceSection = Section("Performance")
    if kind == .worker {
      for prow in formVC.performanceRows(for: .workerComparison([self])) {
        performanceSection <<< prow
      }
    } else {
      for prow in formVC.performanceRows(for: .foremanComparison([self])) {
        performanceSection <<< prow
      }
    }
    
    form
      +++ Section()
      <<< firstnameRow
      <<< lastnameRow
      <<< idRow
      
      +++ Section.init(
        header: "Role",
        footer: """
        Any foreman phone number must include its area code. Example \(Phoney.formatted(number: "0123456789") ?? "")
        """)
      <<< isForemanRow
      <<< phoneRow
//      <<< emailRow
  
//      +++ Section("Contact")
//      <<< phoneRow
    
      +++ orchardSection
    
    _ = id != "" ? (form +++ performanceSection) : form
    
    form
      +++ Section("Further Information")
      <<< infoRow
      
      +++ Section()
      <<< deleteWorkerRow
  }
}

extension Farm {
  func information(for formVC: FormViewController, onChange: @escaping () -> Void) {
    let form = formVC.form
    tempory = Farm(json: json()[id] ?? [:], id: id)
    
    let nameRow = NameRow { row in
      let uniqueNameRule = RuleClosure<String> { (_) -> ValidationError? in
        let notUnique = Entities.shared.farms.contains { $0.value.name == row.value && $0.value.id != self.id }
        return notUnique ? ValidationError(msg: "• Farm names must be unique") : nil
      }
      row.add(rule: RuleRequired(msg: "• Farm names must be filled in"))
      row.add(rule: uniqueNameRule)
      row.title = "Farm Name"
      row.value = name
      row.placeholder = "Name of the farm"
    }.onChange { row in
      self.tempory?.name = row.value ?? ""
      onChange()
    }.cellUpdate { (cell, _) in
      cell.textField.clearButtonMode = .whileEditing
    }.onRowValidationChanged { (cell, row) in
      if row.validationErrors.isEmpty {
        cell.backgroundColor = .white
      } else {
        cell.backgroundColor = .invalidInput
      }
    }
    
    let companyRow = NameRow { row in
      row.title = "Company Name"
      row.value = companyName
      row.placeholder = "Name of the company"
    }.onChange { row in
      self.tempory?.companyName = row.value ?? ""
      onChange()
    }.cellUpdate { (cell, _) in
      cell.textField.clearButtonMode = .whileEditing
    }
    
    let emailRow = EmailRow { row in
      row.title = "Farm Email"
      row.value = email
      row.placeholder = "Farms email address"
    }.onChange { row in
      self.tempory?.email = row.value ?? ""
      onChange()
    }.cellUpdate { (cell, _) in
      cell.textField.clearButtonMode = .whileEditing
    }
    let phoneRow = PhoneRow { row in
      row.title = "Contact Number"
      row.value = contactNumber
      row.placeholder = "Phone number of the farm"
    }.onChange { row in
      self.tempory?.contactNumber = row.value ?? ""
      onChange()
    }.cellUpdate { (cell, _) in
      cell.textField.clearButtonMode = .whileEditing
    }
    
    let provinceRow = NameRow { row in
      row.title = "Province"
      row.value = province
      row.placeholder = "Province location of the farm"
    }.onChange { row in
      self.tempory?.province = row.value ?? ""
      onChange()
    }.cellUpdate { (cell, _) in
      cell.textField.clearButtonMode = .whileEditing
    }
    let nearestTownRow = NameRow { row in
      row.title = "Nearest Town"
      row.value = nearestTown
      row.placeholder = "Town nearest to the farm"
    }.onChange { row in
      self.tempory?.nearestTown = row.value ?? ""
      onChange()
    }.cellUpdate { (cell, _) in
      cell.textField.clearButtonMode = .whileEditing
    }
    
    let detailsRow = TextAreaRow { row in
      row.title = "Details"
      row.value = details
      row.placeholder = "Any extra information"
    }.onChange { row in
      self.tempory?.details = row.value ?? ""
      onChange()
    }
    let o = Orchard(json: ["farm": id], id: "")
    let orchardRow = OrchardInFarmRow(tag: nil, orchard: o) { row in
      row.title = "Add Orchard to \(self.name)"
    }.cellUpdate { (cell, _) in
      cell.textLabel?.textColor = .addOrchard
      cell.textLabel?.textAlignment = .center
    }
    
    let orchardsSection = Section("Orchards in \(name)")
    
    for (_, orchard) in Entities.shared.orchards {
      let oRow = OrchardInFarmRow(tag: nil, orchard: orchard) { row in
        row.title = orchard.name
      }
      if orchard.assignedFarm == id {
        orchardsSection <<< oRow
      }
    }
    
    let deleteFarmRow = ButtonRow { row in
      row.title = "Delete Farm"
    }.onCellSelection { (_, _) in
      let alert = SCLAlertView(appearance: .warningAppearance)
      alert.addButton("Cancel", action: {})
      alert.addButton("Delete") {
        HarvestDB.delete(farm: self) { (_, _) in
          formVC.navigationController?.popViewController(animated: true)
        }
      }
      
      alert.showWarning("Are You Sure You Want to Delete \(self.name)?", subTitle: """
        You will not be able to get back any information about this farm.
        """)
    }.cellUpdate { (cell, _) in
      cell.textLabel?.textColor = .white
      cell.backgroundColor = .red
    }
    
    form +++ Section("Farm")
      <<< nameRow
      <<< companyRow
      
      +++ Section("Contact")
      <<< emailRow
      <<< phoneRow
      
      +++ Section("Location")
      <<< provinceRow
      <<< nearestTownRow
    
      +++ orchardsSection
      <<< orchardRow
      
      +++ Section("Further Information")
      <<< detailsRow
    
      +++ Section()
      <<< deleteFarmRow
  }
}

public class DeletableMultivaluedSection: MultivaluedSection {
  var onRowsRemoved: ((IndexSet) -> Void)?
  
  required public init<S>(_ elements: S) where S: Sequence, S.Element == BaseRow {
    fatalError("init has not been implemented")
  }
  
  required public init() {
    fatalError("init() has not been implemented")
  }
  
  required public init(multivaluedOptions: MultivaluedOptions = MultivaluedOptions.Insert.union(.Delete),
                       header: String = "",
                       footer: String = "",
                       _ initializer: (MultivaluedSection) -> Void = { _ in }) {
    
    super.init(header: header, footer: footer, {section in initializer(section) })
    self.multivaluedOptions = multivaluedOptions
    guard multivaluedOptions.contains(.Insert) else { return }
  }
  
  func initialize() {
    let addRow = addButtonProvider(self)
    addRow.onCellSelection { cell, row in
      guard let tableView = cell.formViewController()?.tableView, let indexPath = row.indexPath else { return }
      cell.formViewController()?.tableView(tableView, commit: .insert, forRowAt: indexPath)
    }
    self <<< addRow
  }
  
  override public func rowsHaveBeenRemoved(_ rows: [BaseRow], at: IndexSet) {
    onRowsRemoved?(at)
  }
}

extension Orchard {
  // swiftlint:disable cyclomatic_complexity
  func information(for formVC: FormViewController, onChange: @escaping () -> Void) {
    let form = formVC.form
    tempory = Orchard(json: json()[id] ?? [:], id: id)
    
    let farms = Entities.shared.farms
    
    let cultivarsRow = DeletableMultivaluedSection(
      multivaluedOptions: [.Insert, .Delete],
      header: "Cultivars",
      footer: "") { (section) in
        section.addButtonProvider = { sectionB in
          return ButtonRow {
            $0.title = "Add Another Cultivar"
          }
        }
        for (idx, cultivar) in cultivars.enumerated() {
          section <<< TextRow {
            $0.placeholder = "Cultivar"
            $0.value = cultivar
          }.onChange { row in
            self.tempory?.cultivars[idx] = row.value ?? ""
            onChange()
          }
        }
        
        section.multivaluedRowToInsertAt = { index in
          self.tempory?.cultivars.append("")
          return TextRow {
            $0.placeholder = "Cultivar"
          }.onChange { row in
            self.tempory?.cultivars[index] = row.value ?? ""
            onChange()
          }
        }
      }
    cultivarsRow.onRowsRemoved = { indexes in
      for i in indexes {
        self.tempory?.cultivars.remove(at: i)
      }
      onChange()
    }
    
    let nameRow = NameRow { row in
      let uniqueNameRule = RuleClosure<String> { (_) -> ValidationError? in
        let notUnique = Entities.shared.orchards.contains {
          $0.value.name == row.value
            && $0.value.assignedFarm == self.tempory?.assignedFarm
            && $0.value.id != self.id
        }
        return notUnique ? ValidationError(msg: "• Orchard names in the same farm must have different names") : nil
      }
      row.add(rule: RuleRequired(msg: "• Orchard names must be filled in"))
      row.add(rule: uniqueNameRule)
      row.title = "Orchard Name"
      row.value = name
      row.placeholder = "Name of the orchard"
    }.onChange { row in
      self.tempory?.name = row.value ?? ""
      onChange()
    }.cellUpdate { (cell, _) in
      cell.textField.clearButtonMode = .whileEditing
    }.onRowValidationChanged { (cell, row) in
      if row.validationErrors.isEmpty {
        cell.backgroundColor = .white
      } else {
        cell.backgroundColor = .invalidInput
      }
    }
    
    let cropRow = TextRow { row in
      row.title = "Orchard Crop"
      row.value = crop
      row.placeholder = "Crop farmed on the orchard"
    }.onChange { row in
      self.tempory?.crop = row.value ?? ""
      onChange()
    }.cellUpdate { (cell, _) in
      cell.textField.clearButtonMode = .whileEditing
    }
    
    let bagMassRow = DecimalRow { row in
      row.title = "Bag Mass (kilogram)"
      row.value = bagMass.isNaN ? nil : bagMass
      row.placeholder = "Average mass of a bag"
    }.onChange { row in
      self.tempory?.bagMass = row.value ?? .nan
      onChange()
    }.cellUpdate { (cell, _) in
      cell.textField.clearButtonMode = .whileEditing
    }
    
    let dateRow = DateRow { row in
      row.title = "Date Planted"
      row.value = date
    }.onChange { row in
      self.tempory?.date = row.value ?? Date()
      onChange()
    }
    
    let irrigationRow = PushRow<IrrigationKind> { row in
      row.title = "Irrigation Kind"
      row.options = IrrigationKind.allCases
      row.value = irrigationKind
    }.onChange { row in
      self.tempory?.irrigationKind = row.value ?? .none
      onChange()
    }
    
    let widthRow = DecimalRow { row in
      row.title = "Tree Spacing (meter)"
      row.value = treeSpacing.isNaN ? nil : treeSpacing
      row.placeholder = "Horizontal Spacing"
    }.onChange { row in
      self.tempory?.treeSpacing = row.value ?? .nan
      onChange()
    }.cellUpdate { (cell, _) in
      cell.textField.clearButtonMode = .whileEditing
    }
    
    let heightRow = DecimalRow { row in
      row.title = "Row Spacing (meter)"
      row.value = rowSpacing.isNaN ? nil : rowSpacing
      row.placeholder = "Vertical Spacing"
    }.onChange { row in
      self.tempory?.rowSpacing = row.value ?? .nan
      onChange()
    }.cellUpdate { (cell, _) in
      cell.textField.clearButtonMode = .whileEditing
    }
    
    let detailsRow = TextAreaRow { row in
      row.value = details
      row.placeholder = "Any extra information"
    }.onChange { row in
      self.tempory?.details = row.value ?? ""
      onChange()
    }
    
    let farmSelection = PushRow<Farm> { row in
      row.title = "Assigned Farm"
      row.add(rule: RuleRequired(msg: "• A farm must be selected for an orchard to be a part of"))
      row.options = []
      var aFarm: Farm? = nil
      
      for (_, farm) in farms {
        let farm = farm
        row.options?.append(farm)
        if farm.id == assignedFarm {
          aFarm = farm
        }
      }
      row.value = aFarm ?? farms.first?.value
      if aFarm == nil {
        self.tempory?.assignedFarm = row.value?.id ?? ""
      }
    }.onChange { (row) in
      self.tempory?.assignedFarm = row.value?.id ?? ""
      onChange()
    }
    
    let orchardAreaRow = OrchardAreaRow { row in
      row.title = "Orchard Location"
      row.value = self
    }.cellUpdate { (cell, _) in
      cell.detailTextLabel?.text = ""
    }
      
    orchardAreaRow.actuallyChanged = { (row) in
      self.tempory?.coords = row.value?.coords ?? []
      onChange()
    }
    
    let performanceSection = Section("Performance")
    for prow in formVC.performanceRows(for: .orchardComparison([self])) {
      performanceSection <<< prow
    }
    
    let deleteOrchardRow = ButtonRow { row in
      row.title = "Delete Orchard"
    }.onCellSelection { (_, _) in
      let alert = SCLAlertView(appearance: .warningAppearance)
      
      alert.addButton("Cancel", action: {})
      alert.addButton("Delete") {
        HarvestDB.delete(orchard: self) { (_, _) in
          formVC.navigationController?.popViewController(animated: true)
        }
      }
      
      alert.showWarning("Are You Sure You Want to Delete \(self.name)?", subTitle: """
        You will not be able to get back any information about this farm.
        Any work done in this orchard will no longer display any statistics.
        """)
    }.cellUpdate { (cell, _) in
      cell.textLabel?.textColor = .white
      cell.backgroundColor = .red
    }
    
    let assignedWorkersRow = MultipleSelectorRow<Worker> { row in
      row.title = "Assigned Workers"
      self.tempory?.assignedWorkers = []
      var opts = [Worker]()
      var vals = Set<Worker>()
      for (_, worker) in Entities.shared.workers {
        opts.append(worker)
        if worker.assignedOrchards.contains(id) {
          vals.insert(worker)
          self.tempory?.assignedWorkers.append((worker.id, .assigned))
        } else {
          self.tempory?.assignedWorkers.append((worker.id, .unassigned))
        }
        row.options = opts
        row.value = vals
      }
    }.onChange { row in
      var idx = 0
      for (assignedWorker, status) in self.tempory?.assignedWorkers ?? [] {
        if [.remove, .unassigned].contains(status)
        && row.value?.contains(where: { $0.id == assignedWorker }) ?? false {
          self.tempory?.assignedWorkers[idx] = (assignedWorker, .add)
        } else if [.add, .assigned].contains(status)
        && !(row.value?.contains(where: { $0.id == assignedWorker }) ?? false) {
          self.tempory?.assignedWorkers[idx] = (assignedWorker, .remove)
        }
        
        idx += 1
      }
      onChange()
    }
    
    form
      +++ Section("Orchard")
      <<< nameRow
      <<< cropRow
    
      +++ Section("Orchard Location")
      <<< orchardAreaRow
    
      +++ Section("Collection Details")
      <<< bagMassRow
      
      +++ Section("Plantation Details")
      <<< irrigationRow
      <<< dateRow
      
      +++ cultivarsRow
      
      +++ Section("Crop Dimensions")
      <<< widthRow
      <<< heightRow
    
      +++ Section("Assigned Farm")
      <<< farmSelection
    
      +++ Section("Assigned Workers")
      <<< assignedWorkersRow
      
    if id != "" {
      form +++ performanceSection
    }
    
    form
      +++ Section("Further Information")
      <<< detailsRow
      
      +++ Section()
      <<< deleteOrchardRow
  }
}

extension Session {
  func information(for formVC: FormViewController, onChange: @escaping () -> Void) {
    let form = formVC.form
    tempory = Session(json: json(), id: id)
    
    let displayRow = LabelRow { row in
      row.title = "Foreman"
      row.value = foreman.description
    }
    
    let startDateRow = DateTimeRow { row in
      row.title = "Time Started"
      row.value = startDate
      row.baseCell.isUserInteractionEnabled = false
    }
    
    let endDateRow = DateTimeRow { row in
      row.title = "Time Ended"
      row.value = endDate
      row.baseCell.isUserInteractionEnabled = false
    }
    
    let sessionRow = SessionRow { row in
      row.title = "Tracked Path and Collection Points"
      row.value = self
    }.cellUpdate { (cell, _) in
      cell.detailTextLabel?.text = ""
    }
    
    let chartRow = DonutChartRow("") { row in
      row.value = self
      if #available(iOS 11, *) {
        row.baseCell.userInteractionEnabledWhileDragging = true
      }
    }
    
    form
      +++ Section("Foreman")
      <<< displayRow
    
      +++ Section("Duration")
      <<< startDateRow
      <<< endDateRow
    
      +++ Section("Tracking")
      <<< sessionRow
    
      +++ Section("Worker Performance Summary")
      <<< chartRow
  }
}

extension HarvestUser {
  func information(for formVC: FormViewController, onChange: @escaping () -> Void) {
    let form = formVC.form
    temporary = HarvestUser(json: json())
    
    let organisationNameRow = TextRow { row in
      row.title = "Organisation Name"
      row.value = HarvestUser.current.organisationName
      row.placeholder = "Name of the Organisation"
    }.cellUpdate { (cell, _) in
      cell.textField.clearButtonMode = .whileEditing
    }.onChange { row in
      self.temporary?.organisationName = row.value ?? ""
      onChange()
    }
    
    let firstnameRow = TextRow { row in
      row.title = "First Name"
      row.value = HarvestUser.current.firstname
      row.placeholder = ""
    }.cellUpdate { (cell, _) in
      cell.textField.clearButtonMode = .whileEditing
    }.onChange { row in
      self.temporary?.firstname = row.value ?? ""
      onChange()
    }
    
    let lastnameRow = TextRow { row in
      row.title = "Last Name"
      row.value = HarvestUser.current.lastname
      row.placeholder = ""
    }.cellUpdate { (cell, _) in
      cell.textField.clearButtonMode = .whileEditing
    }.onChange { row in
      self.temporary?.lastname = row.value ?? ""
      onChange()
    }
    
    form
      +++ Section("Organisation Name")
      <<< organisationNameRow
      
      +++ Section("Farmer Name")
      <<< firstnameRow
      <<< lastnameRow
  }
}

extension EntityItem {
  func information(for formVC: FormViewController, onChange: @escaping () -> Void) {
    switch self {
    case let .worker(w): w.information(for: formVC, onChange: onChange)
    case let .orchard(o): o.information(for: formVC, onChange: onChange)
    case let .farm(f): f.information(for: formVC, onChange: onChange)
    case let .session(s): s.information(for: formVC, onChange: onChange)
    case .shallowSession: break
    case let .user(u): u.information(for: formVC, onChange: onChange)
    }
  }
}
