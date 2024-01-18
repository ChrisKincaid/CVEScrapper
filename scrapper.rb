require 'bundler/setup'
require 'net/http'
require 'uri'
require 'csv'
require 'nokogiri'
require 'mail'

url = 'https://www.cvedetails.com/vulnerability-list/'
response = Net::HTTP.get_response(URI.parse(url))

csv_file_path = 'report.csv'

# Read existing items from CSV file
existing_items = CSV.read(csv_file_path).map { |row| row[0..2] } rescue []

if response.code == '200'
  puts 'Success!'
  doc = Nokogiri::HTML(response.body)
  
  items = doc.css('div[data-tsvfield="cveinfo"]').map do |div|
    title = div.at_css('h3').text.strip
    description = div.at_css('.cvesummarylong').text.strip
    score = div.at_css('.cvssbox').text.strip
    [title, score, description]
  end
  
  # Only keep items that don't already exist in the CSV file
  new_items = items - existing_items
  
  # Append new items to CSV file
  CSV.open(csv_file_path, 'a') do |csv|
    new_items.each { |item| csv << item }
  end

  # Create a new report for the new items
  if new_items.any?
    File.open('report.txt', 'w') do |file|
      file.puts "New CVEs as of #{Time.now}\n\n"
      new_items.each do |item|
        file.puts "#{item[0]}\nSCORE: #{item[1]}\n\nDescription:\n#{item[2]}\n\n"
      end
    end
  else
    puts "No new items found."
  end
else
  puts 'Error!'
end