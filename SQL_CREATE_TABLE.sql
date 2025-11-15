-- !preview conn=DBI::dbConnect(RSQLite::SQLite())

  -- for command line client only, can delete when finished with table creation
  USE wlcarte2; -- change to your user id

  DROP TABLE IF EXISTS BatchConsumption;

  DROP TABLE IF EXISTS ProductBatch;
  DROP TABLE IF EXISTS IngredientBatch;


  DROP TABLE IF EXISTS DoNotCombine;
  DROP TABLE IF EXISTS SupplierFormulationMaterials;
  DROP TABLE IF EXISTS RecipeIngredient;
  DROP TABLE IF EXISTS SupplierFormulation;
  DROP TABLE IF EXISTS Recipe;
  DROP TABLE IF EXISTS RecipePlan;
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
    
--   -- product BOM 
--   CREATE TABLE Recipe (
--     product_id INT,
--     ingredient_id INT,
--     quantity DECIMAL(10, 2) NOT NULL,
--     PRIMARY KEY (product_id, ingredient_id),
--     CONSTRAINT recipe_product_id_fk FOREIGN KEY (product_id) REFERENCES Product(product_id),
--     CONSTRAINT recipe_ingredient_id_fk FOREIGN KEY (ingredient_id) REFERENCES Ingredient(ingredient_id)
--   );

    -- Suggestion to replace Recipe table with 2 new tables (RecipePlan and RecipeIngredient) to allow for version tracking of recipes.
  CREATE TABLE RecipePlan (
    plan_id INT AUTO_INCREMENT PRIMARY KEY,  
    product_id INT NOT NULL,
    manufacturer_id VARCHAR(100) NOT NULL,
    version_no INT NOT NULL,
    creation_date DATE NOT NULL DEFAULT CURRENT_DATE,
    is_active BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE(product_id, manufacturer_id, version_no),
    CONSTRAINT rp_product_id_fk FOREIGN KEY (product_id) REFERENCES Product(product_id) ON DELETE CASCADE,
    CONSTRAINT rp_manufacturer_id_fk FOREIGN KEY (manufacturer_id) REFERENCES Manufacturer(manufacturer_id) ON DELETE CASCADE
    );

  CREATE TABLE RecipeIngredient (
    plan_id INT,
    ingredient_id INT,
    quantity DECIMAL(10, 2) NOT NULL CHECK (quantity > 0),
    PRIMARY KEY (plan_id, ingredient_id),
    CONSTRAINT ri_plan_id_fk FOREIGN KEY (plan_id) REFERENCES RecipePlan(plan_id) ON DELETE CASCADE,
    CONSTRAINT ri_ingredient_id_fk FOREIGN KEY (ingredient_id) REFERENCES Ingredient(ingredient_id) ON DELETE CASCADE
    );


    
    
