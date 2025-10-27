-- !preview conn=DBI::dbConnect(RSQLite::SQLite())

  -- for command line client only, can delete when finished with table creation
  USE wlcarte2; -- change to your user id

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

--   -- insert Recipes (product BOM)
--   INSERT INTO Recipe VALUES (100, 106, 6.0);   -- Steak Dinner calls for 6oz Beef Steak
--   INSERT INTO Recipe VALUES (100, 201, 0.2);   -- Steak Dinner calls for 0.2oz Seasoning Blend
--   INSERT INTO Recipe VALUES (101, 108, 7.0);   -- Mac & Cheese calls for 7oz Pasta
--   INSERT INTO Recipe VALUES (101, 101, 0.5);   -- Mac & Cheese calls for 0.5oz Salt
--   INSERT INTO Recipe VALUES (101, 102, 2.0);   -- Mac & Cheese calls for 2oz Pepper

  -- Steak Dinner recipe plan version1
  INSERT INTO RecipePlan (product_id, manufacturer_id, version_no, is_active)
  VALUES (100, 'MFG001', 1, TRUE);

  SET @steak_plan_id = LAST_INSERT_ID();

  INSERT INTO RecipeIngredient VALUES (@steak_plan_id, 106, 6.0);   -- Beef
  INSERT INTO RecipeIngredient VALUES (@steak_plan_id, 201, 0.2);   -- Seasoning Blend
  
  -- Mac & Cheese recipe plan version1
  INSERT INTO RecipePlan (product_id, manufacturer_id, version_no, is_active)
  VALUES (101, 'MFG002', 1, TRUE);

  SET @mac_plan_id = LAST_INSERT_ID();

  INSERT INTO RecipeIngredient VALUES (@mac_plan_id, 108, 7.0);   -- Pasta
  INSERT INTO RecipeIngredient VALUES (@mac_plan_id, 101, 0.5);   -- Salt
  INSERT INTO RecipeIngredient VALUES (@mac_plan_id, 102, 2.0);   -- Pepper


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
  -- get the active plan for Steak Dinner
  SET @steak_dinner_plan = (SELECT plan_id FROM RecipePlan WHERE product_id = 100 AND is_active = TRUE);
  CALL record_production_batch(
      100,                    -- product_id: Steak Dinner
      'MFG001',              -- manufacturer_id
      100,                    -- quantity: 100 units
      '2026-11-15',          -- expiration_date
      '[
          {"lot_number": "106-SUP020-7", "quantity": 600.0},
          {"lot_number": "201-SUP020-11", "quantity": 20.0}
      ]',
      @steak_dinner_plan
  );

  -- product batch 2: Mac & Cheese 300 units
  -- get the active plan for Mac & Cheese
  SET @mac_and_cheese_plan = (SELECT plan_id FROM RecipePlan WHERE product_id = 101 AND is_active = TRUE);
  CALL record_production_batch(
      101,                    -- product_id: Mac & Cheese
      'MFG002',              -- manufacturer_id
      300,                    -- quantity: 300 units
      '2026-10-30',          -- expiration_date
      '[
          {"lot_number": "101-SUP020-3", "quantity": 150.0},
          {"lot_number": "108-SUP020-9", "quantity": 2100.0},
          {"lot_number": "102-SUP020-5", "quantity": 600.0}
      ]',
      @mac_and_cheese_plan
  );
  
