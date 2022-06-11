//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 08.06.2022.
//

import Foundation
import FluentKit

struct CreateUser: AsyncMigration {
    
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .id()
            .field("email", .string, .required)
            .field("password_hash", .string, .required)
            .field("name", .string, .required)
            .field("work", .string)
            .field("subscribers", .array(of: .uuid))
            .field("subscribtions", .array(of: .uuid))
            .field("images", .array(of: .string))
            .field("image", .string)
            .unique(on: "email")
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
    
}
