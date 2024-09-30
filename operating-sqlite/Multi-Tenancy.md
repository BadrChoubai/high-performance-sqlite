# Multi-Tenancy

Multi-tenancy is an architectural model that allows a single application to serve multiple customers (tenants) while
ensuring data isolation and security. This approach is especially common in Software as a Service (SaaS) environments,
where efficiency and scalability are paramount. By adopting multi-tenancy, businesses can streamline resource
utilization, reduce operational costs, and enhance their capacity for innovation.

In the context of database systems, multi-tenancy supports efficient resource management and scalability, making it an
ideal choice for SaaS applications. However, it also introduces complexities related to data access control, query
management, and schema migrations.

**Definitions**:

- **Multi-tenancy**: A single application serving multiple customers (tenants).
- **Single-tenant**: An application used by one company, often hosted in-house (e.g., a CRM system).
- **Multi-tenant**: A common configuration in SaaS where multiple clients share the same application infrastructure.

## Two Approaches to Multi-Tenancy at the Database Layer:

1. **Single Database with Tenant Column**:
    - **How it works**:  
      All tenants' data is stored in the same database, but each record includes a tenant identifier (e.g., user ID,
      team ID, or company ID).
    - **Advantages**:
        - Easy to manage: Only one database to deal with.
        - Simple queries to insert rows.
    - **Drawbacks**:
        - More complex queries: Every query needs a condition like `WHERE tenant_id = X`.
        - Potential security issues: Failing to include the `tenant_id` condition could expose data to unauthorized
          users.

2. **Database per Tenant** (Recommended for SQLite):
    - **How it works**:  
      Each tenant gets their own database. When a tenant logs in, they are connected to their specific database file.
    - **Advantages**:
        - Guarantees data isolation: Tenants can only access their own data.
        - Aligns with SQLite’s architecture (avoids contention for write locks).
    - **Drawbacks**:
        - More complex operationally: Managing multiple databases can be harder.
        - Scaling: You’ll have as many database files as tenants, but this is manageable with SQLite since it's
          file-based.

### Managing Multi-Tenant SQLite Databases

1. **Attaching Multiple Databases**:
    - You can attach other SQLite databases to a session using the `ATTACH` statement.  
      Example:
      ```sql
      ATTACH 'central.db' AS central;
      ```
    - Use cases:
        - Central database for global settings and tenant routing.
        - Tenant-specific databases for user data.

2. **Tenant Routing**:
    - Use a central database to map subdomains or tenant identifiers to the correct database.  
      Example flow:
        1. User accesses `user.yoursaas.com`.
        2. The application checks the `central.tenants` table for `aaron` and retrieves the correct tenant database.
        3. Subsequent queries are executed against Aaron’s specific database.

#### Benefits of Multi-Database Setup:

- **Data locality**:
    - Tenants’ data can be stored in different regions for performance or legal reasons (e.g., a tenant in Germany could
      have their data stored in the EU).
- **Simpler queries**:
    - Since each tenant has their own database, there’s no need for tenant-specific `WHERE` conditions, reducing the
      risk of
      data leakage.

### Managing Schema Migrations Across Tenant Databases

1. **Tracking Schema Versions with `PRAGMA user_version`**:
    - SQLite allows a user-defined version number for each database, tracked via the `user_version` pragma.
    - Use `PRAGMA user_version = X` to set a version number, and `PRAGMA user_version` to retrieve it.
    - **Use case**:  
      Keep track of which tenants have been migrated to a new schema version. Example flow:
        - Loop through all tenant databases.
        - Check `PRAGMA user_version`.
        - Apply necessary migrations if the version is outdated.

2. **Rolling Migrations**:
    - Perform migrations gradually, updating a few tenant databases at a time and checking for errors before migrating
      the entire set.

### Tools and Services for Multi-Tenancy with SQLite

- **Vanilla SQLite**:
    - Requires manual setup of infrastructure to manage multiple databases.
- **Turso (Mentioned but not part of the course)**:
    - A service that makes it easier to manage multi-tenant databases by automating schema duplication and migrations
      across databases.

### Example Scenarios

- **Centralized Database for Global Data**:  
  Global settings or shared resources can be stored in an attached database, while tenant-specific data resides in
  separate databases.

- **Data Authority**:  
  Having tenant databases in different regions can help with performance and legal compliance (e.g., GDPR).

### Summary of Trade-offs

1. **Single Database**:
    - Pros: Easy to manage.
    - Cons: Complex queries, potential security risks.

2. **Multiple Databases**:
    - Pros: Simpler queries, stronger data isolation, aligns with SQLite's architecture.
    - Cons: More operational complexity, requires a strategy for managing migrations.