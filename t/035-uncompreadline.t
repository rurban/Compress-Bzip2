# -*- mode: perl -*-

#use Test::More tests => 5;
use Test::More qw(no_plan);

## uncompress a compressed simple text file - the lyrics to end of the world REM
## compare against bunzip2 command with od -x and diff

BEGIN {
  use_ok('Compress::Bzip2');
};

my $debugf;
my $INFILE = 't/030-sample.bz2';
my $PREFIX = 't/035-tmp';

my $out;
open( $out, "> $PREFIX-sample.txt" );

my $d = Compress::Bzip2->new( -verbosity => $debugf ? 4 : 0 );
$d->bzopen( $INFILE, "r" );

ok( $d, "open was successful" );

my $counter = 0;
my $bytes = 0;

my $buf;
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

## test readline

my ($rlin, %reflines, %lines);
open( $rlin, "< $PREFIX-reference.txt" ) or die;
while (<$rlin>) {
  chomp;
  $reflines{count}++;
  $reflines{maxlen} = length($_) if !defined($reflines{maxlen}) || length($_) > $reflines{maxlen};
  $reflines{minlen} = length($_) if !defined($reflines{minlen}) || length($_) < $reflines{minlen};
  $reflines{first} = $_ if $reflines{count}==1;
  $reflines{last} = $_;
}
close($rlin);

$d = Compress::Bzip2->new( -verbosity => $debugf ? 4 : 0 );
$d->bzopen( $INFILE, "r" );

my $ln;
ok( $d, "readline open was successful" );
while ( $ln = $d->bzreadline( $buf, 512 ) ) {
  if ( $ln < 0 ) {
    print STDERR "error: $Compress::Bzip2::bzerrno\n";
    last;
  }

  chomp $buf;

  $lines{count}++;
  $lines{maxlen} = length($buf) if !defined($lines{maxlen}) || length($buf) > $lines{maxlen};
  $lines{minlen} = length($buf) if !defined($lines{minlen}) || length($buf) < $lines{minlen};
  $lines{first} = $buf if $lines{count}==1;
  $lines{last} = $buf;
}

ok( $reflines{count} == $lines{count}, "readline linecount is $lines{count}, should be $reflines{count}" );
ok( $reflines{maxlen} == $lines{maxlen}, "readline maximum line length is $lines{maxlen}, should be $reflines{maxlen}" );
ok( $reflines{minlen} == $lines{minlen}, "readline minimum line length is $lines{minlen}, should be $reflines{minlen}" );
ok( $reflines{first} eq $lines{first}, "readline first line is '$lines{first}', should be '$reflines{first}'" );
ok( $reflines{last} eq $lines{last}, "readline last line is '$lines{last}', should be '$reflines{last}'" );
