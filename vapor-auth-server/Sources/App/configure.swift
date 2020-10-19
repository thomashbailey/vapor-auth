import Vapor
import Fluent
import FluentPostgresDriver

// configures your application
public func configure(_ app: Application) throws {
    /// In order for this exmple to run you need to create a postgresql database name vaporauthdb with user vapor
    // 1. psql postgres
    // 2. CREATE DATABASE vaporauthdb;
    // 3. CREATE USER vapor WITH PASSWORD 'some-password';
    // 4. GRANT ALL PRIVILEGES ON DATABASE vaporauthdb TO vapor;
    // 5. ALTER DATABASE vaporauthdb OWNER TO vapor;
    app.databases.use(.postgres(hostname: "localhost",
                                username: "vapor",
                                password: "some-password",
                                database: "vaporauthdb"),
                      as: .psql)
    
    // add migrations
    app.migrations.add(CreateUser())
    app.migrations.add(CreateUserToken())
    
    // register routes
    try routes(app)
}
