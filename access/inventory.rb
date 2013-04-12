#!/usr/bin/env ruby
#
# Name: Casey Scarborough
# Date: April 9, 2013
# Lang: Ruby v2.0.0
#
# Information:
# This application will take in user input and search a Access database
# file for matching barcodes. The application also gives the user the option
# to update the database using a CSV file, and to export the database to
# a TSV file. For full detailed information please see the usage information
# by running the application with the -h, help, or ? flag.
#

require 'csv'
require 'win32ole' #require library for ActiveX Data Objects (ADO)

# Define and set global variable for database file
$database_file_path = "inventory.mdb"

# The class AccessDb shown below is used for database connection handling
class AccessDb
	# Set variables as accessors, so that they have read/writability
	attr_accessor :mdb, :connection, :data, :fields

	# Constructor for class AccessDb
	def initialize (mdb = nil)
		@mdb = mdb
		@connection = nil
		@data = nil
		@fields = nil
	end

	# Open the connection to Database
	def open
		connection_string = 'Provider=Microsoft.Jet.OLEDB.4.0;Data Source='
		connection_string << @mdb
		@connection = WIN32OLE.new('ADODB.Connection')
		@connection.Open(connection_string)
	end

	# Method for querying the Database
	def query(sql)
		recordset = WIN32OLE.new('ADODB.Recordset')
		recordset.Open(sql, @connection)
		@fields = []
		recordset.Fields.each do |field|
			@fields << field.Name
		end

		begin
			# Transpose to have array of rows
			@data = recordset.GetRows.transpose
		rescue
			@data = []
		end

		recordset.Close
	end

	# Method for executing a sql command
	def execute(sql)
		@connection.Execute(sql)
	end
	
	# Method for deleting items from the database
	def delete(barcode)
		self.query("SELECT * FROM items WHERE Barcode='#{barcode}'")
		rows = self.data
		if (rows.count == 1)
			begin # Execute delete query
				self.execute("DELETE FROM items WHERE Barcode='#{barcode}'")
				abort "Item was successfully removed from the database!"
			rescue
				abort "There was an error deleting the item from the database."
			end
		else
			abort "Item does not exist in database."
		end
	end
	
	
	# Destructor method for AccessDb Class
	def close
		@connection.Close
	end
end


# This method loads the database and returns the connection for use in other functions
def load_database
	user_input = ""

	# Check if database file is located in cwd
	until (user_input == "Y" || user_input == "N")
		print "Is the database file in the current working directory and named '#{$database_file_path}'? [Y/N]: "
		user_input = $stdin.gets.strip.upcase
	end

	# If database file is located elsewhere get file path from user
	unless (user_input == "Y")
		puts "Please specify the pathname where the database file is located, including file name."
		puts "(e.g. C:\\tempdir\\inventory.accdb or D:\\Documents\\Barcode Scanner\\inventory.mdb):"
		$database_file_path = $stdin.gets.strip
	end
	begin # Create and open new database connection
		db = AccessDb.new($database_file_path)
		db.open
	rescue
		abort "Unable to continue - database file #{$database_file_path} not found."
	end
	return db
end

# This method displays the help screen
def help_screen
	# define the help variable which holds the help text
	puts "Usage: ruby inventory.rb [?|-h|help|[-u|-o|-z <infile>|[<outfile>]]]\n
    Parameters:
       ?                 displays this usage information
       -h                displays this usage information
       help              displays this usage information
       -u <infile>       update the inventory using the file <infile>.
                         The filename <infile> must have a .csv
                         extension and it must be a text file in comma
                         separated value (CSV) format. Note that the
                         values must be in double quote.
       -z|-o [<outfile>] output either the entire content of the
                         database (-o) or only those records for which
                         the quantity is zero (-z). If no <outfile> is
                         specified then output on the console otherwise
                         output in the text file named <outfile>. The
                         output in both cases must be in a tab separated
                         value (tsv) format.
       -d                prompts the user to enter the barcode of an item
                         to delete from the database"
end

# This method updates the database file using the .csv with the -u argument
def update_inventory
	if (ARGV[1] == nil) # The user did not specify a filename
		abort "The -u argument requires an <infile>"
	else # The file was not a csv file
		if (!ARGV[1].to_s.end_with?(".csv") || ARGV[1] == nil)
			puts "Invalid file format -- Unable to proceed."
		else
			# Get the filename and load the database file
			filename = ARGV[1]
			db = load_database
			
			begin # Attempt to open user csv file
				csv_file = CSV.open(filename, "r")
			rescue # Abort if file not found
				abort "Input file #{ARGV[1]} not found - aborting."
			end
			# Create an array to hold the contents
			update_contents = Array.new{Array.new}
			
			# Put the contents of the file into the array
			CSV.foreach(filename) { |row| update_contents << row }
			
			# Loop through the array adding the items to the database
			update_contents.each do |item|
				begin
					db.execute("INSERT INTO items VALUES('#{item[0]}', '#{item[1]}', '#{item[2]}', #{item[3]}, #{item[4]}, '#{item[5]}')")
				rescue
					abort "There was a problem inserting into the database. Please ensure that there are no duplicate barcodes in the database and the update file."
				end
			end
			# Update successful
			puts "Updated #{csv_file.count} database records successfully"
		end
	end
end

