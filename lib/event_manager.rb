require "csv"
require "google/apis/civicinfo_v2"
require "erb"


def clean_zipcode(zipcode)
	zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone(phone)
	phone = phone.to_s.split(/\D/).join("")
	if phone.length < 10 || phone.length > 11
		phone = "BAD NUMBER"
	elsif phone.length == 11
		phone[0] == 1 ? (phone[1..10]) : "BAD NUMBER"
	else
		phone
	end
	phone != "BAD NUMBER" ? "#{phone[0..2]}-#{phone[3..5]}-#{phone[6..9]}" : "BAD NUMBER"
end

def legislators_by_zipcode(zip)
	civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
	civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

	begin
		civic_info.representative_info_by_address(
															address: zip,
															levels: 'country',
															roles: ['legislatorUpperBody', 'legislatorLowerBody']
														).officials
	rescue 
		"You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"		
	end
end

def save_thank_you_letters(id, form_letter)
	Dir.mkdir("output") unless Dir.exists? "output"

	filename = "output/thanks_#{id}.html"

	File.open(filename,'w') do |file|
		file.puts form_letter
	end
end

def extract_hour(time)
	time = time.split(" ")
	time = DateTime.strptime("#{time[1]}", "%H:%M")
	time.hour
end

def find_peak_hours(hours)
	hours.each_with_object(Hash.new(0)) { |v, h| h[v] += 1 }.max_by(&:last)
end

puts "EventManager Initialized!"

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol
template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter
hours = []

contents.each do |row|
	id = row[0]
	name = row[:first_name]
	
	phone = clean_phone(row[:homephone])

	zipcode = clean_zipcode(row[:zipcode])

	hours << extract_hour(row[:regdate])

	legislators = legislators_by_zipcode(zipcode)

	form_letter = erb_template.result(binding)

	save_thank_you_letters(id, form_letter)	
end

p hours.sort
puts find_peak_hours(hours)
