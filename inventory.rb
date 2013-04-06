#!/Users/Casey/.rvm/rubies/ruby-2.0.0-rc1/bin/ruby
require 'csv'

#Get the command-line arguments
ARGV.each do|a|
	puts "Argument: #{a}"
end

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

def load_file(everything)
	filename = "./inventory.db"
	database_file = File.open(filename)
	database_contents = Array.new{Array.new}
	i = 0
	database_file.each do |line|
		database_contents[i] = line.split(",").map(&:strip)
		i += 1
	end
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
			if (File.file?(new_filename))
				File.delete(new_filename)
			end
			database_contents.each do |a|
				require 'csv'
					CSV.open(new_filename, "ab") do |csv|
					  csv << [a[0], a[1], a[2], a[3], a[4], a[5]]
				end
			end
		end
	else
		if (a[3] == '0')
			puts "==========================================="
			puts "Barcode:       " << a[0]
			puts "Item Name:     " << a[1]
			puts "Item Category: " << a[2]
			puts "Quantity:      " << a[3]
			puts "Price:         " << a[4]
			puts "Description:   " << a[5]
			print "\n"
		end
	end
end

if (ARGV[0] == "?" or ARGV[0] == "-h" or ARGV[0] == "help")
	display_help
elsif (ARGV[0] == "-u")
	if (ARGV[1] == nil)
		puts "You must include a file."
	else
		if (!ARGV[1].to_s.end_with?(".csv"))
			puts "The filename is not of type CSV."
		else
			# update_inventory(ARGV[1])
			puts "The filename ends with CSV."
		end
	end
elsif (ARGV[0] == "-o")
	load_file(true)
elsif (ARGV[0] == "-z")
	load_file(false)
end