import java.util.Scanner;

public class ManufacturerMenu {
    private String userId;
    private Scanner scanner;
    private ProductService productService;
    private RecipeService recipeService;
    private IngredientService ingredientService;
    private ProductionService productionService;
    
    public ManufacturerMenu(String userId, Scanner scanner) {
        this.userId = userId;
        this.scanner = scanner;
        this.productService = new ProductService();
        this.recipeService = new RecipeService();
        this.ingredientService = new IngredientService();
        this.productionService = new ProductionService();
    }
    
    public void show() {
        while (true) {
            System.out.println("\nMANUFACTURER MENU");
            System.out.println("Logged in as: " + userId);
            System.out.println("1. Manage Products");
            System.out.println("2. Manage Recipe Plans");
            System.out.println("3. Create Product Batch");
            System.out.println("4. Reports");
            System.out.println("5. Trace Recall");
            System.out.println("0. Logout");
            System.out.print("Select option: ");
            
            int choice = scanner.nextInt();
            scanner.nextLine();
            
            switch (choice) {
                case 1:
                    manageProducts();
                    break;
                case 2:
                    manageRecipePlans();
                    break;
                case 3:
                    createProductBatch();
                    break;
                case 4:
                    showReports();
                    break;
                case 5:
                    traceRecall();
                    break;
                case 0:
                    System.out.println("Logging out...");
                    return;
                default:
                    System.out.println("Invalid option.");
            }
        }
    }
    
    private void manageProducts() {
        System.out.println("\n Manage Products ");
        System.out.println("1. Create Product");
        System.out.println("2. View My Products");
        System.out.print("Select option: ");
        
        int choice = scanner.nextInt();
        scanner.nextLine();
        
        switch (choice) {
            case 1:
                createProduct();
                break;
            case 2:
                productService.viewProductsByManufacturer(userId);
                break;
            default:
                System.out.println("Invalid option.");
        }
    }
    
    private void createProduct() {
        System.out.println("\n Create Product ");
        
        System.out.print("Enter product id: ");
        int productId = scanner.nextInt();
        scanner.nextLine();
        
        System.out.print("Enter product name: ");
        String name = scanner.nextLine();
        
        System.out.print("Enter category id: ");
        int categoryId = scanner.nextInt();
        scanner.nextLine();
        
        System.out.print("Enter standard batch size: ");
        int standardBatchUnits = scanner.nextInt();
        scanner.nextLine();
        
        productService.createProduct(userId, productId, name, categoryId, standardBatchUnits);
    }
    
    private void manageRecipePlans() {
        System.out.println("\n Manage Recipe Plans ");
        System.out.println("1. Create New Recipe Plan");
        System.out.println("2. View Recipe Plans");
        System.out.println("3. Set Active Recipe Plan");
        System.out.print("Select option: ");
        
        int choice = scanner.nextInt();
        scanner.nextLine();
        
        switch (choice) {
            case 1:
                createRecipePlan();
                break;
            case 2:
                viewRecipePlans();
                break;
            case 3:
                setActiveRecipePlan();
                break;
            default:
                System.out.println("Invalid option.");
        }
    }
    
    private void createRecipePlan() {
        System.out.println("\n Create Recipe Plan ");
        
        // show available products by manufacturer
        productService.viewProductsByManufacturer(userId);
        
        System.out.print("Enter product id: ");
        int productId = scanner.nextInt();
        scanner.nextLine();
        
        System.out.print("Enter version number: ");
        int versionNo = scanner.nextInt();
        scanner.nextLine();
        
        System.out.print("Set as active? (y/n): ");
        boolean isActive = scanner.nextLine().equalsIgnoreCase("y");
        
        int planId = recipeService.createRecipePlan(productId, userId, versionNo, isActive);
        
        if (planId > 0) {
            System.out.println("\nNow you add ingredients to this recipe plan.");
            addIngredientsToRecipe(planId);
        }
    }
    
