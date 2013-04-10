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

	# Destructor method for AccessDb Class
	def close
		@connection.Close
	end
end


# This function loads the database and returns the connection for use in other functions
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
		$database_file_path = gets.strip
	end

	begin
		db = AccessDb.new($database_file_path)
		db.open
	rescue
		#abort "Unable to continue - database file #{$database_file_path} not found."
	end
	return db
end

# This function displays the help screen
def help_screen
	# define the help variable which holds the help text
	help = 
	"Usage: ruby inventory.rb [?|-h|help|[-u|-o|-z <infile>|[<outfile>]]]\n
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
	                     value (tsv) format."

	# print the help screen
	puts help
end

# This function updates the database file using the .csv with the -u argument
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

			# Attempt to open user csv file. If not found, abort program.
			begin
				csv_file = CSV.open(filename, "r")
			# Instead of asking for new file name, abort if file not found.
			rescue
				abort "Input file #{ARGV[1]} not found - aborting."
			end
			
			# Create an array to hold the contents
			update_contents = Array.new{Array.new}
			
			# Put the contents of the file into the array
			CSV.foreach(filename) do |row|
				update_contents << row
			end
			
			# Loop through the array adding the items to the database
			update_contents.each do |a|
				begin
					db.execute("INSERT INTO items VALUES('#{a[0]}', '#{a[1]}', '#{a[2]}', #{a[3]}, #{a[4]}, '#{a[5]}')")
				rescue
					abort "There was a problem inserting into the database. Please ensure that there are no duplicate barcodes in the database and the update file."
				end
			end

			# Update successful
			puts "Updated #{csv_file.count} database records successfully"
		end
	end
end

# This function displays the inventory and is called when user puts -o|-z <outfile>
def display_inventory(everything)	
	# If the user specified -o the if statement runs
	if (everything == true)
		# Query the database and set fields and rows variable
		db = load_database
		db.query("SELECT * FROM items")
		fields = db.fields
		rows = db.data
		# If no file specified output to screen
		if (ARGV[1] == nil)
			content = ""
			# Loop through the rows and append to conent
			rows.each do |a|
				content += "| #{a[0]}".ljust(17)
				content += "| #{a[1]}".ljust(34)
				content += "| #{a[2]}".ljust(18)
				content += "| #{a[3]}".ljust(11)
				content += "| #{a[4]}".ljust(10)
				content += "| #{a[5]}".ljust(29)
				content += " |\n"
			end
			# Set up output table and display data
			puts "\n+----------------+---------------------------------+-----------------+----------+---------+-----------------------------+"
			puts "| Barcode".ljust(17) + "| Item Name:".ljust(34) + 
				"| Item Category".ljust(18) + "| Quantity".ljust(11) + 
				"| Price".ljust(10) + "| Description".ljust(29) + " |"
			puts "+----------------+---------------------------------+-----------------+----------+---------+-----------------------------+"
			print content
			puts "+----------------+---------------------------------+-----------------+----------+---------+-----------------------------+"
			print "\n"
		else # If the user specified a file, output it to a TSV
			new_filename = ARGV[1].to_s
			if (new_filename.end_with?(".tsv"))
				CSV.open(new_filename, "w", {:col_sep => "\t"}) do |csv|
					rows.each do |a|
					  csv << [a[0], a[1], a[2], a[3], a[4], a[5]]
					end
				end
				puts "File was successfully created!"
			else
				puts "File format must be .tsv!"
			end
		end
	else # If the user specified -z
		# Query the database and add fields and rows variables
		db = load_database
		db.query("SELECT * FROM items WHERE Quantity=0")
		fields = db.fields
		rows = db.data
		if (ARGV[1] == nil)
			content = "" # set variable to hold content
			# Loop through the rows and append to conent
			rows.each do |a|
				content += "| #{a[0]}".ljust(17)
				content += "| #{a[1]}".ljust(34)
				content += "| #{a[2]}".ljust(18)
				content += "| #{a[3]}".ljust(11)
				content += "| #{a[4]}".ljust(10)
				content += "| #{a[5]}".ljust(29)
				content += " |\n"
			end
			if (content == "") # if no content was found
				puts "No database records found with zero quantity."
			else # output content
				puts "\n+----------------+---------------------------------+-----------------+----------+---------+-----------------------------+"
				puts "| Barcode".ljust(17) + "| Item Name:".ljust(34) + 
					"| Item Category".ljust(18) + "| Quantity".ljust(11) + 
					"| Price".ljust(10) + "| Description".ljust(29) + " |"
				puts "+----------------+---------------------------------+-----------------+----------+---------+-----------------------------+"
				print content
				puts "+----------------+---------------------------------+-----------------+----------+---------+-----------------------------+"
				print "\n"
			end
		else # If the user specified a file output to TSV
			new_filename = ARGV[1].to_s
			if (new_filename.end_with?(".tsv"))
				CSV.open(new_filename, "w", {:col_sep => "\t"}) do |csv|
					rows.each do |a|
					  csv << [a[0], a[1], a[2], a[3], a[4], a[5]]
					end
				end
				puts "File was successfully created!"
			else
				puts "File format must be .tsv!"
			end
		end
	end
