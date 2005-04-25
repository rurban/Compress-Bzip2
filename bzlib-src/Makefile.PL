use ExtUtils::MakeMaker;

#$Verbose = 1;

WriteMakefile(
	NAME => 'Compress::Bzip2::internal_bzlib',
	SKIP => [qw(all static_lib static dynamic dynamic_lib)],
	clean => {'FILES' => 'libbz2$(LIB_EXT) bzip2 t/??-tmp*'},
);

#libbz2$(LIB_EXT): $(O_FILES)

sub MY::top_targets {
	'
all :: static

pure_all :: static

static :: libbz2$(LIB_EXT) bzip2

libbz2$(LIB_EXT): blocksort$(OBJ_EXT) huffman$(OBJ_EXT) crctable$(OBJ_EXT) randtable$(OBJ_EXT) compress$(OBJ_EXT) decompress$(OBJ_EXT) bzlib$(OBJ_EXT)
	$(AR) cr libbz2$(LIB_EXT) $^
	$(RANLIB) libbz2$(LIB_EXT)

bzip2: libbz2$(LIB_EXT) bzip2$(OBJ_EXT)
';
}
