import java.sql.*;
import java.util.Scanner;

public class ViewerMenu {
    private Scanner scanner;

    public ViewerMenu(Scanner scanner) {
        this.scanner = scanner;
    }

    public void show() {
        while (true) {
            System.out.println("\n VIEWER MENU ");
            System.out.println("1. Browse Products");
            System.out.println("2. Generate Product Ingredient List");
            System.out.println("3. Compare Two Products for Incompatibilities");
            System.out.println("0. Exit");
            System.out.print("Select option: ");
            
            int choice = scanner.nextInt();
            scanner.nextLine();
            
            switch (choice) {
                case 1:
                    browseProducts();
                    break;
                case 2:
                    generateIngredientList();
                    break;
                case 3:
                    compareProducts();
                    break;
                case 0:
                    System.out.println("Exiting.");
                    return;
                default:
                    System.out.println("Invalid option.");
            }
        }
    }
    
    private void browseProducts() {
        System.out.println("\n Browse Products ");
        
        try (Connection conn = DBConnect.getConnection()) {
            String sql = "SELECT p.product_id, p.name, m.manufacturer_name, c.name AS category " +
                        "FROM Product p " +
                        "JOIN Manufacturer m ON p.manufacturer_id = m.manufacturer_id " +
                        "JOIN Category c ON p.category_id = c.category_id " +
                        "ORDER BY m.manufacturer_name, c.name, p.name";
            Statement stmt = conn.createStatement();
            ResultSet rs = stmt.executeQuery(sql);
            
            System.out.println("\nProducts");
            String currentManufacturer = "";
            while (rs.next()) {
                String manufacturer = rs.getString("manufacturer_name");
                if (!manufacturer.equals(currentManufacturer)) {
                    System.out.println("\n[" + manufacturer + "]");
                    currentManufacturer = manufacturer;
                }
                System.out.println("  ID: " + rs.getInt("product_id") +
                                 " | " + rs.getString("name") +
                                 " | Category: " + rs.getString("category"));
            }
            
        } catch (SQLException e) {
            System.err.println("Error browsing products: " + e.getMessage());
        }
    }
    
    private void generateIngredientList() {
        System.out.println("\n Generate Ingredient List ");
        
        browseProducts();
        
        System.out.print("\nEnter product id: ");
        int productId = scanner.nextInt();
        scanner.nextLine();
        
        try (Connection conn = DBConnect.getConnection()) {
            // use the flattened_product_bom view and aggregate by atomic ingredient
            String sql = "SELECT atomic_ingredient_id, atomic_ingredient_name, " +
                        "SUM(atomic_quantity_oz) AS total_quantity " +
                        "FROM flattened_product_bom " +
                        "WHERE product_id = ? AND is_active = TRUE " +
                        "GROUP BY atomic_ingredient_id, atomic_ingredient_name " +
                        "ORDER BY total_quantity DESC";
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setInt(1, productId);
            
            ResultSet rs = stmt.executeQuery();
            
            System.out.println("\n Ingredient List ");
            boolean hasResults = false;
            while (rs.next()) {
                System.out.println(rs.getString("atomic_ingredient_name") +
                                 " (" + rs.getInt("atomic_ingredient_id") + "): " +
                                 rs.getDouble("total_quantity") + " oz");
                hasResults = true;
            }
            
            if (!hasResults) {
                System.out.println("No active recipe found for this product.");
            }
            
        } catch (SQLException e) {
            System.err.println("Error generating ingredient list: " + e.getMessage());
        }
    }
    
    private void compareProducts() {
        System.out.println("\n Compare Products for Incompatibilities ");
        
        browseProducts();
        
        System.out.print("\nEnter first product id: ");
        int productId1 = scanner.nextInt();
        scanner.nextLine();
        
        System.out.print("Enter second product id: ");
        int productId2 = scanner.nextInt();
        scanner.nextLine();
        
        try (Connection conn = DBConnect.getConnection()) {
            // Get all atomic ingredients from both products and check for conflicts
            String sql = "SELECT DISTINCT dnc.ingredientA_id, ia.ingredient_name AS nameA, " +
                        "dnc.ingredientB_id, ib.ingredient_name AS nameB " +
                        "FROM ( " +
                        "    SELECT DISTINCT atomic_ingredient_id AS ingredient_id " +
                        "    FROM flattened_product_bom " +
                        "    WHERE product_id = ? AND is_active = TRUE " +
                        "    UNION " +
                        "    SELECT DISTINCT atomic_ingredient_id AS ingredient_id " +
                        "    FROM flattened_product_bom " +
                        "    WHERE product_id = ? AND is_active = TRUE " +
                        ") AS combined_ingredients " +
                        "JOIN DoNotCombine dnc ON ( " +
                        "    combined_ingredients.ingredient_id = dnc.ingredientA_id OR " +
                        "    combined_ingredients.ingredient_id = dnc.ingredientB_id " +
                        ") " +
                        "JOIN Ingredient ia ON dnc.ingredientA_id = ia.ingredient_id " +
                        "JOIN Ingredient ib ON dnc.ingredientB_id = ib.ingredient_id " +
                        "WHERE EXISTS ( " +
                        "    SELECT 1 FROM flattened_product_bom fpb1 " +
                        "    WHERE fpb1.product_id = ? AND fpb1.is_active = TRUE " +
                        "    AND fpb1.atomic_ingredient_id = dnc.ingredientA_id " +
                        ") " +
                        "AND EXISTS ( " +
                        "    SELECT 1 FROM flattened_product_bom fpb2 " +
                        "    WHERE fpb2.product_id IN (?, ?) AND fpb2.is_active = TRUE " +
                        "    AND fpb2.atomic_ingredient_id = dnc.ingredientB_id " +
                        ")";
            
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setInt(1, productId1);
            stmt.setInt(2, productId2);
            stmt.setInt(3, productId1);
            stmt.setInt(4, productId1);
            stmt.setInt(5, productId2);
            
            ResultSet rs = stmt.executeQuery();
            
            System.out.println("\n Incompatibility Info ");
            boolean hasIncompatibilities = false;
            while (rs.next()) {
                System.out.println("Conflict: " + rs.getString("nameA") +
                                 " cannot be combined with " + rs.getString("nameB"));
                hasIncompatibilities = true;
            }
            
            if (!hasIncompatibilities) {
                System.out.println("No incompatibilities found between products.");
            }
            
        } catch (SQLException e) {
            System.err.println("Error comparing products: " + e.getMessage());
        }
    }
}
