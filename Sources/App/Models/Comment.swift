//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 08.06.2022.
//

import Foundation
import Vapor
import Fluent

final class Comment: Model, Content {
    
    static let schema = "comments"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "user_id")
    var user: User
    
    @Parent(key: "post_id")
    var post: Post
    
    @Field(key: "text")
    var text: String
    
    init() { }
    
    init(id: UUID? = nil, userID: User.IDValue, postID: Post.IDValue, text: String) {
        self.id = id
        self.$user.id = userID
        self.$post.id = postID
        self.text = text
    }
    
}
