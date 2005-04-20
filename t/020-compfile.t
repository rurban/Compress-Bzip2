# -*- mode: perl -*-

use Test::More tests => 5;

## compress a simple text file - the lyrics to end of the world REM
## compare against bzip2 command with od -x and diff

BEGIN {
  use_ok('Compress::Bzip2');
};

my $in;
open( $in, "< t/020-sample.txt" );

my $d = bzopen( "t/020-tmp-sample.bz2", "w" );

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

system( 'bzip2 < t/020-sample.txt | od -x > t/020-tmp-reference-bz2.odx' );
system( 'od -x < t/020-tmp-sample.bz2 | diff -c - t/020-tmp-reference-bz2.odx > t/020-tmp-diff.txt' );

ok( ! -s 't/020-tmp-diff.txt', "no differences with bzip2" );
