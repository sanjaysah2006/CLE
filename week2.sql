
--Q2.1. Books That Were Beaten by Their Adaptation
--Problem Statement:
--A publisher wants to know which books were rated lower than their movie or series version.
--Show the book title, adaptation title, adaptation year, publication year, author name, book rating and
--adaptation rating. Only include books whose rating is lower than their adaptation's rating and whose
--adaptation came out within 4 years of the book. A book's rating is the average of its reviews (2
--decimals). Sort by book title.


CREATE TABLE author (
    author_id INT PRIMARY KEY,
    author_name VARCHAR(100) NOT NULL
);

INSERT INTO author (author_id, author_name)
VALUES
(1, 'Anita Rao'),
(2, 'Dev Malhotra'),
(3, 'Kiran Sethi'),
(4, 'Leela Thomas');

CREATE TABLE book (
    book_id INT PRIMARY KEY,
    author_id INT,
    title VARCHAR(200) NOT NULL,
    publish_year INT,
    FOREIGN KEY (author_id) REFERENCES author(author_id)
);

INSERT INTO book (book_id, author_id, title, publish_year)
VALUES
(101, 1, 'The Monsoon Letters', 2015),
(102, 1, 'City of Lanterns', 2018),
(103, 2, 'Code of the Hills', 2012),
(104, 3, 'The Last Tea Garden', 2019),
(105, 4, 'Silent Harbour', 2016),
(106, 2, 'Paper Kites', 2020);

CREATE TABLE adaptation (
    book_id INT PRIMARY KEY,
    type VARCHAR(20),
    title VARCHAR(200),
    release_year INT,
    rating DECIMAL(3,2),
    FOREIGN KEY (book_id) REFERENCES book(book_id)
);

INSERT INTO adaptation (book_id, type, title, release_year, rating)
VALUES
(101, 'Movie', 'Monsoon Letters', 2017, 8.10),
(102, 'Series', 'Lanterns', 2024, 7.90),
(103, 'Movie', 'Hill Code', 2014, 7.00),
(104, 'Series', 'Tea Garden', 2022, 8.60),
(105, 'Movie', 'Harbour', 2018, 6.50),
(106, 'Movie', 'Kites', 2021, 7.40);

CREATE TABLE review (
    review_id INT PRIMARY KEY,
    book_id INT,
    rating DECIMAL(3,2),
    FOREIGN KEY (book_id) REFERENCES book(book_id)
);

INSERT INTO review (review_id, book_id, rating)
VALUES
(1, 101, 7),
(2, 101, 8),
(3, 102, 6),
(4, 102, 7),
(5, 103, 8),
(6, 103, 7),
(7, 103, 9),
(8, 104, 8),
(9, 104, 8),
(10, 105, 6),
(11, 105, 7),
(12, 106, 7),
(13, 106, 7),
(14, 106, 7);


WITH Bookrating AS(
SELECT DISTINCT
    b.title as book_title,
    ad.title as adaptation_title,
    ad.release_year adaptation_year,
    b.publish_year as publication_year,
    a.author_name as author_name,
    CAST(AVG(r.rating) over (PARTITION by b.book_id ) as DECIMAL(10,2)) as book_rating,
    ad.rating as adaptation_rating
FROM author as a
join book as b on a.author_id = b.author_id
join adaptation as ad on b.book_id = ad.book_id
join review r on b.book_id = r.book_id
)
SELECT * FROM Bookrating
WHERE book_rating < adaptation_rating 
AND  adaptation_year < publication_year+4 
ORDER BY book_title;

--Q2.2. Customer Order Lookup with a Function and a Stored Procedure
--Problem Statement:
--The support team often sends a customer's order list to a partner in the USA, so dates must be in US
--format (MM/DD/YYYY).
--Part A – Create a function dbo.fn_format_us_date that takes a date and returns it as MM/DD/YYYY. For
--example, '2006-11-21 23:34:05.920' should return 11/21/2006.
--Part B – Create a procedure dbo.sp_customer_orders. It takes @customer_id as input and returns two
--output values: @order_count and @total_value. It should show the customer's orders, except cancelled
--ones (order_id, order_date_us, status, order_value), and fill the two output values. If the customer does
--not exist, show no rows and return 0 for both values.


