require 5.003;
use ExtUtils::MakeMaker 5.16;
use Config;

#$Bzip2_INCLUDE = '-I/usr/include/bzip2';
#$Bzip2_INCLUDE = '-I/usr/local/include';
#$Bzip2_INCLUDE = '-I/usr/local/include/bzip2';

#$Bzip2_LIB     = '-L/usr/local/lib';

WriteMakefile(
                NAME   	 	=> 'Compress::Bzip2',
		VERSION_FROM  	=> 'Bzip2.pm',
		LIBS	 	=> [ "$Bzip2_LIB -lbz2" ],
	      	INC      	=> "$Bzip2_INCLUDE",
		'dist'	 	=> {COMPRESS=>'bzip2', SUFFIX=>'bz2'},
	     ) ;



