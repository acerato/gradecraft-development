# This file should contain all the record creation needed to seed the database
# with its default values. The data can then be loaded with the rake db:seed
# (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: "Chicago" }, { name: "Copenhagen" }])
#   Mayor.create(name: "Emanuel", city: cities.first)

# Generate admin
User.create! do |u|
  u.username = "cholma"
  u.first_name = "Caitlin"
  u.last_name = "Holman"
  u.email = "cholma@umich.edu"
  u.password = "fawkes"
end
puts "And we have an admin"

# Generate Barry
User.create! do |u|
  u.username = "fishman"
  u.first_name = "Barry"
  u.last_name = "Fishman"
  u.email = "fishman@umich.edu"
end
puts "Barry is here..."
