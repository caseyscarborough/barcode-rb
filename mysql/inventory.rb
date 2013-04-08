#!/Users/Casey/.rvm/rubies/ruby-2.0.0-rc1/bin/ruby
#
# Name: Casey Scarborough
# Date: April 6, 2013
# Lang: Ruby v2.0.0
#
# Information:
# This application will take in user input and search a MySQL database
# for matching barcodes. The application also gives the user the option
# to update the database using a CSV file, and to export the database to
# a TSV file. For full detailed information please see the usage information
# by running the application with the -h, help, or ? flag.
#
# This application requires the ruby gem 'mysql' to be installed and by
# default uses a local instance of MySQL server.

require 'csv'
require 'rubygems'
require 'mysql'

# Global variables for the database connection
$db_hostname = 'localhost'
$db_user = 'root'
$db_pass = 'root'
$db_name = 'inventory'
$db_table_name = 'inventory'

# This function opens the connection to the database using the global
# variables at the beginning of the file
def open_connection
	begin
		db = Mysql.new $db_hostname, $db_user, $db_pass
	rescue Mysql::Error
		abort "Oops! Couldn't connect to database! Make sure you entered the correct information."
	end
	return db
end


# This function displays the usage information for the application
def display_help
	# define the help variable which holds the help text
	help = "Usage: ruby inventory.rb [?|-h|help|[-u|-o|-z <infile>|[<outfile>]]]\nParameters:
   ?                     displays this usage information
   -h                    displays this usage information
   help                  displays this usage information
   -u <infile>           update the inventory using the file <infile>.
                         The filename <infile> must have a .csv
                         extension and it must be a text file in comma
                         separated value (CSV) format. Note that the
                         values must be in double quote.
   -z|-o [<outfile>]     output either the entire content of the
                         database (-o) or only those records for which
                         the quantity is zero (-z). If no <outfile> is
                         specified then output on the console otherwise
                         output in the text file named <outfile>. The
                         output in both cases must be in a tab separated
                         value (tsv) format.
   -d                    deletes an item specified by the user from the 
                         database"
	# print the help screen
	puts help
end # display_help

