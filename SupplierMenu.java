import java.sql.*;
import java.util.Scanner;

public class SupplierMenu {
    private String supplierId;
    private Scanner scanner;
    private IngredientService ingredientService;

    public SupplierMenu(String supplierId, Scanner scanner) {
        this.supplierId = supplierId;
        this.scanner = scanner;
        this.ingredientService = new IngredientService();
    }

    public void show() {
        while (true) {
            System.out.println("\n SUPPLIER MENU ");
            System.out.println("Logged in as: " + supplierId);
            System.out.println("1. Manage Ingredients Supplied");
            System.out.println("2. Create Ingredient Batch");
            System.out.println("3. View My Formulations");
            System.out.println("4. Manage Do-Not-Combine List");
            System.out.println("0. Logout");
            System.out.print("Select option: ");
            
            int choice = scanner.nextInt();
            scanner.nextLine();
            
            switch (choice) {
                case 1:
                    manageIngredientsSupplied();
                    break;
                case 2:
                    createIngredientBatch();
                    break;
                case 3:
                    viewFormulations();
                    break;
                case 4:
                    manageDoNotCombine();
                    break;
                case 0:
                    System.out.println("Logging out.");
                    return;
                default:
                    System.out.println("Invalid option.");
            }
        }
    }
    
    private void manageIngredientsSupplied() {
        System.out.println("\n Manage Ingredients Supplied ");
        System.out.println("1. Create New Ingredient");
        System.out.println("2. Define Ingredient Composition (for compounds)");
        System.out.println("3. Create Supplier Formulation");
        System.out.print("Select option: ");
        
        int choice = scanner.nextInt();
        scanner.nextLine();
        
        switch (choice) {
            case 1:
                createNewIngredient();
                break;
            case 2:
                defineIngredientComposition();
                break;
            case 3:
                createFormulation();
                break;
            default:
                System.out.println("Invalid option.");
        }
    }

    private void createNewIngredient() {
        System.out.println("\n Create New Ingredient ");
        
        System.out.print("Enter ingredient id: ");
        int ingredientId = scanner.nextInt();
        scanner.nextLine();
        
        System.out.print("Enter ingredient name: ");
        String name = scanner.nextLine();
        
        System.out.print("Enter type (atomic/compound): ");
        String type = scanner.nextLine();
        
        if (!type.equals("atomic") && !type.equals("compound")) {
            System.out.println("Invalid type. Must be 'atomic' or 'compound'.");
            return;
        }
        
        ingredientService.createIngredient(ingredientId, name, type);
        
        // if compound, ask to add materials
        if (type.equals("compound")) {
            System.out.print("\nAdd materials to this compound ingredient? (y/n): ");
            if (scanner.nextLine().equalsIgnoreCase("y")) {
                addMaterialsToCompound(ingredientId);
            }
        }
    }

    private void defineIngredientComposition() {
        System.out.println("\n Define Ingredient Composition ");
        
        ingredientService.viewAllIngredients();
        
        System.out.print("\nEnter parent ingredient id: ");
        int parentId = scanner.nextInt();
        scanner.nextLine();
        
        addMaterialsToCompound(parentId);
    }

    private void addMaterialsToCompound(int parentId) {
        while (true) {
            System.out.print("\nAdd material to compound? (y/n): ");
            if (!scanner.nextLine().equalsIgnoreCase("y")) {
                break;
            }
            
            ingredientService.viewAllIngredients();
            
            System.out.print("Enter child ingredient id: ");
            int childId = scanner.nextInt();
            scanner.nextLine();
            
            System.out.print("Enter quantity: ");
            double quantity = scanner.nextDouble();
            scanner.nextLine();
            
            ingredientService.addIngredientComposition(parentId, childId, quantity);
        }
    }

    private void createFormulation() {
        System.out.println("\n Create Supplier Formulation ");
        
        ingredientService.viewAllIngredients();
        
        System.out.print("\nEnter ingredient id: ");
        int ingredientId = scanner.nextInt();
        scanner.nextLine();
        
        System.out.print("Enter version number: ");
        int versionNo = scanner.nextInt();
        scanner.nextLine();
        
        System.out.print("Enter pack size: ");
        double packSize = scanner.nextDouble();
        scanner.nextLine();
        
        System.out.print("Enter price per unit: ");
        double pricePerUnit = scanner.nextDouble();
        scanner.nextLine();
        
        System.out.print("Enter effective start date (YYYY-MM-DD): ");
        String startDate = scanner.nextLine();
        
        System.out.print("Enter effective end date (YYYY-MM-DD): ");
        String endDate = scanner.nextLine();
        
        ingredientService.createSupplierFormulation(supplierId, ingredientId, versionNo,
                                                    packSize, pricePerUnit, startDate, endDate);
    }
    
    private void createIngredientBatch() {
        System.out.println("\n Create Ingredient Batch ");
        
        // show available ingredients
        ingredientService.viewAllIngredients();
        
        System.out.print("Enter ingredient id: ");
        int ingredientId = scanner.nextInt();
        scanner.nextLine();
        
        System.out.print("Enter Batch ID (e.g. B0009): ");
        String batchId = scanner.nextLine();
        
        System.out.print("Enter quantity: ");
        double quantity = scanner.nextDouble();
        scanner.nextLine();
        
        System.out.print("Enter unit cost (per oz): ");
        double unitCost = scanner.nextDouble();
        scanner.nextLine();
        
        System.out.print("Enter expiration date (YYYY-MM-DD): ");
        String expirationDate = scanner.nextLine();
        
        ingredientService.createIngredientBatch(supplierId, ingredientId, quantity, unitCost, expirationDate, batchId);
    }
    
    private void viewFormulations() {
        System.out.println("\n My Formulations ");
        ingredientService.viewSupplierFormulations(supplierId);
    }
    
    private void manageDoNotCombine() {
        System.out.println("\n Manage Do-Not-Combine List ");
        System.out.println("1. View Do-Not-Combine Pairs");
        System.out.println("2. Add Do-Not-Combine Pair");
        System.out.print("Select option: ");
        
        int choice = scanner.nextInt();
        scanner.nextLine();
        
        switch (choice) {
            case 1:
            	ingredientService.viewDoNotCombine();
                break;
            case 2:
                addDoNotCombine();
                break;
            default:
                System.out.println("Invalid option.");
        }
    }
    
    
    private void addDoNotCombine() {
        System.out.println("\n Add Do-Not-Combine Pair ");
        
        // show available ingredients
        ingredientService.viewAllIngredients();
        
        System.out.print("Enter first ingredient id: ");
        int ingredientA = scanner.nextInt();
        scanner.nextLine();
        
        System.out.print("Enter second ingredient id: ");
        int ingredientB = scanner.nextInt();
        scanner.nextLine();
        
        ingredientService.addDoNotCombine(ingredientA, ingredientB);
    }
}
