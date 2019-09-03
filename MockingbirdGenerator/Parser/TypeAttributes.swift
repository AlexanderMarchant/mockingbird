//
//  TypeAttributes.swift
//  MockingbirdCli
//
//  Created by Andrew Chang on 8/4/19.
//  Copyright © 2019 Bird Rides, Inc. All rights reserved.
//

import Foundation
import SourceKittenFramework

typealias StructureDictionary = [String: SourceKitRepresentable]

extension SwiftDeclarationKind {
  init?(from dictionary: StructureDictionary) {
    guard let rawKind = dictionary[SwiftDocKey.kind.rawValue] as? String else { return nil }
    self.init(rawValue: rawKind)
  }
  
  var isMockable: Bool {
    switch self {
    case .class, .protocol: return true
    default: return false
    }
  }
  
  var isParsable: Bool {
    switch self {
    case .class, .protocol, .struct, .enum, .extension, .typealias: return true
    default: return false
    }
  }
  
  var isMethod: Bool {
    switch self {
    case .functionMethodInstance, .functionMethodStatic, .functionMethodClass: return true
    default: return false
    }
  }
  
  var isVariable: Bool {
    switch self {
    case .varInstance, .varStatic, .varClass: return true
    default: return false
    }
  }
  
  var typeScope: TypeScope {
    switch self {
    case .functionMethodClass, .varClass: return .class
    case .functionMethodStatic, .varStatic: return .static
    default: return .instance
    }
  }
}

enum TypeScope {
  case `instance`, `static`, `class`
}

struct Attributes: OptionSet, Hashable {
  let rawValue: Int
  init(rawValue: Int) {
    self.rawValue = rawValue
  }
  
  // MARK: SourceKit-provided attributes
  static let final = Attributes(rawValue: 1 << 0)
  static let required = Attributes(rawValue: 1 << 1)
  static let optional = Attributes(rawValue: 1 << 2)
  static let lazy = Attributes(rawValue: 1 << 3)
  static let dynamic = Attributes(rawValue: 1 << 4)
  static let weak = Attributes(rawValue: 1 << 5)
  static let `rethrows` = Attributes(rawValue: 1 << 6)
  static let convenience = Attributes(rawValue: 1 << 7)
  
  // MARK: Inferred attributes
  static let constant = Attributes(rawValue: 1 << 8)
  static let computed = Attributes(rawValue: 1 << 9)
  static let `throws` = Attributes(rawValue: 1 << 10)
  static let `inout` = Attributes(rawValue: 1 << 11)
  static let variadic = Attributes(rawValue: 1 << 12)
  static let failable = Attributes(rawValue: 1 << 13)
  static let unwrappedFailable = Attributes(rawValue: 1 << 14)
  static let closure = Attributes(rawValue: 1 << 15)
  static let escaping = Attributes(rawValue: 1 << 16)
  static let autoclosure = Attributes(rawValue: 1 << 17)
  
  static let attributesKey = "key.attributes"
  static let attributeKey = "key.attribute"
}

extension Attributes {
  init?(from kind: SwiftDeclarationAttributeKind) {
    switch kind {
    case .final: self = .final
    case .required: self = .required
    case .optional: self = .optional
    case .lazy: self = .lazy
    case .dynamic: self = .dynamic
    case .weak: self = .weak
    case .rethrows: self = .rethrows
    case .convenience: self = .convenience
    default: return nil
    }
  }
  
  init(from dictionary: StructureDictionary) {
    var attributes = Attributes()
    guard let rawAttributes = dictionary[Attributes.attributesKey] as? [StructureDictionary] else {
      self = attributes
      return
    }
    for rawAttributeDictionary in rawAttributes {
      guard let rawAttribute = rawAttributeDictionary[Attributes.attributeKey] as? String,
        let attributeKind = SwiftDeclarationAttributeKind(rawValue: rawAttribute),
        let attribute = Attributes(from: attributeKind) else { continue }
      attributes.insert(attribute)
    }
    self = attributes
  }
}

enum AccessLevel: String, CustomStringConvertible {
  case `open` = "source.lang.swift.accessibility.open"
  case `public` = "source.lang.swift.accessibility.public"
  case `internal` = "source.lang.swift.accessibility.internal"
  case `fileprivate` = "source.lang.swift.accessibility.fileprivate"
  case `private` = "source.lang.swift.accessibility.private"
  
  static let accessLevelKey = "key.accessibility"
  static let setterAccessLevelKey = "key.setter_accessibility"
  
  var description: String {
    switch self {
    case .open: return "open"
    case .public: return "public"
    case .internal: return "internal"
    case .fileprivate: return "fileprivate"
    case .private: return "private"
    }
  }
  
  init?(from dictionary: StructureDictionary) {
    guard let rawAccessLevel = dictionary[AccessLevel.accessLevelKey] as? String else { return nil }
    self.init(rawValue: rawAccessLevel)
  }
  
  init?(setter dictionary: StructureDictionary) {
    guard let rawAccessLevel = dictionary[AccessLevel.setterAccessLevelKey] as? String
      else { return nil }
    self.init(rawValue: rawAccessLevel)
  }
  
  var isMockable: Bool {
    return self != .fileprivate && self != .private
  }
}