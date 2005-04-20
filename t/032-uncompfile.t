# -*- mode: perl -*-

use Test::More tests => 7;

## uncompress sample2 compressed file from the bzip2 1.0.2 distribution
## compare against bunzip2 command with od -x and diff

BEGIN {
  use_ok('Compress::Bzip2');
};

my $out;
open( $out, "> t/032-tmp-sample.txt" );

my $d = Compress::Bzip2->new( -verbosity => 0 );
$d->bzopen( "t/032-sample.bz2", "r" );

ok( $d, "open was successful" );

my $counter = 0;
my $bytes = 0;

ok( !$d->bzeof, "not at EOF" );

my $read;
while ( $read = $d->bzread( $buf, 512 ) ) {
  if ( $read < 0 ) {
    print STDERR "error: $bytes $Compress::Bzip2::bzerrno\n";
    last;
  }

  $bytes += syswrite( $out, $buf, $read );
  $counter++;
}

ok( $d->bzeof, "at EOF" );

ok( $counter, "$counter data was written, $bytes bytes" );

my $res = $d->bzclose;
ok( !$res, "file was closed $res $Compress::Bzip2::bzerrno" );

close($out);

system( 'bunzip2 < t/032-sample.bz2 > t/032-tmp-reference.txt' );
system( 'diff -c t/032-tmp-sample.txt t/032-tmp-reference.txt > t/032-tmp-diff.txt' );

ok( ! -s 't/032-tmp-diff.txt', "no differences with bunzip2" );
