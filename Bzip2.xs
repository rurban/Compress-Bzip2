/* BZip2.xs -- Bzip2 bindings for Perl5
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <bzlib.h>

#define UNUSED(x)       x = x

static SV *deRef(SV *sv, char *method)
{
	SV *last_sv = NULL;
	while (SvROK(sv) && sv != last_sv)
	{
		last_sv = sv;
		sv = SvRV(sv);
	}
	if (!SvOK(sv))
	 croak("Compress::Bzip2::%s: buffer parameter is not SCALAR", method);
	return sv ;
}

static double constant(char *name, int arg)
{
    UNUSED(name);
    UNUSED(arg);
	errno = EINVAL;
	return 0;
}


/***********************************************************************
// XSUB start
************************************************************************/

MODULE = Compress::Bzip2   PACKAGE = Compress::Bzip2   PREFIX = X_

REQUIRE:	0.0
PROTOTYPES:	ENABLE

BOOT:
	if (BZ2_bzlibVersion() == NULL)
		croak("Compress::Bzip2 cannot load bzip-libraray %s\n",BZ2_bzlibVersion()) ;

double
constant(name, arg)
		char *     name
		int        arg

SV *
X_compress(string, level = 1)
	PREINIT:
		SV *		sv;
		STRLEN		len;
		int		level = 1;
		unsigned char *	in;
		unsigned char *	out;
		void *		wrkmem;
		unsigned int	in_len;
		unsigned int	out_len;
		unsigned int	new_len;
		int		err;
	CODE:
		sv = deRef(ST(0), "compress");
		in = (unsigned char *) SvPV(sv, len);
		if (items == 2 && SvOK(ST(1)))
			level = SvIV(ST(1));
		in_len = len;
		out_len = in_len + in_len / 64 + 16 + 3;
		RETVAL = newSV(5+out_len);
		SvPOK_only(RETVAL);

		out = SvPVX(RETVAL);
		new_len = out_len;

		out[0] = 0xf0;
		err = BZ2_bzBuffToBuffCompress(out+5,&new_len,in,in_len,6,0,240);

		if (err != BZ_OK || new_len > out_len)
		{
			SvREFCNT_dec(RETVAL);
			XSRETURN_UNDEF;
		}
		SvCUR_set(RETVAL,5+new_len);
		out[1] = (in_len >> 24) & 0xff;
		out[2] = (in_len >> 16) & 0xff;
		out[3] = (in_len >>  8) & 0xff;
		out[4] = (in_len >>  0) & 0xff;
	OUTPUT:
		RETVAL

SV *
X_decompress(string)
	PREINIT:
		SV *		sv;
		STRLEN		len;
		unsigned char *	in;
		unsigned char *	out;
		unsigned int	in_len;
		unsigned int	out_len;
		unsigned int	new_len;
		int		err;
	CODE:
		sv = deRef(ST(0), "decompress");
		in = (unsigned char *) SvPV(sv, len);
		if (len < 5 + 3 || in[0] < 0xf0 || in[0] > 0xf1)
			XSRETURN_UNDEF;
		in_len = len - 5;
		out_len = (in[1] << 24) | (in[2] << 16) | (in[3] << 8) | in[4];
		RETVAL = newSV(out_len > 0 ? out_len : 1);
		SvPOK_only(RETVAL);
		out = SvPVX(RETVAL);
		new_len = out_len;
		err = BZ2_bzBuffToBuffDecompress(out,&new_len,in+5,in_len,0,0);
		if (err != BZ_OK || new_len != out_len)
		{
			SvREFCNT_dec(RETVAL);
			XSRETURN_UNDEF;
		}
		SvCUR_set(RETVAL, new_len);
	OUTPUT:
		RETVAL




# vi:ts=4
