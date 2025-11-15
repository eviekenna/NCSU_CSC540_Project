import java.sql.*;

public class IngredientService {
    
    /**
     * view all of the ingredients
     */
    public void viewAllIngredients() {
        // connect to the db
        try (Connection conn = DBConnect.getConnection()) {
            // query to select ingredient details, order alphabetically
            String query = "SELECT ingredient_id, ingredient_name, ingredient_type FROM Ingredient " +
                        "ORDER BY ingredient_name";
            // statement object
            Statement stmt = conn.createStatement();
            // result of execution
            ResultSet rs = stmt.executeQuery(query);
            
            System.out.println("\nAvailable Ingredients");
            // print ingredient info
            while (rs.next()) {
                System.out.println("ID: " + rs.getInt("ingredient_id") +
                                 " Name: " + rs.getString("ingredient_name") +
                                 " Type: " + rs.getString("ingredient_type"));
            }
            
        } catch (SQLException e) {
            System.err.println("Error viewing all ingredients: " + e.getMessage());
        }
    }
    
    /**
     * create a new ingredient
     */
    public void createIngredient(int ingredientId, String name, String type) {
    	// connect to db
        try (Connection conn = DBConnect.getConnection()) {
        	// query insert
            String query = "INSERT INTO Ingredient (ingredient_id, ingredient_name, ingredient_type) " +
                          "VALUES (?, ?, ?)";
            PreparedStatement stmt = conn.prepareStatement(query);
            stmt.setInt(1, ingredientId);
            stmt.setString(2, name);
            stmt.setString(3, type);
            
            stmt.executeUpdate();
            System.out.println("Ingredient '" + name + "' has been created as " + type + ".");
            
        } catch (SQLException e) {
            System.err.println("Error creating ingredient: " + e.getMessage());
        }
    }

    /**
     * add a material to a compound ingredient
     */
    public void addIngredientComposition(int parentId, int childId, double quantity) {
    	// connect to db
        try (Connection conn = DBConnect.getConnection()) {
            // verify parent is compound, can't add to atomic
            String checkQuery = "SELECT ingredient_type FROM Ingredient WHERE ingredient_id = ?";
            PreparedStatement checkStmt = conn.prepareStatement(checkQuery);
            checkStmt.setInt(1, parentId);
            ResultSet rs = checkStmt.executeQuery();
            // not compound
            if (rs.next() && !rs.getString("ingredient_type").equals("compound")) {
                System.out.println("Error: Ingredient " + parentId + " is not a compound ingredient.");
                return;
            }
            
            // add to composition
            String query = "INSERT INTO IngredientComposition (parent_ingredient_id, child_ingredient_id, quantity) " +
                          "VALUES (?, ?, ?)";
            PreparedStatement stmt = conn.prepareStatement(query);
            stmt.setInt(1, parentId);
            stmt.setInt(2, childId);
            stmt.setDouble(3, quantity);
            
            stmt.executeUpdate();
            System.out.println("Material successfully added to compound ingredient.");
            
        } catch (SQLException e) {
            System.err.println("Error adding ingredient composition: " + e.getMessage());
        }
    }

    /**
     * create a supplier formulation
     */
    public void createSupplierFormulation(String supplierId, int ingredientId, int versionNo,
                                          double packSize, double pricePerUnit,
                                          String startDate, String endDate) {
    	// connect to db
        try (Connection conn = DBConnect.getConnection()) {
        	// query
            String query = "INSERT INTO SupplierFormulation " +
                          "(supplier_id, ingredient_id, version_no, pack_size, price_per_unit, " +
                          "effective_period_start_date, effective_period_end_date) " +
                          "VALUES (?, ?, ?, ?, ?, ?, ?)";
            PreparedStatement stmt = conn.prepareStatement(query);
            stmt.setString(1, supplierId);
            stmt.setInt(2, ingredientId);
            stmt.setInt(3, versionNo);
            stmt.setDouble(4, packSize);
            stmt.setDouble(5, pricePerUnit);
            stmt.setString(6, startDate);
            stmt.setString(7, endDate);
            
            stmt.executeUpdate();
            System.out.println("Supplier formulation has been created.");
            
        } catch (SQLException e) {
            System.err.println("Error creating supplier formulation: " + e.getMessage());
        }
    }
    
