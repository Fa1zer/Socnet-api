//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 09.06.2022.
//

import Foundation
import Vapor

struct UserController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let user = routes.grouped("users")
        let passwordProtected = routes.grouped(User.authenticator())
        
        passwordProtected.get("auth", use: self.auth(req:))
        
        user.get("all", use: self.index(req:))
        user.get("user", ":userID", use: self.user(req:))
        user.post("new", use: self.create(req:))
        user.put("change", use: self.change(req:))
        user.get("posts", ":userID", use: self.allPosts(req:))
    }
    
    private func index(req: Request) async throws -> [User] {
        try await User.query(on: req.db).all()
    }
    
    private func auth(req: Request) async throws -> CreateUserData {
        let user = try req.auth.require(User.self)
        
        return CreateUserData(
            id: user.id,
            email: user.email,
            passwordHash: user.passwordHash,
            name: user.name,
            work: user.work,
            subscribers: user.subscribers,
            subscribtions: user.subscribtions,
            images: user.images,
            image: user.image
        )
    }
    
    private func allPosts(req: Request) async throws -> [CreatePostData] {
        guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        let posts = try await user.$posts.get(on: req.db)
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
    
    private func user(req: Request) async throws -> CreateUserData {
        guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound)
        }
                
        return CreateUserData(
            id: user.id,
            email: user.email,
            passwordHash: user.passwordHash,
            name: user.name,
            work: user.work,
            subscribers: user.subscribers,
            subscribtions: user.subscribtions,
            images: user.images,
            image: user.image
        )
    }
    
    private func create(req: Request) async throws -> HTTPStatus {
        try User.Create.validate(content: req)
        
        let create = try req.content.decode(User.Create.self)
        let user = try User(email: create.email, passwordHash: Bcrypt.hash(create.password))
        
        try await user.save(on: req.db)
                
        return .ok
    }
    
    private func change(req: Request) async throws -> HTTPStatus {
        let newUser = try req.content.decode(CreateUserData.self)
        
        guard let oldUser = try await User.find(newUser.id, on: req.db) else {
            throw Abort(.notFound)
        }
                
        oldUser.images = newUser.images
        oldUser.image = newUser.image
        oldUser.name = newUser.name
        oldUser.work = newUser.work
        oldUser.subscribers = newUser.subscribers
        oldUser.subscribtions = newUser.subscribtions
        
        try await oldUser.save(on: req.db)
        
        return .ok
    }
    
    private struct CreateUserData: Content {
        var id: UUID?
        var email: String
        var passwordHash: String
        var name: String
        var work: String
        var subscribers: [UUID]
        var subscribtions: [UUID]
        var images: [String]
        var image: String?
        
        init(id: UUID? = nil, email: String, passwordHash: String, name: String, work: String = "", subscribers: [UUID] = [], subscribtions: [UUID] = [], images: [String] = [], image: String? = nil) {
            self.id = id
            self.email = email
            self.passwordHash = passwordHash
            self.name = name
            self.work = work
            self.subscribers = subscribers
            self.subscribtions = subscribtions
            self.images = images
            self.image = image
        }
    }
    
}
