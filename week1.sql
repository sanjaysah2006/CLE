--Q1.1. Create, Load, Update and Roll Back the Course Batches Table
--Problem Statement:
--EduLearn Institute is starting new batches for its subjects. The academic team wants a table called
--course_batches with proper constraints so that wrong data cannot be entered. After loading the first
--batches, a trainer has to be assigned and some batches have to be opened. During this work an
--operator runs a DELETE by mistake, and the change must be undone with a transaction rollback.
--Create the table with the structure below. batch_id is the primary key, subject_id cannot be NULL,
--capacity must be greater than 0 (CHECK constraint), and status must default to 'Planned' when no value
--is given.

create table course_batches (
	batch_id int primary key,
	subject_id varchar(5) not null,
	batch_name varchar(40) not null,
	start_date date not null,
	capacity int check (capacity >0),
	trainer varchar(40),
	status varchar(10) default 'Planned'
);

select * from course_batches;

insert into course_batches (batch_id,subject_id,batch_name,start_date,capacity,trainer) values
	(1 ,'S01', 'SQL Morning Batch', '2026-04-01', 30,null),
	(2 ,'S02', 'Python Weekend Batch', '2026-04-05', 25, 'Ritu Sharma'),
	(3 ,'S03', 'Visualization Evening', '2026-05-10', 20,null),
	(4, 'S01', 'SQL Evening Batch', '2026-03-20', 30, 'Amit Bansal');

insert into course_batches (batch_id,subject_id,batch_name,start_date,capacity) values
	(5,'S04', 'Stats Crash Course', '2026-04-15', 0);

UPDATE course_batches
SET trainer = CASE
    WHEN batch_id = 1 THEN 'Neha Joshi'
    WHEN batch_id = 3 THEN 'Ritu Sharma'
END
WHERE batch_id IN (1, 3);

BEGIN Transaction;

Delete from course_batches where status ='Planned';

ROLLBACK Transaction;

update course_batches
	set status = 'Open'
	where start_date <= '2026-04-01';

--Q1.2. Admissions Desk List for Jaipur and Delhi
--Problem Statement:
--The admissions desk of EduLearn is calling recently joined students from Jaipur and Delhi. They need a
--list of students who live in Jaipur or Delhi and joined between 1st February 2026 and 31st March 2026
--(both dates included), with the most recent joiner first. They also need a separate list of all distinct cities
--the institute has students from, so they can plan the next campaign. Cities that were not captured
--(NULL) must not appear in that list.

--For example, Kabir Singh lives in Delhi but joined on 2026-01-18, so he must not appear in the first list.
--Note: StudentId is the primary key. Some contact details were never captured and are stored as NULL.

CREATE TABLE students (
    student_id INT PRIMARY KEY,
    student_name VARCHAR(100) not null,
    gender VARCHAR(10) not null,
    city VARCHAR(100),
    email VARCHAR(150),
    phone VARCHAR(15),
    dob DATE,
    join_date DATE not null
);

INSERT INTO students
(student_id, student_name, gender, city, email, phone, dob, join_date)
VALUES
(101,'Aarav Sharma','M','Jaipur','aarav.sharma@gmail.com','9876543210','2004-05-12','2026-01-05'),
(102,'Diya Patel','F','Ahmedabad','diya.patel@yahoo.com',NULL,'2003-11-23','2026-01-10'),
(103,'Kabir Singh','M', 'Delhi', NULL, '9812345678', '2004-02-02', '2026-01-18'),
(104,'Meera Iyer','F', 'Chennai', 'meera.iyer@outlook.com', '9900112233', NULL, '2026-02-03'),
(105,'Rohan Verma', 'M', 'Jaipur', 'rohan.verma@gmail.com', '9811122233', '2005-07-30', '2026-02-14'),
(106,'Sana Khan', 'F', 'Delhi', NULL, NULL, NULL, '2026-02-20'),
(107,'Ishaan Gupta', 'M', 'Pune', 'ishaan.gupta@gmail.com', '9822001100', '2004-09-09', '2026-03-01'),
(108,'Ananya Rao', 'F', NULL, NULL, NULL, '2003-12-19', '2026-03-05'),
(109, 'Vikram Joshi', 'M', 'Jaipur', 'vikram.joshi@yahoo.com', '9876501234', '2004-01-25', '2026-03-11'),
(110, 'Neha Kapoor', 'F', 'Mumbai', 'neha.kapoor@gmail.com', '9800098000', '2005-03-14', '2026-03-20');

