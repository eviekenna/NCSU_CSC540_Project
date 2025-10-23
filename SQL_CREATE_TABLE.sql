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
    on_hand_oz DECIMAL(10, 2) NOT NULL CHECK (on_hand_oz >= 0),
    unit_cost DECIMAL(10, 2) NOT NULL CHECK (unit_cost >= 0),
    expiration_date DATE NOT NULL,
    intake_date DATE NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT batch_supplier_id_fk FOREIGN KEY (supplier_id) REFERENCES Supplier(supplier_id),
    CONSTRAINT batch_ingredient_id_fk FOREIGN KEY (ingredient_id) REFERENCES Ingredient(ingredient_id),
    CONSTRAINT check_90_day_minimum CHECK (DATEDIFF(expiration_date, intake_date) >= 90)
  );

  -- versioning for formulation
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
    i.e. supplier A seasoning blend is different from supplier B seasoning blend. Tracks what is in formulation
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


  -- Triggers
  DROP TRIGGER IF EXISTS generate_product_lot_number;
  DROP TRIGGER IF EXISTS generate_ingredient_lot_number; 
  DROP TRIGGER IF EXISTS prevent_expired_consumption;
  DROP TRIGGER IF EXISTS initialize_on_hand_oz; 
  DROP TRIGGER IF EXISTS update_on_hand_after_consumption;
  
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

  -- prevent expired consumption
  CREATE TRIGGER prevent_expired_consumption
  BEFORE INSERT ON BatchConsumption
  FOR EACH ROW
  BEGIN
      DECLARE lot_expiration_date DATE; -- local variable
    
      -- get expiration date of the ingredient lot
      SELECT expiration_date INTO lot_expiration_date
      FROM IngredientBatch
      WHERE lot_number = NEW.ingredient_lot_number; -- ingredient lot number from new row
    
      -- check if expired
      IF NOW() > lot_expiration_date THEN
          SIGNAL SQLSTATE '45000' -- raise error
          SET MESSAGE_TEXT = 'You should not consume an expired ingredient lot.';
      END IF;
  END//
  
  -- initialize the on hand available oz to the quantity oz when a new ingredient batch is received
  CREATE TRIGGER initialize_on_hand_oz
  BEFORE INSERT ON IngredientBatch
  FOR EACH ROW
  BEGIN
      -- on_hand_oz equal to quantity_oz with new batch
      SET NEW.on_hand_oz = NEW.quantity_oz;
  END//
  
  -- decrement on_hand_oz when consumed
  CREATE TRIGGER update_on_hand_after_consumption
  AFTER INSERT ON BatchConsumption
  FOR EACH ROW
  BEGIN
      -- decrement on_hand_oz on consumption
      UPDATE IngredientBatch
      SET on_hand_oz = on_hand_oz - NEW.quantity_consumed
      WHERE lot_number = NEW.ingredient_lot_number;
    
      -- make sure on_hand_oz is not negative after consumption
      IF (SELECT on_hand_oz FROM IngredientBatch WHERE lot_number = NEW.ingredient_lot_number) < 0 THEN
          SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'Not enough of ingredient in lot for consumption.';
      END IF;
  END//
  
  
  -- Stored Procedures
  DROP PROCEDURE IF EXISTS record_production_batch;
  DROP PROCEDURE IF EXISTS trace_recall;
  DROP PROCEDURE IF EXISTS evaluate_health_risk;

  -- record production batch
  /**
    Creates the product batch, consumes declared ingredient lots atomically, computes cost, and writes finished goods inventory.
  */
  CREATE PROCEDURE record_production_batch(
    -- input parameters
    IN p_product_id INT,
    IN p_manufacturer_id VARCHAR(100),
    IN p_quantity INT,
    IN p_expiration_date DATE,
    IN p_ingredient_lots JSON -- [{"lot_number": "8-SUP001-1", "quantity": 100.0}, {...}, {...}]
  )
  BEGIN
      DECLARE local_total_cost DECIMAL(10, 2) DEFAULT 0.0; -- total cost of all ingredients starts at 0
      DECLARE local_unit_cost DECIMAL(10, 2); -- cost per unit of final product
      DECLARE local_product_lot VARCHAR(100); -- generated lot number of product batch
      DECLARE local_idx INT DEFAULT 0; -- counter for loop which is ingredient lot to process
      DECLARE local_lot_count INT; -- number of total ingredients
      DECLARE local_current_lot VARCHAR(100); -- current ingredient lot being processed
      DECLARE local_current_qty DECIMAL(10, 2); -- how much of current ingredient used
      DECLARE local_ingredient_cost DECIMAL(10, 2); -- cost per oz of curr ingredient
    
      -- atomicity
      START TRANSACTION;
    
      -- create product batch tuple
      INSERT INTO ProductBatch (product_id, manufacturer_id, quantity, unit_cost, expiration_date) -- batch_id is autoincremented and lot_number is generated by trigger
      VALUES (p_product_id, p_manufacturer_id, p_quantity, 0.0, p_expiration_date); -- unit cost will be calculated, default 0
    
      -- get generated lot number
      SET local_product_lot = (SELECT lot_number FROM ProductBatch WHERE batch_id = LAST_INSERT_ID()); -- get latest autoincremented value which is batch_id and filter by that, select the lot_number and set it to local product lot
    
      -- get count of ingredient lots to know how many runs in loop
      SET local_lot_count = JSON_LENGTH(p_ingredient_lots);
    
      -- process each ingredient lot
      WHILE local_idx < local_lot_count DO
          -- get lot number and quantity from JSON object
          SET local_current_lot = JSON_UNQUOTE(JSON_EXTRACT(p_ingredient_lots, CONCAT('$[', local_idx, '].lot_number'))); -- get the element at local index from the lots array and remove the quotes
          SET local_current_qty = JSON_EXTRACT(p_ingredient_lots, CONCAT('$[', local_idx, '].quantity')); -- get the quantity
        
          -- get incredient cost from batch  Get cost per oz for this ingredient lot
          SELECT unit_cost INTO local_ingredient_cost -- select unit cost and put into local var
          FROM IngredientBatch -- grab from IngredientBatch table
          WHERE lot_number = local_current_lot; -- filter on specific lot number
        
          -- add to summation of total cost. local_total_cost += qty * cost
          SET local_total_cost = local_total_cost + (local_current_qty * local_ingredient_cost);
        
          -- record the consumption (triggers will execute for update_on_hand_after_consumption and prevent_expired_consumption)
          INSERT INTO BatchConsumption (product_lot_number, ingredient_lot_number, quantity_consumed)
          VALUES (local_product_lot, local_current_lot, local_current_qty);
        
          SET local_idx = local_idx + 1; -- increment counter
      END WHILE; -- end loop after processing all lots
    
      -- calculate unit cost
      SET local_unit_cost = local_total_cost / p_quantity;
    
      -- update ProductBatch with calculated unit_cost, remember intially was 0 before calculations
      UPDATE ProductBatch
      SET unit_cost = local_unit_cost
      WHERE lot_number = local_product_lot;
    
      -- commit transaction to make changes permanent, does not commit if there was any error at any step
      COMMIT;
    
  END//
  
  
  -- trace recall
  /** 
    Need to compute transitive closure, so follow contamination through all levels of production. 
    contaminated butter -> contaminated gravy -> contaminated steak dinner
    steak dinner is transitively contaminated by the bad butter.
    Find all products that used contaminated ingredient bc no multilevel product parent/child relationship.
  */
  CREATE PROCEDURE trace_recall (
      -- input parameters
      IN p_ingredient_lot_number VARCHAR(100), -- ingredient that is recalled
      IN p_recall_date DATE, -- date of issued recall 
      IN p_window INT -- number of days in recall window
  )
  
  BEGIN
      DECLARE recall_start_date DATE;
      DECLARE recall_end_date DATE;

      -- get the start and end date of the recall window
      SET recall_start_date = DATE_SUB(p_recall_date, INTERVAL p_window DAY); -- recall start date is p_window days before the issued recall date
      SET recall_end_date = DATE_ADD(p_recall_date, INTERVAL p_window DAY); -- recall end date is p_window days after the issued recall date
      
      
      -- find products that included the recalled ingredient lot within the time frame
      SELECT
          pb.lot_number AS contaminated_product_lot -- product affected
      FROM BatchConsumption AS bc -- info about products produced and ingredients used
      JOIN ProductBatch AS pb ON bc.product_lot_number = pb.lot_number -- finished product batchs
      WHERE bc.ingredient_lot_number = p_ingredient_lot_number -- filter so you get only consumption that included recalled ingredient lot
            AND bc.consumption_date BETWEEN recall_start_date AND recall_end_date; -- fliter to get consumption within the desired window
  END//
      
      
 
  -- evaluate health risk
  CREATE PROCEDURE evaluate_health_risk(
    -- input parameters
    IN p_ingredient_list JSON -- array of ingredients
  )
  BEGIN
      -- local variables
      DECLARE ingredient_count INT; -- count of ingredients
      DECLARE idx_a INT DEFAULT 0; -- index a (first ingredient index)
      DECLARE idx_b INT; -- index b (second ingredient index)
      DECLARE ingredient_a INT; -- first ingredient to compare
      DECLARE ingredient_b INT; -- second ingredient to compare
    
      -- number of elements in array
      SET ingredient_count = JSON_LENGTH(p_ingredient_list);
    
      -- check all pairs of ingredients
      WHILE idx_a < ingredient_count DO -- while index is valid first ingredient
          SET ingredient_a = JSON_EXTRACT(p_ingredient_list, CONCAT('$[', idx_a, ']')); -- pull ingredient from JSON array via path $[index]
          SET idx_b = idx_a + 1; -- set second index to one after first so dont compare to itself
        
          WHILE idx_b < ingredient_count DO -- while index is valid second ingredient
              SET ingredient_b = JSON_EXTRACT(p_ingredient_list, CONCAT('$[', idx_b, ']')); -- pull next ingredient in array
            
              -- check if this pair conflicts
              IF EXISTS ( -- true if conflict exists
                  -- query
                  SELECT *
                  FROM DoNotCombine AS dnc -- querying DNC table
                  WHERE (dnc.ingredientA_id = LEAST(ingredient_a, ingredient_b) -- DNC table is set up so pairs are in sorted order (reverse dupes constraint)
                     AND dnc.ingredientB_id = GREATEST(ingredient_a, ingredient_b))
              ) THEN -- if true then execute this block
                  SIGNAL SQLSTATE '45000' -- throw error
                  SET MESSAGE_TEXT = 'Incompatible ingredients detected';
              END IF;
            
              SET idx_b = idx_b + 1; -- move to next B ingredient
          END WHILE; -- all combinations of B ingredient tested
        
          SET idx_a = idx_a + 1; -- move to next A ingredient
      END WHILE; -- all combinations of ingredients tested
    
      -- no conflicts found, return message of no health risks
      SELECT 'No health risks detected.' AS health_risk;
  END// 
  
  DELIMITER ; -- // -> ;
  
  
  /* Populate tables with Insert */
  -- insert Users
  INSERT INTO User VALUES ('MFG001', 'John', 'Smith', 'MANUFACTURER');
  INSERT INTO User VALUES ('MFG002', 'Alice', 'Lee', 'MANUFACTURER');
  INSERT INTO User VALUES ('SUP001', 'Jane', 'Doe', 'SUPPLIER');
  INSERT INTO User VALUES ('SUP020', 'Albert', 'Sup', 'SUPPLIER');
  INSERT INTO User VALUES ('SUP021', 'Baxter', 'Sup', 'SUPPLIER');
  INSERT INTO User VALUES ('VIEW001', 'Bob', 'Johnson', 'VIEWER');

  -- insert Manufacturers
  INSERT INTO Manufacturer VALUES ('MFG001', 'JBS');
  INSERT INTO Manufacturer VALUES ('MFG002', 'General Mills');

  -- insert Suppliers
  INSERT INTO Supplier VALUES ('SUP020', 'Supplier A');
  INSERT INTO Supplier VALUES ('SUP021', 'Supplier B');
  INSERT INTO Supplier VALUES ('SUP001', 'Jane Doe LLC');

  -- insert Categories
  INSERT INTO Category VALUES (2, 'Dinners');
  INSERT INTO Category VALUES (3, 'Sides');

  -- insert Ingredients
  INSERT INTO Ingredient VALUES (101, 'Salt', 'atomic');
  INSERT INTO Ingredient VALUES (102, 'Pepper', 'atomic');
  INSERT INTO Ingredient VALUES (104, 'Sodium Phosphate', 'atomic');
  INSERT INTO Ingredient VALUES (106, 'Beef Steak', 'atomic');
  INSERT INTO Ingredient VALUES (108, 'Pasta', 'atomic');
  INSERT INTO Ingredient VALUES (201, 'Seasoning Blend', 'compound');
  INSERT INTO Ingredient VALUES (301, 'Super Seasoning', 'compound');

  -- insert Products
  INSERT INTO Product VALUES (100, 'Steak Dinner', 'MFG001', 2, 500);
  INSERT INTO Product VALUES (101, 'Mac & Cheese', 'MFG002', 3, 300);

  -- insert Recipes (product BOM)
  INSERT INTO Recipe VALUES (100, 106, 6.0);   -- Steak Dinner calls for 6oz Beef Steak
  INSERT INTO Recipe VALUES (100, 201, 0.2);   -- Steak Dinner calls for 0.2oz Seasoning Blend
  INSERT INTO Recipe VALUES (101, 108, 7.0);   -- Mac & Cheese calls for 7oz Pasta
  INSERT INTO Recipe VALUES (101, 101, 0.5);   -- Mac & Cheese calls for 0.5oz Salt
  INSERT INTO Recipe VALUES (101, 102, 2.0);   -- Mac & Cheese calls for 2oz Pepper

  -- seasoning blend
  INSERT INTO IngredientComposition VALUES (201, 101, 6.0);  -- Seasoning Blend has Salt
  INSERT INTO IngredientComposition VALUES (201, 102, 2.0);  -- Seasoning Blend has Pepper
  
  -- SUP020 version 1 of Seasoning Blend
  INSERT INTO SupplierFormulation (supplier_id, ingredient_id, version_no, pack_size, price_per_unit, effective_period_start_date, effective_period_end_date)
  VALUES ('SUP020', 201, 1, 8.0, 2.5, '2025-01-01', '2025-06-30');
  -- formulation_id = 1

  -- SUP020 formulation
  INSERT INTO SupplierFormulationMaterials VALUES (1, 101, 6.0);
  INSERT INTO SupplierFormulationMaterials VALUES (1, 102, 2.0);

  -- conflict pairs
  INSERT INTO DoNotCombine VALUES (104, 201);
  INSERT INTO DoNotCombine VALUES (104, 106);

  -- Salt (101) batches
  INSERT INTO IngredientBatch (ingredient_id, supplier_id, quantity_oz, unit_cost, expiration_date)
  VALUES (101, 'SUP020', 1000.0, 0.1, '2026-11-15');
  -- trigger generates the lot_number to be '101-SUP020-1'
  -- don't include batch_id, lot_number, on_hand_oz, or intake_date bc of auto-incr, triggers, default value

  INSERT INTO IngredientBatch (ingredient_id, supplier_id, quantity_oz, unit_cost, expiration_date)
  VALUES (101, 'SUP021', 800.0, 0.08, '2026-10-30');
  -- trigger generates the lot_number to be '101-SUP021-2'

  INSERT INTO IngredientBatch (ingredient_id, supplier_id, quantity_oz, unit_cost, expiration_date)
  VALUES (101, 'SUP020', 500.0, 0.1, '2026-11-01');
  -- trigger generates the lot_number to be '101-SUP020-3'

  INSERT INTO IngredientBatch (ingredient_id, supplier_id, quantity_oz, unit_cost, expiration_date)
  VALUES (101, 'SUP020', 500.0, 0.1, '2026-12-15');
  -- trigger generates the lot_number to be '101-SUP020-4'

  -- Pepper (102) batches
  INSERT INTO IngredientBatch (ingredient_id, supplier_id, quantity_oz, unit_cost, expiration_date)
  VALUES (102, 'SUP020', 1200.0, 0.3, '2026-12-15');
  -- trigger generates the lot_number to be '102-SUP020-5'

  -- Beef Steak (106) batches
  INSERT INTO IngredientBatch (ingredient_id, supplier_id, quantity_oz, unit_cost, expiration_date)
  VALUES (106, 'SUP020', 3000.0, 0.5, '2026-12-15');
  -- trigger generates the lot_number to be '106-SUP020-6'

  INSERT INTO IngredientBatch (ingredient_id, supplier_id, quantity_oz, unit_cost, expiration_date)
  VALUES (106, 'SUP020', 600.0, 0.5, '2026-12-20');
  -- trigger generates the lot_number to be '106-SUP020-7'

  -- Pasta (108) batches
  INSERT INTO IngredientBatch (ingredient_id, supplier_id, quantity_oz, unit_cost, expiration_date)
  VALUES (108, 'SUP020', 1000.0, 0.25, '2026-09-28');
  -- trigger generates the lot_number to be '108-SUP020-8'

  INSERT INTO IngredientBatch (ingredient_id, supplier_id, quantity_oz, unit_cost, expiration_date)
  VALUES (108, 'SUP020', 6300.0, 0.25, '2026-12-31');
  -- trigger generates the lot_number to be '108-SUP020-9'

  -- Seasoning Blend (201) batches
  INSERT INTO IngredientBatch (ingredient_id, supplier_id, quantity_oz, unit_cost, expiration_date)
  VALUES (201, 'SUP020', 100.0, 2.5, '2026-11-30');
  -- trigger generates the lot_number to be '201-SUP020-10'

  INSERT INTO IngredientBatch (ingredient_id, supplier_id, quantity_oz, unit_cost, expiration_date)
  VALUES (201, 'SUP020', 20.0, 2.5, '2026-12-30');
  -- trigger generates the lot_number to be '201-SUP020-11'


  -- call the record_production_batch procedure to create product batches and batch consumption records

  -- product Bbatch 1: Steak Dinner 100 units
  CALL record_production_batch(
      100,                    -- product_id: Steak Dinner
      'MFG001',              -- manufacturer_id
      100,                    -- quantity: 100 units
      '2026-11-15',          -- expiration_date
      '[
          {"lot_number": "106-SUP020-7", "quantity": 600.0},
          {"lot_number": "201-SUP020-11", "quantity": 20.0}
      ]'
  );

  -- product batch 2: Mac & Cheese 300 units
  CALL record_production_batch(
      101,                    -- product_id: Mac & Cheese
      'MFG002',              -- manufacturer_id
      300,                    -- quantity: 300 units
      '2026-10-30',          -- expiration_date
      '[
          {"lot_number": "101-SUP020-3", "quantity": 150.0},
          {"lot_number": "108-SUP020-9", "quantity": 2100.0},
          {"lot_number": "102-SUP020-5", "quantity": 600.0}
      ]'
  );
  


  
  
  
  
  
  
  /* Populate tables with Insert */
  
  
