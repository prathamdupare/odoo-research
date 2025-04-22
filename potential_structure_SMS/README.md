**I. Overall Architecture Philosophy**

- **Modular Design:** Break the system into distinct functional components (Python packages/modules). This promotes maintainability, testability, and allows features to be developed or enabled independently. Inspired by Odoo Addons.
- **Layered Architecture:** Clearly separate concerns:
  - **Presentation Layer:** (Your API framework - e.g., Flask, FastAPI, Django) Handles requests and responses.
  - **Business Logic Layer (Services):** Contains the core operations, orchestrates data access, enforces business rules, and handles authorization.
  - **Data Access Layer (DAL):** Uses SQLAlchemy (Models, Session) to interact with the database, defining structure and relationships.
- **ORM-Centric:** Leverage SQLAlchemy for database interactions, defining models declaratively and using the Session for operations. Avoid raw SQL where possible for portability and maintainability.

**II. Proposed Directory Structure**

```
school_management_project/
├── alembic/                  # Alembic migration scripts directory
│   ├── versions/
│   └── env.py
├── school_app/               # Main application package
│   ├── __init__.py
│   │
│   ├── core/                 # Core entities and shared logic (Inspired by Odoo's 'base')
│   │   ├── __init__.py
│   │   ├── models.py         # Student, Teacher, User, Course, Subject, AcademicTerm models
│   │   └── services.py       # Basic services for core models (if needed)
│   │   └── schemas.py        # Pydantic/Marshmallow schemas for core models (optional, for validation/serialization)
│   │
│   ├── enrollment/           # Enrollment-specific functionality
│   │   ├── __init__.py
│   │   ├── models.py         # Enrollment model, maybe Grade model
│   │   └── services.py       # Enrollment creation, grade recording logic
│   │   └── schemas.py        # Schemas for enrollment/grades
│   │
│   ├── attendance/           # (Future Module Example)
│   │   └── ...
│   │
│   ├── security/             # Access control logic, roles, permissions
│   │   ├── __init__.py
│   │   └── services.py       # Functions to check permissions based on user/role
│   │   └── roles.py          # Role definitions
│   │
│   ├── database.py           # SQLAlchemy engine, SessionLocal, Base definition
│   ├── config.py             # Application configuration loading
│   └── main.py               # API Application (FastAPI/Flask/Django) setup and routers
│
├── tests/                    # Unit and integration tests
│   ├── core/
│   └── enrollment/
│
├── alembic.ini               # Alembic configuration file
└── requirements.txt          # Python dependencies
└── ...                     # Other project files (README, etc.)
```

**III. Data Layer (SQLAlchemy Models & Relationships)**

- **Base Setup (`database.py`):**
  - Define `engine = create_engine(...)`.
  - Define `SessionLocal = sessionmaker(...)`.
  - Define `Base = declarative_base()` or `class Base(DeclarativeBase): pass`.
- **Core Models (`core/models.py`):**
  - `User`: Standard user model for login (id, username, hashed_password, role - e.g., using an Enum). Consider linking to Student/Teacher/Parent profiles.
  - `Student`: id, user_id (FK to User, optional), name, birthdate, student_uid (unique ID), contact_info (JSON or separate table?), enrollments (OneToMany).
  - `Teacher`: id, user_id (FK to User, optional), name, subject(s) specialization (Maybe ManyToMany to Subject?), assigned_courses (ManyToMany or through Course).
  - `Course`: id, name, code (unique), subject_id (FK to Subject), teacher_id (FK to Teacher, optional), academic_term_id (FK to AcademicTerm), enrollments (OneToMany).
  - `Subject`: id, name (unique).
  - `AcademicTerm`: id, name (e.g., "2024-2025 Fall"), start_date, end_date.
- **Feature Models (`enrollment/models.py`, etc.):**
  - `Enrollment`: id, student_id (FK), course_id (FK), enrollment_date, status (Enum: 'enrolled', 'withdrawn', 'completed'), grade (could be simple `String` or `Float`, or a FK to a separate `Grade` model if complex). Define relationships back to `Student` and `Course`. Use `Index` or `UniqueConstraint` on `(student_id, course_id)` if a student can only enroll once per course per term.
  - `Grade` (Optional, if complex): id, enrollment_id (FK), grade_value, grade_type (Enum: 'midterm', 'final', 'assignment'), graded_by_teacher_id (FK), date_graded.
  - `AttendanceRecord` (Future): id, enrollment_id (FK), date, status (Enum: 'present', 'absent', 'late', 'excused').
