import java.util.Scanner;
//This program is used to calculate the area of a rectangle

public class CalculateRectangleArea {
    // Main function of the Java Program. Starting point.
    public static void main(String[] args) {
        Scanner input = new Scanner(System.in);
        int width = 0; // width of rectangle
        int height = 0; //height of rectangle
        System.out.print("Enter the height of the rectangle: ");
        height = input.nextInt();
        System.out.print("Enter the width of the rectangle: ");
        width = input.nextInt();
        
        //Area is the product of width time height
        int area = width * height;
        
        //Below prints out the representation of the rectangle.
        for( int i = 0; i < height ; i++){
            for (int j = 0; j < width; j++){
                if(j == 0 || j == (width - 1))
                    System.out.print("[]");
                else
                    System.out.print("[]");
            }
            System.out.println("");
        }
        System.out.print("Do you want to expand the rectangle by a factor?");
        String expand = input.next();
        expand = expand.toLowerCase();
        if(expand.equals("y") || expand.equals("n")){
            System.out.print("Enter size factor: ");
            int expansion = input.nextInt();
            width  = width * expansion;
            height = height * expansion;
            for( int i = 0; i < height ; i++){
                for (int j = 0; j < width; j++){
                    if(j == 0 || j == (width - 1))
                        System.out.print("[]");
                    else
                        System.out.print("[]");
                }
                System.out.println("");
            }
        }
        return;
    }
}
