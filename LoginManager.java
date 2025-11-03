import java.sql.*;
import java.util.Scanner;

public class LoginManager {
    
	
    public String login(Scanner scanner) {
        System.out.print("Enter User ID: ");
        String userId = scanner.nextLine();
        
        try (Connection conn = DBConnect.getConnection()) {
            String sql = "SELECT user_id, first_name, last_name, role_code FROM User WHERE user_id = ?";
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setString(1, userId);
            
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                System.out.println("\nWelcome, " + rs.getString("first_name") + " " + rs.getString("last_name") + ".");
                System.out.println("Role: " + rs.getString("role_code") + "\n");
                return userId;
            } else {
                System.out.println("User not found!");
                return null;
            }
        } catch (SQLException e) {
            e.printStackTrace();
            return null;
        }
    }
    
    public String getUserRole(String userId) {
        try (Connection conn = DBConnect.getConnection()) {
            String sql = "SELECT role_code FROM User WHERE user_id = ?";
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setString(1, userId);
            
            ResultSet rs = stmt.executeQuery();
            if (rs.next()) {
                return rs.getString("role_code");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }
}