- **Relationships:** Use `relationship(back_populates="...")` consistently to define bidirectional relationships. Use `ForeignKey` for ManyToOne. Use `secondary=` with an association `Table` for ManyToMany. Define `cascade` options appropriately (e.g., deleting a Student might cascade delete their Enrollments).

**IV. Business Logic Layer (Services)**

- **Purpose:** Encapsulate operations beyond simple CRUD. Handle validation logic that spans multiple models, coordinate database operations within a transaction, and check permissions.
- **Structure:** Create service functions or classes within each module (e.g., `enrollment/services.py`).
- **Interaction:** Services will typically accept necessary input data, potentially a user context (for permissions), and a SQLAlchemy `Session` object (often via dependency injection in web frameworks). They use the session to query and manipulate models.
- **Example Functions:**
  - `enroll_student(session, student_id, course_id, user_context)`
  - `record_grade(session, enrollment_id, grade_value, teacher_context)`
  - `calculate_student_gpa(session, student_id, term_id)`
  - `get_courses_for_teacher(session, teacher_id, user_context)`
  - `is_enrollment_period_active(term)`
- **Inspiration from `hr_skills_slides`:** The logic to automatically create a "certificate" or update a "skill" upon course completion would live in a service function, likely called after a grade is successfully recorded and meets the passing criteria.

**V. Data Validation**

- **Database Level:** Use SQLAlchemy `Column` constraints (`nullable=False`, `CheckConstraint`, `unique=True`).
- **Application Level:**
  - Before creating/updating models, validate incoming data using Pydantic or Marshmallow schemas (defined in `schemas.py` files).
  - Implement more complex cross-field or business rule validation within the service layer functions before interacting with the session.

**VI. Access Control Strategy**

- **Role-Based Access Control (RBAC):** Define roles (e.g., 'admin', 'teacher', 'student', 'parent' stored on the `User` model or linked profile).
- **Implementation:** Enforce checks within the service layer or API endpoints.
  - A service function should typically receive the `current_user` object or context.
  - Before performing an action, check if the user's role permits it (e.g., `if current_user.role != 'teacher': raise PermissionDenied("Only teachers can record grades")`).
  - When querying data, filter based on the user's role and ownership (e.g., `session.query(Enrollment).filter(Enrollment.student_id == current_user.student_profile.id)` for students viewing their own data).

**VII. Database Schema Management (Migrations)**

- **Tool:** Use **Alembic**. It's the standard for SQLAlchemy.
- **Workflow:**
  1.  Initialize Alembic (`alembic init alembic`).
  2.  Configure `alembic/env.py` to import your `Base.metadata` and database connection details.
  3.  Modify your SQLAlchemy models in `.py` files.
  4.  Generate a migration script: `alembic revision --autogenerate -m "Description of changes"`.
  5.  **Review** the generated script carefully. Autogenerate isn't perfect.
  6.  Apply the migration to the database: `alembic upgrade head`.

**VIII. Configuration & Data Seeding**

- **Configuration:** Use environment variables or config files (`.env`, `config.py`, YAML/JSON) for database URLs, secrets, etc.
- **Seeding:**
  - Use Alembic data migrations (create specific migration scripts that use `op.bulk_insert` or SQLAlchemy Core `table.insert()`).
  - Write separate Python scripts that import your models and use a SQLAlchemy `Session` to create initial data (e.g., subjects, default roles, an initial admin user). Run these scripts during deployment or setup.

**IX. Context Handling**

- **Challenge:** SQLAlchemy doesn't have a built-in `env` like Odoo.
- **Solution:** Pass necessary context explicitly to your service functions. Your web framework likely provides ways to manage request-scoped context (like the current user). For background tasks or scripts, you might need to establish context manually. Common context includes:
  - Current authenticated user and their roles/permissions.
  - Current Academic Term (might be needed for filtering enrollments, etc.).

**X. Next Steps & Considerations**

1.  **Setup:** Initialize project structure, SQLAlchemy (`database.py`), Alembic.
2.  **Core Models:** Define `school_base` models and generate initial migrations.
3.  **Basic Services:** Implement simple CRUD services for core models.
4.  **Authentication:** Implement user login and role management.
5.  **Feature Modules:** Develop `school_enrollment` (models, services, migrations), then `school_grading`, etc.
6.  **Testing:** Write unit tests for services and integration tests for data interactions.
7.  **API/UI:** Build the API endpoints or UI layer on top of the service layer.

This plan provides a solid foundation based on SQLAlchemy, incorporating the valuable structural and conceptual lessons learned from Odoo's design. Remember that this is a starting point, and details will evolve as you build the system.
