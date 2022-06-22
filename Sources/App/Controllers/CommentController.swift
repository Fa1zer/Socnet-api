//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 09.06.2022.
//

import Foundation
import Vapor

struct CommentController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let comment = routes.grouped("comments")
        
        comment.get(":commentID", "user", use: self.commentUser(req:))
        comment.post("new", use: self.create(req:))
    }
    
    private func commentUser(req: Request) async throws -> User {
        guard let comment = try await Comment.find(req.parameters.get("commentID"), on: req.db),
              let user = try await User.find(comment.$user.id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        return user
    }
    
    private func create(req: Request) async throws -> HTTPStatus {
        let createCommentData = try req.content.decode(CreateCommentData.self)
        let comment = Comment(
            id: createCommentData.id,
            userID: createCommentData.userID,
            postID: createCommentData.postID,
            text: createCommentData.text
        )
        
        try await comment.save(on: req.db)
        
        return .ok
    }
    
    struct CreateCommentData: Content {
        var id: UUID?
        var userID: UUID
        var postID: UUID
        var text: String
        
        init(id: UUID? = nil, userID: UUID, postID: UUID, text: String) {
            self.id = id
            self.userID = userID
            self.postID = postID
            self.text = text
        }
    }
    
}
