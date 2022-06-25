//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 09.06.2022.
//

import Foundation
import Vapor

struct PostController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let post = routes.grouped("posts")
        
        post.get("all", use: self.index(req:))
        post.get(":postID", "comments", use: self.commentsIndex(req:))
        post.grouped(UserToken.authenticator()).post("new", use: self.create(req:))
        post.grouped(UserToken.authenticator()).delete("delete", ":postID", use: self.delete(req:))
    }
    
    private func index(req: Request) async throws -> [CreatePostData] {
        let posts = try await Post.query(on: req.db).all()
        var newPosts = [CreatePostData]()
        
        for post in posts {
            newPosts.append(CreatePostData(
                id: post.id,
                userID: post.$user.id,
                image: post.image,
                text: post.text,
                likes: post.likes
            ))
        }
        
        return newPosts
    }
    
    private func create(req: Request) async throws -> HTTPStatus {
        _ = try req.auth.require(User.self)
        let createPostData = try req.content.decode(CreatePostData.self)
        
        let post = Post(
            id: createPostData.id,
            userID: createPostData.userID,
            image: createPostData.image,
            text: createPostData.text,
            likes: createPostData.likes
        )
        
        try await post.save(on: req.db)
        
        return .ok
    }
    
    private func commentsIndex(req: Request) async throws -> [CommentController.CreateCommentData] {
        let comments = try await Post.find(req.parameters.get("postID"), on: req.db)?.$comments.get(on: req.db) ?? []
        var createCommentDatas = [CommentController.CreateCommentData]()
        
        for comment in comments {
            createCommentDatas.append(CommentController.CreateCommentData(
                id: comment.id,
                userID: comment.$user.id,
                postID: comment.$post.id,
                text: comment.text
            ))
        }
        
        return createCommentDatas
    }
    
    private func delete(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let post = try await Post.find(req.parameters.get("postID"), on: req.db)
        
        guard user.id == post?.$user.id else {
            throw Abort(.badRequest)
        }
        
        try await post?.delete(on: req.db)
        
        return .ok
    }
    
}

struct CreatePostData: Content {
    var id: UUID?
    var userID: UUID
    var image: String
    var text: String
    var likes: Int
    
    init(id: UUID? = nil, userID: UUID, image: String, text: String = "", likes: Int = .zero) {
        self.id = id
        self.userID = userID
        self.image = image
        self.text = text
        self.likes = likes
    }
}
