/*
 * Argument.swift
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
 * A command-line argument, defined by a name and a description.
 */
public class Argument {
    public let name: String
    public let description: String

    init(name: String, description: String) {
        assert(name.characters.count > 0, "Name must be a non-zero length string")
        assert(Int(name) == nil && name.toDouble() == nil, "Name cannot be a numeric value")

        assert(description.characters.count > 0, "Description must be a non-zero length string")
        assert(Int(description) == nil && description.toDouble() == nil, "Description cannot be a numeric value")

        self.name = name
        self.description = description
    }
}
