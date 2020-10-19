//
//  AuthToken.swift
//  
//
//  Created by Thomas Bailey on 10/16/20.
//

import Vapor

struct AuthToken: Content {
    struct Token: Content {
        var token: String
        var expired: Date?
    }
    
    var accessToken: Token
    var refreshToken: Token
}
