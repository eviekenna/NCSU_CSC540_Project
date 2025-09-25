-- !preview conn=DBI::dbConnect(RSQLite::SQLite())

  CREATE TABLE Category (
    category_id       BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name              VARCHAR(100) NOT NULL,
    UNIQUE(name)
  );
    
  CREATE TABLE Product (
    product_id INT PRIMARY KEY,
    name VARCHAR(30) NOT NULL,
    manufacturer_id INT NOT NULL,
    category_id INT NOT NULL,
    CONSTRAINT manufacturer_id_fk FOREIGN KEY (manufacturer_id) REFERENCES Manufacturer(manufacturer_id),
    CONSTRAINT category_id_fk FOREIGN KEY (catagory_id) REFERENCES Category(category_id)
  );
    
  CREATE TABLE Recipe (
    product_id INT,
    ingredient_id INT,
    quantity DECIMAL(12, 2) NOT NULL,
    PRIMARY KEY (product_id, ingredient_id),
    CONSTRAINT product_id_fk FOREIGN KEY (product_id) REFERENCES Product(product_id),
    CONSTRAINT ingredient_id_fk FOREIGN KEY (ingredient_id) REFERENCES Ingredient(ingredient_id)
  );

  
  CREATE TABLE Ingredient (
    ingredient_id INT PRIMARY KEY, 
    ingredient_name VARCHAR(100) NOT NULL,
    ingredient_type ENUM('compound', 'atomic') NOT NULL
  );

  /**  
      Parent is the compound ingredient and child are all of the atomic ingredients that make up the compound ingredient.
        Example: 
          INSERT INTO Ingredient VALUES (1, 'Garlic', 'atomic'), (2, 'Tomato', 'atomic'), (3, 'Chocolate', 'atomic'), (4, 'Paprika', 'atomic'); --potential children
          INSERT INTO Ingredient VALUES (50, 'Tomato paste', 'compound') --potential parent
          INSERT INTO IngredientComposition VALUES (50, 1, 3), (50, 2, 9), (50, 4, 2); --adding garlic, tomato, and paprika to compound ingredient tomato paste.
  */
  CREATE TABLE IngredientComposition (
    parent_ingredient_id INT,
    child_ingredient_id INT,
    quantity INT,
    PRIMARY KEY (parent_ingredient_id, child_ingredient_id),
    CONSTRAINT parent_ingredient_id_fk FOREIGN KEY (parent_ingredient_id) REFERENCES Ingredient(ingredient_id),
    CONSTRAINT child_ingredient_id_fk FOREIGN KEY (child_ingredient_id) REFERENCES Ingredient(ingredient_id)
  );
    
  CREATE TABLE Manufacturer (
    manufacturer_id INT PRIMARY KEY, 
    manufacturer_name VARCHAR(100)
  );
    
  CREATE TABLE ProductBatch (
    batch_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    manufacturer_id INT NOT NULL,
    lot_number VARCHAR(100) AS CONCAT(product_id, '-', manufacturer_id, '-', batch_id),
    quantity INT NOT NULL CHECK (quantity >= 0),
    cost INT NOT NULL CHECK (cost >= 0),
    production_date DATE NOT NULL DEFAULT CURRENT_DATE, --trace product for recalls
    expiration_date DATE NOT NULL,
    CONSTRAINT product_id_fk FOREIGN KEY (product_id) REFERENCES Product(product_id),
    CONSTRAINT manufacturer_id_fk FOREIGN KEY (manufacturer_id) REFERENCES Manufacturer(manufacturer_id)
  );

  CREATE TABLE Supplier (
    supplier_id INT PRIMARY KEY,
    supplier_name VARCHAR(100) NOT NULL
  );

  CREATE TABLE IngredientBatch (
    batch_id INT AUTO_INCREMENT PRIMARY KEY,
    ingredient_id INT NOT NULL,
    supplier_id INT NOT NULL,
    lot_number VARCHAR(100) AS CONCAT(ingredient_id, '-', supplier_id, '-', batch_id),
    quantity_oz INT NOT NULL CHECK (quantity_oz >= 0),
    cost DECIMAL(12, 2) NOT NULL CHECK (cost >= 0),
    expiration_date DATE NOT NULL,
    intake_date DATE NOT NULL DEFAULT CURRENT_DATE,
    FOREIGN KEY (supplier_id) REFERENCES Supplier(supplier_id),
    FOREIGN KEY (ingredient_id) REFERENCES Ingredient(ingredient_id),
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

  CREATE TABLE DoNotCombine (
    ingredientA_id INT,
    ingredientB_id INT,
    PRIMARY KEY (ingredientA_id, ingredientB_id),
    CONSTRAINT ingredientA_id_fk FOREIGN KEY (ingredientA_id) REFERENCES Ingredient(ingredient_id),
    CONSTRAINT ingredientB_id_fk FOREIGN KEY (ingredientB_id) REFERENCES Ingredient(ingredient_id),
    CONSTRAINT check_reverse_dupes CHECK (ingredientA_id < ingredientB_id) -- no duplicates i.e. (vinegar & baking soda), (baking soda & vinegar)
  );


    
  
  
