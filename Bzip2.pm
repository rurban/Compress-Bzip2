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
use vars qw($VERSION @ISA @EXPORT_OK $AUTOLOAD);

@ISA = qw(Exporter DynaLoader);

@EXPORT_OK = qw(
	version compress decompress compress_init decompress_init
);

$VERSION = '1.03';

bootstrap Compress::Bzip2 $VERSION;


1;
__END__


=cut

=head1 NAME

Compress::Bzip2 - interface to the bzip2 compression library

=head1 SYNOPSIS

    use Compress::Bzip2;

    $dest = Compress::Bzip2::compress($source, [$level]);
    $dest = Compress::Bzip2::decompress($source);

=head1 DESCRIPTION

The I<Compress::Bzip2> module provides a Perl interface to the I<Bzip2>
compression library (see L</AUTHOR> for details about where to get
I<Bzip2>). A relevant subset of the functionality provided by I<Bzip2>
is available in I<Compress::Bzip2>.

You may pass in a reference to a string wherever a string is required.

You can retrieve the library version using the version function.

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

=head1 ERROR STATUS

If a function reports an error by returning I<undef>, call error to get
the error string.  In list context, returns a list of (string, libbz2 code).

 if(not defined $dest)
 {
     print "compression failed: ".Compress::Bzip2::error();
 }

=head1 STREAMING COMPRESSION

To compress a larger volume of data, the streamed compression interface may
be of use.  For both compression and decompression, you create a stream object,
add data to it, then call finish when done:

 my $stream = Compress::Bzip2::compress_init();

 while(my $data = read_data())
 {
     write_data($stream->add($data));
 }

 write_data($stream->finish());

Note that if you want to be able to decompress the result using the
decompress method, you need to call the prefix method and prefix the result:

 my $original = Compress::Bzip2::decompress($stream->prefix().$output);

The streaming decompression interface is similar; just replace compress_init
with decompress_init.  The optional parameters each takes as well as some
other methods on the stream object are described below:

=head2 compress_init

Takes named parameters:

=over 4

=item level

1 or 9, as for compress (defaults to 1)

=item workFactor

bzip2 library work factor (0-250; if missing or 0 defaults to 30)

=item buffer

buffer size to use (defaults to 8192 - 8K)

=back

=head2 decompress_init

Takes named parameters:

=over 4

=item small

if set (1), use alternative algorithm (slower but uses less memory) (default 0)

=item buffer

buffer size to use (defaults to 8192 - 8K)

=back

=head2 add ( string )

Add data to be compressed/decompressed.  Returns whatever output is available
(possibly none, if it's still buffering it), or undef on error.

=head2 finish ( [string] )

Finish the operation; takes an optional final data string.  Whatever is
returned completes the output; returns undef on error.

=head2 error

Like the function, but applies to the current object only.  Note that errors
in a stream object are also returned by the function.

=head2 input_size

Total bytes passed to the stream.

=head2 output_size

Total bytes received from the stream.

=head1 AUTHOR

The I<Compress::Bzip2> module was written by Gawdi Azem
F<azemgi@rupert.informatik.uni-stuttgart.de> and is now maintained by
Marco Carnut F<kiko@tempest.com.br>.  The streaming interface and error
information were added by David Robins F<dbrobins@davidrobins.net>.

=head1 MODIFICATION HISTORY

1.00 First public release of I<Compress::Bzip2>.

1.02 Added BZ2_ prefixes so that it works with libbz2 versions >1.0

1.03 Added error reporting, and streaming functions, fixed some compression
errors, added tests.
