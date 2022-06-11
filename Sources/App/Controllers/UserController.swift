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
        
        user.get("user", ":userID", use: self.user(req:))
        user.post("new", use: self.create(req:))
        user.put("change", ":userID", use: self.create(req:))
        user.get("posts", ":userID", use: self.allPosts(req:))
    }
    
    private func auth(req: Request) async throws -> CreateUserData {
        let user = try req.auth.require(User.self)
        var images = [File]()
        var file: File? = nil
        
        for image in user.images {
            let data = try await req.fileio.collectFile(at: image)
            
            images.append(File(data: data, filename: image))
        }
                
        if let path = user.image {
            let data = try await req.fileio.collectFile(at: path)
            
            file = File(data: data, filename: path)
        }
        
        return CreateUserData(
            id: user.id,
            email: user.email,
            passwordHash: user.passwordHash,
            name: user.name,
            work: user.work,
            subscribers: user.subscribers,
            subscribtions: user.subscribtions,
            images: images,
            image: file
        )
    }
    
    private func allPosts(req: Request) async throws -> [PostController.CreatePostData] {
        guard let user = try await User.find(req.content.get(at: "userID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        let posts = user.posts
        var newPosts = [PostController.CreatePostData]()
        
        for post in posts {
            let data = try await req.fileio.collectFile(at: post.image)
            
            newPosts.append(PostController.CreatePostData(
                id: post.id,
                userID: post.user.id ?? UUID(),
                image: File(data: data, filename: post.image),
                text: post.text,
                likes: post.likes
            ))
        }
        
        return newPosts
    }
    
    private func user(req: Request) async throws -> CreateUserData {
        guard let user = try await User.find(req.content.get(at: "userID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        var images = [File]()
        var file: File? = nil
        
        for image in user.images {
            let data = try await req.fileio.collectFile(at: image)
            
            images.append(File(data: data, filename: image))
        }
                
        if let path = user.image {
            let data = try await req.fileio.collectFile(at: path)
            
            file = File(data: data, filename: path)
        }
        
        return CreateUserData(
            id: user.id,
            email: user.email,
            passwordHash: user.passwordHash,
            name: user.name,
            work: user.work,
            subscribers: user.subscribers,
            subscribtions: user.subscribtions,
            images: images,
            image: file
        )
    }
    
    private func create(req: Request) async throws -> HTTPStatus {
        try User.Create.validate(content: req)
        
        let create = try req.content.decode(User.Create.self)
        let user = try User(email: create.email, passwordHash: Bcrypt.hash(create.password), name: create.name)
        
        try await user.save(on: req.db)
                
        return .ok
    }
    
    private func change(req: Request) async throws -> HTTPStatus {
        let newUser = try req.content.decode(CreateUserData.self)
        
        guard let oldUser = try await User.find(req.parameters.get(":userID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        var imagesPaths = [String]()
        
        for image in newUser.images {
            try await req.fileio.writeFile(image.data, at: req.application.directory.publicDirectory + image.filename)
            
            imagesPaths.append(req.application.directory.publicDirectory + image.filename)
        }
        
        oldUser.images = imagesPaths
        oldUser.image = newUser.image?.filename
        oldUser.name = newUser.name
        oldUser.work = newUser.work
        oldUser.subscribers = newUser.subscribers
        oldUser.subscribtions = newUser.subscribtions
        
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
        var images: [File]
        var image: File?
        
        init(id: UUID? = nil, email: String, passwordHash: String, name: String, work: String = "", subscribers: [UUID] = [], subscribtions: [UUID] = [], images: [File] = [], image: File? = nil) {
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
