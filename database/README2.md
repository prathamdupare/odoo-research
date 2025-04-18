
**Slide 1: Title Slide**

* **Title:** Odoo's Database Architecture: Under the Hood
* **Subtitle:** Understanding Structure, ORM, Modularity, and Scaling
* **Your Name/Date**

---

**Slide 2: Introduction - Why Talk About Odoo's Database?**

* **What is Odoo?** A suite of open-source business apps (ERP, CRM, etc.).
* **Why is the DB important?**
    * All business data resides here.
    * Understanding the structure is key for:
        * Customization & Development
        * Integration with other systems
        * Reporting & Analytics
        * Troubleshooting & Performance Tuning
* **Key Focus Areas:** ORM, Structure, Interaction, Modularity, Protocols, Scaling.

---

**Slide 3: The Heart of Odoo Data: The ORM**

* **What is an ORM?** Object-Relational Mapper.
    * A programming technique that acts as a bridge between object-oriented code (Python in Odoo) and a relational database (PostgreSQL).
* **Odoo is Heavily ORM-Driven:**
    * You primarily interact with Python objects (models), not raw SQL.
    * The ORM translates Python operations into SQL queries.
* **Benefits:**
    * **Abstraction:** Hides complex SQL.
    * **Productivity:** Faster development using Python objects and methods.
    * **Consistency:** Enforces data access patterns.
    * **Database Agnosticism (mostly):** While designed for PostgreSQL, the ORM provides a layer of independence.

---

**Slide 4: Database Structure: Models Become Tables**

* **Automatic Table Creation:**
    * You define a "Model" in Python (a class inheriting `models.Model`).
    * Odoo automatically creates a corresponding PostgreSQL table when the module is installed/updated.
    * No manual `CREATE TABLE` needed for basic models.
* **Model-to-Table Naming:**
    * Python Model `_name` attribute (e.g., `sale.order`) determines the table name.
    * Convention: Replace dots (`.`) with underscores (`_`).
    * Example: `sale.order` model -> `sale_order` table.
* **Field-to-Column Mapping:**
    * Fields defined in the Python model (e.g., `fields.Char`, `fields.Integer`) map to columns in the table.
    * Example: `name = fields.Char(...)` in the model becomes a `name` column (likely `VARCHAR`) in the table.

---

**Slide 5: Database Structure: Naming Conventions & Prefixes**

* **Purpose:** Prefixes act as namespaces, indicating the module origin or category.
* **Common Prefixes:**
    * `res_`: Core "Resource" models (shared entities).
        * Example: `res.partner` -> `res_partner` (Contacts/Companies)
        * Example: `res.users` -> `res_users` (System Users)
    * `ir_`: Core "Information Repository" models (framework metadata).
        * Example: `ir.model` -> `ir_model` (Stores info about all models)
        * Example: `ir.actions.act_window` -> `ir_actions_act_window` (Window Actions)
    * **Application Specific:** `sale_`, `account_`, `stock_`, `product_`, etc.
        * Example: `account.move` -> `account_move` (Journal Entries)
    * **Custom Modules:** Use their own prefixes (or none, though prefixes recommended).
        * Example: `school.student` -> `school_student`

---

**Slide 6: Database Structure: Relationships**

* **How Tables are Linked:** Defined by *Relational Fields* in Python models.
* **Key Field Types:**
    * **`Many2one` (Foreign Key):**
        * Links *one* record to *one* other record (e.g., an Order linked to *one* Customer).
        * Python: `partner_id = fields.Many2one('res.partner', ...)`
        * Database: Creates a `partner_id` column (INTEGER) in the current table, referencing `res_partner(id)`.
    * **`One2many` (Inverse Relation):**
        * Links *one* record to *many* other records (e.g., one Order linked to *many* Order Lines).
        * Python: `order_line_ids = fields.One2many('sale.order.line', 'order_id', ...)`
        * Database: **No column created** in the current table. Relies on a `Many2one` field (`order_id`) in the *other* table (`sale.order.line`) pointing back.
    * **`Many2many` (Intermediary Table):**
        * Links *many* records to *many* other records (e.g., multiple Contacts linked to multiple Tags/Categories).
        * Python: `category_id = fields.Many2many('res.partner.category', ...)`
        * Database: Creates a *separate* relation table (e.g., `res_partner_category_rel`) with two columns (e.g., `partner_id`, `category_id`) linking the two main tables.

---

**Slide 7: Example: Sales Order Relationships**

* **Models:**
    * `sale.order` (Sales Order)
    * `res.partner` (Customer)
    * `sale.order.line` (Order Line)
* **Relationships in `sale.order` model:**
    * `partner_id = fields.Many2one('res.partner', ...)` -> Links SO to one Customer.
    * `order_line_ids = fields.One2many('sale.order.line', 'order_id', ...)` -> Links SO to many Lines.
* **Database Structure:**
    * `sale_order` table has a `partner_id` column (FK to `res_partner.id`).
    * `sale_order_line` table has an `order_id` column (FK to `sale_order.id`).
    * `res_partner` table exists independently.
    * *(Optional: Show simple diagram)*

---

