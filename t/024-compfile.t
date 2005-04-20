# -*- mode: perl -*-

use Test::More tests => 5;

## test the rollover past blockSize100k
## - make up a large file by essentially repeating one of the other sample files

BEGIN {
  use_ok('Compress::Bzip2');
};

my $debugf = 0;

my $in;
open( $in, "< t/024-sample.txt" );

my $d = Compress::Bzip2->new( -verbosity => $debugf ? 4 : 0, -blockSize100k => 1 );
$d->bzopen( "t/024-tmp-sample.bz2", "w" );

ok( $d, "open was successful" );

my $filecount = 0;
my $counter = 0;
my $bytes = 0;
while ( $bytes < 1_000_000 ) {
  while ( my $ln = sysread( $in, $buf, 512 ) ) {
    my $out = $d->bzwrite( $buf, $ln );
    if ( $out < 0 ) {
      print STDERR "error: $out $Compress::Bzip2::bzerrno\n";
      last;
    }
    print STDERR "read $ln bytes, bzwrite $out bytes\n" if $debugf;
    $bytes += $ln;
    $counter++;
  }

  $filecount++;
  sysseek($in,0,0);
}
ok( $counter, "$counter data was written, $bytes bytes, in $filecount loops" );

my $res = $d->bzclose;
ok( !$res, "file was closed $res $Compress::Bzip2::bzerrno" );

close($in);

my $out;
open( $in, "< t/024-sample.txt" ) or die;
open( $out, '| bzip2 -1 | od -x > t/024-tmp-reference-bz2.odx' ) or die;
for (my $i=0; $i<$filecount; $i++) {
  while ( my $ln = sysread( $in, $buf, 512 ) ) {
    syswrite($out, $buf, $ln);
  }
  sysseek($in,0,0);
}
close($in);
close($out);

system( 'od -x < t/024-tmp-sample.bz2 > t/024-tmp-sample-bz2.odx' );
system( 'diff t/024-tmp-sample-bz2.odx t/024-tmp-reference-bz2.odx > t/024-tmp-diff.txt' );

ok( ! -s 't/024-tmp-diff.txt', "no differences with bzip2" );