-- ============================================================
-- Q2.2. Customer Order Lookup with a Function and a Stored Procedure
-- ============================================================

CREATE TABLE customers (
    customer_id CHAR(3) PRIMARY KEY,
    customer_name VARCHAR(100),
    city VARCHAR(50),
    signup_date DATE
);

INSERT INTO customers VALUES
('C01','Rahul Mehta','Jaipur','2025-11-02'),
('C02','Priya Nair','Kochi','2025-12-15'),
('C03','Arjun Das','Kolkata','2026-01-08'),
('C04','Fatima Sheikh','Mumbai','2026-01-20'),
('C05','Karan Malhotra','Delhi','2026-02-11'),
('C06','Sneha Kulkarni','Pune','2026-02-25');

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id CHAR(3),
    order_date DATE,
    status VARCHAR(30),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

INSERT INTO orders VALUES
(1001,'C01','2026-03-02','Delivered'),
(1002,'C02','2026-03-03','Delivered'),
(1003,'C01','2026-03-10','Delivered'),
(1004,'C03','2026-03-12','Cancelled'),
(1005,'C04','2026-03-15','Shipped'),
(1006,'C05','2026-03-18','Delivered'),
(1007,'C01','2026-04-01','Shipped'),
(1008,'C06','2026-04-03','Pending');