    /**
     * create an ingredient batch
     */
    public void createIngredientBatch(String supplierId, int ingredientId, double quantity, 
                                       double unitCost, String expirationDate, String batchId) {
        // connect to db
        try (Connection conn = DBConnect.getConnection()) {
            // trigger generates lot_number and sets on_hand_oz
            // check constraint enforces 90-day minimum expiration
            String query = "INSERT INTO IngredientBatch (batch_id, ingredient_id, supplier_id, quantity_oz, unit_cost, expiration_date) " +
                          "VALUES (?, ?, ?, ?, ?, ?)";
            // statement object
            PreparedStatement stmt = conn.prepareStatement(query);
            // set query
            stmt.setString(1, batchId);
            stmt.setInt(2, ingredientId);
            stmt.setString(3, supplierId);
            stmt.setDouble(4, quantity);
            stmt.setDouble(5, unitCost);
            stmt.setString(6, expirationDate);
            // update
            stmt.executeUpdate();
            System.out.println("Ingredient batch has been created.");
            
            // show the generated lot number 
            String getLotQuery = "SELECT lot_number FROM IngredientBatch " +
                               "WHERE ingredient_id = ? AND supplier_id = ? AND batch_id = ?";
            PreparedStatement getLotStmt = conn.prepareStatement(getLotQuery); 
            getLotStmt.setInt(1, ingredientId);  
            getLotStmt.setString(2, supplierId);    
            getLotStmt.setString(3, batchId);        
            ResultSet rs = getLotStmt.executeQuery();
            if (rs.next()) {
                System.out.println("Generated Lot Number: " + rs.getString("lot_number"));
            }
            
        } catch (SQLException e) {
            // Check for 90-day constraint violation
            if (e.getMessage().contains("check_90_day_minimum")) {
                System.err.println("Ingredient batch not created. Expiration is within 90 day window.");
            } else {
                System.err.println("Error creating ingredient batch: " + e.getMessage());
            }
        }
    }
    
    /**
     * view supplier formulations
     */
    public void viewSupplierFormulations(String supplierId) {
        // connect to db
        try (Connection conn = DBConnect.getConnection()) {
            // query from view for active formulations
            String query = "SELECT * FROM current_active_supplier_formulations WHERE supplier_id = ?";
            // statement object
            PreparedStatement stmt = conn.prepareStatement(query);
            // set query
            stmt.setString(1, supplierId);
            // results
            ResultSet rs = stmt.executeQuery();
            
            System.out.println("\nActive Formulations");
            boolean hasResults = false;
            // print formulation info
            while (rs.next()) {
                System.out.println("Ingredient: " + rs.getString("ingredient_name") +
                                 " Version: " + rs.getInt("version_no") +
                                 " Pack Size: " + rs.getDouble("pack_size") + " oz" +
                                 " Price: $" + rs.getDouble("price_per_unit") +
                                 " Valid: " + rs.getDate("effective_period_start_date") +
                                 " to " + rs.getDate("effective_period_end_date"));
                hasResults = true;
            }
            
            if (!hasResults) {
                System.out.println("No active formulations found.");
            }
            
        } catch (SQLException e) {
            System.err.println("Error viewing formulations: " + e.getMessage());
        }
    }
    
    /**
     * view all do-not-combine ingredient pairs
     */
    public void viewDoNotCombine() {
        // connect to db
        try (Connection conn = DBConnect.getConnection()) {
            // query incompatible ingredient pairs
            String query = "SELECT dnc.ingredientA_id, ia.ingredient_name AS nameA, " +
                          "dnc.ingredientB_id, ib.ingredient_name AS nameB " +
                          "FROM DoNotCombine dnc " +
                          "JOIN Ingredient ia ON dnc.ingredientA_id = ia.ingredient_id " +
                          "JOIN Ingredient ib ON dnc.ingredientB_id = ib.ingredient_id " +
                          "ORDER BY ia.ingredient_name";
            // statement object
            Statement stmt = conn.createStatement();
            // results
            ResultSet rs = stmt.executeQuery(query);
            
            System.out.println("\nIncompatible Ingredient Pairs");
            // print incompatible pairs
            while (rs.next()) {
                System.out.println(rs.getString("nameA") + " (" + rs.getInt("ingredientA_id") + ")" +
                                 " <-> " +
                                 rs.getString("nameB") + " (" + rs.getInt("ingredientB_id") + ")");
            }
            
        } catch (SQLException e) {
            System.err.println("Error viewing do-not-combine list: " + e.getMessage());
        }
    }
    
    /**
     * add a do-not-combine ingredient pair
     */
    public void addDoNotCombine(int ingredientA, int ingredientB) {
        // ensure A < B for the constraint (avoid duplicates)
        int minId = Math.min(ingredientA, ingredientB);
        int maxId = Math.max(ingredientA, ingredientB);
        
        // connect to db
        try (Connection conn = DBConnect.getConnection()) {
            // query insert incompatible pair
            String query = "INSERT INTO DoNotCombine (ingredientA_id, ingredientB_id) VALUES (?, ?)";
            // statement object
            PreparedStatement stmt = conn.prepareStatement(query);
            // set query
            stmt.setInt(1, minId);
            stmt.setInt(2, maxId);
            // update
            stmt.executeUpdate();
            System.out.println("Do-Not-Combine pair has been added.");
            
        } catch (SQLException e) {
            System.err.println("Error adding Do-Not-Combine pair: " + e.getMessage());
        }
    }
}
