#!/Users/Casey/.rvm/rubies/ruby-2.0.0-rc1/bin/ruby
#
# Name: Casey Scarborough
# Date: April 6, 2013
# Lang: Ruby v2.0.0
#
# Information:
# This application will take in user input and search a database file
# for matching barcodes. The application also gives the user the option
# to update the database using a CSV file, and to export the database to
# a TSV file. For full detailed information please see the usage information
# by running the application with the -h, help, or ? flag.

require 'csv'

# set the global variable for the database filename
$database_filename = "./inventory.accdb"

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
                         value (tsv) format."
	# print the help screen
	puts help
end # display_help

# This function loads the database file and adds the information into an array
def load_database_file
	begin # try to load the file
		# open the file and create an array to hold it
		database_file = File.open($database_filename)
		database_contents = Array.new{Array.new}
		i = 0
		# add the contents of the file to the two-dimensional array
		database_file.each do |line|
			database_contents[i] = line.split(",").map(&:strip)
			i += 1
		end
		return database_contents
	rescue # catch exceptions
		abort "Unable to continue - database file #{$database_filename} not found."
	end
end #load_database_file

# This function reads the file and either outputs it to the screen or into
# a file. It takes in the parameter everything, which tells the function
# whether to display everything or just the zero quantity items
def read_file(everything)
	database_contents = load_database_file
	# if the -o argument was specified
	if (everything == true)
		if (ARGV[1] == nil) # if no file was specified, output to screen
			content = ""
			database_contents.each do |a|
				content += "| #{a[0]}".ljust(17)
				content += "| #{a[1]}".ljust(34)
				content += "| #{a[2]}".ljust(18)
				content += "| #{a[3]}".ljust(11)
				content += "| #{a[4]}".ljust(10)
				content += "| #{a[5]}".ljust(29)
				content += " |".ljust(17) + "\n"
			end
			puts "\n+----------------+---------------------------------+-----------------+----------+---------+-----------------------------+"
			puts "| Barcode".ljust(17) + "| Item Name:".ljust(34) + 
				"| Item Category".ljust(18) + "| Quantity".ljust(11) + 
				"| Price".ljust(10) + "| Description".ljust(29) + " |"
			puts "+----------------+---------------------------------+-----------------+----------+---------+-----------------------------+"
			print content
			puts "+----------------+---------------------------------+-----------------+----------+---------+-----------------------------+"
			print "\n"
		else # output to a file
			# set the filename and check if it is a TSV file
			new_filename = ARGV[1].to_s
			if (new_filename.end_with?(".tsv"))
				# create/open the file for writing and append it with the
				# contents of the array
				CSV.open(new_filename, "w", {:col_sep => "\t"}) do |csv|
					database_contents.each do |a|
					  csv << [a[0], a[1], a[2], a[3], a[4], a[5]]
					end
				end
				puts "File was successfully created!"
			else # give an error
				abort "Invalid file format – unable to proceed."
			end
		end
	else # if the -z argument was specified
		if (ARGV[1] == nil) # if no file was specified
			content = "" # set variable to hold content
			database_contents.each do |a|
				if (a[3] == '0') # if the item has a zero quantity add it to content
					content += "| #{a[0]}".ljust(17)
					content += "| #{a[1]}".ljust(34)
					content += "| #{a[2]}".ljust(18)
					content += "| #{a[3]}".ljust(11)
					content += "| #{a[4]}".ljust(10)
					content += "| #{a[5]}".ljust(29)
					content += " |".ljust(17) + "\n"
				end
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
		else # output to a file
			# set the filename and check if it is a TSV file
			new_filename = ARGV[1].to_s
			if (new_filename.end_with?(".tsv"))
				# create/open the file for writing and append it with the
				# contents of the array
				CSV.open(new_filename, "w", {:col_sep => "\t"}) do |csv|
					database_contents.each do |a|
						if (a[3] == '0')
					  		csv << [a[0], a[1], a[2], a[3], a[4], a[5]]
					  	end
					end
				end
				puts "File was successfully created!"
			else # give an error
				abort "Invalid file format – unable to proceed."
			end
		end
	end
