#!/usr/bin/env ruby
#
# Name: Casey Scarborough
# Date: April 9, 2013
#
# Lang: Ruby v2.0.0
#
# Information:
# This application will take in user input and search a Access database
# file for matching barcodes. The application also gives the user the option
# to update the database using a CSV file, and to export the database to
# a TSV file. For full detailed information please see the usage information
# by running the application with the -h, help, or ? flag.
#
# This application uses the Microsoft ACE OLEDB Provider. If you need to use
# Microsoft Jet or another provider, it may be changed on line 80. Please note
# that if you use Microsoft Jet you will need to convert the accdb file to mdb
# format.

require 'csv'
require 'win32ole' #require library for ActiveX Data Objects (ADO)

# Define and set global variable for database file
$database_file_path ="inventory.accdb"

if (ARGV[0] != "-h" && ARGV[0] != "help" && ARGV[0] != "?")
	user_input = ""
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


# The class AccessDb shown below is used for database connection handling
class AccessDb
	# Set variables as accessors, so that they have read/writability
	attr_accessor :filename, :connection, :data, :fields

	# Constructor for class AccessDb
	def initialize (filename = nil)
		@filename = filename
	end

	# Open the connection to Database
	def open
		@connection = WIN32OLE.new('ADODB.Connection')
		@connection.Open("Provider=Microsoft.ACE.OLEDB.12.0;Data Source=#{@filename}")
	end

	# Method for querying the Database
	def query(sql)
		recordset = WIN32OLE.new('ADODB.Recordset')
		recordset.Open(sql, @connection)
		# Retrieve the names of the fields into an array
		@fields = []
		recordset.Fields.each do |field|
			@fields << field.Name
		end
		begin
			# Transpose to get an array of rows
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


# This class is used for updating the database
class Update
	attr_accessor :query, :filename, :rows, :db

	# Initializer method
	def initialize
		@query = "SELECT * FROM items"
		begin # Create and open new database connection
			@db = AccessDb.new($database_file_path)
			@db.open
		rescue
			abort "Unable to continue - database file #{$database_file_path} not found."
		end # Query the database
		@db.query(@query)
		@rows = @db.data
	end

	# This method imports the data from the CSV file into the database
	def import(filename)
		begin # Attempt to open user csv file
			csv_file = CSV.open(filename, "r")
		rescue # Abort if file not found
			abort "Input file #{ARGV[1]} not found - aborting."
		end
		# Create an array to hold the contents
		update_contents = Array.new{Array.new}

		# Put the contents of the file into the array
		CSV.foreach(filename) { |row| update_contents << row }

		found_match = false
		update_count = 0
		# Loop through the array adding the items to the database
		update_contents.each do |item|
			quantity = 0
			# See if a barcode match exists in the database
			@rows.each do |a|
				if (item[0] == a[0])
					found_match = true
					quantity = item[3].to_i
					quantity += a[3].to_i
					break
				end
			end
			if (found_match == true)
				begin # If a match was found, update that barcode
					query = "UPDATE items SET Barcode=#{item[0]}, ItemName='#{item[1]}', ItemCategory='#{item[2]}', Quantity=#{quantity}, Price=#{item[4]}, Description='#{item[5]}' WHERE Barcode='#{item[0]}'"
					@db.execute(query)
					puts "Updated barcode #{item[0]}"
					found_match = false
					update_count += 1
				rescue
					abort "There was a problem updating the item in the database."
				end
			else # If a match wasn't found, insert that barcode
				begin
					@db.execute("INSERT INTO items VALUES('#{item[0]}', '#{item[1]}', '#{item[2]}', #{item[3]}, #{item[4]}, '#{item[5]}')")
					puts "Inserted barcode #{item[0]}"
					update_count += 1
				rescue
					abort "There was a problem inserting into the database."
				end
			end
		end
		# Update successful
		puts "Updated #{update_count} database records successfully"
		db.close
	end
end


