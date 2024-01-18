### Logistique

##### Stock des produits

SELECT prod.productName, SUM(ordd.quantityOrdered) AS Total_Products_Sold, prod.quantityInStock AS Product_Stock
FROM products AS prod 
INNER JOIN orderdetails AS ordd ON prod.productCode = ordd.productCode 
GROUP BY prod.productName , Product_Stock
ORDER BY Total_Products_Sold LIMIT 5;

##### Le stock des 5 produits les plus vendus
	
SELECT prod.productName, SUM(ordd.quantityOrdered) AS Total_Products_Sold, prod.quantityInStock AS Product_Stock
FROM products AS prod 
INNER JOIN orderdetails AS ordd ON prod.productCode = ordd.productCode 
GROUP BY prod.productName , Product_Stock
ORDER BY total_products_Sold DESC LIMIT 5;

##### Nombre des clients par pays et par année

SELECT COUNT(*) AS Customers, country, YEAR(orderDate) AS Year FROM customers c
INNER JOIN orders ON c.customerNumber = orders.customerNumber
GROUP BY country, Year;

##### Total des commandes par pays
	
SELECT COUNT(orderNumber) AS Orders, country FROM orders
INNER JOIN customers c ON c.customerNumber = orders.customerNumber
GROUP BY country;

##### Nombre de produit envoyé / annulé / on hold 

SELECT Status, COUNT(*) AS Nombre
FROM orders
GROUP BY Status;

##### Statut des commandes classé par date
SELECT Status, YEAR(orderDate) AS Date, COUNT(*) AS Nombre
FROM orders
GROUP BY Status, Date 
ORDER BY DATE DESC;

##### Valeur du stock (quantité de produit en stock * buy price)

SELECT prod.productName, prod.quantityInStock, (prod.quantityInStock * prod.buyPrice) AS stock_value
FROM products AS prod 
INNER JOIN orderdetails AS ordd ON prod.productCode = ordd.productCode 
GROUP BY prod.productName, prod.quantityInStock, prod.buyPrice
ORDER BY stock_value DESC;


### Ressources humaines 

##### Employés ayant le chiffre d'affaires le plus élevé
	
SELECT CONCAT(firstname, '  ', lastname) AS Fullname, SUM(priceEach*quantityOrdered) AS CA
FROM employees e
LEFT JOIN customers c ON e.employeeNumber = c.salesRepEmployeeNumber
LEFT JOIN orders o ON c.customerNumber = o.customerNumber
LEFT JOIN orderdetails od ON od.orderNumber = o.orderNumber
GROUP BY Fullname
ORDER BY CA  DESC;

##### Calculer le nombre d’employé par bureau

SELECT offices.officeCode, offices.city, SUM(orderdetails.priceEach * orderdetails.quantityOrdered) AS Total_CA,
  (SELECT COUNT(*) 
    FROM employees 
    WHERE employees.officeCode = offices.officeCode AND employees.jobTitle = 'Sales Rep'
  ) AS nb_employees
FROM orderdetails
INNER JOIN orders ON orders.orderNumber = orderdetails.orderNumber
INNER JOIN customers ON customers.customerNumber = orders.customerNumber
INNER JOIN employees ON customers.salesRepEmployeeNumber = employees.employeeNumber
INNER JOIN offices ON offices.officeCode = employees.officeCode
GROUP BY offices.officeCode
ORDER BY Total_CA DESC;

###### Chaque mois, les 2 vendeurs avec le CA le plus élevé

CREATE OR REPLACE VIEW CA_per_employee AS (
SELECT CONCAT(firstname, '  ', lastname) AS Fullname, SUM(priceEach*quantityOrdered) AS CA, CONCAT(YEAR(orderdate), '  ', MONTH(orderDate)) AS Date,  
    RANK() OVER (PARTITION BY CONCAT(YEAR(orderdate), '  ', MONTH(orderDate)) ORDER BY SUM(priceEach*quantityOrdered) DESC) AS employee_rank
FROM employees e
LEFT JOIN customers c ON e.employeeNumber = c.salesRepEmployeeNumber
LEFT JOIN orders o ON c.customerNumber = o.customerNumber
LEFT JOIN orderdetails od ON od.orderNumber = o.orderNumber
GROUP BY Fullname, Date);

SELECT * FROM CA_per_employee
WHERE CA IS NOT NULL AND Date IS NOT NULL AND employee_rank <= 2
ORDER BY Date DESC, employee_rank;

##### Employés ayant le CA le plus bas

SELECT CONCAT(firstname, '  ', lastname) AS Fullname, SUM(priceEach*quantityOrdered) AS CA 
FROM employees e
INNER JOIN customers c ON e.employeeNumber = c.salesRepEmployeeNumber
INNER JOIN orders o ON c.customerNumber = o.customerNumber
LEFT JOIN orderdetails od ON od.orderNumber = o.orderNumber
GROUP BY Fullname
ORDER BY CA;

##### Pire employé par année
	
SELECT CONCAT(firstname, '  ', lastname) AS Fullname, SUM(priceEach*quantityOrdered) AS CA, YEAR (orderDate) AS YEAR
FROM employees e
INNER JOIN customers c ON e.employeeNumber = c.salesRepEmployeeNumber
INNER JOIN orders o ON c.customerNumber = o.customerNumber
LEFT JOIN orderdetails od ON od.orderNumber = o.orderNumber
GROUP BY Fullname, YEAR
ORDER BY CA ASC;

##### Meilleur employé par année

SELECT country, SUM(priceEach*quantityOrdered) AS CA, YEAR(orderDate) AS YEAR
FROM orderdetails
INNER JOIN orders ON orders.orderNumber=orderdetails.orderNumber
INNER JOIN customers ON customers.customerNumber = orders.customerNumber
GROUP BY country, YEAR
ORDER BY CA DESC;
### Finances
	
