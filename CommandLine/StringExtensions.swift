/*
 * StringExtensions.swift
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

/* Required for localeconv(3) */
#if os(OSX)
  import Darwin
#elseif os(Linux)
  import Glibc
#endif

internal extension String {
  /* Retrieves locale-specified decimal separator from the environment
   * using localeconv(3).
   */
  private func _localDecimalPoint() -> Character {
    let locale = localeconv()
    if locale != nil {
      let decimalPoint = locale.pointee.decimal_point
      if decimalPoint != nil {
        return Character(UnicodeScalar(UInt32(decimalPoint.pointee)))
      }
    }

    return "."
  }

  /**
   * Attempts to parse the string value into a Double.
   *
   * - returns: A Double if the string can be parsed, nil otherwise.
   */
  func toDouble() -> Double? {
    var characteristic: String = "0"
    var mantissa: String = "0"
    var inMantissa: Bool = false
    var isNegative: Bool = false
    let decimalPoint = self._localDecimalPoint()

    for (i, c) in self.characters.enumerated() {
      if i == 0 && c == "-" {
        isNegative = true
        continue
      }

      if c == decimalPoint {
        inMantissa = true
        continue
      }

      if Int(String(c)) != nil {
        if !inMantissa {
          characteristic.append(c)
        } else {
          mantissa.append(c)
        }
      } else {
        /* Non-numeric character found, bail */
        return nil
      }
    }

    return (Double(Int(characteristic)!) +
      Double(Int(mantissa)!) / pow(Double(10), Double(mantissa.characters.count - 1))) *
      (isNegative ? -1 : 1)
  }

  /**
   * Splits a string into an array of string components.
   *
   * - parameter splitBy:  The character to split on.
   * - parameter maxSplit: The maximum number of splits to perform. If 0, all possible splits are made.
   *
   * - returns: An array of string components.
   */
  func splitByCharacter(splitBy: Character, maxSplits: Int = 0) -> [String] {
    var s = [String]()
    var numSplits = 0

    var curIdx = self.startIndex
    for i in self.characters.indices {
      let c = self[i]
      if c == splitBy && (maxSplits == 0 || numSplits < maxSplits) {
        s.append(self[curIdx..<i])
        curIdx = i.successor()
        numSplits += 1
      }
    }

    if curIdx != self.endIndex {
      s.append(self[curIdx..<self.endIndex])
    }

    return s
  }

  /**
   * Pads a string to the specified width.
   *
   * - parameter width: The width to pad the string to.
   * - parameter padBy: The character to use for padding.
   *
   * - returns: A new string, padded to the given width.
   */
  func paddedToWidth(width: Int, padBy: Character = " ") -> String {
    var s = self
    var currentLength = self.characters.count

    while currentLength < width {
      s.append(padBy)
      currentLength += 1
    }

    return s
  }

  /**
   * Wraps a string to the specified width.
   *
   * This just does simple greedy word-packing, it doesn't go full Knuth-Plass.
   * If a single word is longer than the line width, it will be placed (unsplit)
   * on a line by itself.
   *
   * - parameter width:   The maximum length of a line.
   * - parameter wrapBy:  The line break character to use.
   * - parameter splitBy: The character to use when splitting the string into words.
   *
   * - returns: A new string, wrapped at the given width.
   */
  func wrappedAtWidth(width: Int, wrapBy: Character = "\n", splitBy: Character = " ") -> String {
    var s = ""
    var currentLineWidth = 0

    for word in self.splitByCharacter(splitBy) {
      let wordLength = word.characters.count

      if currentLineWidth + wordLength + 1 > width {
        /* Word length is greater than line length, can't wrap */
        if wordLength >= width {
          s += word
        }

        s.append(wrapBy)
        currentLineWidth = 0
      }

      currentLineWidth += wordLength + 1
      s += word
      s.append(splitBy)
    }

    return s
  }
}

#if os(Linux)
/**
 *  Returns `true` iff `self` begins with `prefix`.
 *
 *  A basic implementation of `hasPrefix` for Linux.
 *  Should be removed once a proper `hasPrefix` patch makes it to the Swift 2.2 development branch.
 */
extension String {
  func hasPrefix(prefix: String) -> Bool {
    if prefix.isEmpty {
      return false
    }

    let c = self.characters
    let p = prefix.characters

    if p.count > c.count {
      return false
    }

    for (c, p) in zip(c.prefix(p.count), p) {
      guard c == p else {
        return false
      }
    }

    return true
  }

  /**
   *  Returns `true` iff `self` ends with `suffix`.
   *
   *  A basic implementation of `hasSuffix` for Linux.
   *  Should be removed once a proper `hasSuffix` patch makes it to the Swift 2.2 development branch.
   */
  func hasSuffix(suffix: String) -> Bool {
    if suffix.isEmpty {
      return false
    }

    let c = self.characters
    let s = suffix.characters

    if s.count > c.count {
      return false
    }

    for (c, s) in zip(c.suffix(s.count), s) {
      guard c == s else {
        return false
      }
    }

    return true
  }
}
#endif
