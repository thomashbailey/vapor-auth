//
//  UserController.swift.swift
//  
//
//  Created by Thomas Bailey on 10/16/20.
//


import Foundation
import Vapor
import Fluent
import FluentPostgresDriver

// MARK: - User Route

/// UserController is a group under route `api`
class UserController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("users") // /api/users/
        
        /// Unprotect route to create a User
        /// Post to `/api/users/`
        users.post(use: createUser)
        
        /// update access token
        /// Post to `/api/users/refresh`
        users.post("refresh", use: refresh)
        
        
        // MARK: - Basic Protected Users
        
        /// protectedUsers are guarded with our basic authentication
        let basicProtectedUsers = users.grouped(User.authenticator())
        
        /// Protected route to login
        /// Post with basic auth to `/api/users/login`
        basicProtectedUsers.post("login", use: login)
        
        
        // MARK: - Authed Users
        
        /// authedUsers have a bearer token
        let authedUsers = users.grouped([
            UserToken.authenticator(),
            User.guardMiddleware()
        ])

        /// route to test bearer authorization
        authedUsers.get("test") { req in
            return "authorized"
        }
    }
    
    // MARK: - Helper Methods
    
    fileprivate func createUser(_ req: Request) throws -> EventLoopFuture<User> {
        try User.Create.validate(content: req)
        let create = try req.content.decode(User.Create.self)
        
        guard create.password == create.confirmPassword else {
            throw Abort(.badRequest, reason: "Passwords did not match")
        }
        
        let user = try User(
            name: create.name,
            email: create.email,
            passwordHash: Bcrypt.hash(create.password)
        )
        return user.save(on: req.db)
            .map { user }
    }
    
    fileprivate func login(_ req: Request) throws -> EventLoopFuture<AuthToken> {
        let user = try req.auth.require(User.self)
        let accessUserToken = try user.generateAccessToken()
        let refreshUserToken = try user.generateRefreshToken()
        
        let accessToken = try accessUserToken.toToken()
        let refreshToken = try refreshUserToken.toToken()
        let authToken = AuthToken(accessToken: accessToken, refreshToken: refreshToken)
        
        return accessUserToken.save(on: req.db)
            .and(refreshUserToken.save(on: req.db))
            .map { (_, _) -> AuthToken in
                authToken
            }
    }
    
    fileprivate func refresh(_ req: Request) throws -> EventLoopFuture<AuthToken> {
        let db = req.db
        let refresh = try req.content.decode(AuthToken.Token.self)
        
        return UserToken
            .query(on: db)
            .filter(\.$token == refresh.token)
            .first()
            .unwrap(or: Abort(.unauthorized))
            .flatMap { (refreshToken) -> EventLoopFuture<AuthToken> in
                refreshToken.$user.get(on: db).flatMap { user -> EventLoopFuture<AuthToken> in
                    do {
                        if !refreshToken.isValid {
                            return refreshToken.delete(on: db)
                                .flatMapThrowing { _ -> AuthToken in
                                    throw Abort(.unauthorized)
                                }
                        }
                        
                        /// These objects are the full values stored in the database
                        let accessUserToken = try user.generateAccessToken()
                        let refreshUserToken = try user.generateRefreshToken()
                        
                        /// AuthToken is only partial data send back to the user
                        let newAccessToken = try accessUserToken.toToken()
                        let newRefreshToken = try refreshUserToken.toToken()
                        let authToken = AuthToken(accessToken: newAccessToken, refreshToken: newRefreshToken)
                        
                        /// Update the token and reset the time to the newly created UserTokens
                        refreshToken.token = newRefreshToken.token
                        refreshToken.expiresAt = newRefreshToken.expired
                        
                        return accessUserToken.save(on: db)
                            .and(refreshToken.update(on: db))
                            .map { (_, _) -> AuthToken in
                                return authToken
                            }
                    } catch  {
                        return req.eventLoop.makeFailedFuture(error)
                    }
                }
            }
    }
            
        
//            .flatMapThrowing { refreshToken -> UserToken in
//                if !refreshToken.isValid {
//                    _ = refreshToken.delete(on: db)
//
//                }
//                return refreshToken
//            }
//            .flatMap { refreshToken -> EventLoopFuture<AuthToken> in
//                refreshToken.$user.get(on: db).flatMapThrowing { user -> AuthToken in
//                    let accessUserToken = try user.generateAccessToken()
//                    let refreshUserToken = try user.generateRefreshToken()
//
//                    let newAccessToken = try accessUserToken.toToken()
//                    let newRefreshToken = try refreshUserToken.toToken()
//                    let authToken = AuthToken(accessToken: newAccessToken, refreshToken: newRefreshToken)
//
//                    refreshToken.token = newRefreshToken.token
//                    refreshToken.expiresAt = newRefreshToken.expired
//
//                    _ = refreshToken.update(on: db)
//
//                    return authToken
//                }
//            }
//    }
//}



//                    return refreshToken.$user.get(on: req.db).flatMap { user -> EventLoopFuture<AuthToken> in
//                        let accessUserToken = try user.generateAccessToken()
//                        let refreshUserToken = try user.generateRefreshToken()
//
//                        let newAccessToken = try accessUserToken.toToken()
//                        let newRefreshToken = try refreshUserToken.toToken()
//                        let authToken = AuthToken(accessToken: newAccessToken, refreshToken: newRefreshToken)
//
//                        refreshToken.token = newRefreshToken.token
//                        refreshToken.expiresAt = newRefreshToken.expired
//
//                        return refreshToken.update(on: req.db).transform(to: authToken)
//                    }
//                    throw Abort(.notAuthorized)
//                }
}
