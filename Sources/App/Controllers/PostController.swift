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
        post.post("new", use: self.create(req:))
        post.delete("delete", ":postID", use: self.delete(req:))
    }
    
    private func index(req: Request) async throws -> [CreatePostData] {
        let posts = try await Post.query(on: req.db).all()
        var newPosts = [CreatePostData]()
        
        for post in posts {
            let data = try await req.fileio.collectFile(at: post.image)
            
            newPosts.append(CreatePostData(
                id: post.id,
                userID: post.user.id ?? UUID(),
                image: File(data: data, filename: post.image),
                text: post.text,
                likes: post.likes
            ))
        }
        
        return newPosts
    }
    
    private func create(req: Request) async throws -> HTTPStatus {
        let createPostData = try req.content.decode(CreatePostData.self)
        
        try await req.fileio.writeFile(
            createPostData.image.data,
            at: req.application.directory.publicDirectory + createPostData.image.filename
        )
        
        let post = Post(
            id: createPostData.id,
            userID: createPostData.userID,
            image: req.application.directory.publicDirectory + createPostData.image.filename,
            text: createPostData.text,
            likes: createPostData.likes
        )
        
        try await post.save(on: req.db)
        
        return .ok
    }
    
    private func delete(req: Request) async throws -> HTTPStatus {
        try await Post.find(req.parameters.get("postID"), on: req.db)?.delete(on: req.db)
        
        return .ok
    }
    
    struct CreatePostData: Content {
        var id: UUID?
        var userID: UUID
        var image: File
        var text: String
        var likes: Int
        
        init(id: UUID? = nil, userID: UUID, image: File, text: String = "", likes: Int = .zero) {
            self.id = id
            self.userID = userID
            self.image = image
            self.text = text
            self.likes = likes
        }
    }
    
}