CREATE TABLE order_items (
    order_id INT,
    product_id VARCHAR(10),
    qty INT,
    unit_price DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

INSERT INTO order_items VALUES
(1001,'P1',2,799),(1001,'P3',5,120),
(1002,'P2',1,1999),
(1003,'P4',2,250),(1003,'P6',1,499),
(1004,'P5',1,1499),
(1005,'P1',1,799),(1005,'P2',1,1999),(1005,'P3',10,120),
(1006,'P6',3,499),
(1007,'P5',1,1499),
(1008,'P4',4,250);
GO

CREATE FUNCTION dbo.fn_format_us_date (@input_date DATETIME)
RETURNS VARCHAR(10)
AS
BEGIN
    RETURN CONVERT(VARCHAR(10), @input_date, 101);
END;
GO

CREATE PROCEDURE dbo.sp_customer_orders
    @customer_id CHAR(3),
    @order_count INT OUTPUT,
    @total_value DECIMAL(10,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @order_count = 0;
    SET @total_value = 0;

    IF NOT EXISTS (SELECT 1 FROM customers WHERE customer_id = @customer_id)
        RETURN;

    SELECT
        o.order_id,
        dbo.fn_format_us_date(o.order_date) AS order_date_us,
        o.status,
        CAST(SUM(oi.qty * oi.unit_price) AS DECIMAL(10,2)) AS order_value
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.customer_id = @customer_id
      AND o.status <> 'Cancelled'
    GROUP BY o.order_id, o.order_date, o.status
    ORDER BY o.order_date;

    SELECT
        @order_count = COUNT(*),
        @total_value = COALESCE(SUM(order_value), 0)
    FROM (
        SELECT o.order_id, SUM(oi.qty * oi.unit_price) AS order_value
        FROM orders o
        JOIN order_items oi ON oi.order_id = o.order_id
        WHERE o.customer_id = @customer_id
          AND o.status <> 'Cancelled'
        GROUP BY o.order_id
    ) x;
END;
GO

DECLARE @cnt INT, @val DECIMAL(10,2);
EXEC dbo.sp_customer_orders
    @customer_id = 'C01',
    @order_count = @cnt OUTPUT,
    @total_value = @val OUTPUT;
SELECT @cnt AS order_count, @val AS total_value;

DECLARE @cnt99 INT, @val99 DECIMAL(10,2);
EXEC dbo.sp_customer_orders
    @customer_id = 'C99',
    @order_count = @cnt99 OUTPUT,
    @total_value = @val99 OUTPUT;
SELECT @cnt99 AS order_count, @val99 AS total_value;
GO


-- Q2.3. Generate Remaining Dates of the Month with a Stored Procedure
--       Problem Statement:
--       Use the table datepro. Create a procedure sp_dateproc that shows every date from the date in Dateint
--       up to the last day of that month, in order.
--       Run it for ids 101, 102 and 104, passed as one text value '101,102,104'. Also change Datentime into a
--       normal date and time by removing the 'T' and the time zone part. Save all rows into a table datepro_data
--       and show id, Dateint, Datentime and Dates.
--       For example, for 20220510 the output shows 10th May to 31st May.


CREATE TABLE datepro (
    id INT PRIMARY KEY,
    Dateint INT,
    Datentime VARCHAR(50)
);

INSERT INTO datepro VALUES
(101,20220510,'2022-05-10T09:30:00+05:30'),
(102,20220227,'2022-02-27T18:45:00+05:30'),
(103,20220925,'2022-09-25T12:16:00+05:30'),
(104,20221229,'2022-12-29T07:05:00+05:30'),
(105,20221228,'2022-12-28T11:29:00+05:30');

CREATE TABLE datepro_data (
    id INT,
    Dateint INT,
    Datentime VARCHAR(20),
    Dates DATE
);
GO

CREATE PROCEDURE dbo.sp_dateproc @ids VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM datepro_data;

    ;WITH SelectedIds AS (
        SELECT TRY_CAST(value AS INT) AS id
        FROM STRING_SPLIT(@ids, ',')
    ),
    SourceRows AS (
        SELECT
            d.id,
            d.Dateint,
            CONVERT(VARCHAR(16), TRY_CONVERT(DATETIMEOFFSET, d.Datentime), 120) AS Datentime,
            TRY_CONVERT(DATE, CONVERT(CHAR(8), d.Dateint), 112) AS StartDate
        FROM datepro d
        JOIN SelectedIds s ON s.id = d.id
    ),
    DateSeries AS (
        SELECT id, Dateint, Datentime, StartDate AS Dates,
               EOMONTH(StartDate) AS LastDate
        FROM SourceRows
        WHERE StartDate IS NOT NULL

        UNION ALL

        SELECT id, Dateint, Datentime, DATEADD(DAY, 1, Dates), LastDate
        FROM DateSeries
        WHERE Dates < LastDate
    )
    INSERT INTO datepro_data (id, Dateint, Datentime, Dates)
    SELECT id, Dateint, Datentime, Dates
    FROM DateSeries
    OPTION (MAXRECURSION 1000);

    SELECT id, Dateint, Datentime, Dates
    FROM datepro_data
    ORDER BY id, Dates;
END;
GO

EXEC dbo.sp_dateproc '101,102,104';
GO

--Q2.4. Open Elective Subject Allotment
--Problem Statement:
--A college wants to give Open Elective subjects to its students. Each student picks 5 subjects in order of
--preference (1 = first choice). Students with a higher GPA get their choice first. Each subject has a limited
--number of seats. If a student's first choice is full, check the second choice, then the third, and so on. If all
--five choices are full, the student is marked as unallotted.
--The seat numbers are kept small on purpose so that some subjects fill up.

CREATE TABLE StudentDetails (
    StudentId BIGINT PRIMARY KEY,
    StudentName VARCHAR(100),
    GPA DECIMAL(3,2),
    Branch VARCHAR(20),
    Section CHAR(1)
);

INSERT INTO StudentDetails VALUES
(159103036,'Mohit Agarwal',8.90,'CCE','A'),
(159103037,'Rohit Agarwal',5.20,'CCE','A'),
(159103038,'Shohit Garg',7.10,'CCE','B'),
(159103039,'Mrinal Malhotra',7.90,'CCE','A'),
(159103040,'Mehreet Singh',5.60,'CCE','A'),
(159103041,'Arjun Tehlan',9.20,'CCE','B');

CREATE TABLE SubjectDetails (
    SubjectId VARCHAR(10) PRIMARY KEY,
    SubjectName VARCHAR(100),
    MaxSeats INT,
    RemainingSeats INT
);

INSERT INTO SubjectDetails VALUES
('PO1491','Basics of Political Science',60,2),
('PO1492','Basics of Accounting',120,1),
('PO1493','Basics of Financial Markets',90,1),
('PO1494','Eco philosophy',60,1),
('PO1495','Automotive Trends',60,0);

CREATE TABLE StudentPreference (
    StudentId BIGINT,
    SubjectId VARCHAR(10),
    Preference INT,
    PRIMARY KEY (StudentId, Preference),
    UNIQUE (StudentId, SubjectId),
    FOREIGN KEY (StudentId) REFERENCES StudentDetails(StudentId),
    FOREIGN KEY (SubjectId) REFERENCES SubjectDetails(SubjectId)
);

INSERT INTO StudentPreference VALUES
(159103036,'PO1491',1),(159103036,'PO1492',2),(159103036,'PO1493',3),(159103036,'PO1494',4),(159103036,'PO1495',5),
(159103037,'PO1494',1),(159103037,'PO1495',2),(159103037,'PO1492',3),(159103037,'PO1491',4),(159103037,'PO1493',5),
(159103038,'PO1492',1),(159103038,'PO1491',2),(159103038,'PO1494',3),(159103038,'PO1495',4),(159103038,'PO1493',5),
(159103039,'PO1491',1),(159103039,'PO1492',2),(159103039,'PO1495',3),(159103039,'PO1493',4),(159103039,'PO1494',5),
(159103040,'PO1492',1),(159103040,'PO1494',2),(159103040,'PO1491',3),(159103040,'PO1493',4),(159103040,'PO1495',5),
(159103041,'PO1491',1),(159103041,'PO1493',2),(159103041,'PO1492',3),(159103041,'PO1494',4),(159103041,'PO1495',5);

CREATE TABLE Allotments (
    SubjectId VARCHAR(10),
    StudentId BIGINT
);

CREATE TABLE UnallotedStudents (
    StudentId BIGINT PRIMARY KEY
);
GO

CREATE PROCEDURE dbo.sp_allot_subjects
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM Allotments;
    DELETE FROM UnallotedStudents;

    DECLARE @student_id BIGINT, @subject_id VARCHAR(10), @remaining INT;

    DECLARE student_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT StudentId
        FROM StudentDetails
        ORDER BY GPA DESC, StudentId;

    OPEN student_cursor;
    FETCH NEXT FROM student_cursor INTO @student_id;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @subject_id = NULL;

        SELECT TOP (1) @subject_id = sp.SubjectId
        FROM StudentPreference sp
        JOIN SubjectDetails sd ON sd.SubjectId = sp.SubjectId
        WHERE sp.StudentId = @student_id
          AND sd.RemainingSeats > 0
        ORDER BY sp.Preference;

        IF @subject_id IS NOT NULL
        BEGIN
            INSERT INTO Allotments(SubjectId, StudentId)
            VALUES (@subject_id, @student_id);

            UPDATE SubjectDetails
            SET RemainingSeats = RemainingSeats - 1
            WHERE SubjectId = @subject_id;
        END
        ELSE
        BEGIN
            INSERT INTO UnallotedStudents(StudentId)
            VALUES (@student_id);
        END;

        FETCH NEXT FROM student_cursor INTO @student_id;
    END;

    CLOSE student_cursor;
    DEALLOCATE student_cursor;

    SELECT SubjectId, StudentId FROM Allotments;
    SELECT StudentId FROM UnallotedStudents;
    SELECT * FROM SubjectDetails;
END;
GO

EXEC dbo.sp_allot_subjects;
GO

--Q2.5. Safe Payment Posting with Error Handling
--Problem Statement:
--Payments should be added only through a stored procedure. The procedure checks the rules, saves the
--payment inside a transaction and, if something goes wrong, undoes the change and saves the error in
--an error_log table.

--Create dbo.sp_record_payment with the inputs @payment_id, @order_id, @amount and @method.
--Check the rules in this order and raise an error with these numbers and messages: 50001 'Order not
--found'; 50002 'Order is cancelled'; 50003 'Amount must be greater than zero'; 50004 'Payment exceeds
--order value' (when the amount already paid plus @amount is more than the order value).
--The error_log table has these columns: log_id (auto number), error_time (default current date and time),
--proc_name, error_number, error_message and input_values (all inputs joined with commas).

CREATE TABLE payments (
    payment_id VARCHAR(10) PRIMARY KEY,
    order_id INT,
    payment_date DATE,
    amount DECIMAL(10,2),
    method VARCHAR(30)
);

INSERT INTO payments VALUES
('PM01',1001,'2026-03-02',2198,'UPI'),
('PM02',1002,'2026-03-03',1000,'Card'),
('PM03',1002,'2026-03-05',999,'Card'),
('PM04',1003,'2026-03-10',500,'UPI'),
('PM05',1005,'2026-03-15',3998,'NetBanking'),
('PM06',1006,'2026-03-18',1497,'UPI'),
('PM07',1009,'2026-04-02',750,'UPI'),
('PM08',1004,'2026-03-12',1499,'Card');

CREATE TABLE error_log (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    error_time DATETIME2 DEFAULT SYSDATETIME(),
    proc_name VARCHAR(128),
    error_number INT,
    error_message VARCHAR(4000),
    input_values VARCHAR(500)
);
GO

CREATE PROCEDURE dbo.sp_record_payment
    @payment_id VARCHAR(10),
    @order_id INT,
    @amount DECIMAL(10,2),
    @method VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM orders WHERE order_id = @order_id)
            THROW 50001, 'Order not found', 1;

        IF EXISTS (SELECT 1 FROM orders WHERE order_id = @order_id AND status = 'Cancelled')
            THROW 50002, 'Order is cancelled', 1;

        IF @amount <= 0
            THROW 50003, 'Amount must be greater than zero', 1;

        DECLARE @order_value DECIMAL(10,2), @already_paid DECIMAL(10,2);

        SELECT @order_value = SUM(qty * unit_price)
        FROM order_items
        WHERE order_id = @order_id;

        SELECT @already_paid = COALESCE(SUM(amount), 0)
        FROM payments
        WHERE order_id = @order_id;

        IF @already_paid + @amount > COALESCE(@order_value, 0)
            THROW 50004, 'Payment exceeds order value', 1;

        INSERT INTO payments(payment_id, order_id, payment_date, amount, method)
        VALUES (@payment_id, @order_id, CAST(GETDATE() AS DATE), @amount, @method);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        INSERT INTO error_log(proc_name, error_number, error_message, input_values)
        VALUES (
            'sp_record_payment',
            ERROR_NUMBER(),
            ERROR_MESSAGE(),
            CONCAT(@payment_id, ',', @order_id, ',', @amount, ',', @method)
        );
    END CATCH;
END;
GO

EXEC dbo.sp_record_payment 'PM09',1007,1499,'Card';
EXEC dbo.sp_record_payment 'PM10',1010,500,'UPI';
EXEC dbo.sp_record_payment 'PM11',1004,100,'UPI';
EXEC dbo.sp_record_payment 'PM12',1003,0,'UPI';
EXEC dbo.sp_record_payment 'PM13',1003,600,'UPI';
EXEC dbo.sp_record_payment 'PM14',1003,499,'UPI';

SELECT payment_id, order_id, amount, method
FROM payments
WHERE payment_id IN ('PM09','PM14');

SELECT log_id, proc_name, error_number, error_message, input_values
FROM error_log
ORDER BY log_id;
GO

--Q2.6. Rank Employees by Salary Within Each Department
--Problem Statement:
--HR wants to compare three ways of numbering employees by salary when two people earn the same,
--and then find the top three salary levels in each department.
--Part A – Inside each department, highest salary first, show three columns for every employee: row_num
--– a unique number 1, 2, 3... (if salaries are the same, the smaller emp_id comes first); rnk – equal
--salaries get the same number and the next number is skipped (1, 1, 3); dense_rnk – equal salaries get
--the same number and nothing is skipped (1, 1, 2). Sort by department, salary (high to low) and emp_id.

--Part B – “Top 3” here means the three highest different salary amounts. Show the employees who are in
--the top three salary levels of their department.

CREATE TABLE emp_salary (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(100),
    department VARCHAR(50),
    salary INT
);

INSERT INTO emp_salary VALUES
(1,'Aditi','Engineering',100000),
(2,'Bharat','Engineering',100000),
(3,'Chetan','Engineering',90000),
(4,'Divya','Engineering',80000),
(5,'Eshan','Engineering',80000),
(6,'Farhan','Engineering',70000),
(7,'Gauri','Sales',75000),
(8,'Harsh','Sales',72000),
(9,'Ira','Sales',72000),
(10,'Jatin','Support',50000),
(11,'Kavya','HR',60000),
(12,'Lokesh','HR',60000);

-- Part A
SELECT
    emp_id,
    emp_name,
    department,
    salary,
    ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC, emp_id) AS row_num,
    RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rnk,
    DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS dense_rnk
