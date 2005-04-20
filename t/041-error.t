# -*- mode: perl -*-

#use Test::More tests => 5;
use Test::More qw(no_plan);
use Fcntl;

BEGIN {
  use_ok('Compress::Bzip2');
};

my $debugf = 0;
my $INFILE = 't/020-sample.txt';
my $PREFIX = 't/041-tmp';

## verbosity 0-4, small 0,1, blockSize100k 1-9, workFactor 0-250, readUncompressed 0,1
my ( $d, $err, $in, $out, $buf, $res );

$d = Compress::Bzip2->new( -workFactor => 1000 );
ok( $d, "object created in spite of error" );
$err = $d->bzerror;
ok( $err, "error is set '$err' vs '$bzerrno'" );

$d->bzclearerr;

$err = $d->bzerror;
ok( !$err, "after bzclearerr, error is not set '$err' vs '$bzerrno'" );

unlink( "$PREFIX-protected.bz2" ) if -f "$PREFIX-protected.bz2";
sysopen( $out, "$PREFIX-protected.bz2", O_WRONLY|O_CREAT ) or die "failed $PREFIX-protected.bz2 $!";
ok( $d->bzopen( $out, "w" ), "bzopen with file handle instead of file" );

open( $in, "< $INFILE" );

while ( my $ln = sysread( $in, $buf, 512 ) ) {
  $res = $d->bzwrite( $buf, $ln );
  if ( $res < 0 ) {
    print STDERR "error: $res $bzerrno\n";
    last;
  }
}

$res = $d->bzclose;
ok( !$res, "file was closed $res $Compress::Bzip2::bzerrno" );

close($in);

system( "bzip2 < $INFILE | od -x > $PREFIX-reference-bz2.odx" );
system( "od -x < $PREFIX-protected.bz2 | diff -c - $PREFIX-reference-bz2.odx > $PREFIX-diff.txt" );

ok( ! -s "$PREFIX-diff.txt", "no differences with bzip2" );

chmod( 0000, "$PREFIX-protected.bz2" ) or die;

$d = Compress::Bzip2->new( -verbosity => $debugf ? 4 : 0, -blockSize100k => 1 );
$res = $d->bzopen( "$PREFIX-protected.bz2", "w" );

ok( !$res, "open failed" );

$res = $d->bzerror;
ok( $res, "error set, is '$res' '$bzerrno'" );