select student_id,student_name,city,join_date 
	into call_list
	from students 
	where city in ('Delhi','Jaipur') and 
	join_date between '2026-02-01' and '2026-04-01';
	

select * from call_list order by join_date desc;

select city 
	into campaign_cities 
	from students 
	where city is not null 
	group by city;


select * from campaign_cities;


--Q1.3. Clean Student Contact Details with Built-in Functions
--Problem Statement:
--Before the student list is shared with the placement team, the contact details must be cleaned. Names
--were typed by hand, so some have extra spaces and mixed case. Phone numbers must never be shared
--in full. The placement team also wants to know how long each student has been with the institute.
--Use the students table above and produce one row per student with these columns: student_id;
--clean_name = the name in UPPER case with leading and trailing spaces removed; email_user = the part
--of the email before '@'; email_domain = the part after '@'; when the email is NULL both of these must
--show 'Not Provided'; masked_phone = 'XXXXXX' followed by the last 4 digits of the phone, or 'Not
--Provided' when phone is NULL; join_month = the month name of join_date (for example January);
--days_with_us = number of days from join_date to 2026-10-01.
--For example, ' aarav sharma ' becomes 'AARAV SHARMA', and phone 9876543210 becomes
--XXXXXX3210.

select
    student_id,
    UPPER(TRIM(student_name)) AS student_name,
    ISNULL(LEFT(email, CHARINDEX('@', email) - 1), 'Not Provided') AS mail_user,
    ISNULL(SUBSTRING(email, CHARINDEX('@', email) + 1, LEN(email)), 'Not Provided') AS email_domain,
    CASE 
		WHEN phone is null THEN 'Not Provided'
		ELSE CONCAT('XXXXXX', RIGHT(phone, 4))
		END AS masked_phone,
    ISNULL(DATENAME(MONTH, join_date), 'Not Provided') AS join_month,
    DATEDIFF(DAY, join_date, '2026-10-01') AS days_with_us
into student_contact_clean
from students
order by student_id asc;

--Q1.4. Classify Incomplete Records Without Treating NULL as Zero
--Problem Statement:
--The data quality team found that many student profiles and fee payments are incomplete. They want
--every student classified so that the counsellors know whom to call, and they want a correct average
--payment value. A NULL means “not known”, so it must never be counted as 0.
--Part A – For each student, check the four fields email, phone, city and dob. missing_fields = how many
--of the four are NULL. profile_status = 'Complete' when nothing is missing; 'Contact Missing' when both
--email and phone are NULL; otherwise 'Partially Complete'.
--Part B – For each payment in fee_payments, payment_class = 'Amount Missing' when amount is NULL;
--'Not Collected' when status is not 'Success'; otherwise 'Collected'. (Check the amount rule first.)
--Part C – Return two values in one row: avg_amount_correct = average of the known amounts only, and
--avg_amount_wrong = average when NULL is replaced by 0. Round both to 2 decimals.


CREATE TABLE payments (
    payment_id VARCHAR(10) PRIMARY KEY,
    student_id INT,
    subject_id VARCHAR(10),
    payment_date DATE,
    amount DECIMAL(10,2),
    status VARCHAR(20)
);

INSERT INTO payments (payment_id, student_id, subject_id, payment_date, amount, status) VALUES
('P01', 101, 'S01', '2026-01-06', 4000, 'Success'),
('P02', 101, 'S02', '2026-01-20', 5000, 'Success'),
('P03', 102, 'S01', '2026-01-11', 4000, 'Failed'),
('P04', 102, 'S01', '2026-01-12', 4000, 'Success'),
('P05', 103, 'S02', '2026-01-19', 2500, 'Success'),
('P06', 103, 'S03', '2026-02-01', 3500, 'Success'),
('P07', 104, 'S01', '2026-02-04', 4000, 'Success'),
('P08', 105, 'S02', '2026-02-15', 5000, 'Success'),
('P09', 105, 'S04', '2026-02-16', NULL, 'Pending'),
('P10', 103, 'S02', '2026-02-19', 2500, 'Success'),
('P11', 107, 'S01', '2026-03-02', 4000, 'Success'),
('P12', 107, 'S02', '2026-03-03', 5000, 'Refunded'),
('P13', 108, 'S03', '2026-03-06', 3500, 'Success'),
('P14', 109, 'S01', '2026-03-12', 4000, 'Success'),
('P15', 110, 'S05', '2026-03-21', 4500, 'Success');