**Slide 8: How the ORM Interacts: Python to Database**

* **Abstraction Layer:** Developers work with Python objects and methods.
* **CRUD Operations via ORM Methods:**
    * `create(vals)`: Inserts a new record (translates to `INSERT INTO ...`).
    * `search(domain)`: Finds record IDs matching criteria (translates to `SELECT id FROM ... WHERE ...`).
    * `browse(ids)`: Retrieves record objects by ID (translates to `SELECT * FROM ... WHERE id IN ...`).
    * `write(vals)`: Updates records (translates to `UPDATE ... SET ... WHERE ...`).
    * `unlink()`: Deletes records (translates to `DELETE FROM ... WHERE ...`).
* **The Environment (`env`):**
    * The context (`self.env`) provides access to all models: `self.env['res.partner'].search(...)`

---

**Slide 9: Example: ORM Interaction Code**

```python
# Find a partner named 'Acme Corp'
partners = self.env['res.partner'].search([('name', '=', 'Acme Corp')])

if partners:
    partner = partners[0] # browse() is often implicit here

    # Create a new sales order for this partner
    order_vals = {
        'partner_id': partner.id,
        'date_order': fields.Datetime.now(),
        # ... other fields
    }
    new_order = self.env['sale.order'].create(order_vals)
    print(f"Created Order ID: {new_order.id} with name: {new_order.name}") # name is often sequence-generated

    # Update the partner's comment field
    partner.write({'comment': 'Updated via ORM example'})

# No explicit SQL written by the developer!
```

---

**Slide 10: Architectural Style & Modularity**

* **Style:** Often described as a **Modular Monolith**.
    * **Monolith Core:** A central framework providing core services (ORM, Web server, Module system).
    * **Modular:** Functionality is broken down into installable **Modules** (or Addons).
* **Internal Layering:** (As discussed previously)
    * Presentation (Web Controllers/UI)
    * Service Layer (Business Logic / DB Management Logic)
    * ORM Layer
    * Database Connection Layer (Connection Pooling)
* **Modularity - The Power of Addons:**
    * Each module encapsulates specific functionality (Models, Views, Data, Controllers).
    * Defined by `__manifest__.py` (metadata, dependencies).
    * Modules create their *own* database tables alongside core tables.
    * Allows extending/modifying Odoo without touching core code (using inheritance, dependencies).

---

**Slide 11: Communication Protocols**

* **Database Level:**
    * **PostgreSQL Wire Protocol:** Used between Odoo (via `psycopg2` library) and the PostgreSQL database server.
* **Internal Communication (Between Odoo Layers):**
    * **RPC (Remote Procedure Call):** Odoo uses an internal RPC mechanism (`dispatch_rpc`) for layers to communicate, e.g., Web Controller calling Database Service methods.
* **External Integration (APIs):**
    * **XML-RPC:** The primary, stable API for external applications to interact with Odoo models (CRUD operations). Typically on port `8069`.
    * **JSON-RPC:** Used extensively by Odoo's own web client (browser communicating with the server). Typically on `/jsonrpc` endpoint.
    * **REST API:** Not available out-of-the-box in older versions, but standard in recent versions or can be added via custom modules or community modules (e.g., OCA's `base_rest`).

---

**Slide 12: Database Scaling & Replication**

* **Scaling Odoo Application Servers:**
    * **Vertical:** Increase CPU/RAM of the Odoo server(s).
    * **Horizontal:** Run multiple Odoo server processes/instances.
        * Requires a load balancer.
        * Odoo configuration (`--workers > 0`) enables multi-processing mode.
* **Scaling/Replicating the Database (PostgreSQL Level):**
    * **Odoo relies on PostgreSQL's capabilities.** Odoo itself doesn't *perform* replication.
    * **Replication:** Standard PostgreSQL **Streaming Replication**.
        * Setup: One Primary (Read-Write) server and one or more Standby (Read-Only) servers.
        * Benefits: High Availability (failover), Read Scalability (offload read queries to standbys).
    * **How Odoo uses replicas:**
        * Requires configuration (possibly connection pooler like PgBouncer/Pgpool-II) to direct reads to standbys and writes to the primary. Odoo doesn't handle this split automatically.
        * Ensures business continuity if the primary DB fails.
    * **Sharding:** More complex partitioning, typically not needed unless dealing with *massive* datasets. Not directly supported by Odoo core.

---

**Slide 13: Summary**

* Odoo uses an **ORM** to map Python objects to PostgreSQL tables.
* Database structure is **auto-generated** based on Python models, following **naming conventions** (`res_`, `ir_`, etc.).
* **Relational fields** (`Many2one`, `One2many`, `Many2many`) define links between tables.
* Developers interact via **ORM methods** (create, search, write...), not raw SQL.
* Architecture is a **Modular Monolith**, enabling extensions via Addons.
* Uses **PostgreSQL protocol** for DB connection and **XML-RPC/JSON-RPC** for external/web client communication.
* **Scaling/Replication** leverages Odoo workers for the application layer and **standard PostgreSQL features** (Streaming Replication) for the database layer.

---

**Slide 14: Q&A**

* Open floor for questions.

---
