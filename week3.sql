
-- Q3.1. Quarterly Sales vs Budget
-- Problem Statement:
-- Finance wants a sales table for 2025 with one row for each category and one column for each quarter.
-- Show 0 for a quarter with no sales. Finance also keeps the budget with one column per quarter, and
-- wants it as one row per category and quarter so it can be compared with actual sales.
-- Part A – Show category, Q1, Q2, Q3, Q4 and total from sales_lines. Part B – Show category_budget as
-- category, quarter, budget. Part C – Show category, quarter, actual, budget and variance (actual –
-- budget) for every category and quarter.


CREATE TABLE sales_lines (
    sale_id INT PRIMARY KEY,
    sale_date DATE,
    category VARCHAR(50),
    amount DECIMAL(10,2)
);


INSERT INTO sales_lines VALUES
(1, '2025-01-15', 'Electronics', 5000),
(2, '2025-02-20', 'Stationery', 800),
(3, '2025-04-03', 'Electronics', 7000),
(4, '2025-05-11', 'Home', 2500),
(5, '2025-06-30', 'Stationery', 600),
(6, '2025-07-19', 'Electronics', 6500),
(7, '2025-08-08', 'Home', 3000),
(8, '2025-10-01', 'Electronics', 9000),
(9, '2025-11-15', 'Stationery', 1200),
(10, '2025-12-24', 'Home', 4000),
(11, '2025-12-26', 'Electronics', 1000);



CREATE TABLE category_budget (
    category VARCHAR(50) PRIMARY KEY,
    Q1 DECIMAL(10,2),
    Q2 DECIMAL(10,2),
    Q3 DECIMAL(10,2),
    Q4 DECIMAL(10,2)
);

INSERT INTO category_budget VALUES
('Electronics', 6000, 6000, 7000, 10000),
('Home', 1000, 2000, 3000, 4000),
('Stationery', 1000, 1000, 500, 1500);

-- PART A
SELECT
    category,

    SUM(CASE WHEN DATEPART(QUARTER, sale_date) = 1
        THEN amount ELSE 0 END) AS Q1,

    SUM(CASE WHEN DATEPART(QUARTER, sale_date) = 2
        THEN amount ELSE 0 END) AS Q2,

    SUM(CASE WHEN DATEPART(QUARTER, sale_date) = 3
        THEN amount ELSE 0 END) AS Q3,

    SUM(CASE WHEN DATEPART(QUARTER, sale_date) = 4
        THEN amount ELSE 0 END) AS Q4,

    SUM(amount) AS total

FROM sales_lines

WHERE YEAR(sale_date) = 2025

GROUP BY category

ORDER BY category;

--PART B

SELECT
    category,
    v.quarter,
    v.budget

FROM category_budget

CROSS APPLY (
    VALUES
        ('Q1', Q1),
        ('Q2', Q2),
        ('Q3', Q3),
        ('Q4', Q4)
) v(quarter, budget)

ORDER BY
    category,
    quarter;

-- PART C


WITH ActualSales AS
(
    SELECT
        category,
        DATEPART(QUARTER, sale_date) AS quarter_no,
        SUM(amount) AS actual

    FROM sales_lines

    WHERE YEAR(sale_date) = 2025

    GROUP BY
        category,
        DATEPART(QUARTER, sale_date)
),

BudgetRows AS
(
    SELECT
        category,
        v.quarter_no,
        v.budget

    FROM category_budget

    CROSS APPLY (
        VALUES
            (1, Q1),
            (2, Q2),
            (3, Q3),
            (4, Q4)
    ) v(quarter_no, budget)
)

SELECT
    b.category,
    'Q' + CAST(b.quarter_no AS VARCHAR(1)) AS quarter,

    COALESCE(a.actual, 0) AS actual,

    b.budget,

    COALESCE(a.actual, 0) - b.budget AS variance

FROM BudgetRows b

