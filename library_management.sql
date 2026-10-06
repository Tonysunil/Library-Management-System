-- ============================================================
-- Library Management System
-- Complete MySQL Database Script
-- SQL Internship Project
-- ============================================================

DROP DATABASE IF EXISTS library_management;
CREATE DATABASE library_management;
USE library_management;

-- =========================
-- TABLES
-- =========================

CREATE TABLE authors (
    author_id INT PRIMARY KEY AUTO_INCREMENT,
    author_name VARCHAR(100) NOT NULL,
    country VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE categories (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE books (
    book_id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(200) NOT NULL,
    author_id INT NOT NULL,
    category_id INT NOT NULL,
    isbn VARCHAR(20) NOT NULL UNIQUE,
    publication_year YEAR,
    total_copies INT NOT NULL DEFAULT 1,
    available_copies INT NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (author_id) REFERENCES authors(author_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    FOREIGN KEY (category_id) REFERENCES categories(category_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CHECK (total_copies >= 0),
    CHECK (available_copies >= 0),
    CHECK (available_copies <= total_copies)
);

CREATE TABLE members (
    member_id INT PRIMARY KEY AUTO_INCREMENT,
    member_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(15) UNIQUE,
    join_date DATE NOT NULL,
    status ENUM('ACTIVE', 'INACTIVE') DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE book_issues (
    issue_id INT PRIMARY KEY AUTO_INCREMENT,
    book_id INT NOT NULL,
    member_id INT NOT NULL,
    issue_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE NULL,
    fine DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    status ENUM('ISSUED', 'RETURNED') DEFAULT 'ISSUED',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (book_id) REFERENCES books(book_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    FOREIGN KEY (member_id) REFERENCES members(member_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CHECK (due_date >= issue_date),
    CHECK (return_date IS NULL OR return_date >= issue_date),
    CHECK (fine >= 0)
);

-- =========================
-- INDEXES
-- =========================

CREATE INDEX idx_books_title ON books(title);
CREATE INDEX idx_books_author ON books(author_id);
CREATE INDEX idx_books_category ON books(category_id);
CREATE INDEX idx_members_name ON members(member_name);
CREATE INDEX idx_issues_book ON book_issues(book_id);
CREATE INDEX idx_issues_member ON book_issues(member_id);
CREATE INDEX idx_issues_due_date ON book_issues(due_date);
CREATE INDEX idx_issues_status ON book_issues(status);

-- =========================
-- SAMPLE AUTHORS
-- =========================

INSERT INTO authors (author_name, country) VALUES
('Robert C. Martin', 'USA'),
('James Gosling', 'Canada'),
('Herbert Schildt', 'USA'),
('Ramez Elmasri', 'USA'),
('Thomas H. Cormen', 'USA'),
('Joshua Bloch', 'USA'),
('Andrew S. Tanenbaum', 'Netherlands'),
('Abraham Silberschatz', 'USA'),
('Ian Sommerville', 'UK'),
('E. Balagurusamy', 'India');

-- =========================
-- SAMPLE CATEGORIES
-- =========================

INSERT INTO categories (category_name) VALUES
('Programming'),
('Database'),
('Computer Science'),
('Algorithms'),
('Software Engineering'),
('Operating Systems'),
('Java'),
('Web Development');

-- =========================
-- SAMPLE BOOKS
-- =========================

INSERT INTO books
(title, author_id, category_id, isbn, publication_year, total_copies, available_copies)
VALUES
('Clean Code', 1, 5, '9780132350884', 2008, 5, 5),
('The Java Programming Language', 2, 7, '9780321349804', 2005, 4, 4),
('Java: The Complete Reference', 3, 7, '9781260440218', 2020, 6, 6),
('Fundamentals of Database Systems', 4, 2, '9780133970777', 2016, 3, 3),
('Introduction to Algorithms', 5, 4, '9780262046305', 2022, 5, 5),
('Effective Java', 6, 7, '9780134685991', 2018, 4, 4),
('Modern Operating Systems', 7, 6, '9780137618873', 2014, 3, 3),
('Operating System Concepts', 8, 6, '9781119800361', 2018, 5, 5),
('Software Engineering', 9, 5, '9780133943030', 2015, 4, 4),
('Programming in ANSI C', 10, 1, '9789352600069', 2016, 5, 5),
('HTML and CSS: Design and Build Websites', 1, 8, '9781118008188', 2011, 2, 2),
('Data Structures and Algorithms', 5, 4, '9780262533058', 2019, 3, 3);

-- =========================
-- SAMPLE MEMBERS
-- =========================

INSERT INTO members
(member_name, email, phone, join_date, status)
VALUES
('Rahul Kumar', 'rahul@gmail.com', '9876543210', '2026-01-10', 'ACTIVE'),
('Priya Sharma', 'priya@gmail.com', '9876543211', '2026-01-15', 'ACTIVE'),
('Arjun Reddy', 'arjun@gmail.com', '9876543212', '2026-02-05', 'ACTIVE'),
('Sneha Patel', 'sneha@gmail.com', '9876543213', '2026-02-20', 'ACTIVE'),
('Amit Kumar', 'amit@gmail.com', '9876543214', '2026-03-01', 'ACTIVE'),
('Neha Singh', 'neha@gmail.com', '9876543215', '2026-03-10', 'ACTIVE'),
('Kiran Rao', 'kiran@gmail.com', '9876543216', '2026-03-15', 'INACTIVE');

-- =========================
-- STORED PROCEDURE: ISSUE BOOK
-- =========================

DELIMITER $$

CREATE PROCEDURE issue_book(
    IN p_book_id INT,
    IN p_member_id INT,
    IN p_days INT
)
BEGIN
    DECLARE v_available INT DEFAULT 0;
    DECLARE v_member_status VARCHAR(20);
    DECLARE v_existing_issue INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_days <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Issue duration must be greater than zero';
    END IF;

    START TRANSACTION;

    SELECT available_copies
    INTO v_available
    FROM books
    WHERE book_id = p_book_id
    FOR UPDATE;

    IF v_available IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Book not found';
    END IF;

    SELECT status
    INTO v_member_status
    FROM members
    WHERE member_id = p_member_id;

    IF v_member_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Member not found';
    END IF;

    IF v_member_status <> 'ACTIVE' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Member is inactive';
    END IF;

    IF v_available <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Book is currently unavailable';
    END IF;

    SELECT COUNT(*)
    INTO v_existing_issue
    FROM book_issues
    WHERE book_id = p_book_id
      AND member_id = p_member_id
      AND return_date IS NULL;

    IF v_existing_issue > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'This member already has this book issued';
    END IF;

    INSERT INTO book_issues
    (book_id, member_id, issue_date, due_date, status)
    VALUES
    (p_book_id, p_member_id, CURDATE(),
     DATE_ADD(CURDATE(), INTERVAL p_days DAY),
     'ISSUED');

    UPDATE books
    SET available_copies = available_copies - 1
    WHERE book_id = p_book_id;

    COMMIT;
END$$

DELIMITER ;

-- =========================
-- STORED PROCEDURE: RETURN BOOK
-- =========================

DELIMITER $$

CREATE PROCEDURE return_book(
    IN p_issue_id INT
)
BEGIN
    DECLARE v_book_id INT;
    DECLARE v_due_date DATE;
    DECLARE v_return_date DATE;
    DECLARE v_status VARCHAR(20);
    DECLARE v_fine DECIMAL(10,2) DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT book_id, due_date, return_date, status
    INTO v_book_id, v_due_date, v_return_date, v_status
    FROM book_issues
    WHERE issue_id = p_issue_id
    FOR UPDATE;

    IF v_book_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Issue record not found';
    END IF;

    IF v_return_date IS NOT NULL OR v_status = 'RETURNED' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Book has already been returned';
    END IF;

    IF CURDATE() > v_due_date THEN
        SET v_fine = DATEDIFF(CURDATE(), v_due_date) * 5;
    END IF;

    UPDATE book_issues
    SET return_date = CURDATE(),
        fine = v_fine,
        status = 'RETURNED'
    WHERE issue_id = p_issue_id;

    UPDATE books
    SET available_copies = available_copies + 1
    WHERE book_id = v_book_id;

    COMMIT;
END$$

DELIMITER ;

-- =========================
-- STORED PROCEDURE: SEARCH BOOKS
-- =========================

DELIMITER $$

CREATE PROCEDURE search_books(
    IN p_keyword VARCHAR(200)
)
BEGIN
    SELECT
        b.book_id,
        b.title,
        a.author_name,
        c.category_name,
        b.isbn,
        b.publication_year,
        b.total_copies,
        b.available_copies
    FROM books b
    JOIN authors a ON b.author_id = a.author_id
    JOIN categories c ON b.category_id = c.category_id
    WHERE b.title LIKE CONCAT('%', p_keyword, '%')
       OR a.author_name LIKE CONCAT('%', p_keyword, '%')
       OR c.category_name LIKE CONCAT('%', p_keyword, '%')
    ORDER BY b.title;
END$$

DELIMITER ;

-- =========================
-- TRIGGER
-- =========================

DELIMITER $$

CREATE TRIGGER before_issue_update
BEFORE UPDATE ON book_issues
FOR EACH ROW
BEGIN
    IF NEW.return_date IS NOT NULL THEN
        IF NEW.return_date > NEW.due_date THEN
            SET NEW.fine =
                DATEDIFF(NEW.return_date, NEW.due_date) * 5;
        ELSE
            SET NEW.fine = 0;
        END IF;

        SET NEW.status = 'RETURNED';
    END IF;
END$$

DELIMITER ;

-- =========================
-- VIEWS
-- =========================

CREATE VIEW book_details AS
SELECT
    b.book_id,
    b.title,
    a.author_name,
    c.category_name,
    b.isbn,
    b.publication_year,
    b.total_copies,
    b.available_copies
FROM books b
JOIN authors a ON b.author_id = a.author_id
JOIN categories c ON b.category_id = c.category_id;

CREATE VIEW active_issues AS
SELECT
    bi.issue_id,
    b.title,
    m.member_id,
    m.member_name,
    m.email,
    bi.issue_date,
    bi.due_date,
    DATEDIFF(CURDATE(), bi.due_date) AS overdue_days
FROM book_issues bi
JOIN books b ON bi.book_id = b.book_id
JOIN members m ON bi.member_id = m.member_id
WHERE bi.return_date IS NULL;

CREATE VIEW overdue_books AS
SELECT
    bi.issue_id,
    b.title,
    m.member_name,
    m.email,
    m.phone,
    bi.issue_date,
    bi.due_date,
    DATEDIFF(CURDATE(), bi.due_date) AS overdue_days,
    DATEDIFF(CURDATE(), bi.due_date) * 5 AS current_fine
FROM book_issues bi
JOIN books b ON bi.book_id = b.book_id
JOIN members m ON bi.member_id = m.member_id
WHERE bi.return_date IS NULL
  AND bi.due_date < CURDATE();

-- =========================
-- IMPORTANT SQL QUERIES
-- =========================

-- 1. All books
SELECT * FROM books;

-- 2. Complete book details
SELECT * FROM book_details;

-- 3. Available books
SELECT
    book_id,
    title,
    total_copies,
    available_copies
FROM books
WHERE available_copies > 0
ORDER BY title;

-- 4. Search Java books
SELECT
    b.book_id,
    b.title,
    a.author_name
FROM books b
JOIN authors a ON b.author_id = a.author_id
WHERE b.title LIKE '%Java%';

-- 5. Books by category
SELECT
    c.category_name,
    COUNT(b.book_id) AS total_books
FROM categories c
LEFT JOIN books b ON c.category_id = b.category_id
GROUP BY c.category_id, c.category_name
ORDER BY total_books DESC;

-- 6. Books by author
SELECT
    a.author_name,
    COUNT(b.book_id) AS total_books
FROM authors a
LEFT JOIN books b ON a.author_id = b.author_id
GROUP BY a.author_id, a.author_name
ORDER BY total_books DESC;

-- 7. Currently issued books
SELECT
    bi.issue_id,
    b.title,
    m.member_name,
    bi.issue_date,
    bi.due_date
FROM book_issues bi
JOIN books b ON bi.book_id = b.book_id
JOIN members m ON bi.member_id = m.member_id
WHERE bi.return_date IS NULL;

-- 8. Overdue books
SELECT * FROM overdue_books;

-- 9. Borrowing history
SELECT
    m.member_name,
    b.title,
    bi.issue_date,
    bi.due_date,
    bi.return_date,
    bi.fine,
    bi.status
FROM book_issues bi
JOIN members m ON bi.member_id = m.member_id
JOIN books b ON bi.book_id = b.book_id
ORDER BY bi.issue_date DESC;

-- 10. Most borrowed books
SELECT
    b.book_id,
    b.title,
    COUNT(bi.issue_id) AS times_borrowed
FROM books b
LEFT JOIN book_issues bi ON b.book_id = bi.book_id
GROUP BY b.book_id, b.title
ORDER BY times_borrowed DESC;

-- 11. Most active members
SELECT
    m.member_id,
    m.member_name,
    COUNT(bi.issue_id) AS books_borrowed
FROM members m
LEFT JOIN book_issues bi ON m.member_id = bi.member_id
GROUP BY m.member_id, m.member_name
ORDER BY books_borrowed DESC;

-- 12. Total fines
SELECT COALESCE(SUM(fine), 0) AS total_fine
FROM book_issues;

-- 13. Library statistics
SELECT
    (SELECT COUNT(*) FROM books) AS book_titles,
    (SELECT COALESCE(SUM(total_copies), 0) FROM books) AS total_copies,
    (SELECT COALESCE(SUM(available_copies), 0) FROM books) AS available_copies,
    (SELECT COUNT(*) FROM book_issues
     WHERE return_date IS NULL) AS currently_issued,
    (SELECT COUNT(*) FROM members
     WHERE status = 'ACTIVE') AS active_members,
    (SELECT COALESCE(SUM(fine), 0)
     FROM book_issues) AS total_fines;

-- 14. Active members
SELECT *
FROM members
WHERE status = 'ACTIVE';

-- 15. Members who never borrowed
SELECT
    m.member_id,
    m.member_name,
    m.email
FROM members m
LEFT JOIN book_issues bi
    ON m.member_id = bi.member_id
WHERE bi.issue_id IS NULL;

-- 16. Books never borrowed
SELECT
    b.book_id,
    b.title
FROM books b
LEFT JOIN book_issues bi
    ON b.book_id = bi.book_id
WHERE bi.issue_id IS NULL;

-- 17. Latest issues
SELECT
    bi.issue_id,
    b.title,
    m.member_name,
    bi.issue_date
FROM book_issues bi
JOIN books b ON bi.book_id = b.book_id
JOIN members m ON bi.member_id = m.member_id
ORDER BY bi.issue_date DESC
LIMIT 10;

-- =========================
-- PROCEDURE TEST COMMANDS
-- =========================

-- Issue a book:
-- CALL issue_book(2, 1, 14);

-- Check issues:
-- SELECT * FROM book_issues;

-- Return the issued book:
-- CALL return_book(1);

-- Search books:
-- CALL search_books('Java');

-- ============================================================
-- END OF SCRIPT
-- ============================================================
