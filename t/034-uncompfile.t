# -*- mode: perl -*-

use Test::More tests => 5;

## test uncompressing a large file
## - make up a large file by essentially repeating one of the other sample files

BEGIN {
  use_ok('Compress::Bzip2');
};

my $debugf = 0;

system( 'cat t/034-sample.bz2 t/034-sample.bz2 t/034-sample.bz2 t/034-sample.bz2 t/034-sample.bz2 > t/034-tmp-sample-by5.bz2' );
system( 'cat t/034-sample.bz2 t/034-sample.bz2 t/034-sample.bz2 t/034-sample.bz2 t/034-sample.bz2 >> t/034-tmp-sample-by5.bz2' );

my $out;
open( $out, "> t/034-tmp-sample.txt" );

my $d = Compress::Bzip2->new( -verbosity => $debugf ? 4 : 0 );
$d->bzopen( "t/034-tmp-sample-by5.bz2", "r" );

ok( $d, "open was successful" );

my $counter = 0;
my $bytes = 0;
while ( my $read = $d->bzread( $buf, 512 ) ) {
  if ( $read < 0 ) {
    print STDERR "error: $bytes $Compress::Bzip2::bzerrno\n";
    last;
  }

  $bytes += syswrite( $out, $buf, $read );

  $bytes += $read;
  $counter++;
}
ok( $counter, "$counter blocks were written, $bytes bytes" );

my $res = $d->bzclose;
ok( !$res, "file was closed $res $Compress::Bzip2::bzerrno" );

close($out);

my $in;
undef $out;

open( $in, "< t/034-tmp-sample-by5.bz2" ) or die;
open( $out, '| bunzip2 | od -x > t/034-tmp-reference-txt.odx' ) or die;
while ( my $ln = sysread( $in, $buf, 512 ) ) {
  syswrite($out, $buf, $ln);
}
close($in);
close($out);

system( 'od -x < t/034-tmp-sample.txt > t/034-tmp-sample-txt.odx' );
system( 'diff t/034-tmp-sample-txt.odx t/034-tmp-reference-txt.odx > t/034-tmp-diff.txt' );

ok( ! -s 't/034-tmp-diff.txt', "no differences with bunzip2" );
