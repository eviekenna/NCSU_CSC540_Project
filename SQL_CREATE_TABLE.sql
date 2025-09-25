-- !preview conn=DBI::dbConnect(RSQLite::SQLite())

  CREATE TABLE Category (
    category_id       BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name              VARCHAR(100) NOT NULL,
    UNIQUE(name)
  );
    
  CREATE TABLE Product (
    product_id INT PRIMARY KEY,
    name VARCHAR(30),
    manufacturer_id INT
    catagory_id INT
    FOREIGN KEY manufacturer_id_fk REFERENCES manufacturer,
    FOREIGN KEY catagory_id_fk REFERENCES category
  );
    
  CREATE TABLE Recipe (
    product_id INT 
    product_id_fk FOREIGN KEY REFERENCES Product(product_id),
    ingredient_id INT 
    ingredient_id_fk FOREIGN KEY REFERENCES Ingredient(ingredient_id), 
    quantity INT,
    PRIMARY KEY (product_id,ingredient_id)
  );
    
  CREATE TABLE Ingredient (
    ingredient_id INT PRIMARY KEY, 
    ingredient_name VARCHAR(30)
  );
    
  CREATE TABLE IngredientComposition (
    ingredient_id INT 
    ingredient_id_fk FOREIGN KEY REFERENCES Ingredient(ingredient_id),
    quantity INT,
    material VARCHAR(30),
  );
    
  CREATE TABLE Manufacturer (
    manufacturer_id INT PRIMARY KEY, 
    manufacturer_name VARCHAR(30),
  );
    
  CREATE TABLE ProductBatch (
    lot_number INT PRIMARY KEY,
    product_id INT,
    manufacturer_id INT,
    product_id_fk FOREIGN KEY REFERENCES Product(product_id),
    manufacturer_id_fk FOREIGN KEY REFERENCES Manufacturer(manufacturer_id),
    quantity INT, 
    date ???????,
    cost INT
  );

  CREATE TABLE Supplier (
    supplier_id INT PRIMARY KEY
    supplier_name VARCHAR(100) NOT NULL
  );

  CREATE TABLE IngredientBatch (
    lot_number VARCHAR(100) PRIMARY KEY,
    ingredient_id INT NOT NULL,
    supplier_id INT NOT NULL,
    quantity_oz INT NOT NULL, -- CHECK here? make sure it is positive
    cost DECIMAL(12, 2) NOT NULL, -- CHECK here? 
    expiration_date DATE NOT NULL,
    intake_date DATE NOT NULL
    FOREIGN KEY (supplier_id) REFERENCES Supplier(supplier_id),
    CONSTRAINT check_90_day_minimum CHECK (DATEDIFF(expiration_date, intake_date) >= 90)
  );

  CREATE TABLE SupplierFormulation (
    formulation_id INT PRIMARY KEY AUTO_INCREMENT,
    supplier_id INT NOT NULL,
    ingredient_id INT NOT NULL,
    pack_size INT NOT NULL CHECK (pack_size > 0),
    price_per_unit DECIMAL(12, 2) NOT NULL CHECK (price_per_unit >= 0),
    effective_period_start_date DATE NOT NULL,
    effective_period_end_date DATE,
    FOREIGN KEY (supplier_id) REFERENCES Supplier(supplier_id),
    FOREIGN KEY (ingredient_id) REFERENCES Ingredient(ingredient_id)
  );

  CREATE TABLE BatchConsumption (
    product_lot_number VARCHAR(100) NOT NULL,
    ingredient_lot_number VARCHAR(100) NOT NULL,
    quantity_consumed INT NOT NULL,
    PRIMARY KEY (product_lot_number, ingredient_lot_number),
    FOREIGN KEY (product_lot_number) REFERENCES ProductBatch(lot_number),
    FOREIGN KEY (ingredient_lot_number) REFERENCES IngredientBatch(lot_number)
  );


    
  
  