# This function displays the contents of the database
def display_contents(everything)
	# Open database connection
	db = open_connection
	if (everything == true)
		if (ARGV[1] == nil) # if no file was specified, output to screen
			begin
				# Set results equal to the result of the MySQL query
				results = db.query "SELECT * FROM #{$db_name}.#{$db_table_name}"
				puts "\nNumber of items: #{results.num_rows}"

				puts "+----------------+---------------------------------+-----------------+----------+---------+-----------------------------+"
				puts "| Barcode".ljust(17) + "| Item Name:".ljust(34) + 
					"| Item Category".ljust(18) + "| Quantity".ljust(11) + 
					"| Price".ljust(10) + "| Description".ljust(29) + " |"
				puts "+----------------+---------------------------------+-----------------+----------+---------+-----------------------------+"
				# Loop through the results and output the data
				results.each_hash do |item|
					print "| #{item['Barcode']}".ljust(17)
					print "| #{item['ItemName']}".ljust(34)
					print "| #{item['ItemCategory']}".ljust(18)
					print "| #{item['Quantity']}".ljust(11)
					print "| #{item['Price']}".ljust(10)
					print "| #{item['Description']}".ljust(29) + " |"
					print "\n"
				end
				puts "+----------------+---------------------------------+-----------------+----------+---------+-----------------------------+"
				print "\n"
				results.free
			rescue
				abort "Could not retrieve information from database. Ensure that table name has been entered properly."
			ensure
				db.close
			end
		else # output to a file
			# set the filename and check if it is a TSV file
			new_filename = ARGV[1].to_s
			if (new_filename.end_with?(".tsv"))
				# query the database
				database_contents = db.query "SELECT * FROM #{$db_name}.#{$db_table_name}"
				# create/open the file for writing and add the database contents to it
				CSV.open(new_filename, "w", {:col_sep => "\t"}) do |csv|
					database_contents.each_hash do |a|
					  csv << [a['Barcode'], a['ItemName'], a['ItemCategory'], a['Quantity'], a['Price'], a['Description']]
					end
				end
				puts "File was successfully created!"
			else # give an error
				abort "Invalid file format – unable to proceed."
			end
		end
	elsif (everything == false)
		if (ARGV[1] == nil) # if no file specified output to screen
			begin
				# Set results equal to the result of the MySQL query
				results = db.query "SELECT * FROM #{$db_name}.#{$db_table_name} WHERE Quantity=0"
				puts "\nNumber of items: #{results.num_rows}"

				puts "+----------------+---------------------------------+-----------------+----------+---------+-----------------------------+"
				puts "| Barcode".ljust(17) + "| Item Name:".ljust(34) + 
					"| Item Category".ljust(18) + "| Quantity".ljust(11) + 
					"| Price".ljust(10) + "| Description".ljust(29) + " |"
				puts "+----------------+---------------------------------+-----------------+----------+---------+-----------------------------+"
				# Loop through the results and output the data
				results.each_hash do |item|
					print "| #{item['Barcode']}".ljust(17)
					print "| #{item['ItemName']}".ljust(34)
					print "| #{item['ItemCategory']}".ljust(18)
					print "| #{item['Quantity']}".ljust(11)
					print "| #{item['Price']}".ljust(10)
					print "| #{item['Description']}".ljust(29) + " |"
					print "\n"
				end
				puts "+----------------+---------------------------------+-----------------+----------+---------+-----------------------------+"
				print "\n"
				results.free
			rescue
				abort "Could not retrieve information from database. Ensure that table name has been entered properly."
			ensure
				db.close
			end
		else # output to a file
			# set the filename and check if it is a TSV file
			new_filename = ARGV[1].to_s
			if (new_filename.end_with?(".tsv"))
				# create/open the file for writing and append it with the
				# contents of the array
				database_contents = db.query "SELECT * FROM #{$db_name}.#{$db_table_name} WHERE Quantity=0"
				CSV.open(new_filename, "w", {:col_sep => "\t"}) do |csv|
					database_contents.each_hash do |a|
					  csv << [a['Barcode'], a['ItemName'], a['ItemCategory'], a['Quantity'], a['Price'], a['Description']]
					end
				end
				puts "File was successfully created!"
			else # give an error
				abort "Invalid file format – unable to proceed."
			end
		end
	end
end

# This function updates the inventory file with the contents from a different
# CSV file that is specified
def update_inventory
	# if the user did not specify an infile
	if (ARGV[1] == nil)
		puts "The -u option requires an <infile> of type .csv."
	else # if they specified a file
		# check that it ends with .csv
		if (!ARGV[1].to_s.end_with?(".csv"))
			abort "Invalid file format – unable to proceed."
		else # if it exists and ends with .csv
			# set the filename and load the database contents
			filename = "./" << ARGV[1]
			database_contents = Array.new{Array.new}

			begin # attempt to open user csv file
				csv_file = File.open(filename, "r")
			rescue # abort if not found
				abort "Input file #{ARGV[1]} not found - aborting."
			end

			# add the contents of the user's csv file to the database array
			CSV.foreach(filename) do |row|
				database_contents << row
			end

			db = open_connection
			begin
				database_contents.each do |a|
					db.query("INSERT INTO #{$db_name}.#{$db_table_name} ( \
					`Barcode`, `ItemName`, `ItemCategory`, `Quantity`, `Price`, `Description` \
					) VALUES ( \
					'#{a[0]}', '#{a[1]}', '#{a[2]}', #{a[3]}, #{a[4]}, '#{a[5]}')")
				end
			rescue
				abort "Unable to update database. Make sure that there are not duplicate Barcode entries."
			ensure
				db.close
			end

			# Update successful
			puts "Updated #{csv_file.count} database records successfully"
		end
	end
end

# This function takes in user input to add an entry to the database
def add_information(bc)
	# get user input
	barcode = bc
	print "Enter Item Name: "
	item_name = gets.strip
	print "Item Category: "
	item_category = gets.strip
	print "Quantity: "
	quantity = gets.strip
	print "Price: "
	price = gets.strip
	print "Description: "
	description = gets.strip

	db = open_connection
	begin # try to add information to the database
		db.query("INSERT INTO #{$db_name}.#{$db_table_name} ( \
		`Barcode`, `ItemName`, `ItemCategory`, `Quantity`, `Price`, `Description` \
		) VALUES ( \
		'#{barcode}', '#{item_name}', '#{item_category}', #{quantity}, #{price}, '#{description}')")
	rescue Exception => e # abort if error and print error
		abort "Could not add information to the database."
		puts "Error code: #{e.errno}"
		puts "Error message: #{e.error}"
	end # if passed, give success message
	puts "Information successfully added!"