FROM emp_salary
ORDER BY
    CASE department WHEN 'Engineering' THEN 1 WHEN 'HR' THEN 2 WHEN 'Sales' THEN 3 ELSE 4 END,
    salary DESC,
    emp_id;

-- Part B: top three distinct salary levels in each department
WITH SalaryLevels AS (
    SELECT *,
           DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS salary_level
    FROM emp_salary
)
SELECT department, emp_name, salary, salary_level
FROM SalaryLevels
WHERE salary_level <= 3
ORDER BY
    CASE department WHEN 'Engineering' THEN 1 WHEN 'HR' THEN 2 WHEN 'Sales' THEN 3 ELSE 4 END,
    salary_level,
    emp_id;
GO

--Q2.7. Book and Author View with Comma-Separated Names
--Problem Statement:
--Create a view vw_book_author that shows each book title, its author names and how many books each
--of those authors has written. If a book has more than one author, show the names separated by commas
--in alphabetical order, and show the book counts in the same order.

--For example, The Glass Fort is written by Meera Kaul (3 books) and Tanvi Bose (1 book), so it shows
--'Meera Kaul,Tanvi Bose' and '3,1'.

CREATE TABLE Books (
    BookID INT PRIMARY KEY,
    Title VARCHAR(200)
);

INSERT INTO Books VALUES
(1,'Desert Winds'),(2,'River Songs'),(3,'The Glass Fort'),
(4,'Night Train'),(5,'Salt and Stone'),(6,'Paper Moons');

