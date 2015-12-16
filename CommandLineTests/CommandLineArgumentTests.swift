/*
 * CommandLineArgumentTests.swift
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

import XCTest
@testable import CommandLine
#if os(OSX)
  import Darwin
#elseif os(Linux)
  import Glibc
#endif

internal class CommandLineArgumentTests: XCTestCase {
  /* TODO: The commented-out tests segfault on Linux as of the Swift 2.2 2015-12-10 snapshot. */
  var allTests : [(String, () -> ())] {
    return [
      ("testCommandArguments", testCommandArguments),
      ("testCommandArgumentsExpectations", testCommandArgumentsExpectations),
      ("testPrintUsageWithUnlimitedCommandArguments", testPrintUsageWithUnlimitedCommandArguments),
      ("testPrintUsageWithLimitedCommandArguments", testPrintUsageWithLimitedCommandArguments)
    ]
  }

  func testCommandArguments() {
    let option = BoolOption(shortFlag: "a", longFlag: "a1", required: true, helpMessage: "")
    runCommandArgumentTest(CommandLine(arguments: ["CommandLineTests", "-a", "--", "arg1", "arg2", "arg3"]), option: option, expectedArguments: ["arg1", "arg2", "arg3"])
    runCommandArgumentTest(CommandLine(arguments: ["CommandLineTests", "-a", "arg1", "--", "arg2", "arg3"]), option: option, expectedArguments: ["arg1", "arg2", "arg3"])
    runCommandArgumentTest(CommandLine(arguments: ["CommandLineTests", "arg1", "-a", "arg2", "--", "arg3"]), option: option, expectedArguments: ["arg1", "arg2", "arg3"])
    runCommandArgumentTest(CommandLine(arguments: ["CommandLineTests", "arg3", "arg1", "-a", "arg2", "--"]), option: option, expectedArguments: ["arg3", "arg1", "arg2"])
  }

  func runCommandArgumentTest(cli:CommandLine, option:BoolOption, expectedArguments:[String]) {
    cli.addOption(option)
    do {
      try cli.parse()
      XCTAssertTrue(option.value, "Failed to get true value from short bool")
    } catch {
      XCTFail("Failed to parse command arguments with bool option: \(error)")
    }
    let parsedArguments = cli.getCommandArguments()
    XCTAssert(parsedArguments == expectedArguments, "Arguments were not parsed correctly. Expected \(expectedArguments), got \(parsedArguments)")
  }

  func testCommandArgumentsExpectations() {
    /**
     truth table of doom

     a = command argument description array provided
     b = # parsed arguments < # descriptions
     c = # parsed arguments = # descriptions
     d = # parsed arguments > # descriptions
     e = # parsed arguments < max argument limit (only if max arguments != -1)
     f = # parsed arguments = max argument limit (only if max arguments != -1)
     g = # parsed arguments > max argument limit (only if max arguments != -1)
     h = strict parsing enabled

     p = should throw ParseError.MissingExpectedCommandArgument
     q = should throw ParseError.TooManyCommandArguments

     a | b | c | d | e | f | g | h || p | q | test case
     --------------------------------------------------
     0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 || 0 | 0 | I
     0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 || 0 | 0 | II
     1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 || 1 | 0 | III
     1 | 1 | 0 | 0 | 0 | 0 | 0 | 1 || 1 | 0 | IV
     1 | 1 | 0 | 0 | 1 | 0 | 0 | 0 || 1 | 0 | V
     1 | 1 | 0 | 0 | 1 | 0 | 0 | 1 || 1 | 0 | VI
     1 | 0 | 1 | 0 | 0 | 0 | 0 | 0 || 0 | 0 | VII
     1 | 0 | 1 | 0 | 0 | 0 | 0 | 1 || 0 | 0 | VIII
     1 | 0 | 1 | 0 | 0 | 1 | 0 | 0 || 0 | 0 | IX
     1 | 0 | 1 | 0 | 0 | 1 | 0 | 1 || 0 | 0 | X
     1 | 0 | 0 | 1 | 0 | 0 | 0 | 0 || 0 | 0 | XI
     1 | 0 | 0 | 1 | 0 | 0 | 0 | 1 || 0 | 0 | XII
     1 | 0 | 0 | 1 | 0 | 0 | 1 | 0 || 0 | 0 | XIII
     1 | 0 | 0 | 1 | 0 | 0 | 1 | 1 || 0 | 1 | XIV
     */

    let option = BoolOption(shortFlag: "a", longFlag: "a1", required: true, helpMessage: "")
    var cli = CommandLine(arguments: ["CommandLine", "-a"])
    cli.addOption(option)

    // --- no expectations ---

    // I
    runExpectedCommandArgumentTest(cli, option: option, strict: false, shouldFailNotEnough: false, shouldFailTooMany: false)

    // II
    runExpectedCommandArgumentTest(cli, option: option, strict: true, shouldFailNotEnough: false, shouldFailTooMany: false)

    // --- more argument descriptions provided than were parsed, unlimited max ---

    let descriptions = [ Argument(name: "arg1", description: "description 1"), Argument(name: "arg2", description: "description 2")]
    cli.addCommandArgumentDescriptions(descriptions)

    // III
    runExpectedCommandArgumentTest(cli, option: option, strict: false, shouldFailNotEnough: true, shouldFailTooMany: false)

    // IV
    runExpectedCommandArgumentTest(cli, option: option, strict: true, shouldFailNotEnough: true, shouldFailTooMany: false)

    // --- more argument descriptions provided than were parsed, limited max ---

    cli.addCommandArgumentDescriptions(descriptions, maxAllowedArguments: 2)

    // V
    runExpectedCommandArgumentTest(cli, option: option, strict: false, shouldFailNotEnough: true, shouldFailTooMany: false)

    // VI
    runExpectedCommandArgumentTest(cli, option: option, strict: true, shouldFailNotEnough: true, shouldFailTooMany: false)

    // --- expectation met with descriptions provided + unlimited max args allowed ---

    cli = CommandLine(arguments: ["CommandLine", "-a", "arg1", "arg2"])
    cli.addOption(option)
    cli.addCommandArgumentDescriptions(descriptions)

    // VII
    runExpectedCommandArgumentTest(cli, option: option, strict: false, shouldFailNotEnough: false, shouldFailTooMany: false)

    // VIII
    runExpectedCommandArgumentTest(cli, option: option, strict: true, shouldFailNotEnough: false, shouldFailTooMany: false)

    // --- expectation met with descriptions provided + limited max args allowed ---

    cli.addCommandArgumentDescriptions(descriptions, maxAllowedArguments: 2)

    // IX
    runExpectedCommandArgumentTest(cli, option: option, strict: false, shouldFailNotEnough: false, shouldFailTooMany: false)

    // X
    runExpectedCommandArgumentTest(cli, option: option, strict: true, shouldFailNotEnough: false, shouldFailTooMany: false)

    // --- more arguments than expected argument descriptions but unlimited max arguments ---

    cli = CommandLine(arguments: ["CommandLine", "-a", "arg1", "arg2", "arg3"])
    cli.addOption(option)
    cli.addCommandArgumentDescriptions(descriptions)

    // XI
    runExpectedCommandArgumentTest(cli, option: option, strict: false, shouldFailNotEnough: false, shouldFailTooMany: false)

    // XII
    runExpectedCommandArgumentTest(cli, option: option, strict: true, shouldFailNotEnough: false, shouldFailTooMany: false)

    // --- more arguments than expected argument descriptions with limited max arguments ---

    cli.addCommandArgumentDescriptions(descriptions, maxAllowedArguments: 2)

    // XIII
    runExpectedCommandArgumentTest(cli, option: option, strict: false, shouldFailNotEnough: false, shouldFailTooMany: false)

    // XIV
    runExpectedCommandArgumentTest(cli, option: option, strict: true, shouldFailNotEnough: false, shouldFailTooMany: true)
  }

  func runExpectedCommandArgumentTest(cli:CommandLine, option: BoolOption, strict: Bool, shouldFailNotEnough: Bool, shouldFailTooMany: Bool) {

    do {
      try cli.parse(strict)
      if shouldFailNotEnough {
        XCTFail("Did not throw expected MissingExpectedCommandArgument.")
      } else if shouldFailTooMany {
        XCTFail("Did not throw expected TooManyCommandArguments.")
      }
    } catch CommandLine.ParseError.MissingExpectedCommandArgument {
      XCTAssert(shouldFailNotEnough, "Threw unexpected MissingExpectedCommandArgument.")
    } catch CommandLine.ParseError.TooManyCommandArguments {
      XCTAssert(shouldFailTooMany, "Threw unexpected TooManyCommandArguments.")
    } catch {
      XCTFail("Failed to parse command arguments with bool options: \(error)")
    }
  }

  func testPrintUsageWithUnlimitedCommandArguments() {
    runUsageTestWithArgumentLimit(-1)
  }

  func testPrintUsageWithLimitedCommandArguments() {
    runUsageTestWithArgumentLimit(2)
  }

  func runUsageTestWithArgumentLimit(limit:Int) {
    let cli = CommandLine(arguments: [ "CommandLineTests", "-dvvv", "--name", "John Q. Public",
      "-f", "45", "-p", "0.05", "-x", "extra1", "extra2", "extra3" ])

    let boolOpt = BoolOption(shortFlag: "d", longFlag: "debug", helpMessage: "Enables debug mode.")
    let counterOpt = CounterOption(shortFlag: "v", longFlag: "verbose",
      helpMessage: "Enables verbose output. Specify multiple times for extra verbosity.")
    let stringOpt = StringOption(shortFlag: "n", longFlag: "name", required: true,
      helpMessage: "Name a Cy Young winner.")
    let intOpt = IntOption(shortFlag: "f", longFlag: "favorite", required: true,
      helpMessage: "Your favorite number.")
    let doubleOpt = DoubleOption(shortFlag: "p", longFlag: "p-value", required: true,
      helpMessage: "P-value for test.")
    let extraOpt = MultiStringOption(shortFlag: "x", longFlag: "Extra", required: true,
      helpMessage: "X is for Extra.")

    let opts = [boolOpt, counterOpt, stringOpt, intOpt, doubleOpt, extraOpt]
    cli.addOptions(opts)

    cli.addCommandArgumentDescriptions([ Argument(name: "arg1", description: "description 1"), Argument(name: "arg2", description: "description 2")], maxAllowedArguments: limit)

    var out = ""
    cli.printUsage(&out)
    XCTAssertGreaterThan(out.characters.count, 0)

    /* There should be at least 2 lines per option, plus the intro Usage statement */
    XCTAssertGreaterThanOrEqual(out.splitByCharacter("\n").count, (opts.count * 2) + 1)
  }
}

