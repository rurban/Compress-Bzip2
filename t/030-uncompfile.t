# -*- mode: perl -*-

use Test::More tests => 5;

## uncompress a compressed simple text file - the lyrics to end of the world REM
## compare against bunzip2 command with od -x and diff

BEGIN {
  use_ok('Compress::Bzip2');
};

my $INFILE = 't/030-sample.bz2';
my $PREFIX = 't/030-tmp';

my $out;
open( $out, "> $PREFIX-sample.txt" );

my $d = Compress::Bzip2->new( -verbosity => 0 );
$d->bzopen( $INFILE, "r" );

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

system( "bunzip2 < $INFILE > $PREFIX-reference.txt" );
system( "diff -c $PREFIX-sample.txt $PREFIX-reference.txt > $PREFIX-diff.txt" );

ok( ! -s "$PREFIX-diff.txt", "no differences with bunzip2" );
