//
//  File.swift
//  
//
//  Created by Thomas Bailey on 10/16/20.
//


import Foundation
import Fluent
import Vapor

struct CreateUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.schema)
            .id()
            .field(User.FieldKeys.name, .string, .required)
            .field(User.FieldKeys.email, .string, .required)
            .field(User.FieldKeys.passwordHash, .string, .required)
            .unique(on: User.FieldKeys.email)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.schema).delete()
    }
}
