// swift-tools-version:4.2

/*
* Package.swift
* Copyright (c) 2015 Ben Gollmer.
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

import PackageDescription

let package = Package(
    name: "CommandLineKit",
    products: [
        .library(
            name: "CommandLineKit",
            targets: ["CommandLineKit"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CommandLineKit",
            path: "CommandLineKit"),
        .testTarget(
            name: "CommandLineKitTests",
            dependencies: ["CommandLineKit"],
            path: "Tests"),
    ]
)
