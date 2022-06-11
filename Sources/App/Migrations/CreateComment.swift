//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 08.06.2022.
//

import Foundation
import FluentKit

struct CreateComment: AsyncMigration {
    
    func prepare(on database: Database) async throws {
        try await database.schema("comments")
            .id()
            .field("user_id", .uuid, .required)
            .field("post_id", .uuid, .required)
            .field("text", .string, .required)
            .create()
    }
            
    func revert(on database: Database) async throws {
        try await database.schema("comments").delete()
    }
    
}
