import java.sql.*;
import java.util.Scanner;

public class QueryMenu {
    private Scanner scanner;

    public QueryMenu(Scanner scanner) {
        this.scanner = scanner;
    }

    public void show() {
        while (true) {
            System.out.println("\n QUERY MENU ");
            System.out.println(
                    "1. List ingredients and lot number of last Steak Dinner "
                            + "batch (MFG001)");
            System.out.println("2. Total spent by MFG002 per supplier");
            System.out.println(
                    "3. Find unit cost for product lot 100-MFG001-B0901");
            System.out
                    .println("4. Find conflicting ingredients for product lot "
                            + "100-MFG001-B0901");
            System.out.println(
                    "5. Manufacturers not supplied by Supplier B (21)");
            System.out.println("0. Exit");
            System.out.print("Select option: ");

            int choice = scanner.nextInt();
            scanner.nextLine();

            switch (choice) {
                case 1:
                    executeQuery1();
                    break;
                case 2:
                    executeQuery2();
                    break;
                case 3:
                    executeQuery3();
                    break;
                case 4:
                    executeQuery4();
                    break;
                case 5:
                    executeQuery5();
                    break;
                case 0:
                    System.out.println("Exiting.");
                    return;
                default:
                    System.out.println("Invalid option.");
            }
        }
    }

    private void executeQuery1() {
        String query = """
                    SELECT I.ingredient_name, BC.ingredient_lot_number
                    FROM ProductBatch PB
                    JOIN BatchConsumption BC ON PB.lot_number = BC.product_lot_number
                    JOIN IngredientBatch IB ON BC.ingredient_lot_number = IB.lot_number
                    JOIN Ingredient I ON IB.ingredient_id = I.ingredient_id
                    WHERE PB.product_id = 100
                      AND PB.manufacturer_id = 'MFG001'
                      AND PB.production_date = (
                          SELECT MAX(PB2.production_date)
                          FROM ProductBatch PB2
                          WHERE PB2.product_id = 100 AND PB2.manufacturer_id = 'MFG001'
                      );
                """;
        this.executeAndPrint(query, "Ingredient", "Lot Number");
    }

    private void executeQuery2() {
        String query = """
                    SELECT IB.supplier_id, S.supplier_name,
                           SUM(BC.quantity_consumed * IB.unit_cost) AS total_spent
                    FROM ProductBatch PB
                    JOIN BatchConsumption BC ON PB.lot_number = BC.product_lot_number
                    JOIN IngredientBatch IB ON BC.ingredient_lot_number = IB.lot_number
                    JOIN Supplier S ON IB.supplier_id = S.supplier_id
                    WHERE PB.manufacturer_id = 'MFG002'
                    GROUP BY IB.supplier_id, S.supplier_name;
                """;
        this.executeAndPrint(query, "Supplier ID", "Supplier Name",
                "Total Spent");
    }

    private void executeQuery3() {
        String query = "SELECT PB.unit_cost FROM ProductBatch PB WHERE PB.lot_number = '100-MFG001-B0901';";
        this.executeAndPrint(query, "Unit Cost");
    }

    private void executeQuery4() {
        String query = """
                    SELECT DISTINCT I2.ingredient_id, I2.ingredient_name
                    FROM BatchConsumption BC
                    JOIN IngredientBatch IB ON BC.ingredient_lot_number = IB.lot_number
                    JOIN DoNotCombine DNC ON IB.ingredient_id = DNC.ingredientA_id
                    JOIN Ingredient I2 ON I2.ingredient_id = DNC.ingredientB_id
                    WHERE BC.product_lot_number = '100-MFG001-B0901'
                    UNION
                    SELECT DISTINCT I2.ingredient_id, I2.ingredient_name
                    FROM BatchConsumption BC
                    JOIN IngredientBatch IB ON BC.ingredient_lot_number = IB.lot_number
                    JOIN DoNotCombine DNC ON IB.ingredient_id = DNC.ingredientB_id
                    JOIN Ingredient I2 ON I2.ingredient_id = DNC.ingredientA_id
                    WHERE BC.product_lot_number = '100-MFG001-B0901';
                """;
        this.executeAndPrint(query, "Ingredient ID", "Ingredient Name");
    }

    private void executeQuery5() {
        String query = """
                    SELECT M.manufacturer_id, M.manufacturer_name
                    FROM Manufacturer M
                    WHERE M.manufacturer_id NOT IN (
                        SELECT DISTINCT PB.manufacturer_id
                        FROM ProductBatch PB
                        JOIN BatchConsumption BC ON PB.lot_number = BC.product_lot_number
                        JOIN IngredientBatch IB ON BC.ingredient_lot_number = IB.lot_number
                        WHERE IB.supplier_id = '21'
                    );
                """;
        this.executeAndPrint(query, "Manufacturer ID", "Manufacturer Name");
    }


    // Helper function to execute any SQL query and print the results
    private void executeAndPrint(String query, String... headers) {
        try (Connection conn = DBConnect.getConnection();
                Statement stmt = conn.createStatement();
                ResultSet rs = stmt.executeQuery(query)) {

            System.out.println("\n--- Query Results ---");
            boolean hasResults = false;

            while (rs.next()) {
                hasResults = true;
                for (int i = 0; i < headers.length; i++) {
                    System.out.print(
                            headers[i] + ": " + rs.getString(i + 1) + " | ");
                }
                System.out.println();
            }

            if (!hasResults) {
                System.out.println("No results found.");
            }

        } catch (SQLException e) {
            System.err.println("Error executing query: " + e.getMessage());
        }
    }
}
