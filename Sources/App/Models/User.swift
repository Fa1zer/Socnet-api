//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 08.06.2022.
//

import Foundation
import Fluent
import Vapor

final class User: Model, Content {
    
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "password_hash")
    var passwordHash: String
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "work")
    var work: String
    
    @Field(key: "subscribers")
    var subscribers: [UUID]
    
    @Field(key: "subscribtions")
    var subscribtions: [UUID]
    
    @Field(key: "images")
    var images: [String]
    
    @OptionalField(key: "image")
    var image: String?
    
    @Children(for: \.$user)
    var posts: [Post]
    
    init() { }
    
    init(id: UUID? = nil, email: String, passwordHash: String, name: String = "", work: String = "", subscribers: [UUID] = [], subscribtions: [UUID] = [], images: [String] = [], image: String? = nil) {
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

extension User {
    struct Create: Content {
        var email: String
        var password: String
    }
}

extension User.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
    }
}

extension User: ModelAuthenticatable {
    
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$passwordHash
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
    
}

extension User {
    func generateToken() throws -> UserToken {
        try .init(
            value: [UInt8].random(count: 16).base64,
            userID: self.requireID()
        )
    }
}
