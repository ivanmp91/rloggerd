#!/usr/bin/perl
# This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information visit opentodo.net or any suggestion or report please contact to ivan@opentodo.net

use Sys::Syslog qw(:DEFAULT setlogsock);
use Getopt::Long;

my $tag="rloggerd"; #Defines the name of the server
my $sock="udp"; #selects the default type of socket udp 
my $server; #setup the default syslog server
my $facility; #setup the facility to send to the syslog server
my $priority; #setup the level priority to send to the syslog server
my $file; #sets the log file that will send to the syslog server
my %facilities = ( #Stores the facilities to parse for the Syslog module
	audit=>LOG_AUDIT,
	auth=>LOG_AUTH,
	authpriv=>LOG_AUTHPRIV,
	console=>LOG_CONSOLE,
	cron=>LOG_CRON,
	daemon=>LOG_DAEMON,
	ftp=>LOG_FTP,
	kern=>LOG_KERN,
	install=>LOG_INSTALL,
	launchd=>LOG_LAUNCHD,
	lfmt=>LOG_LFMT,
	local0=>LOG_LOCAL0,
	local1=>LOG_LOCAL1,
	local2=>LOG_LOCAL2,
	local3=>LOG_LOCAL3,
	local4=>LOG_LOCAL4,
	local5=>LOG_LOCAL5,
	local6=>LOG_LOCAL6,
	local7=>LOG_LOCAL7,
	lpr=>LOG_LPR,
	mail=>LOG_MAIL,
	netinfo=>LOG_NETINFO,
	news=>LOG_NEWS,
	ntp=>LOG_NTP,
	ras=>LOG_RAS,
	remoteauth=>LOG_REMOTEAUTH,
	security=>LOG_SECURITY,
	syslog=>LOG_SYSLOG,
	user=>LOG_USER,
	uucp=>LOG_UUCP,
);

my %priorities = ( #Stores the priorities to parse for the Syslog module
	debug=>LOG_DEBUG,
	info=>LOG_INFO,
	notice=>LOG_NOTICE,
	warning=>LOG_WARNING,
	crit=>LOG_CRIT,
	alert=>LOG_ALERT,
	emerg=>LOG_EMERG,
);

my $params={}; #Stores the parameters

GetOptions($params,
	"server=s" =>\$server,
	"socket:s" =>\$sock,
	"facility=s" =>\$facility,
	"priority=s" =>\$priority,
	"file=s" =>\$file,
	"tag:s"=>\$tag,
	"help",
	"daemon",) 
	or die usage();

checkArguments();

#open the log file entered and call read all the lines
sub openFile{
  
  open(DATA,$file) || die "The file can't be open";

  while(<DATA>){
    sendLogging($_);
  }
  close(DATA);
}
#Check arguments are correctly entered
sub checkArguments{ 
  if(defined($params->{help})){
    usage();
  }
  else{
      if(exists($facilities{$facility}) && exists($priorities{$priority})){
	if(defined($params->{daemon})){
	  monitorFile();
	}
	else{
	  openFile();
	}
      }
      else{
	  usage("The option entered is not valid");
      }
  }
    
}

#Send the new lines continuously to the syslog server
sub monitorFile{
  open(DATA,"tail -0f $file |") || die "The file can't be open";

  while(<DATA>){
    sendLogging($_);
  }

  close(DATA);

}
#Send log line to the server
sub sendLogging{
  openlog($tag,"ndelay",$facilities{$facility});
  setlogsock($sock,$server) or die "Connection to syslog server failed";
  syslog($priorities{$priority},shift) or die "Connection to syslog server failed";
  closelog();
}
#Menu help to use rloggerd
sub usage{
   print shift()."\n";
   print <<EOF;  
Usage: loggerd.pl [OPTIONS] 
Read a log file and send each line to a remote syslog server
with a facility and priority.
Mandatory arguments:
	--server    : ip address of remote server
	--facility  : facility type message to send to the server. Available options:
		      audit
		      auth
		      authpriv
		      console
		      cron
		      daemon
		      ftp
		      kern
		      install
		      launchd
		      lfmt
		      local0-7
		      lpr
		      mail
		      netinfo
		      news
		      ntp
		      ras
		      remoteauth
		      security
		      syslog
		      user
		      uucp
	--priority  : priority level to send to the server. Available options:
		      debug
		      info
		      notice
		      warning
		      crit
		      alert
		      emerg
	--file      : the log file to read
Optional arguments:
	--socket    : the type of socket used. Default use udp, available options:
		      tcp
		      udp
		      unix
	--tag	    : message to prepend for each message log
	--daemon    : this option reads the log file and sends the new entries continuously to the server
	--help      : print this menu help
Thanks for using rloggerd. The author is Ivan Mora Perez to report any error or suggestion the e-mail contact is: ivan\@opentodo.net
EOF
  exit 0;
}