CREATE TABLE Authors (
    AuthorID INT PRIMARY KEY,
    AuthorName VARCHAR(100)
);

INSERT INTO Authors VALUES
(1,'Meera Kaul'),(2,'Rohan Sen'),(3,'Tanvi Bose'),(4,'Ishita Roy');

CREATE TABLE BookAuthors (
    BookID INT,
    AuthorID INT,
    PRIMARY KEY (BookID, AuthorID),
    FOREIGN KEY (BookID) REFERENCES Books(BookID),
    FOREIGN KEY (AuthorID) REFERENCES Authors(AuthorID)
);

INSERT INTO BookAuthors VALUES
(1,1),(2,2),(3,1),(3,3),(4,4),(5,2),(6,2),(6,1);
GO

CREATE VIEW dbo.vw_book_author
AS
WITH AuthorBookCounts AS (
    SELECT ba.AuthorID, COUNT(DISTINCT ba.BookID) AS Book_count
    FROM BookAuthors ba
    GROUP BY ba.AuthorID
)
SELECT
    b.Title AS Booktitle,
    STRING_AGG(CAST(a.AuthorName AS VARCHAR(MAX)), ',')
        WITHIN GROUP (ORDER BY a.AuthorName) AS Authorname,
    STRING_AGG(CAST(abc.Book_count AS VARCHAR(20)), ',')
        WITHIN GROUP (ORDER BY a.AuthorName) AS Book_count
