#!/usr/bin/env ruby

require 'rubygems'
require 'graphviz'
require 'getoptlong'
config = '/etc/puppet/puppet.conf'

def printusage(error_code)
    puts "Usage: #{$0}"
    puts "\n Options:"
    puts "--config <puppet config file>"
    exit(error_code)
end

opts = GetoptLong.new(
        [ "--config",     "-c",   GetoptLong::REQUIRED_ARGUMENT ],
        [ "--help",        "-h",   GetoptLong::NO_ARGUMENT ],
        [ "--usage",       "-u",   GetoptLong::NO_ARGUMENT ],
        [ "--version",     "-v",   GetoptLong::NO_ARGUMENT ]
)

begin
    opts.each do |opt, arg|
        case opt
        when "--config"
            config = arg

        when "--help"
            printusage(0)

        when "--usage"
            printusage(0)

        when "--version"
            puts "%s" % Puppet.version
            exit
        end
    end
rescue GetoptLong::InvalidOption => detail
    $stderr.puts "Try '#{$0} --help'"
    exit(1)
end

require 'puppet/rails'
Puppet[:config] = config
Puppet.parse_config
pm_conf = Puppet.settings.instance_variable_get(:@values)[:puppetmasterd]

adapter = pm_conf[:dbadapter]
args = {:adapter => adapter, :log_level => pm_conf[:rails_loglevel]}

case adapter
    when "sqlite3"
        args[:dbfile] = pm_conf[:dblocation]
    when "mysql", "postgresql"
        args[:host]     = pm_conf[:dbserver] unless pm_conf[:dbserver].to_s.empty?
        args[:username] = pm_conf[:dbuser] unless pm_conf[:dbuser].to_s.empty?
        args[:password] = pm_conf[:dbpassword] unless pm_conf[:dbpassword].to_s.empty?
        args[:database] = pm_conf[:dbname] unless pm_conf[:dbname].to_s.empty?
        socket          = pm_conf[:dbsocket]
        args[:socket]   = socket unless socket.to_s.empty?
        connections     = pm_conf[:dbconnections].to_i
        args[:pool]     = connections if connections > 0
    else
        raise ArgumentError, "Invalid db adapter %s" % adapter
end

args[:database] = "puppet" unless not args[:database].to_s.empty?

ActiveRecord::Base.establish_connection(args)

xendomains = Puppet::Rails::FactName.find_by_name('xendomains')

g = GraphViz::new( "G", :rankdir => 'LR')

xendomains.fact_values.each do |d|
	host = g.add_node(d.host.name, { :shape => 'box', :style => 'filled', :fillcolor => 'red' })
	d.value.split(",").each do |node|
		g.add_node(node + d.host.name).label = node
		g.add_edge(host, node + d.host.name)
	end
end

g.output( :png => "#{$0}.png" )
