# -*- mode: perl -*-

use Test::More tests => 5;

## uncompress a compressed simple text file - the lyrics to end of the world REM
## compare against bunzip2 command with od -x and diff

BEGIN {
  use_ok('Compress::Bzip2');
};

my $out;
open( $out, "> t/033-tmp-sample.txt" );

my $d = Compress::Bzip2->new( -verbosity => 0 );
$d->bzopen( "t/033-sample.bz2", "r" );

ok( $d, "open was successful" );

my $counter = 0;
my $bytes = 0;

my $read;
while ( $read = $d->bzread( $buf, 512 ) ) {
  if ( $read < 0 ) {
    print STDERR "error: $bytes $Compress::Bzip2::bzerrno\n";
    last;
  }

  $bytes += syswrite( $out, $buf, $read );
  $counter++;
}

ok( $counter, "$counter data was written, $bytes bytes" );

my $res = $d->bzclose;
ok( !$res, "file was closed $res $Compress::Bzip2::bzerrno" );

close($out);

system( 'bunzip2 < t/033-sample.bz2 > t/033-tmp-reference.txt' );
system( 'diff -c t/033-tmp-sample.txt t/033-tmp-reference.txt > t/033-tmp-diff.txt' );

ok( ! -s 't/033-tmp-diff.txt', "no differences with bunzip2" );
