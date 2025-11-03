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
        
        // go to menu according to role
        switch (role) {
            case "MANUFACTURER":
                ManufacturerMenu manufacturerMenu = new ManufacturerMenu(userId);
                manufacturerMenu.show(scanner);
                break;
            case "SUPPLIER":
                SupplierMenu supplierMenu = new SupplierMenu(userId);
                supplierMenu.show(scanner);
                break;
            case "VIEWER":
                ViewerMenu viewerMenu = new ViewerMenu();
                viewerMenu.show(scanner);
                break;
            default:
                System.out.println("Unknown role. Exiting...");
        }
        
        scanner.close();
    }
}