import Swift

struct SortedDictionary<Key: Hashable, Value> : Collection {
  typealias SortingElement = Key
  
  struct DefaultIndex: Comparable, Strideable {
    typealias Stride = Int
    
    var boxed: Int
    
    init(_ b: Int) {
      boxed = b
    }
    
    static func == (lhs: Index, rhs: Index) -> Bool {
      return lhs.boxed == rhs.boxed
    }
    
    static func < (lhs: Index, rhs: Index) -> Bool {
      return lhs.boxed < rhs.boxed
    }
    
    func distance(to other: Index) -> Int {
      return other.boxed - boxed
    }
    
    func advanced(by n: Int) -> Index {
      return Index(boxed + n)
    }
  }
  
  var _dict: [Key: Value]
  var _ref: SortedArray<Key>
  var areInIncreasingOrder: Comparator
  
  typealias Element = (key: Key, value: Value)
  
  init(_ areInIncreasingOrder: @escaping (Key, Key) -> Bool) {
    _dict = [:]
    self.areInIncreasingOrder = areInIncreasingOrder
    _ref = SortedArray<Key>(areInIncreasingOrder: areInIncreasingOrder)
  }
  
  init(uniqueKeysWithValues pairs: [(Key, Value)],
       _ areInIncreasingOrder: @escaping (Key, Key) -> Bool) {
    _dict = Dictionary.init(pairs, uniquingKeysWith: { _, b in b })
    self.areInIncreasingOrder = areInIncreasingOrder
    _ref = SortedArray.init(pairs.map { $0.0 }, areInIncreasingOrder: areInIncreasingOrder)
  }
  
  var startIndex: DefaultIndex {
    return Index(_ref.startIndex)
  }
  
  var endIndex: DefaultIndex {
    return Index(_ref.endIndex)
  }
  
  func index(after: DefaultIndex) -> DefaultIndex {
    return Index(_ref.index(after: after.boxed))
  }
  
  subscript(index: DefaultIndex) -> Element {
    let key = _ref[index.boxed]
    let value = _dict[key]
    return (key: key, value: value!)
  }
  
  func mapValues<T>(_ f: (Value) -> T) -> SortedDictionary<Key, T> {
    var result = SortedDictionary<Key, T>(areInIncreasingOrder)
    result._dict = _dict.mapValues(f)
    result._ref.insert(elements: _dict.keys)
    return result
  }
}

extension SortedDictionary: SortedUniqueInsertableCollection, CustomStringConvertible {
  @discardableResult
  mutating func insert(unique element: Element) -> (Bool, Index) {
    let (contains, idx) = insertionPoint(for: element.key)
    if !contains {
      let i = _ref.insert(element.key)
      _dict[element.key] = element.value
      return (false, DefaultIndex(i))
    } else {
      return (true, idx)
    }
  }
  
  func sortingElement(for element: Element) -> SortingElement {
    return element.key
  }
  
  var description: String {
    guard _ref.count > 0 else {
      return "[]"
    }
    let firstKey = _ref[0]
    var result = "[\(firstKey): \(_dict[firstKey]!)"
    
    for key in _ref.dropFirst() {
      
      result += ", \(key): \(_dict[key]!)"
    }
    result += "]"
    return result
  }
}

extension SortedDictionary where Key: Comparable {
  init() {
    areInIncreasingOrder = (<)
    _dict = [:]
    _ref = SortedArray<Key>(areInIncreasingOrder: <)
  }
}

extension SortedDictionary: RangeRemovableCollection {
  mutating func removeSubrange(_ bounds: Range<Index>) {
    for ref_offset in stride(from: bounds.lowerBound, to: bounds.upperBound, by: 1) {
      guard let idx = _dict.index(forKey: _ref[ref_offset.boxed]) else {
        continue
      }
      _dict.remove(at: idx)
    }
    _ref.removeSubrange(bounds.lowerBound.boxed..<bounds.upperBound.boxed)
  }
}

extension SortedDictionary: RandomAccessCollection {
  subscript(key: Key) -> Value? {
    get {
      return _dict[key]
    }
    set {
      if let idx = _dict.index(forKey: key) {
        if let value = newValue {
          _dict[key] = value
        } else {
          _dict.remove(at: idx)
          _ref.remove(at: _ref.index(of: key)!)
        }
      } else {
        if let value = newValue {
          insert(unique: (key: key, value: value))
        } else {
          fatalError("Cannot delete key that doesn't exist")
        }
      }
    }
  }
  
  subscript(key: Key, default def: Value) -> Value {
    get {
      return self[key] ?? def
    }
    
    set {
      if self[key] == nil {
        self[key] = def
      } else {
        self[key] = newValue
      }
    }
  }
  
  subscript(index: Int) -> Value? {
    get {
      return _dict[_ref[index]]
    }
    set {
      _dict[_ref[index]] = newValue
    }
  }
}
