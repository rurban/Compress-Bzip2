# -*- mode: perl -*-

use Test::More tests => 4;
#use Test::More qw(no_plan);

## uncompress sample2 from the bzip2 1.0.2 distribution
## compare against bunzip2 command with od -x and diff

BEGIN {
  use_ok('Compress::Bzip2');
};

my $debugf = 0;
my $INFILE = 't/032-sample.bz2';
my $PREFIX = 't/060-tmp';

my ( $in, $out, $d, $outbuf, $counter, $bytes, $bytesout );

open( $in, "< $INFILE" ) or die "$INFILE: $!";
open( $out, "> $PREFIX-out.txt" ) or die "$PREFIX-out.txt: $!";

## verbosity 0-4, small 0,1, blockSize100k 1-9, workFactor 0-250, readUncompressed 0,1
$d = bzinflateInit( -verbosity => $debugf ? 4 : 0 );

ok( $d, "bzinflateInit was successful" );

$counter = 0;
$bytes = 0;
$bytesout = 0;
while ( my $ln = sysread( $in, $buf, 512 ) ) {
  $outbuf = $d->bzinflate( $buf );
  if ( !defined($outbuf) ) {
    print STDERR "error: $outbuf $bzerrno\n";
    last;
  }

  if ( $outbuf ne '' ) {
    syswrite( $out, $outbuf );
    $bytesout += length($outbuf);
  }

  $bytes += $ln;
  $counter++;
}

$outbuf = $d->bzclose;
if ( defined($outbuf) && $outbuf ne '' ) {
  syswrite( $out, $outbuf );
  $bytesout += length($outbuf);
  
  $counter++;
}

ok( $bytes && $bytesout, "$counter blocks read, $bytes bytes in, $bytesout bytes out" );

close($in);
close($out);

system( "bunzip2 -1 < $INFILE | od -x > $PREFIX-reference-txt.odx" );
system( "od -x < $PREFIX-out.txt > $PREFIX-out-txt.odx" );
system( "diff -c $PREFIX-out-txt.odx $PREFIX-reference-txt.odx > $PREFIX-diff.txt" );

ok( ! -s "$PREFIX-diff.txt", "no differences with bunzip2" );