FROM Books b
JOIN BookAuthors ba ON ba.BookID = b.BookID
JOIN Authors a ON a.AuthorID = ba.AuthorID
JOIN AuthorBookCounts abc ON abc.AuthorID = a.AuthorID
GROUP BY b.BookID, b.Title;
GO

SELECT * FROM dbo.vw_book_author ORDER BY Booktitle;
GO

--Q2.8. Revised Salary and Comparison with the Previously Hired Employee
--Problem Statement:
--HR wants a view that shows each employee's new salary and compares their salary with the person
--hired just before them.
--Rules: Inc_Sal is the new salary – Chicago gets 5% more, Boston 3%, Dallas and New York 10%, all
--other places no increase. Previous_emp_sal is the salary of the person hired just before (by Hiredate).
--message is 'Salary is greater than previously hired employee', 'Salary is less than previously hired
--employee', 'Salary is same as previously hired employee', or 'No previous employee' for the first person
--hired. Remove the middle name from Full_name (keep the first and last word). Show 'NA' when
--deptname or loc is missing. Create the view VW_EMP_DEPT and show it sorted by Hiredate.

CREATE TABLE Employee (
    Empid INT PRIMARY KEY,
    Full_name VARCHAR(100),
    Salary DECIMAL(10,2),
    Hiredate DATE,
    deptid INT NULL
);

