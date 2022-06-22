//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 08.06.2022.
//

import Foundation
import FluentKit

struct CreatePost: AsyncMigration {
    
    func prepare(on database: Database) async throws {
        try await database.schema("posts")
            .id()
            .field("image", .string, .required)
            .field("text", .string)
            .field("likes", .int)
            .field("user_id", .uuid, .required)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("posts").delete()
    }
    
}
