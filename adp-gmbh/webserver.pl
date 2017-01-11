#!/usr/bin/perl
use warnings;
use strict;


use strict;
use warnings;

use Socket;
use IO::Select;

use threads;
use threads::shared;


$|  = 1;

# The following variables should be set within init_webserver_extension
use vars qw/
 $port_listen
/;


require "http_handler.pl";
init_webserver_extension();

local *S;

socket     (S, PF_INET   , SOCK_STREAM , getprotobyname('tcp')) or die "couldn't open socket: $!";
setsockopt (S, SOL_SOCKET, SO_REUSEADDR, 1);
bind       (S, sockaddr_in($port_listen, INADDR_ANY));
listen     (S, 5)                                               or die "don't hear anything:  $!";

my $ss = IO::Select->new();
$ss -> add (*S);


while(1) {
  my @connections_pending = $ss->can_read();
  foreach (@connections_pending) {
    my $fh;
    my $remote = accept($fh, $_);

    my($port,$iaddr) = sockaddr_in($remote);
    my $peeraddress = inet_ntoa($iaddr);

    my $t = threads->create(\&new_connection, $fh);
    $t->detach();
  }
}

sub extract_vars {
  my $line = shift;
  my %vars;

  foreach my $part (split '&', $line) {
    $part =~ /^(.*)=(.*)$/;

    my $n = $1;
    my $v = $2;
  
    $n =~ s/%(..)/chr(hex($1))/eg;
    $v =~ s/%(..)/chr(hex($1))/eg;
    $vars{$n}=$v;
  }

  return \%vars;
}

sub new_connection {
  my $fh = shift;

  binmode $fh;

  my %req;

  $req{HEADER}={}; 

  my $request_line = <$fh>;
  my $first_line = "";

  while ($request_line ne "\r\n") {
     unless ($request_line) {
       close $fh; 
     }

     chomp $request_line;

     unless ($first_line) {
       $first_line = $request_line;

      my @parts = split(" ", $first_line);
       if (@parts != 3) {
         close $fh;
       }

       $req{METHOD} = $parts[0];
       $req{OBJECT} = $parts[1];
     }
     else {
       my ($name, $value) = split(": ", $request_line);
       $name       = lc $name;
       $req{HEADER}{$name} = $value;
     }

     $request_line = <$fh>;
  }

  http_request_handler($fh, \%req);

  close $fh;
}