INSERT INTO Employee VALUES
(1012,'Raji K Nair',35500,'2018-04-09',1),
(1009,'Jeena',12000,'2018-11-17',2),
(1005,'Nidhi R Shetty',10000,'2019-01-16',3),
(1011,'Jiya Shetty',45500,'2019-03-27',4),
(1003,'Arun Kumar Menon',45500,'2019-08-02',5),
(1007,'Farah Ali',30000,'2020-02-10',NULL),
(1001,'Manoj P Iyer',52000,'2020-07-15',2);

CREATE TABLE Dept_loc (
    deptid INT PRIMARY KEY,
    deptname VARCHAR(100),
    loc VARCHAR(50)
);

INSERT INTO Dept_loc VALUES
(1,'HR','Dallas'),
(2,'Sales','Chicago'),
(3,'Customer service','Chicago'),
(4,'IT','Boston'),
(5,'Research','Seattle'),
(6,'Legal','New York');
GO

CREATE VIEW dbo.VW_EMP_DEPT
AS
WITH EmployeeCompare AS (
    SELECT
        e.Empid,
        CASE
            WHEN CHARINDEX(' ', LTRIM(RTRIM(e.Full_name))) = 0
                THEN LTRIM(RTRIM(e.Full_name))
            ELSE LEFT(LTRIM(RTRIM(e.Full_name)),
                      CHARINDEX(' ', LTRIM(RTRIM(e.Full_name))) - 1)
                 + ' ' +
                 RIGHT(LTRIM(RTRIM(e.Full_name)),
                       CHARINDEX(' ', REVERSE(LTRIM(RTRIM(e.Full_name)))) - 1)
        END AS Full_name,
        e.Salary,
        CAST(e.Salary *
            CASE d.loc
                WHEN 'Chicago' THEN 1.05
                WHEN 'Boston' THEN 1.03
                WHEN 'Dallas' THEN 1.10
                WHEN 'New York' THEN 1.10
                ELSE 1.00
            END AS DECIMAL(10,2)) AS Inc_Sal,
        LAG(e.Salary) OVER (ORDER BY e.Hiredate, e.Empid) AS Previous_emp_sal,
        e.Hiredate,
        COALESCE(d.deptname, 'NA') AS deptname,
        COALESCE(d.loc, 'NA') AS loc
    FROM Employee e
    LEFT JOIN Dept_loc d ON d.deptid = e.deptid
)
SELECT
    Empid,
    Full_name,
    Salary,
    Inc_Sal,
    Previous_emp_sal,
    Hiredate,
    deptname,
    loc,
    CASE
        WHEN Previous_emp_sal IS NULL THEN 'No previous employee'
        WHEN Inc_Sal > Previous_emp_sal THEN 'Salary is greater than previously hired employee'
        WHEN Inc_Sal < Previous_emp_sal THEN 'Salary is less than previously hired employee'
        ELSE 'Salary is same as previously hired employee'
    END AS message
FROM EmployeeCompare;
GO

SELECT * FROM dbo.VW_EMP_DEPT ORDER BY Hiredate, Empid;
GO

--Q2.9. Running Total and 3-Month Moving Average of Revenue
--Problem Statement:
--The sales head wants, for each region and month: the running total of revenue, the average of the last 3
--months (this month and the two before it) and this month's share of the region's total revenue in percent
--(2 decimals).

CREATE TABLE monthly_sales (
    month_start DATE,
    region VARCHAR(20),
    revenue INT,
    PRIMARY KEY (month_start, region)
);

INSERT INTO monthly_sales VALUES
('2026-01-01','North',120000),
('2026-02-01','North',135000),
('2026-03-01','North',128000),
('2026-04-01','North',150000),
('2026-05-01','North',160000),
('2026-06-01','North',145000),
('2026-01-01','South',90000),
('2026-02-01','South',85000),
('2026-03-01','South',110000),
('2026-04-01','South',105000),
('2026-05-01','South',130000),
('2026-06-01','South',140000);