LEFT JOIN ActualSales a
    ON b.category = a.category
    AND b.quarter_no = a.quarter_no

ORDER BY
    b.category,
    b.quarter_no;

GO


-- Q3.2. Sync the Product Master
--Problem Statement:
--Every night the product master must be updated from the staging table: add new products, update
--changed products and remove products marked as deleted. Products that did not change must not be
--touched.
--Also show, for each product that was changed, what happened to it (INSERT, UPDATE or DELETE).

CREATE TABLE product_master (
    product_id VARCHAR(10) PRIMARY KEY,
    product_name VARCHAR(100),
    price DECIMAL(10,2),
    is_active BIT
);

INSERT INTO product_master VALUES
('P1', 'Wireless Mouse', 799, 1),
('P2', 'USB-C Hub', 1999, 1),
('P3', 'Notebook A5', 120, 1),
('P4', 'Gel Pen Pack', 250, 1);


CREATE TABLE product_staging (
    product_id VARCHAR(10),
    product_name VARCHAR(100),
    price DECIMAL(10,2),
    is_deleted CHAR(1)
);

INSERT INTO product_staging VALUES
('P2', 'USB-C Hub 7-in-1', 2199, 'N'),
('P3', 'Notebook A5', 120, 'N'),
('P4', 'Gel Pen Pack', 250, 'Y'),
('P5', 'Desk Lamp', 1499, 'N'),
('P6', 'Water Bottle', 499, 'N');


DECLARE @Actions TABLE (
    product_id VARCHAR(10),
    action VARCHAR(10)
);


MERGE INTO product_master AS target

USING product_staging AS source

ON target.product_id = source.product_id

WHEN MATCHED
    AND source.is_deleted = 'Y'

THEN DELETE

WHEN MATCHED
    AND source.is_deleted = 'N'
    AND (
        target.product_name <> source.product_name
        OR target.price <> source.price
        OR target.is_active = 0
    )

THEN UPDATE SET
    target.product_name = source.product_name,
    target.price = source.price,
    target.is_active = 1

WHEN NOT MATCHED BY TARGET
    AND source.is_deleted = 'N'

THEN INSERT (
    product_id,
    product_name,
    price,
    is_active
)
VALUES (
    source.product_id,
    source.product_name,
    source.price,
    1
)

OUTPUT
    COALESCE(inserted.product_id, deleted.product_id),
    $action
INTO @Actions;

SELECT *
FROM product_master
ORDER BY product_id;


SELECT
    product_id,
    action
FROM @Actions
ORDER BY product_id;

GO


--Q3.3. Keep Address History in CustomerDim
--Problem Statement:
--CustomerDim must keep the full history of each customer's address. Create a trigger named trg_dim on
--CustomerDim that runs instead of a normal insert. When an existing customer is inserted with a new
--address, close the current row (EffectiveEndDate = the day before today, IsCurrent = 0) and add a new
--current row. A new customer is simply added as a current row. New rows get EffectiveStartDate = today
--and EffectiveEndDate = 9999-12-31.
--After creating the trigger, insert the four rows below in one INSERT statement:
--Note: Customer dimension that must keep full history (SCD Type 2).


-- =====================================================
-- Q3.3 CUSTOMER DIMENSION - SCD TYPE 2
-- =====================================================


CREATE TABLE CustomerDim (
    CustomerID INT,
    CustomerName VARCHAR(100),
    [Address] VARCHAR(200),
    EffectiveStartDate DATE,
    EffectiveEndDate DATE,
    IsCurrent BIT
);


INSERT INTO CustomerDim VALUES
(1, 'John Doe', '123 Main St',
 '2023-01-01', '9999-12-31', 1),

(2, 'Alice Johnson', '456 Elm St',
 '2023-01-01', '9999-12-31', 1),

(3, 'Bob Smith', '789 Oak St',
 '2023-01-01', '9999-12-31', 1);

GO