end

# This function searches the database for a barcode inputted by the 
# user. If it is found, it displays the information. If not, it asks the
# user if they'd like to enter the information for that barcode number
# into the database.
def search_database(user_input)
	content = "" # set variable to hold content
	# open database connection
	db = open_connection
	begin # query the database
		results = db.query "SELECT * FROM #{$db_name}.#{$db_table_name}"
	rescue # catch any errors
		abort "Could not query database. Ensure that database and table names are correct."
	end # loop through the results
	results.each_hash do |a|
		if (a['Barcode'] == user_input) # if any matching barcodes append content
			if (a['Quantity'] == "0") # if quantity == 0
				user_decision = ""
				loop do # ask the user if they'd like to update quantity
					print "\nBarcode " + user_input + " found in the database but has a zero quantity. Do you want to update quantity? [Y/N]: "
					user_decision = gets.strip.upcase # get user input and break when Y or N
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
					db.query "UPDATE #{$db_name}.#{$db_table_name} SET Quantity = #{quantity} WHERE Barcode = #{user_input}"
				end # output item details
				content += "Details are given below.\n"
				content += "   Item Name: " << a['ItemName'] + "\n"
				content += "   Item Category: " << a['ItemCategory'] + "\n"
				content += "   Quantity: " << quantity.to_s + "\n"
				content += "   Price: " << a['Price'] + "\n"
				content += "   Description: " << a['Description'] + "\n"
				content += "\n"
			else # if the quantity is not zero, output item details
				content += "\nBarcode " + user_input + " found in the database. Details are given below.\n"
				content += "   Item Name: " << a['ItemName'] + "\n"
				content += "   Item Category: " << a['ItemCategory'] + "\n"
				content += "   Quantity: " << a['Quantity'] + "\n"
				content += "   Price: " << a['Price'] + "\n"
				content += "   Description: " << a['Description'] + "\n"
				content += "\n"
			end
		end
	end
	if (content == "") # if no result
		user_decision = "" # create user decision variable
		loop do # ask the user if they'd like to enter information
			print "Barcode " + user_input + " NOT found in the database. Do you want to enter information? [Y/N]: "
			user_decision = gets.strip.upcase
			break if (user_decision == "Y" || user_decision == "N")
		end

		# call the add_information function
		if(user_decision == "Y")
			add_information(user_input)
		# say goodby
		elsif(user_decision == "N")
			puts "Goodbye!"
		end
	else
		puts content
	end
	db.close
end

# This function allows the user to delete an item from the database.
# It is useful for adding an item that has a duplicate barcode, since
# the database will not allow duplicate barcodes by default
def delete_item(barcode)
	# open a connection
	db = open_connection
	begin # try to query the database
		db.query("DELETE FROM #{$db_name}.#{$db_table_name} WHERE Barcode = #{barcode}")
	rescue # catch any errors
		abort "Unable to delete barcode. Are you sure it exists?"
	end
	puts "Item deleted successfully!"
end

#---- MAIN APPLICATION DRIVER ----#

# if argument is ?, -h, or help, display the help screen
if (ARGV[0] == "?" or ARGV[0] == "-h" or ARGV[0] == "help")
	display_help
# if it is -u, call the update_inventory function
elsif (ARGV[0] == "-u")
	update_inventory
# if it is -o, call display_contents with everything as true
elsif (ARGV[0] == "-o")
	display_contents(true)
# if it is -z, call display_contents with everything as false
elsif (ARGV[0] == "-z")
	display_contents(false)
# if no arguments exist, block and wait for user input to search for barcode
elsif (ARGV[0] == "-d")
	print "Enter barcode of the item you'd like to delete from the database: "
	user_input = $stdin.gets.strip.to_i
	delete_item(user_input)
elsif (ARGV[0] == nil)
	print "> "
	user_input = gets.strip # get user input
	search_database(user_input)
end