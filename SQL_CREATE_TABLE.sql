-- !preview conn=DBI::dbConnect(RSQLite::SQLite())

  -- for command line client only, can delete when finished with table creation
  USE wlcarte2; -- change to your user id

  DROP TABLE IF EXISTS BatchConsumption;
  DROP TABLE IF EXISTS DoNotCombine;
  DROP TABLE IF EXISTS SupplierFormulationMaterials;
  DROP TABLE IF EXISTS SupplierFormulation;
  DROP TABLE IF EXISTS IngredientBatch;
  DROP TABLE IF EXISTS ProductBatch;
  DROP TABLE IF EXISTS Recipe;
  DROP TABLE IF EXISTS IngredientComposition;
  DROP TABLE IF EXISTS Product;
  DROP TABLE IF EXISTS Supplier;
  DROP TABLE IF EXISTS Manufacturer;
  DROP TABLE IF EXISTS Ingredient;
  DROP TABLE IF EXISTS Category;
  DROP TABLE IF EXISTS User;


  CREATE TABLE User (
    user_id VARCHAR(100) PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role_code ENUM('MANUFACTURER', 'SUPPLIER', 'VIEWER') NOT NULL
  );

  CREATE TABLE Category (
    category_id       INT UNSIGNED PRIMARY KEY,
    name              VARCHAR(100) NOT NULL,
    UNIQUE(name)
  );

  CREATE TABLE Ingredient (
    ingredient_id INT PRIMARY KEY, 
    ingredient_name VARCHAR(100) NOT NULL,
    ingredient_type ENUM('compound', 'atomic') NOT NULL
  );

  CREATE TABLE Manufacturer (
    manufacturer_id VARCHAR(100) PRIMARY KEY, 
    manufacturer_name VARCHAR(100),
    CONSTRAINT manf_user_fk FOREIGN KEY (manufacturer_id) REFERENCES User(user_id)
  );

  CREATE TABLE Supplier (
    supplier_id VARCHAR(100) PRIMARY KEY,
    supplier_name VARCHAR(100) NOT NULL,
    CONSTRAINT sup_user_fk FOREIGN KEY (supplier_id) REFERENCES User(user_id)
  );
    
  CREATE TABLE Product (
    product_id INT PRIMARY KEY,
    name VARCHAR(30) NOT NULL,
    manufacturer_id VARCHAR(100) NOT NULL,
    category_id INT UNSIGNED NOT NULL,
    standard_batch_units INT NOT NULL,
    CONSTRAINT prod_manufacturer_id_fk FOREIGN KEY (manufacturer_id) REFERENCES Manufacturer(manufacturer_id),
    CONSTRAINT prod_category_id_fk FOREIGN KEY (category_id) REFERENCES Category(category_id)
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
    quantity DECIMAL(10, 2) NOT NULL CHECK (quantity > 0),
    PRIMARY KEY (parent_ingredient_id, child_ingredient_id),
    CONSTRAINT parent_ingredient_id_fk FOREIGN KEY (parent_ingredient_id) REFERENCES Ingredient(ingredient_id),
    CONSTRAINT child_ingredient_id_fk FOREIGN KEY (child_ingredient_id) REFERENCES Ingredient(ingredient_id),
    CONSTRAINT parent_notequal_child CHECK (parent_ingredient_id != child_ingredient_id)
  );
    
  -- product BOM 
  CREATE TABLE Recipe (
    product_id INT,
    ingredient_id INT,
    quantity DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (product_id, ingredient_id),
    CONSTRAINT recipe_product_id_fk FOREIGN KEY (product_id) REFERENCES Product(product_id),
    CONSTRAINT recipe_ingredient_id_fk FOREIGN KEY (ingredient_id) REFERENCES Ingredient(ingredient_id)
  );

    
    
  CREATE TABLE ProductBatch (
    batch_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    manufacturer_id VARCHAR(100) NOT NULL,
    lot_number VARCHAR(100) UNIQUE,
    quantity INT NOT NULL CHECK (quantity >= 0),
    unit_cost DECIMAL(10, 2) NOT NULL CHECK (unit_cost >= 0),
    production_date DATE NOT NULL DEFAULT CURRENT_DATE, -- trace product for recalls
    expiration_date DATE NOT NULL,
    CONSTRAINT batch_product_id_fk FOREIGN KEY (product_id) REFERENCES Product(product_id),
    CONSTRAINT batch_manufacturer_id_fk FOREIGN KEY (manufacturer_id) REFERENCES Manufacturer(manufacturer_id)
  );


  CREATE TABLE IngredientBatch (
    batch_id INT AUTO_INCREMENT PRIMARY KEY,
    ingredient_id INT NOT NULL,
    supplier_id VARCHAR(100) NOT NULL,
    lot_number VARCHAR(100) UNIQUE,
    quantity_oz DECIMAL(10, 2) NOT NULL CHECK (quantity_oz >= 0),
    available_oz DECIMAL(10, 2) NOT NULL CHECK (available_oz >= 0),
    unit_cost DECIMAL(10, 2) NOT NULL CHECK (unit_cost >= 0),
    expiration_date DATE NOT NULL,
    intake_date DATE NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT batch_supplier_id_fk FOREIGN KEY (supplier_id) REFERENCES Supplier(supplier_id),
    CONSTRAINT batch_ingredient_id_fk FOREIGN KEY (ingredient_id) REFERENCES Ingredient(ingredient_id),
    CONSTRAINT check_90_day_minimum CHECK (DATEDIFF(expiration_date, intake_date) >= 90)
  );

  -- ingredient formulation
  CREATE TABLE SupplierFormulation (
    formulation_id INT AUTO_INCREMENT PRIMARY KEY,
    supplier_id VARCHAR(100) NOT NULL,
    ingredient_id INT NOT NULL,
    version_no INT NOT NULL,
    pack_size DECIMAL(10, 2) NOT NULL CHECK (pack_size > 0),
    price_per_unit DECIMAL(10, 2) NOT NULL CHECK (price_per_unit >= 0),
    effective_period_start_date DATE NOT NULL,
    effective_period_end_date DATE,
    UNIQUE (supplier_id, ingredient_id, version_no), -- supplier version of ingredients should be unique
    CONSTRAINT form_supplier_id_fk FOREIGN KEY (supplier_id) REFERENCES Supplier(supplier_id),
    CONSTRAINT form_ingredient_id_fk FOREIGN KEY (ingredient_id) REFERENCES Ingredient(ingredient_id),
    CONSTRAINT date_order CHECK (effective_period_end_date IS NULL OR effective_period_start_date < effective_period_end_date) -- doesn't expire or start date is before end date
  );

  /** different suppliers can have different formulations 
    i.e. supplier A seasoning blend is different from supplier B seasoning blend
  */
  CREATE TABLE SupplierFormulationMaterials (
    formulation_id INT NOT NULL,
    ingredient_id INT NOT NULL,
    qty DECIMAL(10, 2) NOT NULL CHECK (qty > 0),
    PRIMARY KEY (formulation_id, ingredient_id), 
    CONSTRAINT supmat_formulation_id_fk FOREIGN KEY (formulation_id) REFERENCES SupplierFormulation(formulation_id),
    CONSTRAINT supmat_ingredient_fk FOREIGN KEY (ingredient_id) REFERENCES Ingredient(ingredient_id)
  );

  CREATE TABLE BatchConsumption (
    product_lot_number VARCHAR(100) NOT NULL,
    ingredient_lot_number VARCHAR(100) NOT NULL,
    quantity_consumed DECIMAL(10, 2) NOT NULL,
    consumption_date DATE NOT NULL DEFAULT CURRENT_DATE, -- for recall 20 day window
    PRIMARY KEY (product_lot_number, ingredient_lot_number),
    CONSTRAINT bcons_product_lot_number_fk FOREIGN KEY (product_lot_number) REFERENCES ProductBatch(lot_number),
    CONSTRAINT bcons_ingredient_lot_number_fk FOREIGN KEY (ingredient_lot_number) REFERENCES IngredientBatch(lot_number)
  );

  CREATE TABLE DoNotCombine (
    ingredientA_id INT,
    ingredientB_id INT,
    PRIMARY KEY (ingredientA_id, ingredientB_id),
    CONSTRAINT dnc_ingredientA_id_fk FOREIGN KEY (ingredientA_id) REFERENCES Ingredient(ingredient_id),
    CONSTRAINT dnc_ingredientB_id_fk FOREIGN KEY (ingredientB_id) REFERENCES Ingredient(ingredient_id),
    CONSTRAINT check_reverse_dupes CHECK (ingredientA_id < ingredientB_id) -- no duplicates i.e. (vinegar & baking soda), (baking soda & vinegar)
  );


  /* Triggers */
  
  /**
  	batch_id has not been generated yet but we need it for the lot_number so we trigger a lookup to see what the next autoincremented batch id number will be so we can calculate the lot number
  */
  DELIMITER // -- ; -> //

  -- product lot number
  CREATE TRIGGER generate_product_lot_number
  BEFORE INSERT ON ProductBatch
  FOR EACH ROW
  BEGIN
      DECLARE next_id INT; -- store the next autoincrement value
      SELECT AUTO_INCREMENT INTO next_id -- select the autoincrement val
      FROM information_schema.TABLES -- from system table
      WHERE TABLE_SCHEMA = DATABASE() -- current database
      AND TABLE_NAME = 'ProductBatch'; -- product batch table
      SET NEW.lot_number = CONCAT(NEW.product_id, '-', NEW.manufacturer_id, '-', next_id); -- create the lot number
  END//
  
  -- ingredient lot number
  CREATE TRIGGER generate_ingredient_lot_number
  BEFORE INSERT ON IngredientBatch
  FOR EACH ROW
  BEGIN
      DECLARE next_id INT;
      SELECT AUTO_INCREMENT INTO next_id
      FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'IngredientBatch';
      SET NEW.lot_number = CONCAT(NEW.ingredient_id, '-', NEW.supplier_id, '-', next_id);
  END//

  DELIMITER ; -- // -> ;
  
  
  
  
  
  
  
  
  
  
  /* Populate tables with Insert */
  
