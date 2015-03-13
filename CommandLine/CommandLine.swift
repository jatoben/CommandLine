/*
 * CommandLine.swift
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

/* Required for setlocale(3) */
@exported import Darwin

let ShortOptionPrefix = "-"
let LongOptionPrefix = "--"

/* Stop parsing arguments when an ArgumentStopper (--) is detected. This is a GNU getopt
 * convention; cf. https://www.gnu.org/prep/standards/html_node/Command_002dLine-Interfaces.html
 */
let ArgumentStopper = "--"

/* Allow arguments to be attached to flags when separated by this character.
 * --flag=argument is equivalent to --flag argument
 */
let ArgumentAttacher: Character = "="

/**
 * The CommandLine class implements a command-line interface for your app.
 * 
 * To use it, define one or more Options (see Option.swift) and add them to your
 * CommandLine object, then invoke parse(). Each Option object will be populated with
 * the value given by the user.
 *
 * If any required options are missing or if an invalid value is found, parse() will return
 * false. You can then call printUsage() to output an automatically-generated usage message.
 */
public class CommandLine {
  private var _arguments: [String]
  private var _options: [Option] = [Option]()
  
  /**
   * Initializes a CommandLine object.
   *
   * :param: arguments Arguments to parse. If omitted, the arguments passed to the app
   *   on the command line will automatically be used.
   *
   * :returns: An initalized CommandLine object.
   */
  public init(arguments: [String] = Process.arguments) {
    self._arguments = arguments
    
    /* Initialize locale settings from the environment */
    setlocale(LC_ALL, "")
  }
  
  /* Returns all argument values from flagIndex to the next flag or the end of the argument array. */
  private func _getFlagValues(#flagIndex: Int) -> [String] {
    var args: [String] = [String]()
    var skipFlagChecks = false
    
    /* Grab attached arg, if any */
    var attachedArg = _arguments[flagIndex].splitByCharacter(ArgumentAttacher, maxSplits: 1)
    if attachedArg.count > 1 {
      args.append(attachedArg[1])
    }
    
    for var i = flagIndex + 1; i < _arguments.count; i++ {
      if !skipFlagChecks {
        if _arguments[i] == ArgumentStopper {
          skipFlagChecks = true
          continue
        }
        
        if _arguments[i].hasPrefix(ShortOptionPrefix) && _arguments[i].toInt() == nil &&
          _arguments[i].toDouble() == nil {
          break
        }
      }
    
      args.append(_arguments[i])
    }
    
    return args
  }
  
  /**
   * Adds an Option to the command line.
   *
   * :param: option The option to add.
   */
  public func addOption(option: Option) {
    _options.append(option)
  }
  
  /**
   * Adds one or more Options to the command line.
   *
   * :param: options An array containing the options to add.
   */
  public func addOptions(options: [Option]) {
    _options += options
  }
  
  /**
   * Adds one or more Options to the command line.
   *
   * :param: options The options to add.
   */
  public func addOptions(options: Option...) {
    _options += options
  }
  
  /**
   * Sets the command line Options. Any existing options will be overwritten.
   *
   * :param: options An array containing the options to set.
   */
  public func setOptions(options: [Option]) {
    _options = options
  }
  
  /**
   * Sets the command line Options. Any existing options will be overwritten.
   *
   * :param: options The options to set.
   */
  public func setOptions(options: Option...) {
    _options = options
  }
  
  /**
   * Parses command-line arguments into their matching Option values.
   *
   * :returns: True if all arguments were parsed successfully, false if any option had an
   *   invalid value or if a required option was missing.
   */
  public func parse() -> (Bool, String?) {
    
    for (idx, arg) in enumerate(_arguments) {
      if arg == ArgumentStopper {
        break
      }
      
      if !arg.hasPrefix(ShortOptionPrefix) {
        continue
      }
      
      /* Swift strings don't have substringFromIndex(). Do a little dance instead. */
      var flag = ""
      var skipChars =
        arg.hasPrefix(LongOptionPrefix) ? count(LongOptionPrefix) : count(ShortOptionPrefix)
      for c in arg {
        if skipChars-- > 0 {
          continue
        }
        
        flag.append(c)
      }
      
      /* Remove attached argument from flag */
      flag = flag.splitByCharacter(ArgumentAttacher, maxSplits: 1)[0]
      
      var flagMatched = false
      for option in _options {
        if flag == option.shortFlag || flag == option.longFlag {
          var vals = self._getFlagValues(flagIndex: idx)
          if !option.match(vals) {
            return (false, "Invalid value for \(option.longFlag)")
          }
          
          flagMatched = true
          break
        }
      }
      
      /* Flags that do not take any arguments can be concatenated */
      if !flagMatched && !arg.hasPrefix(LongOptionPrefix) {
        for (i, c) in enumerate(flag) {
          var flagLength = count(flag)
          for option in _options {
            if String(c) == option.shortFlag {
              /* Values are allowed at the end of the concatenated flags, e.g.
               * -xvf <file1> <file2>
               */
              var vals = (i == flagLength - 1) ? self._getFlagValues(flagIndex: idx) : [String]()
              if !option.match(vals) {
                return (false, "Invalid value for \(option.longFlag)")
              }
              
              break
            }
          }
        }
      }
    }

    /* Check to see if any required options were not matched */
    for option in _options {
      if option.required && !option.isSet {
        return (false, "\(option.longFlag) is required")
      }
    }
    
    return (true, nil)
  }
  
  /** Prints a usage message to stdout. */
  public func printUsage() {
    let name = _arguments[0]
    
    var flagWidth = 0
    for opt in _options {
      flagWidth = max(flagWidth,
        count("  \(ShortOptionPrefix)\(opt.shortFlag), \(LongOptionPrefix)\(opt.longFlag):"))
    }
    
    println("Usage: \(name) [options]")
    for opt in _options {
      let flags = "  \(ShortOptionPrefix)\(opt.shortFlag), \(LongOptionPrefix)\(opt.longFlag):".paddedToWidth(flagWidth)
      
      println("\(flags)\n      \(opt.helpMessage)")
    }
  }
}