# This class is used to display information from the database
class Display
	# Accessors for the class
	attr_accessor :query, :all, :rows, :filename

	# Class constructor
	def initialize (all = true)
		@all = all
		if (@all == false) 
			@query = "SELECT * FROM items WHERE Quantity=0"
		else @query = "SELECT * FROM items"
		end

		# New database instance
		begin # Create and open new database connection
			@db = AccessDb.new($database_file_path)
			@db.open
		rescue
			abort "Unable to continue - database file #{$database_file_path} not found."
		end
		# Query the database and get the rows
		@db.query(@query)
		@rows = @db.data
	end

	# This method displays the data onto the screen
	def display
		# Set up output table and display data
		puts "\n+----------------+---------------------------------+-----------------+----------+---------+-----------------------------+"
		puts "| Barcode".ljust(17) + "| Item Name:".ljust(34) + 
			"| Item Category".ljust(18) + "| Quantity".ljust(11) + 
			"| Price".ljust(10) + "| Description".ljust(29) + " |"
		puts "+----------------+---------------------------------+-----------------+----------+---------+-----------------------------+"
		@rows.each do |item|
			print "| #{item[0]}".ljust(17) + "| #{item[1]}".ljust(34) + "| #{item[2]}".ljust(18) + "| #{item[3]}".ljust(11) + "| #{item[4]}".ljust(10) + "| #{item[5]}".ljust(29) + " |\n"
		end
		puts "+----------------+---------------------------------+-----------------+----------+---------+-----------------------------+"
	end

	# This method exports the data to a text file
	def export(filename)
		@filename = filename
		if (@filename.end_with?(".tsv"))
			CSV.open(@filename, "w", {:col_sep => "\t"}) do |csv|
				rows.each { |item| csv << [item[0], item[1], item[2], item[3], item[4], item[5]] }
			end
			puts "File was successfully created!"
		else abort "File format must be .tsv!"
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
					user_decision = $stdin.gets.strip.upcase
					break if (user_decision == "Y" || user_decision == "N")
				end
				if (user_decision == "Y")
					loop do # get new quantity
						print "Enter the new quantity: [> 0]: "
						# convert the input to an integer, will convert to 0 if not an int
						quantity = $stdin.gets.strip.to_i
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
			else # If it does not have a zero quantity
				puts "Barcode #{barcode} found in the database. Details are given below."
				puts "   Item Name: #{item[1]}"
				puts "   Item Category: #{item[2]}"
				puts "   Quantity: #{item[3]}"
				puts "   Price: #{item[4]}"
				puts "   Description: #{item[5]}"
			end
		end
	else # If the item was not found
		user_input = ""

		# Prompt user if they'd like to add it
		until (user_input == "Y" || user_input == "N")
			print "Barcode #{barcode} NOT found in the database. Do you want to enter information? [Y/N]: "
			user_input = $stdin.gets.strip.upcase
		end

		# If yes, call new_db_entry
		if (user_input == "Y")
			new_db_entry(barcode,db)
		else
			print "Enter the barcode to search for: " # Block and wait for input
			input = $stdin.gets.strip
			# Search the database for matching barcode
			search_inventory(input,db)
		end
	end
end



# If the user entered ? -h or help
if (ARGV[0] == '?' || ARGV[0] == '-h' || ARGV[0] == 'help')
	help_screen
# If the user entered -u
elsif (ARGV[0] == '-u')
	if (ARGV[1] == nil) # The user did not specify a filename
		abort "The -u argument requires an <infile>"
	else
		if (!ARGV[1].to_s.end_with?(".csv"))
			abort "Invalid file format -- Unable to proceed."
		else
			filename = ARGV[1].to_s
			update = Update.new
			update.import(filename)
		end
	end
# If the user entered -z or -o
elsif (ARGV[0] == '-z' || ARGV[0] == '-o')
	# If user entered -z, set everything to false, otherwise true
	ARGV[0] == '-z' ? everything = false : everything = true

	# Create a new instance of Display and either display it or export it
	table = Display.new(everything)
	if (ARGV[1] == nil)
		table.display
	else
		filename = ARGV[1].to_s
		table.export(filename)
	end
# If the user entered -d
elsif (ARGV[0] == '-d')
	begin # Create and open new database connection
		db = AccessDb.new($database_file_path)
		db.open
	rescue
		abort "Unable to continue - database file #{$database_file_path} not found."
	end
	print "Enter the barcode of the item to delete: "
	barcode = $stdin.gets.strip
	db.delete(barcode)
elsif (ARGV[0] == nil) # Load the database
	begin # Create and open new database connection
		db = AccessDb.new($database_file_path)
		db.open
	rescue
		abort "Unable to continue - database file #{$database_file_path} not found."
	end
	print "Enter the barcode to search for: " # Block and wait for input
	input = $stdin.gets.strip
	# Search the database for matching barcode
	search_inventory(input,db)
else # Invalid argument
	abort "Invalid option: #{ARGV[0]}\nPlease see usage information (-h, ?, or help)"
end