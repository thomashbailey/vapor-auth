# vapor-auth

** In order to run the vapor-auth-server **

In order for this exmple to run you need to create a postgresql database name vaporauthdb with user vapor
1. psql postgres
2. CREATE DATABASE vaporauthdb;
3. CREATE USER vapor WITH PASSWORD 'some-password';
4. GRANT ALL PRIVILEGES ON DATABASE vaporauthdb TO vapor;
5. ALTER DATABASE vaporauthdb OWNER TO vapor;