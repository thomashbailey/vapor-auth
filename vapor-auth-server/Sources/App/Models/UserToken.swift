//
//  File.swift
//  
//
//  Created by Thomas Bailey on 10/16/20.
//

import Fluent
import Vapor

final class UserToken: Model, Content {
    static let schema = "user_tokens"
    
    struct FieldKeys {
        static var token: FieldKey { "token" }
        static var tokenType: FieldKey { "token_type" }
        static var userId: FieldKey { "user_id" }
        static var expiresAt: FieldKey { "expires_at" }
        static var createdAt: FieldKey { "created_at" }
    }
    
    enum TokenType: String, Codable {
        case access
        case refresh
    }

    @ID(key: .id)
    var id: UUID?

    @Field(key: FieldKeys.token)
    var token: String
    
    @Field(key: FieldKeys.tokenType)
    var tokenType: TokenType

    @Parent(key: FieldKeys.userId)
    var user: User
    
    @Field(key: FieldKeys.expiresAt)
    var expiresAt: Date?
    
    @Timestamp(key: FieldKeys.createdAt, on: .create)
    var createdAt: Date?

    init() { }

    init(id: UUID? = nil,
         token: String,
         tokenType: TokenType,
         userID: UUID,
         expiresAt: Date?,
         createdAt: Date?) {
        self.id = id
        self.token = token
        self.tokenType = tokenType
        self.$user.id = userID
        self.expiresAt = expiresAt
        self.createdAt = createdAt
    }
}

// MARK: - ModelTokenAuthenticatable

extension UserToken: ModelTokenAuthenticatable {
    static let valueKey = \UserToken.$token
    static let userKey = \UserToken.$user

    var isValid: Bool {
        guard let expiryDate = expiresAt else {
            return true
        }

        return expiryDate > Date()
    }
}

// MARK: - Helper Methods

extension UserToken {
    func toToken() throws -> AuthToken.Token {
        guard let expireDate = expiresAt else {
            throw Abort(.internalServerError)
        }
        return AuthToken.Token(token: token, expired: expireDate)
    }
}