SELECT
    student_id,
    student_name,
    (CASE WHEN email IS NULL THEN 1 ELSE 0 END +
     CASE WHEN phone IS NULL THEN 1 ELSE 0 END +
     CASE WHEN city IS NULL THEN 1 ELSE 0 END +
     CASE WHEN dob IS NULL THEN 1 ELSE 0 END) AS missing_fields,
    CASE
        WHEN email IS NOT NULL AND phone IS NOT NULL
         AND city IS NOT NULL AND dob IS NOT NULL
            THEN 'Complete'
        WHEN email IS NULL AND phone IS NULL
            THEN 'Contact Missing'
        ELSE 'Partially Complete'
    END AS profile_status
INTO fee_payments
FROM students;

SELECT
    payment_id,
    student_id,amount,
    status,
    CASE 
        WHEN amount is null THEN 'Amount Missing'
        WHEN status = 'Success' THEN 'Collected'
        ELSE 'Not Collected'
        END AS payment_class
INTO payment_classification
FROM payments;

SELECT
    ROUND(AVG(amount), 2) AS avg_amount_correct,
    ROUND(AVG(ISNULL(amount, 0)), 2) AS avg_amount_wrong
INTO payment_average_check
FROM payments;


--Q1.5. Calculate Subject Demand
--Problem Statement:
--The academic head wants to know which subjects are in demand so that more batches can be planned.
--For every subject, show how many valid students are enrolled, how many seats are left and a demand
--level. A subject with no enrollments must still appear with 0.
--Only enrollments of students who exist in the students table are valid. demand_level: 'High' for 4 or more
--students, 'Medium' for 2 to 3, 'Low' for 1 and 'No Demand' for 0. seats_left = max_seats –
--enrolled_students. Sort by enrolled_students (highest first) and then by subject_id.

CREATE TABLE subjects (
    subject_id VARCHAR(10) PRIMARY KEY,
    subject_name VARCHAR(100),
    fee INT,
    max_seats INT
);

INSERT INTO subjects (subject_id, subject_name, fee, max_seats)
VALUES
('S01', 'SQL Fundamentals', 4000, 30),
('S02', 'Python Programming', 5000, 30),
('S03', 'Data Visualization', 3500, 20),
('S04', 'Statistics', 3000, 25),
('S05', 'Cloud Basics', 4500, 20),
('S06', 'Machine Learning', 6000, 15);

CREATE TABLE enrollments (
    enrollment_id VARCHAR(10) PRIMARY KEY,
    student_id INT,
    subject_id VARCHAR(10),
    enroll_date DATE
);

select * from enrollments
INSERT INTO enrollments (enrollment_id, student_id, subject_id, enroll_date) VALUES
('E01', 101, 'S01', '2026-01-06'),
('E02', 101, 'S02', '2026-01-06'),
('E03', 102, 'S01', '2026-01-11'),
('E04', 103, 'S02', '2026-01-19'),
('E05', 103, 'S03', '2026-02-01'),
('E06', 104, 'S01', '2026-02-04'),
('E07', 105, 'S02', '2026-02-15'),
('E08', 105, 'S04', '2026-02-15'),
('E09', 107, 'S01', '2026-03-02'),
('E10', 107, 'S02', '2026-03-02'),
('E11', 108, 'S03', '2026-03-06'),
('E12', 109, 'S01', '2026-03-12'),
('E13', 110, 'S05', '2026-03-21'),
('E14', 112, 'S02', '2026-03-25');


select 
s.subject_id,
s.subject_name,
count(e.subject_id) as enrolled_students,
(s.max_seats - count(e.subject_id)) as seats_left,
case 
when count(e.subject_id) > 3 then 'High' 
when count(e.subject_id) > 1 then 'Medium'
when count(e.subject_id) > 0 then 'Low'
else 'No Demand'
end as demand_level