SELECT
    region,
    month_start,
    revenue,
    SUM(revenue) OVER (
        PARTITION BY region
        ORDER BY month_start
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total,
    CAST(AVG(CAST(revenue AS DECIMAL(18,2))) OVER (
        PARTITION BY region
        ORDER BY month_start
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS DECIMAL(18,2)) AS moving_avg_3m,
    CAST(100.0 * revenue / SUM(revenue) OVER (PARTITION BY region)
         AS DECIMAL(10,2)) AS pct_of_total
FROM monthly_sales
ORDER BY region, month_start;
GO

--Q2.10. Keep the Latest Record per Customer
--Problem Statement:
--Every change to a customer is saved as a new row in customer_updates, and sometimes the same row
--comes twice. We only need the latest row for each customer. If two rows have the same updated_at,
--keep the one with the bigger load_id.
--Part A – Show the latest row for each customer. Part B – Show how many rows were loaded, how many
--are kept and how many are removed.
--For example, C01 has two rows at 2026-05-03 09:00 – load 6 (Delhi) wins over load 3 (Jaipur).
--Note: Every change in the source system is loaded as a new row. load_id increases with every load.


CREATE TABLE customer_updates (
    load_id INT PRIMARY KEY,
    customer_id VARCHAR(10),
    email VARCHAR(100),
    city VARCHAR(50),
    updated_at DATETIME2
);

INSERT INTO customer_updates VALUES
(1,'C01','rahul@mail.com','Jaipur','2026-05-01 10:00:00'),
(2,'C02','priya@mail.com','Kochi','2026-05-01 10:05:00'),
(3,'C01','rahul.m@mail.com','Jaipur','2026-05-03 09:00:00'),
(4,'C03','arjun@mail.com','Kolkata','2026-05-02 12:00:00'),
(5,'C02','priya@mail.com','Kochi','2026-05-01 10:05:00'),
(6,'C01','rahul.m@mail.com','Delhi','2026-05-03 09:00:00'),
(7,'C04','fatima@mail.com','Mumbai','2026-05-04 08:30:00'),
(8,'C03','arjun.d@mail.com','Kolkata','2026-05-05 18:45:00');

-- Part A
WITH RankedUpdates AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY customer_id
               ORDER BY updated_at DESC, load_id DESC
           ) AS rn
    FROM customer_updates
)
SELECT customer_id, email, city, updated_at, load_id
INTO customer_latest
FROM RankedUpdates
WHERE rn = 1;

SELECT * FROM customer_latest ORDER BY customer_id;

-- Part B
SELECT
    (SELECT COUNT(*) FROM customer_updates) AS rows_loaded,
    (SELECT COUNT(*) FROM customer_latest) AS rows_kept,
    (SELECT COUNT(*) FROM customer_updates)
      - (SELECT COUNT(*) FROM customer_latest) AS rows_removed;
GO

--Q2.11. Longest Login Streak per User
--Problem Statement:
--For each user, find the longest run of days in a row on which they logged in. Show the start date, end
--date and number of days. If a user has two runs of the same length, show the latest one.
--Note: One row per user per day the user logged in.

CREATE TABLE logins (
    user_id VARCHAR(10),
    login_date DATE,
    PRIMARY KEY (user_id, login_date)
);

INSERT INTO logins VALUES
('U1','2026-03-01'),('U1','2026-03-02'),('U1','2026-03-03'),
('U1','2026-03-05'),('U1','2026-03-06'),('U1','2026-03-07'),
('U2','2026-03-01'),('U2','2026-03-03'),('U2','2026-03-04'),
('U2','2026-03-05'),('U2','2026-03-06'),('U2','2026-03-10'),
('U3','2026-03-02'),
('U4','2026-03-01'),('U4','2026-03-02'),('U4','2026-03-04'),
('U4','2026-03-05'),('U4','2026-03-08'),('U4','2026-03-09');

WITH NumberedLogins AS (
    SELECT
        user_id,
        login_date,
        DATEADD(DAY,
            -CAST(ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY login_date) AS INT),
            login_date) AS streak_group
    FROM logins
),
Streaks AS (
    SELECT
        user_id,
        MIN(login_date) AS streak_start,
        MAX(login_date) AS streak_end,
        COUNT(*) AS streak_days
    FROM NumberedLogins
    GROUP BY user_id, streak_group
),
RankedStreaks AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY user_id
               ORDER BY streak_days DESC, streak_end DESC
           ) AS rn
    FROM Streaks
)
SELECT user_id, streak_start, streak_end, streak_days
INTO longest_streak
FROM RankedStreaks
WHERE rn = 1;

SELECT * FROM longest_streak ORDER BY user_id;
GO