end

# This function prompts the user to enter information and adds it to the database
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


# This function searches the database file for the barcode entered by the user
def search_inventory(barcode,db)
	# Query the database
	db.query("SELECT * FROM items WHERE Barcode='#{barcode}'")
	fields = db.fields
	rows = db.data
	
	database_item = ""
	rows.each do |a| # Loop through each row
		if (a[0] == barcode) # find a match
			if (a[3] == 0) # If it has zero quantity
				user_decision = ""
				loop do # Ask user if they want to update quantity
					print "\nBarcode " + barcode + " found in the database but has a zero quantity. Do you want to update quantity? [Y/N]: "
					user_decision = gets.strip.upcase
					break if (user_decision == "Y" || user_decision == "N")
				end
				if (user_decision == "Y")
					quantity = 0
					loop do # get new quantity
						print "Enter the new quantity: [> 0]: "
						# convert the input to an integer, will convert to 0 if not an int
						quantity = gets.strip.to_i
						break if (quantity > 0)
					end # set quantity == new quantity and write to file
					db.execute("UPDATE items SET Quantity=#{quantity} WHERE Barcode='#{barcode}'")
				end # output item details
				puts "Update was successful!"
				database_item += "Details are given below.\n"
				database_item += "   Item Name: " << a[1] + "\n"
				database_item += "   Item Category: " << a[2] + "\n"
				database_item += "   Quantity: " << quantity.to_s + "\n"
				database_item += "   Price: " << a[4] + "\n"
				database_item += "   Description: " << a[5] + "\n"
				database_item += "\n"
			else # If it does not have a zero quantity
				database_item << "Barcode #{barcode} found in the database. Details are given below.\n"
				database_item << "   Item Name: #{a[1]}\n"
				database_item << "   Item Category: #{a[2]}\n"
				database_item << "   Quantity: #{a[3]}\n"
				database_item << "   Price: #{a[4]}\n"
				database_item << "   Description: #{a[5]}\n"
				database_item << "\n"
			end
		end
	end
	
	# If the item was not found
	if (database_item == "")
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
	else # If it was found
		puts database_item
	end
end

# This function is used to delete items from the database
def delete_item
	db = load_database
	
	# Get barcode
	print "Enter the barcode of the item you'd like to delete: "
	barcode = $stdin.gets.strip
	
	begin # Execute delete query
		db.execute("DELETE FROM items WHERE Barcode='#{barcode}'")
	rescue
		abort "There was an error deleting the item from the database."
	end
	puts "Item deleted successfully!"
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
	delete_item
else # Load the database
	dbcontents = load_database
	print "> " # Block and wait for input
	input = $stdin.gets.strip
	# Search the database for matching barcode
	search_inventory(input,dbcontents)
end
