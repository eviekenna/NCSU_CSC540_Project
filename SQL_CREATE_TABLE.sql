-- !preview conn=DBI::dbConnect(RSQLite::SQLite())

  CREATE TABLE category (
  category_id       BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name              VARCHAR(100) NOT NULL,
  UNIQUE(name)
)
  CREATE TABLE Product (
  product_id 
  )