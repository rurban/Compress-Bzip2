use File::Copy ;

BEGIN {
  eval { require File::Spec::Functions ; File::Spec::Functions->import( qw(catfile rel2abs) ) } ;
  *catfile = sub { return join( '/', @_ ) } if $@;
}

require VMS::Filespec if $^O eq 'VMS';

$::BZIP = $ENV{BZLIB_BIN} ? catfile( $ENV{BZLIB_BIN}, 'bzip2') :
    -x 'bzip2' ? rel2abs( 'bzip2' ) : 'bzip2';

$::debugf = $ENV{DEBUG};

sub dump_block {
  my %block;
  ( $block{1}, $block{2} ) = @_;

  for ( my $i=0; $i<length($block{1}); $i+=16 ) {
    my %xbuf;

    foreach my $j ( 1, 2 ) {
      for ( my $k=0; $k<16 && $i+$k<length($block{$j}); $k++ ) {
	$xbuf{$j} .= ' ' if $xbuf{$j} && $k % 2 == 0;
	$xbuf{$j} .= unpack( "H2", substr($block{$j},$i+$k,1) );
      }

      printf STDERR "%03d %s\n", $i, $xbuf{$j};
    }

    print STDERR "\n";
  }
}

sub compare_binary_files {
  my ( $file1, $file2 ) = @_;
  my ( %fh, %buf, %ln, %counter );

  if ( -s $file1 != -s $file2 ) {
    print STDERR "files not the same size", " $file1 is ".(-s $file1), ", $file2 is ".(-s $file2),"\n";
    return 0;
  }

  open( $fh{1}, $file1 );
  open( $fh{2}, $file2 );

  my $same = 1;
  my $notdone;
  $counter{blocks}++;
  while ( !$notdone ) {
    $ln{1} = sysread( $fh{1}, $buf{1}, 512 );
    $ln{2} = sysread( $fh{2}, $buf{2}, 512 );
    if ( $ln{1} != $ln{2} ) {
      print STDERR "blocks not the same size\n";
      return 0;
    }
    if ($buf{1} ne $buf{2}) {
      print STDERR "block $counter{blocks} not the same\n";
      dump_block($buf{1}, $buf{2});
      return 0;
    }
    return 1 if $ln{1} == 0;
    $counter{blocks}++;
  }

  close( $fh{1} );
  close( $fh{2} );

  return 0;
}

sub display_file {
  my ( $file ) = @_;
  my $in;
  if ( !open( $in, $file ) ) {
    warn "Error: unable to open $file: $!\n";
  }
  else {
    while (<$in>) {
      print STDERR $_;
    }
    close($in);
  }
}
