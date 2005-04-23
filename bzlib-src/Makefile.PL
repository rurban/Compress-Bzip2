use ExtUtils::MakeMaker;
$Verbose = 1;
WriteMakefile(
	NAME => 'Compress::Bzip2::bzlib',
	SKIP => [qw(all static_lib static dynamic dynamic_lib)],
	clean => {'FILES' => 'libbz2$(LIB_EXT) bzip2'},
);

#libbz2$(LIB_EXT): $(O_FILES)

sub MY::top_targets {
	'
all :: static

pure_all :: static

static :: libbz2$(LIB_EXT) bzip2

libbz2$(LIB_EXT): blocksort.o huffman.o crctable.o randtable.o compress.o decompress.o bzlib.o
	$(AR) cr libbz2$(LIB_EXT) $(O_FILES)
	$(RANLIB) libbz2$(LIB_EXT)

bzip2: libbz2.a bzip2.o
';
}
