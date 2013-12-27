#!/usr/bin/env ruby
=begin
  This script will accept arguments for dns and push updates to the API
  Parameters: 
    --subdomain
    --override_ip
=end

require 'fog'
require 'optparse'
require 'ipaddr'

def get_user_input(prompt)
    print "#(prompt): "
    gets.chomp
end

def rackspace_username
    Fog.credentials[:rackspace_username] || get_user_input("Enter Rackspace Username")
end

def rackspace_api_key
    Fog.credentials[:rackspace_api_key] || get_user_input("Enter Rackspace API key")
end

# parse command line options
options = OpenStruct.new
options.fqdn = ""
options.ip = ""
options.dc = :dfw
options.create = false
options.adminemail = nil

optparse = OptionParser.new do |opts|
    opts.banner = "Usage: rax-dyndns.rb [options] fqdn ipaddress"
    opts.on('--datacenter DC', [:dfw, :ord], 'Create server in datacenter (dfw, ord)') {|dc| options.dc = dc}
    opts.on('--create EMAIL', 'Create domain if it doesn\'t exist with admin email EMAIL') {|e| options.create = true; options.adminemail = e}
    opts.on('-h','--help','Show help') {puts opts; exit}
end
optparse.parse!

# check required parameters
if ARGV.length != 2
    p optparse
    exit
end
options.fqdn = ARGV.shift
options.ip = ARGV.shift

# check ip address validity
begin
    addr = IPAddr.new(options.ip)
rescue ArgumentError
    puts "#{options.ip} is not a valid IP address"
    exit
end

# validate fqdn
fqdnsplit = options.fqdn.split('.')
if fqdnsplit.length < 3
    puts "#{options.fqdn} is not a valid fully qualified domain name"
    exit
end
domain = fqdnsplit.last(2).join('.')

#create the DNS service
service = Fog::DNS.new({
    :provider           => 'rackspace',
    :rackspace_username => rackspace_username,
    :rackspace_api_key  => rackspace_api_key,
})

#check if domain exists already
zone = service.zones.find {|z| z.domain == domain}

#if zone doesn't exist, and we don't want to create
if zone == nil and not options.create
    puts "Zone #{domain} does not exist. Specify --create to create"
    exit
end

#if we're here and zone doesn't exist, create it
if zone == nil
    puts "Zone #{domain} does not exist, creating..."
    zone = service.zones.create(
        :domain => domain, :email => options.adminemail)
end

#check if record already exists
rec = zone.records.select{|record| record.name == options.fqdn}
if rec == nil
    puts "Record not found, creating"
    zone.record.create(
        :name => options.fqdn, :type => "A", :value => options.ip)
else
    puts "Record found, modifying existing record"
    print rec.id
end
# #find record name
# rec = options.fqdn
# puts "Record found: #{rec}"

# #check if record exists already in zone
# zone.records.each do |record|
#     if options.fqdn == record.name.to_s
#         puts "Record already exists: #{r}"
#         found = true
#     end
# end