--   CREATE TABLE ProductBatch (
--     batch_id INT AUTO_INCREMENT PRIMARY KEY,
--     product_id INT NOT NULL,
--     manufacturer_id VARCHAR(100) NOT NULL,
--     lot_number VARCHAR(100) UNIQUE,
--     quantity INT NOT NULL CHECK (quantity >= 0),
--     unit_cost DECIMAL(10, 2) NOT NULL CHECK (unit_cost >= 0),
--     production_date DATE NOT NULL DEFAULT CURRENT_DATE, -- trace product for recalls
--     expiration_date DATE NOT NULL,
--     plan_id INT,
--     CONSTRAINT pbatch_product_id_fk FOREIGN KEY (product_id) REFERENCES Product(product_id),
--     CONSTRAINT pbatch_manufacturer_id_fk FOREIGN KEY (manufacturer_id) REFERENCES Manufacturer(manufacturer_id),
--     CONSTRAINT pbatch_plan_id_fk FOREIGN KEY (plan_id) REFERENCES RecipePlan(plan_id) ON DELETE SET NULL
--   );
  CREATE TABLE ProductBatch (
    batch_id VARCHAR(20) NOT NULL,
    product_id INT NOT NULL,
    manufacturer_id VARCHAR(100) NOT NULL,
    lot_number VARCHAR(100) NOT NULL UNIQUE, 
    quantity INT NOT NULL CHECK (quantity >= 0),
    unit_cost DECIMAL(10, 2) NOT NULL CHECK (unit_cost >= 0),
    production_date DATE NOT NULL DEFAULT CURRENT_DATE, -- trace product for recalls
    expiration_date DATE NOT NULL,
    plan_id INT,
    PRIMARY KEY (product_id, manufacturer_id, batch_id),
    CONSTRAINT pbatch_product_id_fk FOREIGN KEY (product_id) REFERENCES Product(product_id),
    CONSTRAINT pbatch_manufacturer_id_fk FOREIGN KEY (manufacturer_id) REFERENCES Manufacturer(manufacturer_id),
    CONSTRAINT pbatch_plan_id_fk FOREIGN KEY (plan_id) REFERENCES RecipePlan(plan_id) ON DELETE SET NULL
  );


  CREATE TABLE IngredientBatch (
    batch_id VARCHAR(20) NOT NULL,
    ingredient_id INT NOT NULL,
    supplier_id VARCHAR(100) NOT NULL,
    lot_number VARCHAR(100) UNIQUE,
    quantity_oz DECIMAL(10, 2) NOT NULL CHECK (quantity_oz >= 0),
    on_hand_oz DECIMAL(10, 2) NOT NULL CHECK (on_hand_oz >= 0),
    unit_cost DECIMAL(10, 2) NOT NULL CHECK (unit_cost >= 0),
    expiration_date DATE NOT NULL,
    intake_date DATE NOT NULL DEFAULT CURRENT_DATE,
    PRIMARY KEY (ingredient_id, supplier_id, batch_id),
    CONSTRAINT ibatch_supplier_id_fk FOREIGN KEY (supplier_id) REFERENCES Supplier(supplier_id),
    CONSTRAINT ibatch_ingredient_id_fk FOREIGN KEY (ingredient_id) REFERENCES Ingredient(ingredient_id),
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
  -- DROP TRIGGER IF EXISTS generate_product_lot_number;
  DROP TRIGGER IF EXISTS generate_ingredient_lot_number; 
  DROP TRIGGER IF EXISTS prevent_expired_consumption;
  DROP TRIGGER IF EXISTS initialize_on_hand_oz; 
  DROP TRIGGER IF EXISTS update_on_hand_after_consumption;
--   DROP TRIGGER IF EXISTS update_single_active_version;
--   DROP TRIGGER IF EXISTS insert_single_active_version;
  
  /**
  	batch_id has not been generated yet but we need it for the lot_number so we trigger a lookup to see what the next autoincremented batch id number will be so we can calculate the lot number
  */
  DELIMITER // -- ; -> //

  -- product lot number
--   CREATE TRIGGER generate_product_lot_number
--   BEFORE INSERT ON ProductBatch
--   FOR EACH ROW
--   BEGIN
--       DECLARE next_id INT; -- store the next autoincrement value
--       SELECT AUTO_INCREMENT INTO next_id -- select the autoincrement val
--       FROM information_schema.TABLES -- from system table
--       WHERE TABLE_SCHEMA = DATABASE() -- current database
--       AND TABLE_NAME = 'ProductBatch'; -- product batch table
--       SET NEW.lot_number = CONCAT(NEW.product_id, '-', NEW.manufacturer_id, '-', next_id); -- create the lot number
--   END//
  
  -- ingredient lot number
--   CREATE TRIGGER generate_ingredient_lot_number
--   BEFORE INSERT ON IngredientBatch
--   FOR EACH ROW
--   BEGIN
--       DECLARE next_id INT;

--       -- query to select the latest autoincrement value and store in next_id
--       SELECT AUTO_INCREMENT INTO next_id
--       FROM information_schema.TABLES
--       WHERE TABLE_SCHEMA = DATABASE()
--       AND TABLE_NAME = 'IngredientBatch';

--       -- set the lot number
--       SET NEW.lot_number = CONCAT(NEW.ingredient_id, '-', NEW.supplier_id, '-', next_id);
--   END//

  -- prevent expired consumption
  CREATE TRIGGER generate_ingredient_lot_number
  BEFORE INSERT ON IngredientBatch
  FOR EACH ROW
  BEGIN
      -- use the manually provided batch_id to build lot_number
	  SET NEW.lot_number = CONCAT(NEW.ingredient_id, '-', NEW.supplier_id, '-', NEW.batch_id);
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
  
--   -- should only have 1 active version of recipe so we know which recipe to use
--   CREATE TRIGGER insert_single_active_version -- new version is the active one
--   AFTER INSERT ON RecipePlan
--   FOR EACH ROW
--   BEGIN
--       IF NEW.is_active = TRUE THEN
--           -- all other plans should be false
--           UPDATE RecipePlan
--           SET is_active = FALSE
--           WHERE product_id = NEW.product_id
--           AND manufacturer_id = NEW.manufacturer_id
--           AND plan_id != NEW.plan_id;
--       END IF;
--   END//
--   
--   CREATE TRIGGER update_single_active_version 
--   BEFORE UPDATE ON RecipePlan
--   FOR EACH ROW
--   BEGIN
--       -- old recipe plan becomes active, all others are not active
--       IF NEW.is_active = TRUE AND OLD.is_active = FALSE THEN
--           -- all other recipe plans should not be active
--           UPDATE RecipePlan
--           SET is_active = FALSE
--           WHERE product_id = NEW.product_id
--           AND manufacturer_id = NEW.manufacturer_id
--           AND plan_id != new.plan_id;
--       END IF;
--   END//
  
  
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
    IN p_ingredient_lots JSON, -- [{"lot_number": "8-SUP001-1", "quantity": 100.0}, {...}, {...}]
    IN p_plan_id INT,
    IN p_batch_id VARCHAR(20)
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
      
      SET local_product_lot = CONCAT(p_product_id, '-', p_manufacturer_id, '-', p_batch_id);
    
      -- make sure plan version exists for product
      IF NOT EXISTS (
          SELECT * FROM RecipePlan
          WHERE plan_id = p_plan_id
          AND product_id = p_product_id
          AND manufacturer_id = p_manufacturer_id
      ) THEN 
          SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'Invald plan_id';
      END IF;
      -- atomicity
      START TRANSACTION;
    
      -- create product batch tuple
      INSERT INTO ProductBatch (batch_id, lot_number, product_id, manufacturer_id, quantity, unit_cost, expiration_date, plan_id)
      VALUES (p_batch_id, local_product_lot, p_product_id, p_manufacturer_id, p_quantity, 0.0, p_expiration_date, p_plan_id); -- unit cost will be calculated, default 0
    
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
  
  DROP VIEW IF EXISTS current_active_supplier_formulations;
  DROP VIEW IF EXISTS flattened_product_bom;
  DROP VIEW IF EXISTS health_risk_violations_last_30_days;
  
  -- current active supplier formulations
  CREATE VIEW current_active_supplier_formulations AS
  SELECT 
      sf.formulation_id,
      sf.supplier_id,
      s.supplier_name,
      sf.ingredient_id,
      i.ingredient_name,
      i.ingredient_type,
      sf.version_no,
      sf.pack_size,
      sf.price_per_unit,
      sf.effective_period_start_date,
      sf.effective_period_end_date
  FROM SupplierFormulation sf
  JOIN Supplier s ON sf.supplier_id = s.supplier_id
  JOIN Ingredient i ON sf.ingredient_id = i.ingredient_id
  WHERE CURDATE() BETWEEN sf.effective_period_start_date 
      AND COALESCE(sf.effective_period_end_date, '9999-12-31');





  -- flattened bom view
  CREATE VIEW flattened_product_bom AS
  SELECT 
      rp.plan_id,
      rp.product_id,
      p.name AS product_name,
      rp.manufacturer_id,
      m.manufacturer_name,
      rp.version_no,
      rp.is_active,
      -- show both compound and atomic ingredients
      ri.ingredient_id AS bom_ingredient_id,
      i.ingredient_name AS bom_ingredient_name,
      i.ingredient_type AS bom_ingredient_type,
      ri.quantity AS bom_quantity,
      -- for atomic: show itself; for compound: show child
      COALESCE(ic.child_ingredient_id, ri.ingredient_id) AS atomic_ingredient_id,
      COALESCE(ai.ingredient_name, i.ingredient_name) AS atomic_ingredient_name,
      -- calculate atomic quantity (if compound, distribute proportionally)
      CASE 
          WHEN i.ingredient_type = 'atomic' THEN ri.quantity
          ELSE ri.quantity * ic.quantity / 
             (SELECT SUM(quantity) FROM IngredientComposition WHERE parent_ingredient_id = i.ingredient_id)
      END AS atomic_quantity_oz
  FROM RecipePlan rp
  JOIN Product p ON rp.product_id = p.product_id
  JOIN Manufacturer m ON rp.manufacturer_id = m.manufacturer_id
  JOIN RecipeIngredient ri ON rp.plan_id = ri.plan_id
  JOIN Ingredient i ON ri.ingredient_id = i.ingredient_id
  LEFT JOIN IngredientComposition ic ON i.ingredient_id = ic.parent_ingredient_id AND i.ingredient_type = 'compound'
  LEFT JOIN Ingredient ai ON ic.child_ingredient_id = ai.ingredient_id;







  -- health risk violation view
  CREATE VIEW health_risk_violations_last_30_days AS
  SELECT DISTINCT
      pb.lot_number AS product_lot_number,
      pb.product_id,
      p.name AS product_name,
      pb.manufacturer_id,
      pb.production_date,
      dnc.ingredientA_id,
      ia.ingredient_name AS ingredientA_name,
      dnc.ingredientB_id,
      ib.ingredient_name AS ingredientB_name,
    'Incompatible ingredients detected' AS violation_type
  FROM ProductBatch pb
  JOIN Product p ON pb.product_id = p.product_id
  JOIN BatchConsumption bc1 ON pb.lot_number = bc1.product_lot_number
  JOIN IngredientBatch ib1 ON bc1.ingredient_lot_number = ib1.lot_number
  JOIN BatchConsumption bc2 ON pb.lot_number = bc2.product_lot_number
  JOIN IngredientBatch ib2 ON bc2.ingredient_lot_number = ib2.lot_number
  JOIN DoNotCombine dnc ON (
      (ib1.ingredient_id = dnc.ingredientA_id AND ib2.ingredient_id = dnc.ingredientB_id) OR
      (ib1.ingredient_id = dnc.ingredientB_id AND ib2.ingredient_id = dnc.ingredientA_id)
  )
  JOIN Ingredient ia ON dnc.ingredientA_id = ia.ingredient_id
  JOIN Ingredient ib ON dnc.ingredientB_id = ib.ingredient_id
  WHERE pb.production_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    AND bc1.ingredient_lot_number < bc2.ingredient_lot_number; -- avoid duplicates


  
  DELIMITER ; -- // -> ;
  
