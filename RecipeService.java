import java.sql.*;
import java.util.*;

public class RecipeService {
    
    /**
     * Create a new recipe plan version
     */
    public int createRecipePlan(int productId, String manufacturerId, int versionNo, boolean isActive) {
        // connect to db
    	try (Connection conn = DBConnect.getConnection()) {
    		// query, insert a recipe plan
            String query = "INSERT INTO RecipePlan (product_id, manufacturer_id, version_no, is_active) " +
                        "VALUES (?, ?, ?, FALSE)";
            // statement object, return the auto generated key (plan_id)
            PreparedStatement stmt = conn.prepareStatement(query, Statement.RETURN_GENERATED_KEYS);
            // set the query with passed parameters
            stmt.setInt(1, productId);
            stmt.setString(2, manufacturerId);
            stmt.setInt(3, versionNo);
            
            // update the statement object
            stmt.executeUpdate();
            // results
            ResultSet rs = stmt.getGeneratedKeys();
            // print plan id
            if (rs.next()) {
                int planId = rs.getInt(1);
                System.out.println("Recipe plan created with id: " + planId);
                
                // set active
                if (isActive) {
                	setActivePlan(planId, productId, manufacturerId);
                }
                
                // return generated plan id
                return planId;
            }
            
        } catch (SQLException e) {
            System.err.println("Error creating recipe plan: " + e.getMessage());
        }
    	// plan id was not successfully created
        return -1;
    }
    
    /**
     * add an ingredient to the recipe plan
     */
    public void addIngredientToRecipe(int planId, int ingredientId, double quantityOz) {
        // connect to db
    	try (Connection conn = DBConnect.getConnection()) {
    		// query, insert ingredient to plan
            String query = "INSERT INTO RecipeIngredient (plan_id, ingredient_id, quantity) " +
                        "VALUES (?, ?, ?)";
            // statment object
            PreparedStatement stmt = conn.prepareStatement(query);
            // set query with parameters
            stmt.setInt(1, planId);
            stmt.setInt(2, ingredientId);
            stmt.setDouble(3, quantityOz);
            // update
            stmt.executeUpdate();
            System.out.println("Ingredient has been added to recipe plan.");
            
        } catch (SQLException e) {
            System.err.println("Error adding ingredient to recipe plan: " + e.getMessage());
        }
    }
    
    /**
     * view recipe plans for a product based on productId and manufacturerId
     */
    public void viewRecipePlans(int productId, String manufacturerId) {
    	// connect to db
        try (Connection conn = DBConnect.getConnection()) {
        	// query, selects plan info orders by plan id number descending
            String query = "SELECT plan_id, version_no, creation_date, is_active " +
                        "FROM RecipePlan " +
                        "WHERE product_id = ? AND manufacturer_id = ? " +
                        "ORDER BY version_no DESC";
            // statment object
            PreparedStatement stmt = conn.prepareStatement(query);
            // set query
            stmt.setInt(1, productId);
            stmt.setString(2, manufacturerId);
            // results
            ResultSet rs = stmt.executeQuery();
            System.out.println("\nRecipe Plans");
            // print recipe plan info for each plan
            while (rs.next()) {
                System.out.println("Plan ID: " + rs.getInt("plan_id") +
                                 " Version: " + rs.getInt("version_no") +
                                 " Created: " + rs.getDate("creation_date") +
                                 " Active: " + (rs.getBoolean("is_active") ? "Active plan" : "Not active plan"));
            }
            
        } catch (SQLException e) {
            System.err.println("Error viewing recipe plans: " + e.getMessage());
        }
    }
    
    /**
     * get active plan id for a product from manufacturer
     */
    public int getActivePlanId(int productId, String manufacturerId) {
    	// connect to db
        try (Connection conn = DBConnect.getConnection()) {
        	// query, get active recipe plan_id based on product and manufacturer
            String query = "SELECT plan_id FROM RecipePlan " +
                        "WHERE product_id = ? AND manufacturer_id = ? AND is_active = TRUE";
            // statement object
            PreparedStatement stmt = conn.prepareStatement(query);
            // set query
            stmt.setInt(1, productId);
            stmt.setString(2, manufacturerId);
            // results
            ResultSet rs = stmt.executeQuery();
            // if results contain active plan id return it
            if (rs.next()) {
                return rs.getInt("plan_id");
            }
            
        } catch (SQLException e) {
            System.err.println("Error getting active plan: " + e.getMessage());
        }
        // results did not find active plan successfully
        return -1;
    }
    
    /**
     * set a recipe plan as active, deactivating others
     */
    public void setActivePlan(int planId, int productId, String manufacturerId) {
        // connect to db 
    	try (Connection conn = DBConnect.getConnection()) {
    		// need to deactivate all plans AND activate our specific plan. All or nothing transaction
            conn.setAutoCommit(false);
            
            // deactivate all plans
            String query1 = "UPDATE RecipePlan SET is_active = FALSE " +
                         "WHERE product_id = ? AND manufacturer_id = ?";
            // statement object
            PreparedStatement stmt1 = conn.prepareStatement(query1);
            // set query1
            stmt1.setInt(1, productId);
            stmt1.setString(2, manufacturerId);
            // update
            int deactivatedPlans = stmt1.executeUpdate();
            System.out.println("Deactivated " + deactivatedPlans + " plans.");
            
            // active the passed plan id
            String query2 = "UPDATE RecipePlan SET is_active = TRUE WHERE plan_id = ?";
            // statement object
            PreparedStatement stmt2 = conn.prepareStatement(query2);
            // set query2
            stmt2.setInt(1, planId);
            // update
            int activatedPlans = stmt2.executeUpdate();
            if (activatedPlans == 0) {
            	conn.rollback();
            	System.out.println("Error, plan id " + planId + " not found.");
            	return;
            }
            
            // commit the statements
            conn.commit();
            conn.setAutoCommit(true);
            // success
            System.out.println("Recipe plan " + planId + " is now active.");
            
        } catch (SQLException e) {
            System.err.println("Error setting active plan: " + e.getMessage());
            
        }
    }
}