    private void addIngredientsToRecipe(int planId) {
        while (true) {
        	// confirm addition or not
            System.out.print("\nAdd ingredient to recipe? (y/n): ");
            if (!scanner.nextLine().equalsIgnoreCase("y")) {
                break;
            }
            
            // show available ingredients
            System.out.print("\n  Available Ingredients: ");
            ingredientService.viewAllIngredients();
            
            System.out.print("Enter ingredient id: ");
            int ingredientId = scanner.nextInt();
            scanner.nextLine();
            
            System.out.print("Enter quantity: ");
            double quantityOz = scanner.nextDouble();
            scanner.nextLine();
            
            recipeService.addIngredientToRecipe(planId, ingredientId, quantityOz);
        }
        
        System.out.println("Recipe plan is complete.");
    }
    
    private void viewRecipePlans() {
        System.out.println("\n View Recipe Plans ");
        productService.viewProductsByManufacturer(userId);
        
        System.out.print("Enter product id to view recipes: ");
        int productId = scanner.nextInt();
        scanner.nextLine();
        
        recipeService.viewRecipePlans(productId, userId);
    }
    
    private void setActiveRecipePlan() {
        System.out.println("\n Set Active Recipe Plan ");
        
        System.out.print("Enter product id: ");
        int productId = scanner.nextInt();
        scanner.nextLine();
        
        recipeService.viewRecipePlans(productId, userId);
        
        System.out.print("Enter plan id to activate plan: ");
        int planId = scanner.nextInt();
        scanner.nextLine();


        recipeService.setActivePlan(planId, productId, userId);
    }
    
    private void createProductBatch() {
        System.out.println("\n Create Product Batch ");
        
        // show products
        productService.viewProductsByManufacturer(userId);
        
        System.out.print("Enter product id: ");
        int productId = scanner.nextInt();
        scanner.nextLine();
        
        // get active plan
        int planId = recipeService.getActivePlanId(productId, userId);
        if (planId == -1) {
            System.out.println("No active recipe plan found for this product.");
            return;
        }
        
        System.out.print("Enter Batch ID (e.g., B0901): ");
        String batchId = scanner.nextLine();
        
        System.out.print("Enter quantity (a multiple of standard batch size): ");
        int quantity = scanner.nextInt();
        scanner.nextLine();
        
        System.out.print("Enter expiration date (YYYY-MM-DD): ");
        String expirationDate = scanner.nextLine();
        
        System.out.print("Use FEFO auto-selection? (y/n): ");
        String useFEFO = scanner.nextLine();
        
        if (useFEFO.equalsIgnoreCase("y")) {
            // FEFO auto-selection
            productionService.createProductBatchFEFO(productId, userId, quantity, expirationDate, planId, batchId);
        } else {
            // manual selection ***needs to be fixed, placeholder JSON []***
        	productionService.recordProductionBatch(productId, userId, quantity, expirationDate, "[]", planId, batchId);
        }
    }
    
    private void showReports() {
        System.out.println("\n Reports ");
        System.out.println("1. On-Hand Inventory");
        System.out.println("2. Nearly Out-of-Stock Items");
        System.out.println("3. Almost Expired Items");
        System.out.println("4. Product Batch Cost Summary");
        System.out.println("5. Health Risk Violations (Last 30 Days)");
        System.out.print("Select report: ");
        
        int choice = scanner.nextInt();
        scanner.nextLine();
        
        switch (choice) {
            case 1:
                productionService.viewOnHandInventory();
                break;
            case 2:
                productionService.viewNearlyOutOfStock();
                break;
            case 3:
                productionService.viewAlmostExpired();
                break;
            case 4:
                System.out.print("Enter product lot number: ");
                String lotNumber = scanner.nextLine();
                productionService.viewBatchCostSummary(lotNumber);
                break;
            case 5:
                productionService.viewHealthRiskViolations();
                break;
            default:
                System.out.println("Invalid option.");
        }
    }
    
    private void traceRecall() {
        System.out.println("\n Trace Recall ");
        
        System.out.print("Enter ingredient lot number: ");
        String lotNumber = scanner.nextLine();
        
        System.out.print("Enter recall date (YYYY-MM-DD): ");
        String recallDate = scanner.nextLine();
        
        System.out.print("Enter window (days): ");
        String windowInput = scanner.nextLine();
        int windowDays = windowInput.isEmpty() ? 1 : Integer.parseInt(windowInput);
        
        productionService.traceRecall(lotNumber, recallDate, windowDays);
    }
}

