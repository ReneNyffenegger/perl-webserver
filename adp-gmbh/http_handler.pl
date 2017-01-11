sub http_request_handler {
  my $fh     =   shift;
  my $req_   =   shift;

  my %req    =   %$req_;

  my %header = %{$req{HEADER}};

  print $fh "HTTP/1.0 200 OK\r\n";
  print $fh "Server: adp perl webserver\r\n";

  #print $fh "content-length: ... \r\n";

  print $fh "\r\n";

  print $fh "<html><h1>hello</h1></html>";

  print $fh "Method: $req{METHOD}<br>";
  print $fh "Object: $req{OBJECT}<br>";

  foreach my $r (keys %header) {
    print $fh $r, " = ", $header{$r} , "<br>";
  }
}

sub init_webserver_extension {
  $port_listen = 8888;
}

1;
