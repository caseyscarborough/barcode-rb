#!/Users/Casey/.rvm/rubies/ruby-2.0.0-rc1/bin/ruby
require 'csv'

$database_filename = "./inventory.accdb" 
def display_help
	# define the help variable which holds the help text
	help = 
"Usage: ruby inventory.rb [?|-h|help|[-u|-o|-z <infile>|[<outfile>]]]\n
Parameters:
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
end

def load_database_file
	begin
		database_file = File.open($database_filename)
		database_contents = Array.new{Array.new}
		i = 0
		database_file.each do |line|
			database_contents[i] = line.split(",").map(&:strip)
			i += 1
		end
		return database_contents
	rescue
		"Unable to continue - database file #{$database_filename} not found."
	end
end

def read_file(everything)
	database_contents = load_database_file
	if (everything == true)
		if (ARGV[1] == nil)
			database_contents.each do |a|
				puts "==========================================="
				puts "Barcode:       " << a[0]
				puts "Item Name:     " << a[1]
				puts "Item Category: " << a[2]
				puts "Quantity:      " << a[3]
				puts "Price:         " << a[4]
				puts "Description:   " << a[5]
				print "\n"
			end
		else
			new_filename = ARGV[1].to_s
			if (new_filename.end_with?(".tsv"))
				CSV.open(new_filename, "w", {:col_sep => "\t"}) do |csv|
					database_contents.each do |a|
					  csv << [a[0], a[1], a[2], a[3], a[4], a[5]]
					end
				end
				puts "File was successfully created!"
			else
				puts "File format must be .tsv!"
			end
		end
	else
		content = ""
		database_contents.each do |a|
			if (a[3] == '0')
				content += "===========================================\n"
				content += "Barcode:       " << a[0] + "\n"
				content += "Item Name:     " << a[1] + "\n"
				content += "Item Category: " << a[2] + "\n"
				content += "Quantity:      " << a[3] + "\n"
				content += "Price:         " << a[4] + "\n"
				content += "Description:   " << a[5] + "\n"
				content += "\n"
			end
		end
		if (content == "")
			puts "No database records found with zero quantity."
		else
			puts content
		end
	end
end

def update_inventory
	if (ARGV[1] == nil)
		puts "\n-u requires an <infile>"
		puts "Usage: ruby inventory.rb [?|-h|help|[-u|-o|-z <infile>|[<outfile>]]]"
	else
		if (!ARGV[1].to_s.end_with?(".csv") || ARGV[1] == nil)
			puts "\nInvalid file format – unable to proceed."
			puts "Usage: ruby inventory.rb [?|-h|help|[-u|-o|-z <infile>|[<outfile>]]]\n"
		else
			filename = "./" << ARGV[1]

			database_contents = load_database_file

			# Attempt to open user csv file. If not found, abort program.
			begin
				csv_file = File.open(filename, "r")
			# Instead of asking for new file name, abort if file not found.
			rescue
				abort "Input file #{ARGV[1]} not found - aborting."
			end

			CSV.foreach(filename) do |row|
				database_contents << row
			end

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

def search_database(user_input)
	database_contents = load_database_file
	content = ""
	database_contents.each do |a|
		if (a[0] == user_input)
			content += "Barcode " + user_input + " found in the database. Details are given below.\n"
			content += "   Item Name: " << a[1] + "\n"
			content += "   Item Category: " << a[2] + "\n"
			content += "   Quantity: " << a[3] + "\n"
			content += "   Price: " << a[4] + "\n"
			content += "   Description: " << a[5] + "\n"
			content += "\n"
		end
	end
	if (content == "")
		puts "Barcode " + user_input + " NOT found in the database. Do you want to enter information? [Y/N]: "
	else
		puts content
	end
end

if (ARGV[0] == "?" or ARGV[0] == "-h" or ARGV[0] == "help")
	display_help
elsif (ARGV[0] == "-u")
	update_inventory
elsif (ARGV[0] == "-o")
	read_file(true)
elsif (ARGV[0] == "-z")
	read_file(false)
elsif (ARGV[0] == nil)
	print "> "
	user_input = gets.strip
	search_database(user_input)
end