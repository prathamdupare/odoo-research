Drawing on the information in "Chapter 1: Architecture Overview", Odoo follows a **multitier application architecture**. More specifically, it employs a **three-tier architecture**, separating the **presentation**, **business logic**, and **data storage** layers.

Here's a breakdown of each tier:

- **Presentation Tier**: This layer is responsible for the user interface and is a combination of **HTML5, JavaScript, and CSS**. It's important to note that since version 15.0, Odoo is actively transitioning to its own in-house developed **OWL framework** as part of its presentation tier, although the legacy JavaScript framework is still supported.

- **Logic Tier**: The core of Odoo's functionality resides in this tier, which is written exclusively in **Python**. This is where business rules, workflows, and data manipulation logic are implemented.

- **Data Tier**: This layer is responsible for the storage and retrieval of data. Odoo exclusively supports **PostgreSQL** as its Relational Database Management System (RDBMS).

Extensions to both the server-side (logic and data) and client-side (presentation) of Odoo are packaged as **modules**. These modules are optionally loaded within a specific **database** and are designed to address a single business purpose. Odoo **modules** can either introduce entirely new business logic to an Odoo system or modify and expand upon existing functionalities. Developers organize their business features within these **modules**, some of which are user-facing and presented as **Apps**. The terms **modules** and **addons** are often used interchangeably, and the directories where the Odoo server locates them form the `addons_path`.

An Odoo module **can** include several elements:

- **Business objects**: These are Python classes (extending `models.Model`) that represent business entities (like invoices) and whose fields are automatically mapped to database columns through Odoo's **Object-Relational Mapping (ORM)** layer.
- **Object views**: These define how business objects are displayed in the user interface.
- **Data files**: These are typically XML or CSV files that declare model data such as views, reports, configuration settings (including security rules), and demonstration data.
- **Web controllers**: These handle requests coming from web browsers.
- **Static web data**: This includes images, CSS, and JavaScript files utilized by the web interface or website.

The fundamental structure of an Odoo module as a directory often contains:

```
module/
├── models/
│   ├── *.py
│   └── __init__.py
├── data/
│   └── *.xml
├── __init__.py
└── __manifest__.py
```

The `__manifest__.py` file is crucial as it declares the module and its metadata. When a module includes business objects (Python files), they are organized as a Python package with an `__init__.py` file that imports the various Python files within the `models` directory.

Finally, Odoo is offered in two main **Editions**: **Odoo Enterprise** (which is licensed and has shared source code) and **Odoo Community** (which is open-source). The Enterprise version provides additional functionalities through extra modules installed on top of the Community version, along with services like support and upgrades.
