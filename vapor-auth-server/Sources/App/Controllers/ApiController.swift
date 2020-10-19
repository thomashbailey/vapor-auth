//
//  File.swift
//  
//
//  Created by Thomas Bailey on 10/16/20.
//

import Vapor

class ApiController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let apiRoute = routes.grouped("api")
        try apiRoute.register(collection: UserController())
    }
    
    
}
