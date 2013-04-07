Ruby Barcode and Inventory Application
======================================

This is an application written in Ruby v2.0.0 that reads a barcode by using a barcode scanner or from the keyboard by typing the numeric representation of the barcode. Once a barcode is read into the application, the database file will be searched. If found the information for the item will be given in the following format:
	Barcode 9780321545893 found in the database. Details are given below:
      Item Name: Artificial Intelligence
      Item Category: Book
      Quantity: 2
      Price: 129.00
      Description: Addison Wesley Publ.

If the item is not found in the database, then the user is given the option to add the information for the specified item into the database.

The user may also update the database file using the contents of a comma-separated-values (.csv) file that they specify. This is performed by running the application with the -u flag with a specified .csv file after it.

The contents of the database can also be printed out using the -o flag. This will print out all information for all records in the database file. If the user uses the -z flag instead of the -o flag, only the records with a zero quantity will be displayed. The information for the -o or the -z flags can be output to a file by specifying a .tsv file after the argument.

By default, the database file is located in the same directory as the program, but it can be changed to a different filename or an absolute file path using the global variable at the beginning of the inventory.rb file.