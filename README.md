# Library Management System

A MySQL-based **Library Management System** developed as part of an SQL internship project. The project manages books, authors, categories, library members, book issuing, returns, and fines

## Technologies Used

* MySQL
* SQL
* MySQL Workbench
* GitHub

## Features

* Add and manage books
* Manage authors and categories
* Manage library members
* Issue books to members
* Return books
* Track available book copies
* Track due dates
* Calculate overdue fines
* Search books
* View borrowing history
* Find overdue books
* Generate basic library reports

## Database Tables

The project contains five main tables:

### Authors

Stores information about book authors.

* `author_id`
* `author_name`
* `country`

### Categories

Stores different book categories.

* `category_id`
* `category_name`

### Books

Stores information about books.

* `book_id`
* `title`
* `author_id`
* `category_id`
* `isbn`
* `publication_year`
* `total_copies`
* `available_copies`

### Members

Stores library member information.

* `member_id`
* `member_name`
* `email`
* `phone`
* `join_date`
* `status`

### Book Issues

Stores information about issued and returned books.

* `issue_id`
* `book_id`
* `member_id`
* `issue_date`
* `due_date`
* `return_date`
* `fine`
* `status`

## Database Relationships

```text
Authors ────────< Books >──────── Categories
                    |
                    |
                    v
               Book Issues
                    ^
                    |
                 Members
```

* One author can have multiple books.
* One category can contain multiple books.
* One member can issue multiple books.
* A book can be issued multiple times.

## SQL Concepts Used

* Database and table creation
* Primary keys
* Foreign keys
* Constraints
* `INSERT`
* `SELECT`
* `UPDATE`
* `WHERE`
* `LIKE`
* `JOIN`
* `GROUP BY`
* `ORDER BY`
* Aggregate functions
* Date functions
* Views
* Stored procedures
* Triggers
* Transactions
* Indexes

## Book Issue

When a book is issued:

1. The system checks book availability.
2. It checks whether the member is active.
3. An issue record is created.
4. The due date is calculated.
5. Available book copies are reduced.

Example:

```sql
CALL issue_book(2, 1, 14);
```

## Book Return

When a book is returned:

1. The return date is recorded.
2. The fine is calculated if the book is overdue.
3. The available book count is increased.
4. The issue status is changed to `RETURNED`.

Example:

```sql
CALL return_book(1);
```

## Fine Calculation

The project uses a fine of **₹5 per overdue day**.

```text
Fine = Overdue Days × ₹5
```

## Example SQL Queries

### View All Books

```sql
SELECT * FROM books;
```

### Find Available Books

```sql
SELECT title, available_copies
FROM books
WHERE available_copies > 0;
```

### Search for Java Books

```sql
SELECT *
FROM books
WHERE title LIKE '%Java%';
```

### View Overdue Books

```sql
SELECT * FROM overdue_books;
```

## Project Structure

```text
Library-Management-System/
│
├── library_management.sql
└── README.md
```

## How to Run

1. Install **MySQL Server** and **MySQL Workbench**.
2. Open `library_management.sql` in MySQL Workbench.
3. Execute the complete SQL script.
4. The `library_management` database will be created automatically.
5. Check the tables using:

```sql
USE library_management;

SHOW TABLES;
```

## Learning Outcomes

Through this project, I gained practical experience in:

* Designing a relational database
* Creating tables and relationships
* Writing SQL queries
* Using joins
* Working with stored procedures
* Managing book issue and return operations
* Handling dates and fines
* Creating reports using SQL

## Future Improvements

* Admin login
* Student/member login
* Book reservation
* Email notifications
* Web interface
* Java backend
* Spring Boot integration
* Library dashboard

## Author

**Sunil Behera**

**Intern ID:** `CITS9335`

**B.Tech – Computer Science Engineering**

**SQL Internship Project**
