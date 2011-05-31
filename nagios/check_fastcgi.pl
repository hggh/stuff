#!/usr/bin/perl -w

# check_fastcgi.pl checks if a php-cgi server (or, theorically, any 
# other fastcgi server) is alive.
#
# Copyright (c) 2009 Rodolfo Gonzalez <rodolfo_gonzalez@hotmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# include modules

use strict;
use FCGI::Client;
use IO::Socket::INET;
use Getopt::Long;

# command line parameters with some defaults

my $host = '';         # server host
my $port = 9999;       # tcp port
my $script = '';       # test script (absolute path starting at / - root directory -)
my $query_string = ''; # query string
my $expected = 'OK';   # expected string
my $timeout = 5;       # timeout in seconds

# check command line options

GetOptions ('H=s' => \$host, 'p=i' => \$port, 's=s' => \$script, 'q=s' => \$query_string, 'e=s' => \$expected, 't=i' => \$timeout);

if (($host eq '') || ($script eq '')) {
   print "Usage: check_php-cgi.pl -H host -s <test script> [-p port] [-q <query string>] [-e <expected string>] [-t <timeout seconds>]\n";
   exit(-1);
}

# run check

my $sock = IO::Socket::INET->new(
    PeerAddr => $host,
    PeerPort => $port,
    Timeout  => $timeout,
    Proto    => 'tcp',
) or &_bad();

my $client = FCGI::Client::Connection->new( sock => $sock ) or &_bad();

my ( $stdout, $stderr ) = $client->request(
    +{
        REQUEST_METHOD  => 'GET',
        PHP_SELF        => $script,
        SCRIPT_FILENAME => $script,
        QUERY_STRING    => $query_string,
    },
    ''
) or &_bad();

if ($stdout =~ /$expected/) {
   &_good();
}
else {
   &_bad();
}

sub _good()
{
   print "OK: fastcgi server is working.";
   exit(0);
}

sub _bad()
{
   print "FastCGI CRITICAL: fastcgi has not responded.";
   exit(2);
}
