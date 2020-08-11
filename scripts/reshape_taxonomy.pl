$c = 0;
while (<STDIN>) {
  $c++;
  if ($c == 1) {
	print $_
  } else {
    chomp;
    @f = split /,/, $_;
    for (my $i = 0; $i <= 7; $i++) {
	print $f[$i];
        print "," if ($i < 7);
    }
    print "\n";
  }
}
