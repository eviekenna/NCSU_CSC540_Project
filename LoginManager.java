import java.sql.*;
import java.util.ArrayList;
import java.util.Scanner;

public class LoginManager {
	
	private static String queryUserId = "VIEW QUERIES";
    
	/**
	 * login to db
	 */
    public String login(Scanner scanner) {
    	System.out.print("Choose a role: [1] Manufacturer [2] Supplier [3] Viewer [4] Queries: ");
    	String roleSelecString = scanner.nextLine(); 
    	int roleSelection = Integer.parseInt(roleSelecString);
    	
    	if (roleSelection != 1 && roleSelection != 2 && roleSelection != 3 && roleSelection != 4) {
            System.out.println("Not a valid input. Logging out.");
            System.exit(1);
    	}
    	ArrayList<Integer> rolesList = new ArrayList<Integer> (3);
    	rolesList.add(1);
    	rolesList.add(2);
    	rolesList.add(3);
    	boolean needUserID = false;
    	needUserID = rolesList.contains(roleSelection);
    	if (!needUserID) {
    		// queries
    		System.out.println("Implement query menu.");
    		return queryUserId;
    	}
    	else {
        	// prompt user for id, e.g. MFG001
            System.out.print("Enter User ID: ");
            String userId = scanner.nextLine();
            // connect to db
            try (Connection conn = DBConnect.getConnection()) {
            	// query 
                String query = "SELECT user_id, first_name, last_name, role_code FROM User WHERE user_id = ?";
                PreparedStatement stmt = conn.prepareStatement(query);
                stmt.setString(1, userId);
                // results
                ResultSet rs = stmt.executeQuery();
                // print hello and info
                if (rs.next()) {
                    System.out.println("\nHello, " + rs.getString("first_name") + " " + rs.getString("last_name") + ".");
                    System.out.println("Role: " + rs.getString("role_code") + "\n");
                    return userId;
                } else {
                    System.out.println("User not found.");
                    return null;
                }
            } catch (SQLException e) {
                e.printStackTrace();
                return null;
            }
    	}
    	
//    	// prompt user for id, e.g. MFG001
//        System.out.print("Enter User ID: ");
//        String userId = scanner.nextLine();
//        // connect to db
//        try (Connection conn = DBConnect.getConnection()) {
//        	// query 
//            String query = "SELECT user_id, first_name, last_name, role_code FROM User WHERE user_id = ?";
//            PreparedStatement stmt = conn.prepareStatement(query);
//            stmt.setString(1, userId);
//            // results
//            ResultSet rs = stmt.executeQuery();
//            // print hello and info
//            if (rs.next()) {
//                System.out.println("\nHello, " + rs.getString("first_name") + " " + rs.getString("last_name") + ".");
//                System.out.println("Role: " + rs.getString("role_code") + "\n");
//                return userId;
//            } else {
//                System.out.println("User not found.");
//                return null;
//            }
//        } catch (SQLException e) {
//            e.printStackTrace();
//            return null;
//        }
    }
    
    /**
     * get user's role
     */
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