into subject_demand
from subjects s
left join enrollments e
    on s.subject_id = e.subject_id
    and e.student_id in (select student_id from students)
group by s.subject_id,s.subject_name,s.max_seats;


--Q1.6. Calculate Monthly Revenue
--Problem Statement:
--The finance team closes the books every month. From fee_payments (shown in Q1.4), they need one
--row per month with the number of successful payments, the total revenue, the average successful
--payment and the number of payments that did not turn into revenue (any status other than 'Success').
--Show the month as YYYY-MM. Only include months where total revenue is at least 15,000, and sort by
--month.

SELECT
    FORMAT(payment_date, 'yyyy-MM') AS pay_month,
    SUM(CASE WHEN status = 'Success' THEN 1 ELSE 0 END) AS successful_payments,

    SUM(CASE WHEN status = 'Success' THEN amount ELSE 0 END) AS total_revenue,

    AVG(CASE WHEN status = 'Success' THEN amount END) AS avg_payment,

    SUM(CASE WHEN status <> 'Success' THEN 1 ELSE 0 END) AS other_payments

INTO monthly_revenue
FROM payments
GROUP BY FORMAT(payment_date, 'yyyy-MM')
HAVING SUM(CASE WHEN status = 'Success' THEN amount ELSE 0 END) >= 15000;

select
s.subject_name,
sum(case when p.status = 'Success' then p.amount Else 0 end) as total_revenue
into subject_revenue
from subjects s
join payments p on s.subject_id = p.subject_id
group by s.subject_name
having sum(case when p.status = 'Success' then p.amount Else 0 end) >8000
order by total_revenue desc;

--Q1.7. Find Unmatched Students, Customers and Orders
--Problem Statement:
--Two systems were merged and the data team must find records that do not match. In EduLearn, they
--need students who have not enrolled in any subject. In the ShopEasy store data (store_customers and
--store_orders), they need customers who have never placed an order, and orders that cannot be linked to
--a valid customer (either the customer_id is NULL or it does not exist in store_customers).


CREATE TABLE store_customers (
    customer_id VARCHAR(10) PRIMARY KEY,
    customer_name VARCHAR(100),
    city VARCHAR(50)
);

INSERT INTO store_customers
VALUES
('C01', 'Rahul Mehta', 'Jaipur'),
('C02', 'Priya Nair', 'Kochi'),
('C03', 'Arjun Das', 'Kolkata'),
('C04', 'Fatima Sheikh', 'Mumbai'),
('C05', 'Karan Malhotra', 'Delhi');

CREATE TABLE store_orders (
    order_id VARCHAR(10) PRIMARY KEY,
    customer_id VARCHAR(10),
    order_date DATE,
    amount DECIMAL(10,2)
);

INSERT INTO store_orders
VALUES
('O1001', 'C01', '2026-03-01', 1200),
('O1002', 'C02', '2026-03-02', 850),
('O1003', 'C01', '2026-03-05', 430),
('O1004', 'C07', '2026-03-06', 999),
('O1005', 'C04', '2026-03-08', 2100),
('O1006', NULL, '2026-03-09', 300);

select s.student_id , s.student_name, s.city 
into students_not_enrolled
from students s
left join enrollments e on e.student_id = s.student_id
where e.enrollment_id is null; 

select sc.customer_id, sc.customer_name,sc.city
into customers_without_orders
from store_customers sc
left join store_orders so on sc.customer_id = so.customer_id
where so.order_id is null;

select so.order_id,so.customer_id,so.amount,
case when so.customer_id is null then 'Guest order - no customer'
else 'Customer not found'
end as issue
from store_customers sc
right join store_orders so on sc.customer_id = so.customer_id
where sc.city is null;

--Q1.8. Order Summary Report Across Five Tables
--Problem Statement:
--ShopEasy's operations manager wants one report that shows, for every order, who placed it, how many
--items it has, its total value, how much has been paid and whether it is fully paid. The data is spread
--across customers, orders, order_items and payments.
--item_count = total quantity in the order; order_value = SUM(qty * unit_price); paid_amount = total of all
--payments for the order (0 when there is none); balance = order_value – paid_amount; payment_status =
--'Paid' when paid_amount >= order_value, 'Partially Paid' when some amount is paid, otherwise 'Unpaid'.
--Sort by order_id.

