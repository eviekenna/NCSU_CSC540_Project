import java.sql.Connection;

import java.sql.DriverManager;
import java.sql.SQLException;

public class DBConnect {

	private static final String url = "jdbc:mariadb://classdb2.csc.ncsu.edu:3306/wlcarte2";
	//private static final String url = "jdbc:mariadb://152.14.85.57:3306/wlcarte2";
	private static final String user = "wlcarte2";
	private static final String pswd = "200189853";
		
	public static Connection getConnection() throws SQLException {
		return DriverManager.getConnection(url, user, pswd);
	}
		
	public static void main(String args[]) {
		try (Connection conn = getConnection()) {
			System.out.println("Successfully connected to DB");
		} catch (SQLException e) {
			e.printStackTrace();
		}
	}
	
}
