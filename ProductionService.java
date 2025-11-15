import java.sql.*;
import java.util.*;

public class ProductionService {
    
    /**
     * creates a product batch with FEFO auto selection for ingredient lots
     */
    public void createProductBatchFEFO(int productId, String manufacturerId, 
                                           int quantity, String expirationDate, 
                                           int planId, String batchId) {
    	// connect to db
        try (Connection conn = DBConnect.getConnection()) {
            
        	// get required ingredients from recipe plan
            Map<Integer, Double> requiredIngredients = getRequiredIngredients(conn, planId, quantity);
            
            // selected ingredient lots for production
            List<IngredientLot> selectedLots = new ArrayList<>();
            // for each ingredient, get id and required quantity
            for (Map.Entry<Integer, Double> entry : requiredIngredients.entrySet()) {
                int ingredientId = entry.getKey();
                double requiredQty = entry.getValue();
                // ingredient lot FEFO
                List<IngredientLot> lotsForIngredient = selectLotsWithFEFO(conn, ingredientId, requiredQty);
                // add ingredient lot to selected lots
                selectedLots.addAll(lotsForIngredient);
            }
            
            // JSON string builder for selected lots
            String ingredientLotsJSON = buildLotsJSON(selectedLots);
            
            // call method that calls procedure to record the batch production
            recordProductionBatch(productId, manufacturerId, quantity, 
                                expirationDate, ingredientLotsJSON, planId, batchId);
            
        } catch (SQLException e) {
            System.err.println("Error in FEFO batch creation: " + e.getMessage());
            //e.printStackTrace();
        }
    }
    
    /**
     * get the required ingredients and quantities from the recipe plan
     * total required is required quantity per batch times batch quantity
     */
    private Map<Integer, Double> getRequiredIngredients(Connection conn, int planId, int batchQuantity) 
            throws SQLException {
    	// ingredients needed
        Map<Integer, Double> ingredients = new HashMap<>();
        // query, get ingredient and quantity
        String query = "SELECT ingredient_id, quantity FROM RecipeIngredient WHERE plan_id = ?";
        // statement object
        PreparedStatement stmt = conn.prepareStatement(query);
        // set query
        stmt.setInt(1, planId);
        // results
        ResultSet rs = stmt.executeQuery();
        // for each ingredient get the id, quantity and calculate total quantity needed, put it into map
        while (rs.next()) {
            int ingredientId = rs.getInt("ingredient_id");
            double qtyPerBatch = rs.getDouble("quantity");
            double totalQty = qtyPerBatch * batchQuantity;
            // put id and total into map
            ingredients.put(ingredientId, totalQty);
        }
        // return map of ingredients and total quantity needed
        return ingredients;
    }
    
    /**
     * select ingredient lots using FEFO (First Expired, First Out)
     * finds the earliest-expiring lot with enough quantity for each ingredient
     */
    private List<IngredientLot> selectLotsWithFEFO(Connection conn, int ingredientId, 
                                                    double requiredQty) throws SQLException {
        // selected lots
    	List<IngredientLot> selectedLots = new ArrayList<>();
        
        // find single lot with enough quantity, preferring soonest expiration (FEFO)
        String query = "SELECT lot_number, on_hand_oz, expiration_date " +
                     "FROM IngredientBatch " +
                     "WHERE ingredient_id = ? " +
                     "AND on_hand_oz >= ? " +  // no splitting, must have enough on hand to use
                     "AND expiration_date > NOW() " +
                     "ORDER BY expiration_date ASC, batch_id ASC " +
                     "LIMIT 1";  // no splitting, only one lot
        // statement object
        PreparedStatement stmt = conn.prepareStatement(query);
        // set query
        stmt.setInt(1, ingredientId);
        stmt.setDouble(2, requiredQty);
        // results
        ResultSet rs = stmt.executeQuery();
        // if results are not empty, grab lotNumber and available quantity
        if (rs.next()) {
            String lotNumber = rs.getString("lot_number");
            double on_hand_qty = rs.getDouble("on_hand_oz");
            
            // use required quantity from this singular
            selectedLots.add(new IngredientLot(lotNumber, requiredQty));
            // successfully used lot
            System.out.println("  Selected: " + lotNumber + 
                             " (" + requiredQty + " oz out of " + on_hand_qty + " oz available)");
        } else {
            throw new SQLException("No one lot with enough on hand quantity for ingredient " + 
            		ingredientId);
        }
        // selected lots for production
        return selectedLots;
    }
    