CREATE TABLE customers (
    customer_id VARCHAR(10) PRIMARY KEY,
    customer_name VARCHAR(100),
    city VARCHAR(50),
    signup_date DATE
);

CREATE TABLE products (
    product_id VARCHAR(10) PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    unit_price DECIMAL(10,2)
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id VARCHAR(10),
    order_date DATE,
    status VARCHAR(20)
);

CREATE TABLE order_items (
    order_id INT,
    product_id VARCHAR(10),
    qty INT,
    unit_price DECIMAL(10,2)
);

CREATE TABLE payments_8 (
    payment_id VARCHAR(10) PRIMARY KEY,
    order_id INT,
    payment_date DATE,
    amount DECIMAL(10,2),
    method VARCHAR(30)
);

INSERT INTO customers VALUES
('C01', 'Rahul Mehta', 'Jaipur', '2025-11-02'),
('C02', 'Priya Nair', 'Kochi', '2025-12-15'),
('C03', 'Arjun Das', 'Kolkata', '2026-01-08'),
('C04', 'Fatima Sheikh', 'Mumbai', '2026-01-20'),
('C05', 'Karan Malhotra', 'Delhi', '2026-02-11'),
('C06', 'Sneha Kulkarni', 'Pune', '2026-02-25');

INSERT INTO products VALUES
('P1', 'Wireless Mouse', 'Electronics', 799),
('P2', 'USB-C Hub', 'Electronics', 1999),
('P3', 'Notebook A5', 'Stationery', 120),
('P4', 'Gel Pen Pack', 'Stationery', 250),
('P5', 'Desk Lamp', 'Home', 1499),
('P6', 'Water Bottle', 'Home', 499);

INSERT INTO orders VALUES
(1001, 'C01', '2026-03-02', 'Delivered'),
(1002, 'C02', '2026-03-03', 'Delivered'),
(1003, 'C01', '2026-03-10', 'Delivered'),
(1004, 'C03', '2026-03-12', 'Cancelled'),
(1005, 'C04', '2026-03-15', 'Shipped'),
(1006, 'C05', '2026-03-18', 'Delivered'),
(1007, 'C01', '2026-04-01', 'Shipped'),
(1008, 'C06', '2026-04-03', 'Pending');

INSERT INTO order_items VALUES
(1001, 'P1', 2, 799),
(1001, 'P3', 5, 120),
(1002, 'P2', 1, 1999),
(1003, 'P4', 2, 250),
(1003, 'P6', 1, 499),
(1004, 'P5', 1, 1499),
(1005, 'P1', 1, 799),
(1005, 'P2', 1, 1999),
(1005, 'P3', 10, 120),
(1006, 'P6', 3, 499),
(1007, 'P5', 1, 1499),
(1008, 'P4', 4, 250);

INSERT INTO payments_8 VALUES
('PM01', 1001, '2026-03-02', 2198, 'UPI'),
('PM02', 1002, '2026-03-03', 1000, 'Card'),
('PM03', 1002, '2026-03-05', 999, 'Card'),
('PM04', 1003, '2026-03-10', 500, 'UPI'),
('PM05', 1005, '2026-03-15', 3998, 'NetBanking'),
('PM06', 1006, '2026-03-18', 1497, 'UPI'),
('PM07', 1009, '2026-04-02', 750, 'UPI'),
('PM08', 1004, '2026-03-12', 1499, 'Card');

SELECT
    o.order_id,
    c.customer_name,
    o.order_date,
    o.status,

    ISNULL(oi.item_count, 0) AS item_count,
    ISNULL(oi.order_value, 0) AS order_value,
    ISNULL(pay.paid_amount, 0) AS paid_amount,

    ISNULL(oi.order_value, 0) -
    ISNULL(pay.paid_amount, 0) AS balance,

    CASE
        WHEN ISNULL(pay.paid_amount, 0) >= ISNULL(oi.order_value, 0)
            THEN 'Paid'
        WHEN ISNULL(pay.paid_amount, 0) > 0
            THEN 'Partially Paid'
        ELSE 'Unpaid'
    END AS payment_status
