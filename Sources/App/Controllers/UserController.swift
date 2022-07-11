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
        let tokenProtected = user.grouped(UserToken.authenticator())
        
        passwordProtected.get("auth", use: self.auth(req:))
        
        tokenProtected.get("me", use: self.me(req:))
        tokenProtected.put("change", use: self.change(req:))
        tokenProtected.delete("logOut", use: self.deleteUserToken(req:))
        tokenProtected.put("subscribe", ":userID", use: self.subscribe(req:))
        tokenProtected.put("unsubscribe", ":userID", use: self.unsubscribe(req:))
        
        user.get("all", use: self.index(req:))
        user.get("user", ":userID", use: self.user(req:))
        user.post("new", use: self.create(req:))
        user.get("posts", ":userID", use: self.allPosts(req:))
    }
    
    private func index(req: Request) async throws -> [User] {
        try await User.query(on: req.db).all()
    }
    
    private func me(req: Request) async throws -> User {
        try req.auth.require(User.self)
    }
    
    private func subscribe(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        
        guard let someUser =  try await User.find(req.parameters.get("userID"), on: req.db),
              let userID = user.id,
              let someUserID = someUser.id,
              userID != someUserID else {
            throw Abort(.badRequest)
        }
        
        someUser.subscribers.append(userID)
        user.subscribtions.append(someUserID)
        
        try await someUser.save(on: req.db)
        try await user.save(on: req.db)
        
        return .ok
    }
    
    private func unsubscribe(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        
        guard let someUser =  try await User.find(req.parameters.get("userID"), on: req.db),
              let userID = user.id,
              let someUserID = someUser.id,
              user.subscribtions.contains(someUserID),
              someUser.subscribers.contains(userID) else {
            throw Abort(.notFound)
        }
        
        for i in 0 ..< someUser.subscribers.count {
            if someUser.subscribers[i] == userID {
                someUser.subscribers.remove(at: i)
                
                break
            }
        }
        
        for i in 0 ..< user.subscribtions.count {
            if user.subscribtions[i] == someUserID {
                user.subscribtions.remove(at: i)
                
                break
            }
        }
        
        try await someUser.save(on: req.db)
        try await user.save(on: req.db)
        
        return .ok
    }
    
    private func auth(req: Request) async throws -> UserToken {
        let user = try req.auth.require(User.self)
        let token = try user.generateToken()
        
        try await token.save(on: req.db)
        
        return token
    }
    
    private func deleteUserToken(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let token = try await UserToken.query(on: req.db).all().filter { $0.$user.id == user.id }.first
        
        try await token?.delete(on: req.db)
        
        return .ok
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
        let oldUser = try req.auth.require(User.self)
        
        guard oldUser.id == newUser.id else {
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