    /**
     * build JSON string array for ingredient lots
     * [{"lot_number": "8-SUP001-1", "quantity": 100.0}, {...}, {...}]
     */
    private String buildLotsJSON(List<IngredientLot> lots) {
    	// string builder
        StringBuilder json_str = new StringBuilder("[");
        // loop through all lots
        for (int i = 0; i < lots.size(); i++) {
            IngredientLot lot_single = lots.get(i);
            json_str.append("{\"lot_number\": \"").append(lot_single.lotNumber)
                .append("\", \"quantity\": ").append(lot_single.quantity)
                .append("}");
            // add comma except for last lot
            if (i < lots.size() - 1) {
            	json_str.append(", ");
            }
        }
        // close string
        json_str.append("]");
        // toString method
        return json_str.toString();
    }
    
    /**
     * calls stored procedure, manual selection not FEFO
     */
    public void recordProductionBatch(int productId, String manufacturerId, 
                                     int quantity, String expirationDate,
                                     String ingredientLotsJson, int planId, String batchId) {
    	// connect to db
        try (Connection conn = DBConnect.getConnection()) {
        	// query, calls procedure to record batch production
            String query = "{CALL record_production_batch(?, ?, ?, ?, ?, ?)}";
            // statement object to call procedure
            CallableStatement stmt = conn.prepareCall(query);
            // set query
            stmt.setInt(1, productId);
            stmt.setString(2, manufacturerId);
            stmt.setInt(3, quantity);
            stmt.setString(4, expirationDate);
            stmt.setString(5, ingredientLotsJson);
            stmt.setInt(6, planId);
            stmt.setString(7,  batchId);
            // execute
            stmt.execute();
            // success
            System.out.println("Product batch has been created successfully.");
            
        } catch (SQLException e) {
            System.err.println("Error creating product batch: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    /**
     * trace recall for contaminated ingredient lots
     */
    public void traceRecall(String ingredientLotNumber, String recallDate, int windowDays) {
    	// connect to db
        try (Connection conn = DBConnect.getConnection()) {
        	// query, procedure call for recall
            String query = "{CALL trace_recall(?, ?, ?)}";
            // statement object to call procedure
            CallableStatement stmt = conn.prepareCall(query);
            // set query
            stmt.setString(1, ingredientLotNumber);
            stmt.setString(2, recallDate);
            stmt.setInt(3, windowDays);
            
            // results
            ResultSet rs = stmt.executeQuery();
            
            // print results header info
            System.out.println("\nRECALL TRACE RESULTS");
            System.out.println("Ingredient Lot: " + ingredientLotNumber);
            System.out.println("Recall Date: " + recallDate);
            System.out.println("Window: " + windowDays + " days");
            System.out.println("\nContaminated Product Lots:");
            
            // flag for if there are recalls
            boolean hasRecalls = false;
            // while results are not empty, print the recalls
            while (rs.next()) {
                System.out.println("  - " + rs.getString("contaminated_product_lot"));
                hasRecalls = true; // recall was found
            }
            // if results is empty, there were no recalls
            if (!hasRecalls) {
                System.out.println(" No contaminated product lots found.");
            }
            
        } catch (SQLException e) {
            System.err.println("Error tracing recall: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    /**
     * on-hand inventory report
     * show all ingredient batches with current on-hand quantities
     */
    public void viewOnHandInventory() {
        // connect to db
        try (Connection conn = DBConnect.getConnection()) {
            // query to get all batches with on-hand > 0
            String query = "SELECT ib.ingredient_id, i.ingredient_name, ib.lot_number, " +
                          "ib.on_hand_oz, ib.expiration_date, s.supplier_name " +
                          "FROM IngredientBatch ib " +
                          "JOIN Ingredient i ON ib.ingredient_id = i.ingredient_id " +
                          "JOIN Supplier s ON ib.supplier_id = s.supplier_id " +
                          "WHERE ib.on_hand_oz > 0 " +
                          "ORDER BY i.ingredient_name, ib.expiration_date ASC";
            // statement object
            Statement stmt = conn.createStatement();
            // results
            ResultSet rs = stmt.executeQuery(query);
            
            System.out.println("\nON HAND INVENTORY");
            
            // initialize
            String currentIngredient = "";
            double totalForIngredient = 0.0;
            boolean hasInventory = false;
            
            // print inventory info
            while (rs.next()) {
                String ingredientName = rs.getString("ingredient_name");
                
                // print ingredient header
                if (!ingredientName.equals(currentIngredient)) {
                    if (!currentIngredient.isEmpty()) {
                        System.out.println(" Total for " + currentIngredient + ": " + 
                                         totalForIngredient + " oz\n");
                    }
                    System.out.println("Ingredient: " + ingredientName + 
                                     " (ID: " + rs.getInt("ingredient_id") + ")");
                    currentIngredient = ingredientName;
                    totalForIngredient = 0.0;
                }
                
                // print lot details
                double onHand = rs.getDouble("on_hand_oz");
                System.out.println("  Lot: " + rs.getString("lot_number") +
                                 " | On Hand: " + onHand + " oz" +
                                 " | Expires: " + rs.getDate("expiration_date") +
                                 " | Supplier: " + rs.getString("supplier_name"));
                totalForIngredient += onHand;
                hasInventory = true;
            }
            
            // print total for last ingredient
            if (!currentIngredient.isEmpty()) {
                System.out.println("  Total for " + currentIngredient + ": " + 
                                 totalForIngredient + " oz\n");
            }
            
            // no inventory
            if (!hasInventory) {
                System.out.println("No inventory on hand.");
            }
            
            
        } catch (SQLException e) {
            System.err.println("Error viewing on hand inventory: " + e.getMessage());
            //e.printStackTrace();
        }
    }

    /**
     * nearly out-of-stock items report
     * shows ingredients where total on hand is less than what is needed 
     * for a standard batch of any product that uses that ingredient
     */
    public void viewNearlyOutOfStock() {
        // connect to db
        try (Connection conn = DBConnect.getConnection()) {
            // for each ingredient, check if total on-hand is less than 
            // the amount needed for any product's standard batch
            String query = "SELECT DISTINCT i.ingredient_id, i.ingredient_name, " +
                          "SUM(ib.on_hand_oz) AS total_on_hand, " +
                          "p.product_id, p.name AS product_name, " +
                          "p.standard_batch_units, " +
                          "ri.quantity AS qty_per_unit, " +
                          "(ri.quantity * p.standard_batch_units) AS qty_for_standard_batch " +
                          "FROM Ingredient i " +
                          "LEFT JOIN IngredientBatch ib ON i.ingredient_id = ib.ingredient_id " +
                          "JOIN RecipeIngredient ri ON i.ingredient_id = ri.ingredient_id " +
                          "JOIN RecipePlan rp ON ri.plan_id = rp.plan_id AND rp.is_active = TRUE " +
                          "JOIN Product p ON rp.product_id = p.product_id " +
                          "GROUP BY i.ingredient_id, i.ingredient_name, p.product_id, p.name, " +
                          "p.standard_batch_units, ri.quantity " +
                          "HAVING SUM(COALESCE(ib.on_hand_oz, 0)) < (ri.quantity * p.standard_batch_units) " +
                          "ORDER BY i.ingredient_name, p.name";
            // statement object
            Statement stmt = conn.createStatement();
            // results
            ResultSet rs = stmt.executeQuery(query);
            
            System.out.println("\nNEARLY OUT-OF-STOCK ITEMS");
            boolean hasStockProblem = false;
            // print nearly out-of-stock info
            while (rs.next()) {
                System.out.println("Ingredient: " + rs.getString("ingredient_name") + 
                                 " (ID: " + rs.getInt("ingredient_id") + ")");
                System.out.println(" Total On Hand: " + rs.getDouble("total_on_hand") + " oz");
                System.out.println(" Not enough for: " + rs.getString("product_name") +
                                 " (ID: " + rs.getInt("product_id") + ")");
                System.out.println("  Standard Batch Size: " + rs.getInt("standard_batch_units") + " units");
                System.out.println("  Requires: " + rs.getDouble("qty_for_standard_batch") + " oz");
                System.out.println("  Short by: " + 
                                 (rs.getDouble("qty_for_standard_batch") - rs.getDouble("total_on_hand")) + " oz");
                System.out.println();
                hasStockProblem = true;
            }
            
            if (!hasStockProblem) {
                System.out.println("All ingredients have sufficient stock for standard batches.");
            }
            
        } catch (SQLException e) {
            System.err.println("Error viewing nearly out-of-stock items: " + e.getMessage());
            //e.printStackTrace();
        }
    }

    /**
     * almost-expired ingredient lots report
     * shows ingredient batches expiring within 
     */
    public void viewAlmostExpired() {
        // connect to db
        try (Connection conn = DBConnect.getConnection()) {
            // query for batches expiring within threshold window of 10 days
            String query = "SELECT ib.lot_number, i.ingredient_name, ib.on_hand_oz, " +
                          "ib.expiration_date, s.supplier_name, " +
                          "DATEDIFF(ib.expiration_date, CURDATE()) AS days_until_expiration " +
                          "FROM IngredientBatch ib " +
                          "JOIN Ingredient i ON ib.ingredient_id = i.ingredient_id " +
                          "JOIN Supplier s ON ib.supplier_id = s.supplier_id " +
                          "WHERE ib.on_hand_oz > 0 " +
                          "AND ib.expiration_date > CURDATE() " +
                          "AND ib.expiration_date <= DATE_ADD(CURDATE(), INTERVAL 10 DAY) " +
                          "ORDER BY ib.expiration_date ASC, i.ingredient_name";
            // statement object
            Statement stmt = conn.createStatement();
            // results
            ResultSet rs = stmt.executeQuery(query);
            
            System.out.println("\nALMOST-EXPIRED INGREDIENT LOTS");
            
            boolean hasExpiring = false;
            
            // print almost expired lots info
            while (rs.next()) {
            	// days to expiration from datediff
                int daysLeft = rs.getInt("days_until_expiration");
                System.out.println("Lot: " + rs.getString("lot_number"));
                System.out.println(" Ingredient: " + rs.getString("ingredient_name"));
                System.out.println(" On-Hand: " + rs.getDouble("on_hand_oz") + " oz");
                System.out.println(" Expiration: " + rs.getDate("expiration_date") +
                                 " (" + daysLeft + " day" + (daysLeft != 1 ? "s" : "") + " remaining)");
                System.out.println(" Supplier: " + rs.getString("supplier_name"));
                System.out.println();
                hasExpiring = true;
            }
            // no soon expiring
            if (!hasExpiring) {
                System.out.println("No ingredient lots expiring within the next 10 days.");
            }
            
        } catch (SQLException e) {
            System.err.println("Error viewing almost-expired lots: " + e.getMessage());
            //e.printStackTrace();
        }
    }

    /**
     * Batch Cost Summary for a product batch report
     * shows cost breakdown for a product lot
     */
    public void viewBatchCostSummary(String productLotNumber) {
        // connect to db
        try (Connection conn = DBConnect.getConnection()) {
            // get product batch details
            String query1 = "SELECT pb.lot_number, pb.product_id, p.name AS product_name, " +
                               "pb.manufacturer_id, m.manufacturer_name, " +
                               "pb.quantity, pb.unit_cost, pb.production_date, pb.expiration_date, " +
                               "(pb.quantity * pb.unit_cost) AS total_batch_cost " +
                               "FROM ProductBatch pb " +
                               "JOIN Product p ON pb.product_id = p.product_id " +
                               "JOIN Manufacturer m ON pb.manufacturer_id = m.manufacturer_id " +
                               "WHERE pb.lot_number = ?";
            // statement object
            PreparedStatement stmt = conn.prepareStatement(query1);
            // set query
            stmt.setString(1, productLotNumber);
            
            ResultSet batchrs = stmt.executeQuery();
            
            if (!batchrs.next()) {
                System.out.println("\nProduct lot " + productLotNumber + " not found.");
                return;
            }
            // batch cost info
            System.out.println("\nBATCH COST SUMMARY");
            System.out.println("Product Lot: " + batchrs.getString("lot_number"));
            System.out.println("Product: " + batchrs.getString("product_name") + 
                             " (ID: " + batchrs.getInt("product_id") + ")");
            System.out.println("Manufacturer: " + batchrs.getString("manufacturer_name") +
                             " (ID: " + batchrs.getString("manufacturer_id") + ")");
            System.out.println("Production Date: " + batchrs.getDate("production_date"));
            System.out.println("Expiration Date: " + batchrs.getDate("expiration_date"));
            System.out.println("Quantity Produced: " + batchrs.getInt("quantity") + " units");
            System.out.println("\n--- Cost Breakdown ---");
            
            // get ingredient consumption details
            String query2 = "SELECT bc.ingredient_lot_number, i.ingredient_name, " +
                                    "bc.quantity_consumed, ib.unit_cost, " +
                                    "(bc.quantity_consumed * ib.unit_cost) AS ingredient_cost " +
                                    "FROM BatchConsumption bc " +
                                    "JOIN IngredientBatch ib ON bc.ingredient_lot_number = ib.lot_number " +
                                    "JOIN Ingredient i ON ib.ingredient_id = i.ingredient_id " +
                                    "WHERE bc.product_lot_number = ? " +
                                    "ORDER BY ingredient_cost DESC";
            // statement object
            PreparedStatement stmt2 = conn.prepareStatement(query2);
            // set query2
            stmt2.setString(1, productLotNumber);
            // ingredient results
            ResultSet ingredientRs = stmt2.executeQuery();
            double calculatedTotalCost = 0.0; // might not need
            // go through all ingredients
            while (ingredientRs.next()) {
                double cost = ingredientRs.getDouble("ingredient_cost");
                System.out.println("Ingredient Lot: " + ingredientRs.getString("ingredient_lot_number"));
                System.out.println("  Ingredient: " + ingredientRs.getString("ingredient_name"));
                System.out.println("  Quantity Consumed: " + ingredientRs.getDouble("quantity_consumed") + " oz");
                System.out.println("  Unit Cost: $" + ingredientRs.getDouble("unit_cost") + "/oz");
                System.out.println("  Total Cost: $" + String.format("%.2f", cost));
                System.out.println();
                // summation (might not need depending on what we want to display)
                calculatedTotalCost += cost;
            }
            
            System.out.println(" Summary ");
            System.out.println("Total Batch Cost: $" + String.format("%.2f", batchrs.getDouble("total_batch_cost")));
            System.out.println("Cost Per Unit: $" + String.format("%.2f", batchrs.getDouble("unit_cost")));
            
        } catch (SQLException e) {
            System.err.println("Error viewing batch cost summary: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    /**
     * view health risk violations from the last 30 days
     * shows product batches that contain incompatible ingredient pairs
     */
    public void viewHealthRiskViolations() {
        // connect to db
        try (Connection conn = DBConnect.getConnection()) {
            // query the view for violations
            String query = "SELECT * FROM health_risk_violations_last_30_days " +
                          "ORDER BY production_date DESC, product_lot_number";
            // statement object
            Statement stmt = conn.createStatement();
            // results
            ResultSet rs = stmt.executeQuery(query);
            
            System.out.println("\nHEALTH RISK VIOLATIONS (Last 30 Days)");
            
            // flag
            boolean hasViolations = false;
            String currentLot = "";
            
            // print health violation info
            while (rs.next()) {
                String lotNumber = rs.getString("product_lot_number");
                
                // print header if it's a new lot
                if (!lotNumber.equals(currentLot)) {
                    if (hasViolations) {
                        System.out.println();
                    }
                    System.out.println("Product Lot: " + lotNumber);
                    System.out.println("  Product: " + rs.getString("product_name") + 
                                     " (ID: " + rs.getInt("product_id") + ")");
                    System.out.println("  Manufacturer: " + rs.getString("manufacturer_id"));
                    System.out.println("  Production Date: " + rs.getDate("production_date"));
                    System.out.println("  Incompatible Pairs:");
                    currentLot = lotNumber;
                }
                
                // print the specific incompatibility
                System.out.println("    - " + rs.getString("ingredientA_name") + 
                                 " (ID: " + rs.getInt("ingredientA_id") + ") <--> " +
                                 rs.getString("ingredientB_name") + 
                                 " (ID: " + rs.getInt("ingredientB_id") + ")");
                
                hasViolations = true;
            }
            
            // if no violations found
            if (!hasViolations) {
                System.out.println("No health risk violations found in the last 30 days.");
            }
            
            
        } catch (SQLException e) {
            System.err.println("Error viewing health risk violations: " + e.getMessage());
            //e.printStackTrace();
        }
    }
    
    /**
     * helper class, creates IngredientLot object that has lot number and quantity info
     */
    private static class IngredientLot {
    	// attributes
        String lotNumber;
        double quantity;
        // constructor
        IngredientLot(String lotNumber, double quantity) {
            this.lotNumber = lotNumber;
            this.quantity = quantity;
        }
    }
}
