# Operating SQLite: Multi-Database Approach

In SQLite, it can be beneficial to split your database by function, especially in web applications where you have a
queue system and a caching system. While traditional databases can handle multiple concurrent writes without issue,
SQLite allows only one writer at a time, which can become a bottleneck for systems like queues or caches that involve
frequent writes.

To avoid this, you can create multiple SQLite databases for different purposes. For example:

- `database.sqlite` for your application's core data (e.g., users, comments, tasks).
- `cache.sqlite` for storing cached data.
- `queue.sqlite` for managing job queues.

By separating these concerns into different databases, you effectively gain the ability to have three concurrent
writers: one for your core app data, one for the cache, and one for the queue. This approach reduces write contention
and optimizes performance.

This pattern can also be extended to multi-tenancy, where each tenant might have its own database, allowing isolated and
more efficient data management per tenant.

## Multi-Tenancy

Multi-tenancy is a common approach in SaaS (Software as a Service) applications, where the same application is shared
across multiple customers or tenants. In multi-tenancy, there are two typical approaches at the database layer:

- **Single Database for All Tenants**: All tenants share a single database, with each tenant's data distinguished by
  tenant-specific identifiers. This approach is simple to implement but can become complex to manage as the number of
  tenants grows, especially in terms of ensuring data isolation and optimizing performance.
- **Separate Database per Tenant**: Each tenant has their own isolated database. This approach offers stronger data
  isolation and can be more performant, particularly when combined with SQLite's design. Since databases in SQLite are
  cheap and easy to create, this method scales well for multi-tenancy, allowing each tenant to have dedicated resources
  for their data.

When using multiple databases in a multi-tenant setup, each tenant's database can be treated similarly to the earlier
example of splitting functionality. For example, each tenant could have:

- `tenant_database_{id}.sqlite` for their specific data.
- `tenant_cache_{id}.sqlite` for their cached values.
- `tenant_queue_{id}.sqlite` for their queued jobs.

This setup ensures that no single tenant's operations will impact another tenant, improving overall reliability and
performance as the number of tenants grows.

By breaking the databases into smaller, specialized units, you reduce contention and ensure that each functional
component (core data, cache, queue) or each tenant operates independently, taking full advantage of SQLite's ability to
handle multiple databases efficiently.