# This method displays the inventory and is called when user puts -o|-z <outfile>
def display_inventory(everything)
	db = load_database
	# If user specifies -o, get everything, else only 0 quantity items
	if (everything == true) then query = "SELECT * FROM items";
	else query = "SELECT * FROM items WHERE Quantity=0"; end;
	# Query the database and get the rows array
	db.query(query)
	rows = db.data
	
	if (ARGV[1] == nil) # If the user did not specify a filename
		# Set up output table and display data
		puts "\n+----------------+---------------------------------+------" +
			"-----------+----------+---------+-----------------------------+"
		puts "| Barcode".ljust(17) + "| Item Name:".ljust(34) + 
			"| Item Category".ljust(18) + "| Quantity".ljust(11) + 
			"| Price".ljust(10) + "| Description".ljust(29) + " |"
		puts "+----------------+---------------------------------+--------" +
			"---------+----------+---------+-----------------------------+"
		rows.each do |item|
			print "| #{item[0]}".ljust(17)
			print "| #{item[1]}".ljust(34)
			print "| #{item[2]}".ljust(18)
			print "| #{item[3]}".ljust(11)
			print "| #{item[4]}".ljust(10)
			print "| #{item[5]}".ljust(29)
			print " |\n"
		end
		puts "+----------------+---------------------------------+--------" +
			"---------+----------+---------+-----------------------------+"
		print "\n"
	else # If the user specified a file, output it to a TSV
		new_filename = ARGV[1].to_s
		if (new_filename.end_with?(".tsv"))
			CSV.open(new_filename, "w", {:col_sep => "\t"}) do |csv|
				rows.each { |item| csv << [item[0], item[1], item[2], item[3], item[4], item[5]] }
			end
			puts "File was successfully created!"
		else puts "File format must be .tsv!"
		end
	end
end

# This method prompts the user to enter information and adds it to the database
def new_db_entry(barcode,db)
	# Get item information
	print "Enter the item name: "
	item_name = $stdin.gets.strip
	print "Enter the item category: "
	item_category = $stdin.gets.strip
	print "Enter the quantity: "
	quantity = $stdin.gets.strip
	print "Enter the price: "
	price = $stdin.gets.strip
	print "Enter the description: "
	description = $stdin.gets.strip
	
	begin # Execute insert statement to add item to the database
		db.execute("INSERT INTO items VALUES ('#{barcode}', '#{item_name}', '#{item_category}', #{quantity}, #{price}, '#{description}')")
	rescue 
		abort "There was an error inputting the item into the database."
	end
	puts "Item successfully inserted!"
end


# This method searches the database file for the barcode entered by the user
def search_inventory(barcode,db)
	# Query the database
	db.query("SELECT * FROM items WHERE Barcode='#{barcode}'")
	rows = db.data
	
	if (rows.count == 1) # If the item was found
		rows.each do |item| # Loop through each row
			if (item[3] == 0) # If it has zero quantity
				user_decision = ""
				quantity = 0
				loop do # Ask user if they want to update quantity
					print "\nBarcode " + barcode + " found in the database but has a zero quantity. Do you want to update quantity? [Y/N]: "
					user_decision = gets.strip.upcase
					break if (user_decision == "Y" || user_decision == "N")
				end
				if (user_decision == "Y")
					loop do # get new quantity
						print "Enter the new quantity: [> 0]: "
						# convert the input to an integer, will convert to 0 if not an int
						quantity = gets.strip.to_i
						break if (quantity > 0)
					end # set quantity == new quantity and write to file
					begin
						db.execute("UPDATE items SET Quantity=#{quantity} WHERE Barcode='#{barcode}'")
						puts "Update was successful!"
					rescue
						puts "There was a problem updating the quantity. "
					end
				end # output item details
				puts "Details are given below."
				puts "   Item Name: #{item[1]}"
				puts "   Item Category: #{item[2]}"
				puts "   Quantity: #{quantity.to_s}"
				puts "   Price: #{item[4]}"
				puts "   Description: #{item[5]}"
				print "\n"
			else # If it does not have a zero quantity
				puts "Barcode #{barcode} found in the database. Details are given below."
				puts "   Item Name: #{item[1]}"
				puts "   Item Category: #{item[2]}"
				puts "   Quantity: #{item[3]}"
				puts "   Price: #{item[4]}"
				puts "   Description: #{item[5]}"
				print "\n"
			end
		end
	else # If the item was not found
		user_input = ""
	
		# Prompt user if they'd like to add it
		until (user_input == "Y" || user_input == "N")
			print "Barcode #{barcode} NOT found in the database. Do you want to enter information? [Y/N]: "
			user_input = gets.strip.upcase
		end
		
		# If yes, call new_db_entry
		if (user_input == "Y")
			new_db_entry(barcode,db)
		end
	end
end



# If the user entered ? -h or help
if (ARGV[0] == '?' || ARGV[0] == '-h' || ARGV[0] == 'help')
	help_screen
# If the user entered -u
elsif (ARGV[0] == '-u')
	update_inventory
# If the user entered -z or -o
elsif (ARGV[0] == '-z' || ARGV[0] == '-o')
	if (ARGV[0] == '-z')
		display_inventory(false)
	else
		display_inventory(true)
	end
# If the user entered -d
elsif (ARGV[0] == '-d')
	db = load_database
	print "Enter the barcode of the item to delete: "
	barcode = $stdin.gets.strip
	db.delete(barcode)
else # Load the database
	dbcontents = load_database
	print "> " # Block and wait for input
	input = $stdin.gets.strip
	# Search the database for matching barcode
	search_inventory(input,dbcontents)
end
