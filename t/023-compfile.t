# -*- mode: perl -*-

use Test::More tests => 5;

## compress sample3 from the bzip2 1.0.2 distribution
## compare against bzip2 command with od -x and diff

BEGIN {
  use_ok('Compress::Bzip2');
};

my $in;
open( $in, "< t/023-sample.txt" );

my $d = bzopen( "t/023-tmp-sample.bz2", "w" );

ok( $d, "open was successful" );

my $counter = 0;
my $bytes = 0;
while ( my $ln = read( $in, $buf, 512 ) ) {
  my $out = $d->bzwrite( $buf, $ln );
  if ( $out < 0 ) {
    print STDERR "error: $out $Compress::Bzip2::bzerrno\n";
    last;
  }
  $bytes += $ln;
  $counter++;
}
ok( $counter, "$counter data was written, $bytes bytes" );

my $res = $d->bzclose;
ok( !$res, "file was closed $res $Compress::Bzip2::bzerrno" );

close($in);

system( 'bzip2 < t/023-sample.txt | od -x > t/023-tmp-reference-bz2.odx' );
system( 'od -x < t/023-tmp-sample.bz2 | diff -c - t/023-tmp-reference-bz2.odx > t/023-tmp-diff.txt' );

ok( ! -s 't/023-tmp-diff.txt', "no differences with bzip2" );
