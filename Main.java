import java.util.Scanner;

public class Main {
    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);
        LoginManager loginManager = new LoginManager();
        
        System.out.println("Food Manufacturing System");
        
        // login
        String userId = loginManager.login(scanner);
        if (userId == null) {
            System.out.println("Login failed. Exiting...");
            return;
        }
        
        // get the user role
        String role = loginManager.getUserRole(userId);
        if (userId == "VIEW QUERIES") {
        	role = "VIEW QUERIES";
        }
        if (role == null) {
        	System.out.println("Empty role. Logging out.");
        	System.exit(1);
        }
        
        // go to menu according to role
        switch (role) {
            case "MANUFACTURER":
                ManufacturerMenu manufacturerMenu = new ManufacturerMenu(userId, scanner);
                manufacturerMenu.show();
                break;
            case "SUPPLIER":
                SupplierMenu supplierMenu = new SupplierMenu(userId, scanner);
                supplierMenu.show();
                break;
            case "VIEWER":
                ViewerMenu viewerMenu = new ViewerMenu(scanner);
                viewerMenu.show();
                break;
            case "VIEW QUERIES":
            	QueryMenu queryMenu = new QueryMenu(scanner);
            	queryMenu.show();
            	break;
            default:
                System.out.println("Unknown role. Exiting...");
        }
        
        scanner.close();
    }
}