CREATE TRIGGER trg_dim
ON CustomerDim
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Today DATE = CAST(GETDATE() AS DATE);

    UPDATE cd

    SET
        EffectiveEndDate = DATEADD(DAY, -1, @Today),
        IsCurrent = 0

    FROM CustomerDim cd

    INNER JOIN inserted i
        ON cd.CustomerID = i.CustomerID

    WHERE cd.IsCurrent = 1
      AND cd.[Address] <> i.[Address];


    INSERT INTO CustomerDim (
        CustomerID,
        CustomerName,
        [Address],
        EffectiveStartDate,
        EffectiveEndDate,
        IsCurrent
    )

    SELECT
        i.CustomerID,
        i.CustomerName,
        i.[Address],
        @Today,
        '9999-12-31',
        1

    FROM inserted i

    WHERE NOT EXISTS (
        SELECT 1
        FROM CustomerDim cd
        WHERE cd.CustomerID = i.CustomerID
          AND cd.IsCurrent = 1
          AND cd.[Address] = i.[Address]
    );

END;

GO

-- INSERT FOUR NEW CUSTOMER RECORDS


INSERT INTO CustomerDim (
    CustomerID,
    CustomerName,
    [Address]
)
VALUES
(1, 'John Doe', 'Ajmer'),
(4, 'David Richard', 'Mumbai'),
(3, 'Bob Smith', 'Chennai'),
(5, 'Eva Dsouza', 'Mumbai');


SELECT
    CustomerID,
    CustomerName,
    [Address],
    EffectiveStartDate,
    EffectiveEndDate,
    IsCurrent

FROM CustomerDim

ORDER BY
    CustomerID,
    EffectiveStartDate;

GO


--Q3.4. Make a Slow Customer Lookup Faster
--Problem Statement:
--The support team searches orders by customer every few minutes, and the search has become slow
--because the orders table is large.
--Create a table sales_big (order_id INT primary key, customer_id VARCHAR(6), order_date DATE,
--amount DECIMAL(10,2)) and fill it with 500,000 rows: customer_id goes from C0000 to C4999 (row
--number % 5000), order_date starts at 2023-01-01 and moves one day for each row and repeats every
--1,095 days, and amount is (row number * 37) % 5000 + 99.



CREATE TABLE sales_big (
    order_id INT PRIMARY KEY,
    customer_id VARCHAR(6),
    order_date DATE,
    amount DECIMAL(10,2)
);

GO


WITH Numbers AS
(
    SELECT TOP (500000)

        ROW_NUMBER() OVER (
            ORDER BY (SELECT NULL)
        ) AS rn

    FROM sys.all_objects a

    CROSS JOIN sys.all_objects b
)

INSERT INTO sales_big (
    order_id,
    customer_id,
    order_date,
    amount
)

SELECT
    rn,

    'C' + RIGHT(
        '0000' + CAST((rn - 1) % 5000 AS VARCHAR(4)),
        4
    ),

    DATEADD(
        DAY,
        (rn - 1) % 1095,
        CAST('2023-01-01' AS DATE)
    ),

    ((rn * 37) % 5000) + 99

FROM Numbers;

GO

-- PART A: RUN ORIGINAL QUERY WITHOUT INDEX


SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT
    order_id,
    order_date,
    amount
FROM dbo.sales_big
WHERE customer_id = 'C0042'
  AND order_date >= '2025-03-01'
  AND order_date < '2025-04-01';

GO

-- PART B: CREATE NONCLUSTERED COMPOSITE INDEX


CREATE NONCLUSTERED INDEX IX_sales_big_customer_date

ON dbo.sales_big (
    customer_id,
    order_date
)

INCLUDE (amount);

GO

-- PART C

SELECT
    order_id,
    order_date,
    amount
FROM dbo.sales_big
WHERE customer_id = 'C0042'
  AND order_date >= '2025-03-01'
  AND order_date < '2025-04-01';

GO


SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;


EXEC sp_helpindex 'sales_big';

GO
