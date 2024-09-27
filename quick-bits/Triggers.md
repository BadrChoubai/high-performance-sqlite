# Triggers in SQLite

Triggers are powerful tools in SQLite that can automatically execute specified actions in response to certain changes in
a database. They can be particularly useful for tasks like maintaining audit logs, enforcing business rules, or
automatically updating related records.

--- 

## Understanding Triggers

SQLite supports several types of triggers:

- **INSERT**: Triggered after a row is inserted.
- **UPDATE**: Triggered after a row is updated.
- **DELETE**: Triggered after a row is deleted.
- **Triggers on Views**: Triggers can also be created for views.

While the SQLite documentation provides thorough coverage of all available triggers, here we focus on a practical
example demonstrating how to track changes to email addresses in a user database.

## Example: Tracking Email Changes with a Trigger

In this example, we create a trigger to log changes made to the email field in the `users` table. This can help in
monitoring potential fraud or unusual activity, such as multiple sign-ups with different email addresses.

### Step 1: View Current Users and Email Audit Table

Start by querying the `users` and `email_audit` tables to understand the current state of your data.

```sqlite
-- Select top 2 users
SELECT *
FROM users
LIMIT 2;

SELECT *
FROM email_audit;
```

### Step 2: Create the Trigger

We create a trigger named `trg_email_updated` that activates after an update to the `email` column of the `users` table.
This trigger will insert a new record into the `email_audit` table, capturing the user's ID, the old email, and the new
email.

```sqlite
CREATE TRIGGER trg_email_updated
    AFTER UPDATE OF email
    ON users
BEGIN
    INSERT INTO email_audit (user_id, old, new)
    VALUES (old.id, old.email, new.email);
END;
```

### Step 3: Update a User's Email

Now we update a user's email address to trigger the functionality of our newly created trigger.

```sqlite
UPDATE users
SET email = 'ladarius.dibbert@roven.com'
WHERE id = 1;
```

### Step 4: Check the Email Audit Table

After updating the user's email, check the `email_audit` table to see the recorded change.

```sqlite
SELECT *
FROM email_audit;
```

### Cleanup

Finally, to clean up after our demonstration, we can delete the entries from the `email_audit` table and drop the
trigger.

```sqlite
-- Cleanup
DELETE
FROM email_audit;

DROP TRIGGER trg_email_updated;
```

## Key Takeaways

- **Simplicity and Power**: Triggers can simplify your application code by automatically performing actions in response
  to changes, allowing you to manage data integrity and enforce business rules effectively.
- **Audit Logging**: This specific trigger example illustrates how to implement an audit log that captures changes to
  critical fields in your database, making it easier to monitor and troubleshoot.
- **Usage Guidelines**: While triggers are powerful, they should be used judiciously. It's often better to keep most
  logic at the application layer for better discoverability and communication among developers.

Triggers can be extremely beneficial for scenarios where actions need to be taken automatically based on data changes.
Whether for auditing, enforcing rules, or automating tasks, understanding how to implement and use triggers effectively
is an important skill in database management.