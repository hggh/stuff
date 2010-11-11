module Puppet::Parser::Functions
	newfunction(:get_parent_host, :type => :rvalue) do |args|
		domain   = lookupvar('domain')
		hostname = lookupvar('hostname')

		parent_node = ""

		xendomains = Puppet::Rails::FactName.find_by_name('xendomains')

		xendomains.fact_values.each do |d|
			host = d.host.name
			if host.match(/#{domain}$/)
				d.value.split(",").each { |node| parent_node = host if (node == hostname or node == hostname.gsub("-","")) }
			end
		end
		parent_node
	end
end
