import java.sql.*;
import java.util.*;

public class ProductService {
    
    /**
     * create a new product
     */
    public void createProduct(String manufacturerId, int productId, String name, 
                             int categoryId, int standardBatchUnits) {
    	// connect to db
        try (Connection conn = DBConnect.getConnection()) {
        	// query, insert new product
            String query = "INSERT INTO Product (product_id, name, manufacturer_id, category_id, standard_batch_units) " +
                        "VALUES (?, ?, ?, ?, ?)";
            // statement obejct
            PreparedStatement stmt = conn.prepareStatement(query);
            // set query with passed parameters
            stmt.setInt(1, productId);
            stmt.setString(2, name);
            stmt.setString(3, manufacturerId);
            stmt.setInt(4, categoryId);
            stmt.setInt(5, standardBatchUnits);
            // update
            stmt.executeUpdate();
            // update successful
            System.out.println("New product has been created.");
            
        } catch (SQLException e) {
            System.err.println("Error creating product: " + e.getMessage());
        }
    }
    
    /**
     * view all products for a manufacturer
     */
    public void viewProductsByManufacturer(String manufacturerId) {
    	// connect to db
        try (Connection conn = DBConnect.getConnection()) {
        	// query, get all all product info
            String query = "SELECT p.product_id, p.name, c.name AS category, p.standard_batch_units " +
                        "FROM Product p " +
                        "JOIN Category c ON p.category_id = c.category_id " +
                        "WHERE p.manufacturer_id = ?";
 
            // statement object
            PreparedStatement stmt = conn.prepareStatement(query);
            // set query
            stmt.setString(1, manufacturerId);
            // results
            ResultSet rs = stmt.executeQuery();
            System.out.println("\nProducts");
            // print products info
            while (rs.next()) {
                System.out.println("ID: " + rs.getInt("product_id") + 
                                 " Name: " + rs.getString("name") +
                                 " Category: " + rs.getString("category") +
                                 " Std Batch: " + rs.getInt("standard_batch_units") + " units");
            }
            
        } catch (SQLException e) {
            System.err.println("Error viewing products: " + e.getMessage());
        }
    }
    
}