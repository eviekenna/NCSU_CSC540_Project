-- !preview conn=DBI::dbConnect(RSQLite::SQLite())

  CREATE TABLE Category (
  category_id       BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name              VARCHAR(100) NOT NULL,
  UNIQUE(name)
)
  CREATE TABLE Product (
  product_id INT PRIMARY KEY,
  name VARCHAR(30),
  manufacturer_id INT
  catagory_id INT
  FOREIGN KEY manufacturer_id_fk REFERENCES manufacturer,
  FOREIGN KEY catagory_id_fk REFERENCES category
  )
  CREATE TABLE Recipe (
  product_id INT 
  product_id_fk FOREIGN KEY REFERENCES Product(product_id),
  ingredient_id INT 
  ingredient_id_fk FOREIGN KEY REFERENCES Ingredient(ingredient_id), 
  quantity INT,
  PRIMARY KEY (product_id,ingredient_id)
  )
  CREATE TABLE Ingredient (
  ingredient_id INT PRIMARY KEY, 
  ingredient_name VARCHAR(30)
  )
  CREATE TABLE IngredientComposition (
  ingredient_id INT 
  ingredient_id_fk FOREIGN KEY REFERENCES Ingredient(ingredient_id),
  quantity INT,
  material VARCHAR(30),
  )
  CREATE TABLE Manufacturer (
  manufacturer_id INT PRIMARY KEY, 
  manufacturer_name VARCHAR(30),
  )
  CREATE TABLE ProductBatch (
  lot_number INT PRIMARY KEY,
  product_id INT,
  manufacturer_id INT,
  product_id_fk FOREIGN KEY REFERENCES Product(product_id),
  manufacturer_id_fk FOREIGN KEY REFERENCES Manufacturer(manufacturer_id),
  quantity INT, 
  date ???????,
  cost INT
  )
  
  