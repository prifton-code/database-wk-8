-- Library Management System Database
-- Created by: [PRIFTON]
-- Date: [20-10-2025]

-- Create the database
CREATE DATABASE IF NOT EXISTS library_management;
USE library_management;

-- 1. Members Table
CREATE TABLE members (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    join_date DATE NOT NULL,
    membership_status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
    total_books_borrowed INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_email_format CHECK (email LIKE '%@%.%')
);

-- 2. Authors Table
CREATE TABLE authors (
    author_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    birth_year INT,
    death_year INT,
    nationality VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_author_name (first_name, last_name)
);

-- 3. Publishers Table
CREATE TABLE publishers (
    publisher_id INT AUTO_INCREMENT PRIMARY KEY,
    publisher_name VARCHAR(100) NOT NULL UNIQUE,
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Books Table
CREATE TABLE books (
    book_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    author_id INT NOT NULL,
    publisher_id INT NOT NULL,
    isbn VARCHAR(20) UNIQUE NOT NULL,
    publication_year INT,
    genre VARCHAR(50) NOT NULL,
    total_copies INT NOT NULL DEFAULT 1 CHECK (total_copies >= 0),
    available_copies INT NOT NULL DEFAULT 1 CHECK (available_copies >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (author_id) REFERENCES authors(author_id) ON DELETE CASCADE,
    FOREIGN KEY (publisher_id) REFERENCES publishers(publisher_id) ON DELETE CASCADE,
    INDEX idx_book_title (title),
    INDEX idx_book_genre (genre)
);

-- 5. Borrowings Table (Transactions)
CREATE TABLE borrowings (
    borrowing_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    member_id INT NOT NULL,
    borrow_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE NULL,
    status ENUM('borrowed', 'returned', 'overdue') DEFAULT 'borrowed',
    fine_amount DECIMAL(8, 2) DEFAULT 0.00 CHECK (fine_amount >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE,
    CHECK (due_date >= borrow_date),
    CHECK (return_date IS NULL OR return_date >= borrow_date),
    INDEX idx_borrowing_dates (borrow_date, due_date),
    INDEX idx_borrowing_status (status)
);

-- 6. Fines Table
CREATE TABLE fines (
    fine_id INT AUTO_INCREMENT PRIMARY KEY,
    borrowing_id INT NOT NULL UNIQUE,
    member_id INT NOT NULL,
    amount DECIMAL(8, 2) NOT NULL CHECK (amount >= 0),
    paid_amount DECIMAL(8, 2) DEFAULT 0.00 CHECK (paid_amount >= 0),
    status ENUM('pending', 'paid', 'waived') DEFAULT 'pending',
    issued_date DATE NOT NULL,
    paid_date DATE NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (borrowing_id) REFERENCES borrowings(borrowing_id) ON DELETE CASCADE,
    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE,
    CHECK (paid_amount <= amount),
    INDEX idx_fine_status (status)
);

--  Sample data for demonstration
INSERT INTO members (first_name, last_name, email, phone, join_date) VALUES
('Alice', 'Johnson', 'alice.johnson@email.com', '+254 701 555-0101', '2024-01-15'),
('Bob', 'Smith', 'bob.smith@email.com', '+254 702 555-0102', '2024-02-20'),
('Carol', 'Davis', 'carol.davis@email.com', '+254 703 555-0103', '2024-03-10');

INSERT INTO authors (first_name, last_name, birth_year, nationality) VALUES
('George', 'Orwell', 1903, 'British'),
('J.K.', 'Rowling', 1965, 'British'),
('Stephen', 'King', 1947, 'American');

INSERT INTO publishers (publisher_name, address, phone) VALUES
('Penguin Books', '123 Book Lane, London', '+254 704 555-0201'),
('Scholastic', '456 Reading Rd, New York', '+254 705 555-0202'),
('Random House', '789 Library St, Chicago', '+254 706 555-0203');

INSERT INTO books (title, author_id, publisher_id, isbn, publication_year, genre, total_copies, available_copies) VALUES
('1984', 1, 1, '978-0451524935', 1949, 'Dystopian', 5, 5),
('Harry Potter and the Philosopher''s Stone', 2, 2, '978-0439708180', 1997, 'Fantasy', 3, 3),
('The Shining', 3, 3, '978-0307743657', 1977, 'Horror', 4, 4);

-- Sample borrowing record
INSERT INTO borrowings (book_id, member_id, borrow_date, due_date, status) VALUES
(1, 1, '2024-06-01', '2024-06-15', 'borrowed');

-- Update available copies after borrowing
UPDATE books SET available_copies = available_copies - 1 WHERE book_id = 1;
UPDATE members SET total_books_borrowed = total_books_borrowed + 1 WHERE member_id = 1;

-- Create a view for currently borrowed books
CREATE VIEW current_borrowings AS
SELECT 
    m.first_name, 
    m.last_name, 
    b.title, 
    br.borrow_date, 
    br.due_date,
    DATEDIFF(CURRENT_DATE, br.due_date) AS days_overdue
FROM borrowings br
JOIN members m ON br.member_id = m.member_id
JOIN books b ON br.book_id = b.book_id
WHERE br.status = 'borrowed';

-- Create a view for book availability
CREATE VIEW book_availability AS
SELECT 
    b.title, 
    a.first_name AS author_first, 
    a.last_name AS author_last,
    b.available_copies,
    b.total_copies,
    (b.available_copies > 0) AS is_available
FROM books b
JOIN authors a ON b.author_id = a.author_id;

-- Display database information
SELECT 'Library Management Database created successfully!' AS status;
SELECT COUNT(*) AS total_tables FROM information_schema.tables 
WHERE table_schema = 'library_management';

-- Show sample data
SELECT 'Sample Members:' AS info;
SELECT * FROM members LIMIT 3;

SELECT 'Sample Books:' AS info;
SELECT b.title, a.first_name, a.last_name, b.genre 
FROM books b 
JOIN authors a ON b.author_id = a.author_id 
LIMIT 3;