INTO order_summary
FROM orders o

JOIN customers c
    ON o.customer_id = c.customer_id

LEFT JOIN (
    SELECT
        order_id,
        SUM(qty) AS item_count,
        SUM(qty * unit_price) AS order_value
    FROM order_items
    GROUP BY order_id
) oi
    ON o.order_id = oi.order_id

LEFT JOIN (
    SELECT
        order_id,
        SUM(amount) AS paid_amount
    FROM payments_8
    GROUP BY order_id
) pay
    ON o.order_id = pay.order_id

ORDER BY o.order_id;

select * from order_summary;

--Q1.9. Reconcile Orders with Payments
--Problem Statement:
--The finance team compares the order system with the payment gateway every week. They need a list of
--every problem found, from both sides: payments that point to an order that does not exist, active orders
--with no payment, orders paid less than their value and cancelled orders that were paid (a refund is
--required). Matched orders must not be listed.
--Use the order value from Q1.8. recon_status rules, checked in this order: 'Unknown Order' when the
--payment's order is not in orders; 'Refund Required' when the order is Cancelled and has a payment;
--'Payment Missing' when the order is not Cancelled and has no payment; 'Short Paid' when paid_amount
--< order_value. Show order_id from whichever side has it. Sort by order_id.

SELECT
    o.order_id,
    o.status AS order_status,
    oi.order_value,
    ISNULL(p.paid_amount, 0) AS paid_amount,

    CASE
        WHEN o.order_id IS NULL THEN 'Unknown Order'
        WHEN o.status = 'Cancelled' AND p.paid_amount > 0 THEN 'Refund Required'
        WHEN ISNULL(p.paid_amount, 0) = 0 THEN 'Payment Missing'
        WHEN p.paid_amount < oi.order_value THEN 'Short Paid'
        ELSE 'Reconciled'
    END AS recon_status
INTO payment_reconciliation
FROM orders o

FULL OUTER JOIN
(
    SELECT
        order_id,
        SUM(qty * unit_price) AS order_value
    FROM order_items
    GROUP BY order_id
) oi
    ON o.order_id = oi.order_id

FULL OUTER JOIN
(
    SELECT
        order_id,
        SUM(amount) AS paid_amount
    FROM payments_8
    GROUP BY order_id
) p
    ON COALESCE(o.order_id, oi.order_id) = p.order_id

WHERE
    o.status = 'Cancelled'
    OR ISNULL(p.paid_amount, 0) = 0
    OR p.paid_amount < oi.order_value
    OR o.order_id IS NULL

ORDER BY COALESCE(o.order_id, p.order_id);

--Q1.10. Employee Directory with Managers and Departments
--Problem Statement:
--HR wants an employee directory that shows each employee's manager and department. The CEO has
--no manager and a new joiner has no department yet; both must still appear. HR also wants to see
--departments that have no employees so that hiring can be planned.
--Part A – emp_id, emp_name, manager_name ('No Manager' when there is none), dept_name ('Not
--Assigned' when NULL) and location ('Not Assigned' when NULL), sorted by emp_id.
--Part B – departments with no employees: dept_id, dept_name, location.

CREATE TABLE employees (
    emp_id VARCHAR(10) PRIMARY KEY,
    emp_name VARCHAR(100),
    dept_id INT,
    manager_id VARCHAR(10),
    salary DECIMAL(12,2),
    hire_date DATE
);

INSERT INTO employees
VALUES
('E01', 'Asha Verma', 10, NULL, 150000, '2018-04-01'),
('E02', 'Ravi Kumar', 20, 'E01', 95000, '2019-06-15'),
('E03', 'Meena Pillai', 20, 'E02', 72000, '2021-01-10'),
('E04', 'John Mathew', 20, 'E02', 72000, '2022-03-01'),
('E05', 'Sara Ali', 30, 'E01', 98000, '2019-09-20'),
('E06', 'Vivek Rao', 30, 'E05', 64000, '2023-02-14'),
('E07', 'Pooja Shah', 30, 'E05', 58000, '2024-07-01'),
('E08', 'Nikhil Jain', 20, 'E03', 55000, '2025-01-06'),
('E09', 'Tara Menon', 40, 'E01', 88000, '2020-11-11'),
('E10', 'Imran Qureshi', NULL, 'E01', 61000, '2025-08-18');

CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(100),
    location VARCHAR(100)
);

