#!/usr/bin/perl

use Compress::Bzip2;

if (0)
{
open F, ">crap.txt";
for ($x=1; $x<1000000; $x++)
	{
	print F '...';
	}
close F;
}

$/ = undef;
open F, "<crap.txt.bz2";
$in = <F>;
close F;
$/ = "\n";

$BUFFER = undef;
$ratio = 20;
while (!defined($BUFFER))
	{
	$BUFFER = &Compress::Bzip2::decompress($in,$ratio); 
	$ratio *= 2;
	print "Ratio is now: $ratio\n";
	}

if (defined($BUFFER))
	{
	print "Buffer is defined ".length($BUFFER)." bytes\n";
	} else {
	print "Buffer is not defined.\n";
	}