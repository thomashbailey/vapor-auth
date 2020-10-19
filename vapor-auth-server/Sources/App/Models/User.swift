//
//  File.swift
//  
//
//  Created by Thomas Bailey on 10/16/20.
//

import Fluent
import Vapor

final class User: Model, Content {
    static let schema = "users"
    
    struct FieldKeys {
        static var id: FieldKey { .id }
        static var name: FieldKey { "name" }
        static var email: FieldKey { "email" }
        static var passwordHash: FieldKey { "password_hash" }
    }

    @ID(key: FieldKeys.id)
    var id: UUID?

    @Field(key: FieldKeys.name)
    var name: String

    @Field(key: FieldKeys.email)
    var email: String

    @Field(key: FieldKeys.passwordHash)
    var passwordHash: String

    init() { }

    init(id: UUID? = nil, name: String, email: String, passwordHash: String) {
        self.id = id
        self.name = name
        self.email = email
        self.passwordHash = passwordHash
    }
}

// MARK: - Validatable

extension User {
    struct Create: Content, Validatable {
        var name: String
        var email: String
        var password: String
        var confirmPassword: String
        
        static func validations(_ validations: inout Validations) {
            validations.add("name", as: String.self, is: !.empty)
            validations.add("email", as: String.self, is: .email)
            validations.add("password", as: String.self, is: .count(8...))
        }
    }
}

// MARK: - ModelAuthenticatable

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$passwordHash

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}

// MARK: - Generate Auth Token

extension User {
    private func generateToken(expireDate: Date, tokenType: UserToken.TokenType) throws -> UserToken {
        return try .init(token:  [UInt8].random(count: 16).base64,
                         tokenType: tokenType,
                         userID: self.requireID(),
                         expiresAt: expireDate,
                         createdAt: Date())
    }
    
    /// generateAccessToken has a default expiry date of 1 hour
    func generateAccessToken() throws -> UserToken {
        let calendar = Calendar(identifier: .gregorian)
        guard let expireDate = calendar.date(byAdding: .minute, value: 5, to: Date()) else {
            throw Abort(.internalServerError)
        }
        
        return try generateToken(expireDate: expireDate, tokenType: .access)
    }
    
    /// generateRefreshToken has a default expiry date of 1 month
    func generateRefreshToken() throws -> UserToken {
        let calendar = Calendar(identifier: .gregorian)
        guard let expireDate = calendar.date(byAdding: .hour, value: 1, to: Date()) else {
            throw Abort(.internalServerError)
        }
        
        return try generateToken(expireDate: expireDate, tokenType: .refresh)
    }
}