INSERT INTO departments
VALUES
(10, 'Leadership', 'Jaipur'),
(20, 'Engineering', 'Bengaluru'),
(30, 'Analytics', 'Pune'),
(40, 'Finance', 'Mumbai'),
(50, 'Legal', 'Delhi');

select
    e.emp_id,
    e.emp_name,
    isnull(es.emp_name,'No Manager') as manager_name,
    isnull(d.dept_name,'Not Assigned') as dept_name,
    isnull(d.location,'Not Assigned') as location
into employee_directory
from employees e
left join employees es on e.manager_id = es.emp_id
left join departments d on 
e.dept_id = d.dept_id;

select 
    d.dept_id,
    d.dept_name,
    d.location
into empty_departments
from departments d
left join employees e
    on d.dept_id = e.dept_id
where e.emp_id is null;

--Q1.11. Salary Benchmarks Using Subqueries
--Problem Statement:
--The compensation team is preparing salary benchmarks from the employees table.
--Part A – Find the 4th highest distinct salary in the company (equal salaries count once).
--Part B – List employees who earn more than the average salary of their own department. Employees
--without a department are ignored. Show emp_name, dept_id, salary and dept_avg_salary (rounded to 2
--decimals), sorted by dept_id and salary descending.
--Part C – List every manager (an employee who has at least one direct report) with the number of direct
--reports. Use EXISTS to find managers and a scalar subquery to count reports.

select e.salary as fourth_highest_salary from
(select 
    DENSE_RANK() 
        over(order by salary desc) as rnk ,
        * 
        from employees 
        ) e
where e.rnk = 4;

select 
e.emp_name,
e.dept_id,
e.salary,
(select avg(salary) from employees where dept_id = e.dept_id) as dept_avg_salary
from employees e
where salary > (select avg(salary) from employees where dept_id = e.dept_id);

SELECT
    e.emp_id,
    e.emp_name,
    (
        SELECT COUNT(*)
        FROM employees sub
        WHERE sub.manager_id = e.emp_id
    ) AS direct_reports
FROM employees e
WHERE EXISTS (
    SELECT 1
    FROM employees sub
    WHERE sub.manager_id = e.emp_id
);


--Q1.12. Compare CRM and Billing Customer Lists
--Problem Statement:
--ShopEasy keeps customers in two systems. Before a migration, the data team must compare the two
--lists using set operations.
--Return: (A) customers present in both systems; (B) customers only in CRM; (C) customers only in billing;
--(D) the number of rows returned by UNION and by UNION ALL of the two lists, in one row.


CREATE TABLE crm_customers (
    customer_id VARCHAR(10),
    email VARCHAR(100)
);
INSERT INTO crm_customers VALUES
('C01', 'rahul.mehta@mail.com'),
('C02', 'priya.nair@mail.com'),
('C02', 'priya.nair@mail.com'),
('C03', 'arjun.das@mail.com'),
('C04', 'fatima.s@mail.com');

CREATE TABLE billing_customers (
    customer_id VARCHAR(10),
    email VARCHAR(100)
);
INSERT INTO billing_customers VALUES
('C02', 'priya.nair@mail.com'),
('C04', 'fatima.s@mail.com'),
('C05', 'karan.m@mail.com'),
('C06', 'sneha.k@mail.com');


select distinct c.* from
crm_customers c join billing_customers b
on c.customer_id = b.customer_id

select c.* from
crm_customers c 
left join billing_customers b
on c.customer_id = b.customer_id
where b.customer_id is null;

select b.* from
crm_customers c 
right join billing_customers b
on c.customer_id = b.customer_id
where c.customer_id is null;

SELECT
    (SELECT COUNT(*)
     FROM (
         SELECT customer_id, email FROM crm_customers
         UNION
         SELECT customer_id, email FROM billing_customers
     ) AS U) AS union_count,

    (SELECT COUNT(*)
     FROM (
         SELECT customer_id, email FROM crm_customers
         UNION ALL
         SELECT customer_id, email FROM billing_customers
     ) AS UA) AS union_all_count; 
