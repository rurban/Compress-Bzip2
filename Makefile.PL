require 5.003;
use ExtUtils::MakeMaker 5.16;
use Config;

# override library and include directory here if desired
my $lib = '';
my $inc = '';

# try to find libbz2 if we're not given a location
unless($lib and $inc) {
	for my $prefix($Config{siteprefixexp},$Config{prefixexp},
     '/usr','/usr/local','/opt') {
		$lib ||= "$prefix/lib"
		 if -f "$prefix/lib/libbz2.a" or -f "$prefix/lib/libbz2.so";
		$inc ||= "$prefix/include"
		 if -f "$prefix/include/bzlib.h";
		last if $lib and $inc;
	}
}

die "can't find libbz2!" unless $lib;
die "can't find bzlib.h!" unless $inc;
$lib = "-L$lib -lbz2";
$inc = "-I$inc";
print "using library $lib and include path $inc\n";

# generate the Makefile
WriteMakefile(
	NAME			=> 'Compress::Bzip2',
	VERSION_FROM	=> 'Bzip2.pm',
	LIBS			=> [$lib],
	INC				=> $inc,
);


# vi:ts=4:noet
