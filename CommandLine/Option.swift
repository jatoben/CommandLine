/*
 * Option.swift
 * Copyright (c) 2014 Ben Gollmer.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * The base class for a command-line option.
 */
public class Option {
  var shortFlag: String
  var longFlag: String
  var required: Bool
  var helpMessage: String
  
  /* Override this property to test _value for nil on each Option subclass.
   *
   * This is necessary to support nil checks on an array of Options (see
   * CommandLine.parse()) because Swift doesn't allow overriding property
   * declarations with differing types, and methods (unlike functions) are not
   * covariant as of beta 4.
   */
  var isSet: Bool {
    return false
  }
  
  public init(shortFlag: String, longFlag: String, required: Bool, helpMessage: String) {
    assert(countElements(shortFlag) == 1, "Short flag must be a single character")
    assert(shortFlag.toInt() == nil && shortFlag.toDouble() == nil, "Short flag cannot be a numeric value")
    assert(longFlag.toInt() == nil && longFlag.toDouble() == nil, "Long flag cannot be a numeric value")
    
    self.shortFlag = shortFlag
    self.longFlag = longFlag
    self.helpMessage = helpMessage
    self.required = required
  }
  
  func match(values: [String]) -> Bool {
    return false
  }
}

/**
 * A boolean option. The presence of either the short or long flag will set the value to true;
 * absence of the flag(s) is equivalent to false.
 */
public class BoolOption: Option {
  private var _value: Bool = false
  
  public var value: Bool {
    return _value
  }
  
  override var isSet: Bool {
    return _value != nil
  }
  
  public init(shortFlag: String, longFlag: String, helpMessage: String) {
    super.init(shortFlag: shortFlag, longFlag: longFlag, required: false, helpMessage: helpMessage)
  }
  
  override func match(values: [String]) -> Bool {
    _value = true
    return true
  }
}

/**  An option that accepts a positive or negative integer value. */
public class IntOption: Option {
  private var _value: Int?
  
  public var value: Int? {
    return _value
  }
  
  override var isSet: Bool {
    return _value != nil
  }
  
  override func match(values: [String]) -> Bool {
    if values.count == 0 {
      return false
    }
    
    if let val = values[0].toInt() {
      _value = val
      return true
    }
    
    return false
  }
}

/**
 * An option that represents an integer counter. Each time the short or long flag is found
 * on the command-line, the counter will be incremented.
 */
public class CounterOption: Option {
  private var _value: Int = 0
  
  public var value: Int {
    return _value
  }
  
  override var isSet: Bool {
    return _value != nil
  }
  
  public init(shortFlag: String, longFlag: String, helpMessage: String) {
    super.init(shortFlag: shortFlag, longFlag: longFlag, required: false, helpMessage: helpMessage)
  }
  
  override func match(values: [String]) -> Bool {
    _value += 1
    return true
  }
}

/**  An option that accepts a positive or negative floating-point value. */
public class DoubleOption: Option {
  private var _value: Double?
  
  public var value: Double? {
    return _value
  }
  
  override var isSet: Bool {
    return _value != nil
  }
  
  override func match(values: [String]) -> Bool {
    if values.count == 0 {
      return false
    }
    
    if let val = values[0].toDouble() {
      _value = val
      return true
    }
    
    return false
  }
}

/**  An option that accepts a string value. */
public class StringOption: Option {
  private var _value: String? = nil
  
  public var value: String? {
    return _value
  }
  
  override var isSet: Bool {
    return _value != nil
  }
  
  override func match(values: [String]) -> Bool {
    if values.count == 0 {
      return false
    }
    
    _value = values[0]
    return true
  }
}

/**  An option that accepts one or more string values. */
public class MultiStringOption: Option {
  private var _value: [String]?
  
  public var value: [String]? {
    return _value
  }
  
  override var isSet: Bool {
    return _value != nil
  }
  
  override func match(values: [String]) -> Bool {
    if values.count == 0 {
      return false
    }
    
    _value = values
    return true
  }
}

/** Enums must conform to this protocol to be used as an EnumOption type. */
public protocol StringConvertible {
  typealias ItemType
  class func fromRaw(String) -> ItemType?
}

/** An option that represents an enum value. */
public class EnumOption<T:StringConvertible where T.ItemType == T>: Option {
  /* Note: The where clause in the type specifier above is needed to tell the compiler
   * that T is equivalent to StringConvertible.ItemType. See
   * http://stackoverflow.com/a/24845414 for a detailed discussion.
   */
  
  private var _value: T?
  
  public var value: T? {
    return _value
  }
  
  override var isSet: Bool {
    return _value != nil
  }
  
  override public init(shortFlag: String, longFlag: String, required: Bool, helpMessage: String) {
    super.init(shortFlag: shortFlag, longFlag: longFlag, required: required, helpMessage: helpMessage)
  }
  
  override func match(values: [String]) -> Bool {
    if values.count == 0 {
      return false
    }
    
    if let v = T.fromRaw(values[0]) {
      _value = v
      return true
    }
    
    return false
  }
}
