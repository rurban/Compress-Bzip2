use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Compress::Bzip2',
    VERSION_FROM      => 'lib/Compress/Bzip2.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Compress/Bzip2.pm', # retrieve abstract from module
       AUTHOR         => 'Rob Janes <rwjanes@primus.ca>') : ()),
    LIBS              => ['-lbz2'], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
	clean => {FILES=>'const-c.inc const-xs.inc t/???-tmp-* junk* *~ lib/Compress/*~ t/*~'},
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(BZ_CONFIG_ERROR BZ_DATA_ERROR BZ_DATA_ERROR_MAGIC
		 BZ_FINISH BZ_FINISH_OK BZ_FLUSH BZ_FLUSH_OK BZ_IO_ERROR
		 BZ_MAX_UNUSED BZ_MEM_ERROR BZ_OK BZ_OUTBUFF_FULL
		 BZ_PARAM_ERROR BZ_RUN BZ_RUN_OK BZ_SEQUENCE_ERROR
		 BZ_STREAM_END BZ_UNEXPECTED_EOF));
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Compress::Bzip2',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