end # read_file

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
			database_contents = load_database_file

			begin # attempt to open user csv file
				csv_file = File.open(filename, "r")
			rescue # abort if not found
				abort "Input file #{ARGV[1]} not found - aborting."
			end

			# add the contents of the user's csv file to the database array
			CSV.foreach(filename) do |row|
				database_contents << row
			end

			# write the database array to the database file
			CSV.open($database_filename, "w") do |csv|
				database_contents.each do |a|
					csv << [a[0], a[1], a[2], a[3], a[4], a[5]]
				end
			end

			# Update successful
			puts "Updated #{csv_file.count} database records successfully"
		end
	end
end

# This function takes in user input to add an entry to the database file
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

	begin # try to add information to the file
		CSV.open($database_filename, "ab") do |csv|
			csv << [barcode,item_name,item_category,quantity,price,description]
		end
	rescue # abort if error
		abort "Could not add information."
	end # if passed, give success message
	puts "Information successfully added!"
end

def write_to_file(database_contents)
	begin
		CSV.open($database_filename, "w") do |csv|
			database_contents.each do |a|
				csv << [a[0], a[1], a[2], a[3], a[4], a[5]]
			end
		end
	rescue
		puts "There was a problem updating the database."
	end
	print "\nQuantity successfully updated!\n"
end

# This function searches the database file for a barcode inputted by the 
# user. If it is found, it displays the information. If not, it asks the
# user if they'd like to enter the information for that barcode number.
def search_database(user_input, database_contents)
	content = "" # set variable to hold content
	database_contents.each do |a|
		if (a[0] == user_input) # if any matching barcodes append content
			if (a[3] == "0")
				user_decision = ""
				loop do
					print "\nBarcode " + user_input + " found in the database but has a zero quantity. Do you want to update quantity? [Y/N]: "
					user_decision = gets.strip.upcase
					break if (user_decision == "Y" || user_decision == "N")
				end
				if (user_decision == "Y")
					quantity = 0
					loop do
						print "Enter the new quantity: [> 0]: "
						# convert the input to an integer, will convert to 0 if not an int
						quantity = gets.strip.to_i
						break if (quantity > 0)
					end
					a[3] = quantity.to_s
					write_to_file(database_contents)
				end
				content += "Details are given below.\n"
				content += "   Item Name: " << a[1] + "\n"
				content += "   Item Category: " << a[2] + "\n"
				content += "   Quantity: " << a[3] + "\n"
				content += "   Price: " << a[4] + "\n"
				content += "   Description: " << a[5] + "\n"
				content += "\n"
			else
				content += "\nBarcode " + user_input + " found in the database. Details are given below.\n"
				content += "   Item Name: " << a[1] + "\n"
				content += "   Item Category: " << a[2] + "\n"
				content += "   Quantity: " << a[3] + "\n"
				content += "   Price: " << a[4] + "\n"
				content += "   Description: " << a[5] + "\n"
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
end

#---- MAIN APPLICATION DRIVER ----#

# if argument is ?, -h, or help, display the help screen
if (ARGV[0] == "?" or ARGV[0] == "-h" or ARGV[0] == "help")
	display_help
# if it is -u, call the update_inventory function
elsif (ARGV[0] == "-u")
	update_inventory
# if it is -o, call read_file with everything as true
elsif (ARGV[0] == "-o")
	read_file(true)
# if it is -z, call read_file with everything as false
elsif (ARGV[0] == "-z")
	read_file(false)
# if no arguments exist, block and wait for user input to search for barcode
elsif (ARGV[0] == nil)
	print "> "
	user_input = gets.strip # get user input
	database_contents = load_database_file
	search_database(user_input, database_contents)
end