#  Bzip2.pm --
#
#  Gawdi Azem
#  azemgi@rupert.informatik.uni-stuttgart.de

package Compress::Bzip2;

require 5.003_05 ;
require Exporter;
require DynaLoader;
use AutoLoader;
use Carp;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

@ISA = qw(Exporter DynaLoader);

@EXPORT = qw(
);

@EXPORT_OK = qw(
	compress decompress
);

$VERSION = "1.00";

sub AUTOLOAD {
    my($constname);
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    croak "Compress::Bzip2 macro $constname not defined";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap Compress::Bzip2 $VERSION;

# Preloaded methods go here.


1 ;
# Autoload methods go after __END__, and are processed by the autosplit program.

1;
__END__


=cut

=head1 NAME

Compress::Bzip2 - Interface to Bzip2 compression library

=head1 SYNOPSIS

    use Compress::Bzip2;

    $dest = Compress::Bzip2::compress($source, [$level]);
    $dest = Compress::Bzip2::decompress($source);

=head1 DESCRIPTION

The I<Compress::Bzip2> module provides a Perl interface to the I<Bzip2>
compression library (see L</AUTHOR> for details about where to get
I<Bzip2>). A relevant subset of the functionality provided by I<Bzip2>
is available in I<Compress::Bzip2>.

All string parameters can either be a scalar or a scalar reference.

=head1 COMPRESSION FUNCTIONS

$dest = Compress::Bzip2::compress($string)

Compress a string using the default compression level, returning a string
containing compressed data.

$dest = Compress::Bzip2::compress($string, $level)

Compress string, using the chosen compression level (either 1 or 9).
Return a string containing the compressed data.

On error I<undef> is returned.

=head1 DECOMPRESSION FUNCTIONS

$dest = Compress::Bzip2::decompress($string)

Decompress the data in string, returning a string containing the
decompressed data.

On error I<undef> is returned.

=head1 AUTHOR

The I<Compress::Bzip2> module was written by Gawdi Azem
F<azemgi@rupert.informatik.uni-stuttgart.de>.

=head1 MODIFICATION HISTORY

1.00 First public release of I<Compress::Bzip2>.

