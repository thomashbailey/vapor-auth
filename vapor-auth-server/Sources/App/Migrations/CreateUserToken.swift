//
//  File.swift
//  
//
//  Created by Thomas Bailey on 10/16/20.
//

import Foundation
import Fluent
import Vapor

struct CreateUserToken: Migration {
    static var schema = "user_tokens"
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CreateUserToken.schema)
            .id()
            .field(UserToken.FieldKeys.token, .string, .required)
            .unique(on: UserToken.FieldKeys.token)
            .field(UserToken.FieldKeys.tokenType, .string, .required)
            .field(UserToken.FieldKeys.userId, .uuid, .required, .references(User.schema, User.FieldKeys.id))
            .field(UserToken.FieldKeys.createdAt, .datetime, .required)
            .field(UserToken.FieldKeys.expiresAt, .datetime, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(CreateUserToken.schema).delete()
    }
}