##### Total Chiffre d'affaires par Date
	
SELECT CONCAT(MONTH(orderDate), ' / ', YEAR(orderdate)) AS Date, SUM(priceEach*quantityOrdered) AS CA
From orders
JOIN orderdetails ON orders.orderNumber = orderdetails.orderNumber
GROUP BY Date;

##### Total Chiffre d'affaires par pays (ordre décroissant)

SELECT country, SUM(priceEach*quantityOrdered) AS CA
FROM orderdetails
INNER JOIN orders ON orders.orderNumber=orderdetails.orderNumber
INNER JOIN customers ON customers.customerNumber = orders.customerNumber
GROUP BY country
ORDER BY CA DESC;

##### Total CA par bureau (voir quel bureau est le plus efficace en fonction du nombre de vendeurs)
	
SELECT offices.officeCode, offices.city, SUM(orderdetails.priceEach * orderdetails.quantityOrdered) AS Total_CA,
  (SELECT COUNT(*) 
    FROM employees 
    WHERE employees.officeCode = offices.officeCode AND employees.jobTitle = 'Sales Rep'
  ) AS nb_employees
FROM orderdetails
INNER JOIN orders ON orders.orderNumber = orderdetails.orderNumber
INNER JOIN customers ON customers.customerNumber = orders.customerNumber
INNER JOIN employees ON customers.salesRepEmployeeNumber = employees.employeeNumber
INNER JOIN offices ON offices.officeCode = employees.officeCode
GROUP BY offices.officeCode
ORDER BY Total_CA DESC;

##### Impayés des clients (classé par ordre décroissant)

SELECT orders.customerNumber, customers.customerName, SUM(priceEach*quantityOrdered) AS CA, paiements.total_payments, (SUM(priceEach*quantityOrdered) - paiements.total_payments) AS impayés
FROM orderdetails
INNER JOIN orders ON orders.orderNumber=orderdetails.orderNumber
INNER JOIN customers ON customers.customerNumber = orders.customerNumber
INNER JOIN 	(
    SELECT payments.customerNumber, SUM(payments.amount) AS total_payments
	FROM payments 
	GROUP BY payments.customerNumber
    ) AS paiements
    ON paiements.customerNumber=orders.customerNumber
GROUP BY orders.customerNumber
ORDER BY impayés DESC;

##### Total journalier de chiffre d'affaire par pays

SELECT orderDate, country, SUM(priceEach*quantityOrdered) AS CA
FROM orderdetails
INNER JOIN orders ON orders.orderNumber=orderdetails.orderNumber
INNER JOIN customers ON customers.customerNumber = orders.customerNumber
GROUP BY orderDate,country
ORDER BY CA DESC;

##### Panier moyen

SELECT country, SUM(priceEach*quantityOrdered) AS Total_CA, COUNT(orderdetails.orderNumber) AS nb_commandes, ROUND(SUM(priceEach*quantityOrdered)/COUNT(orderdetails.orderNumber),2) AS Panier_moyen
FROM orderdetails
INNER JOIN orders ON orders.orderNumber=orderdetails.orderNumber
INNER JOIN customers ON customers.customerNumber = orders.customerNumber
GROUP BY country
ORDER BY Panier_moyen DESC;
### Ventes

##### Ville avec le plus de ventes

SELECT country, SUM(priceEach*quantityOrdered) AS CA
FROM orderdetails
INNER JOIN orders ON orders.orderNumber=orderdetails.orderNumber
INNER JOIN customers ON customers.customerNumber = orders.customerNumber
GROUP BY country
ORDER BY CA DESC;

#### 5 produits ayant été le - vendus

SELECT productName, SUM(quantityOrdered) AS less_sold_product
FROM orderdetails ordd
INNER JOIN products pro ON pro.productCode = ordd.productCode
GROUP BY productName
ORDER BY less_sold_product LIMIT 5;

##### 5 produits ayant été le plus vendus 

SELECT productName, SUM(quantityOrdered) AS best_sold_product
FROM orderdetails ordd
INNER JOIN products pro ON pro.productCode = ordd.productCode
INNER JOIN orders ON ordd.orderNumber = orders.orderNumber
GROUP BY productName
ORDER BY best_sold_product DESC LIMIT 5;

##### 5 produits les + vendus le dernier trimestre
	
SELECT p.productName, SUM(od.quantityOrdered) AS Sales_Last_3_Months
FROM orderdetails od
INNER JOIN orders o ON od.orderNumber = o.orderNumber
INNER JOIN products p ON p.productCode = od.productCode
WHERE o.orderdate BETWEEN '2023-02-28' AND '2023-05-30'
GROUP BY p.productName , od.quantityOrdered
ORDER BY Sales_Last_3_Months DESC LIMIT 5;

SELECT p.productName, SUM(od.quantityOrdered) AS sales_last_3_months
FROM orderdetails od
INNER JOIN orders o ON od.orderNumber = o.orderNumber
INNER JOIN products p ON p.productCode = od.productCode
WHERE o.orderDate >= DATE(NOW() - INTERVAL 3 MONTH)
GROUP BY p.productName
ORDER BY sales_last_3_months DESC
LIMIT 5;

##### 5 produits les - vendus le dernier trimestre

SELECT productName, SUM(quantityOrdered) AS less_sold
FROM orderdetails ordd
RIGHT JOIN products pro ON pro.productCode = ordd.productCode
RIGHT JOIN orders o ON ordd.orderNumber = o.orderNumber
WHERE o.orderDate >= DATE(NOW() - INTERVAL 3 MONTH)
GROUP BY productName
ORDER BY less_sold ASC LIMIT 5;
