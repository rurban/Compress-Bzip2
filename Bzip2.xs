/* BZip2.xs -- Bzip2 bindings for Perl5

   See documentation "Programming with libbzip2"
	available at http://www.tug.org/tex-archive/tools/bzip2/docs/manual_3.html.
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <bzlib.h>

/* module globals for storing error information */
static int last_bzerror = 0;
static SV* last_sverror = 0;

/* stream object internal structure */
typedef struct
{
	int compress;				/* true iff compression stream */
    int done;                   /* true iff finished decompression */
	bz_stream bzs;				/* contained bz_stream structure */
	unsigned size;				/* size of buffer to use */
	int bzerror;				/* last error, or 0 */
	SV* sverror;				/* error string, or NULL */
}
bz_object;


/* continually dereference until we get to a non-RV (or a loop) */
static SV* deRef(SV* sv, char* method)
{
	SV *last_sv = 0;
	while(SvROK(sv) && sv != last_sv)
	{
		last_sv = sv;
		sv = SvRV(sv);
	}
	if(!SvOK(sv))
		croak("Compress::Bzip2::%s: buffer parameter is not scalar", method);
	return sv;
}

/* store error message for later retrieval */
static void fail(char* text, ...)
{
	va_list va;

	va_start(va,text);
	if(!last_sverror)
		last_sverror = newSVpv("",0);
	sv_vsetpvfn(last_sverror,text,strlen(text),&va,0,0,0);
	va_end(va);
	last_bzerror = 0;
}

/* store libbz2 error message for later retrieval */
static void bzFail(bz_object* bzo, char* text, int bzerror)
{
	char* type = 0;

#define BZERROR(n) case BZ_##n: type = #n; break;
	switch(bzerror)
	{

	/* actual errors */
	BZERROR(CONFIG_ERROR);
	BZERROR(SEQUENCE_ERROR);
	BZERROR(PARAM_ERROR)
	BZERROR(MEM_ERROR)
	BZERROR(DATA_ERROR)
	BZERROR(DATA_ERROR_MAGIC)
	BZERROR(IO_ERROR)
	BZERROR(UNEXPECTED_EOF)
	BZERROR(OUTBUFF_FULL)

	/* success conditions, shouldn't see these */
	BZERROR(OK)
	BZERROR(RUN_OK)
	BZERROR(FLUSH_OK);
	BZERROR(FINISH_OK);
	BZERROR(STREAM_END);
	}
#undef BZERROR

	if(type)
		fail("%s: %s", text, type);
	else
		fail("%s: unknown error", text);
	last_bzerror = bzerror;

	if(bzo)
	{
		bzo->bzerror = bzerror;
		if(bzo->sverror)
			SvREFCNT_dec(bzo->sverror);
		bzo->sverror = newSVsv(last_sverror);
	}
}

/* stream compression memory allocator */
static void* bzalloc(void* opaque, int n, int m)
{
  New(0,opaque,n*m,char);
  return opaque;
}

/* stream compression memory deallocator */
static void bzfree(void* opaque, void* p)
{
  Safefree(p);
}

/* create stream object */
static SV* stream_new(int compress, unsigned size, bz_object** pbzo)
{
	SV* obj;

	if(!size)
		croak("Compress::Bzip2 buffer size must be > 0");

	/* initialize the bz_object and bz_stream */
	Newz(0,*pbzo,1,bz_object);
	(**pbzo).compress	 = compress;
	(**pbzo).size		 = size;
	(**pbzo).bzs.bzalloc = bzalloc;
	(**pbzo).bzs.bzfree  = bzfree;

	/* wrap the stream in an RV pointing to an IV holding the address
	   (this is portable since a pointer is guaranteed to fit in an IV) */
	obj = NEWSV(0,0);
	sv_setref_iv(obj,"Compress::Bzip2::stream",(IV)*pbzo);
	return obj;
}

/* extract stream object */
static bz_object* stream_self(SV* self)
{
	if(!SvROK(self))
		croak("Compress::Bzip2::stream object must be a reference");
	self = SvRV(self);
	if(!SvIOKp(self))
		croak("Compress::Bzip2::stream object internal structure corrupt");
	return (bz_object*)SvIVX(self);
}

/* add data to compression stream */
void stream_compress(bz_object* bzo, SV* in, SV** pout, int finish)
{
	STRLEN len, out = 0;
	int err = BZ_OK;

	if(in)
	{
		in = deRef(in, "compress");
		bzo->bzs.next_in = SvPV(in,len);
	}
	else
		len = 0;
	bzo->bzs.avail_in = len;

	*pout = newSVpvn("",0);

	/* loop until data is consumed/output */
	while((bzo->bzs.avail_in || finish) && BZ_STREAM_END != err)
	{
		bzo->bzs.next_out  = SvGROW(*pout,out+bzo->size)+out;
		bzo->bzs.avail_out = bzo->size;

		if((err = BZ2_bzCompress(&bzo->bzs,finish ? BZ_FINISH : BZ_RUN)) < 0)
		{
			SvREFCNT_dec(*pout);
			*pout = 0;
			bzFail(bzo,"BZ2_bzCompress",err);
			return;
		}
	
		out += bzo->size-bzo->bzs.avail_out;
	}

	/* ignored some of the input */
	if(bzo->bzs.avail_in)
		croak("Compress::Bzip2::stream::add left %d byte(s)",bzo->bzs.avail_in);

	SvCUR_set(*pout,out);
}

/* add data to decompression stream */
void stream_decompress(bz_object* bzo, SV* in, SV** pout, int finish)
{
	STRLEN len, out = 0, add;
	int err = BZ_OK;

	if(in)
	{
		in = deRef(in, "decompress");
		bzo->bzs.next_in = SvPV(in,len);
	}
	else
		len = 0;
	bzo->bzs.avail_in = len;

	*pout = newSVpvn("",0);

	/* loop until data is consumed/output */
	while(bzo->bzs.avail_in || (finish && !bzo->done))
	{
		bzo->bzs.next_out  = SvGROW(*pout,out+bzo->size)+out;
		bzo->bzs.avail_out = bzo->size;

		if((err = BZ2_bzDecompress(&bzo->bzs)) < 0)
		{
			SvREFCNT_dec(*pout);
			bzFail(bzo,"BZ2_bzDecompress",err);
			*pout = 0;
			return;
		}
	
		add = bzo->size-bzo->bzs.avail_out;
		out += add;

        if(BZ_STREAM_END == err)
			bzo->done = 1, add = 0;
		if(!add && !bzo->bzs.avail_in)
			break;
	}

	if(bzo->bzs.avail_in)
		croak("Compress::Bzip2::stream::add left %d byte(s)",bzo->bzs.avail_in);

	SvCUR_set(*pout,out);
}


/***********************************************************************
// XSUB start
************************************************************************/

MODULE = Compress::Bzip2   PACKAGE = Compress::Bzip2   PREFIX = X_

REQUIRE:	0.0
PROTOTYPES:	ENABLE

BOOT:
	if(!BZ2_bzlibVersion())
		croak("Compress::Bzip2 cannot load bzip2 library");

SV*
version()
	CODE:
		RETVAL = newSVpv(BZ2_bzlibVersion(),0);
	OUTPUT:
		RETVAL

SV*
X_compress(sv, level = 1)
		SV*		sv;
		int		level;
	PREINIT:
		STRLEN		len;
		unsigned char *	in;
		unsigned char *	out;
		void *		wrkmem;
		unsigned int	in_len;
		unsigned int	out_len;
		unsigned int	new_len;
		int		err;
	CODE:
		sv = deRef(sv, "compress");
		in = (unsigned char*) SvPV(sv, len);
		in_len = len;

		/* use an extra 1% + 600 bytes (see libbz2 documentation) */
		out_len = in_len + ( in_len + 99 ) / 100 + 600;
		RETVAL = newSV(5+out_len);
		SvPOK_only(RETVAL);

		out = (unsigned char*)SvPVX(RETVAL);
		new_len = out_len;

		out[0] = 0xf0;
		err = BZ2_bzBuffToBuffCompress(
			   (char*)out+5,&new_len,(char*)in,in_len,6,0,240);

		if (err != BZ_OK || new_len > out_len)
		{
			SvREFCNT_dec(RETVAL);
			bzFail(0,"BZ2_bzBuffToBuffCompress",err);
			XSRETURN_UNDEF;
		}
		SvCUR_set(RETVAL,5+new_len);
		out[1] = (in_len >> 24) & 0xff;
		out[2] = (in_len >> 16) & 0xff;
		out[3] = (in_len >>  8) & 0xff;
		out[4] = (in_len >>  0) & 0xff;
	OUTPUT:
		RETVAL

SV*
X_decompress(sv)
		SV *		sv;
	PREINIT:
		STRLEN		len;
		unsigned char *	in;
		unsigned char *	out;
		unsigned int	in_len;
		unsigned int	out_len;
		unsigned int	new_len;
		int		err;
	CODE:
		sv = deRef(sv, "decompress");
		in = (unsigned char*)SvPV(sv, len);
		if (len < 5 + 3 || in[0] < 0xf0 || in[0] > 0xf1)
		{
			fail("invalid buffer (too short %d or bad marker %d)",len,in[0]);
			XSRETURN_UNDEF;
		}
		in_len = len - 5;
		out_len = (in[1] << 24) | (in[2] << 16) | (in[3] << 8) | in[4];
		RETVAL = newSV(out_len > 0 ? out_len : 1);
		SvPOK_only(RETVAL);
		out = (unsigned char*)SvPVX(RETVAL);
		new_len = out_len;
		err = BZ2_bzBuffToBuffDecompress(
			   (char*)out,&new_len,(char*)in+5,in_len,0,0);
		if (err != BZ_OK || new_len != out_len)
		{
			SvREFCNT_dec(RETVAL);
			bzFail(0,"BZ2_bzBuffToBuffDecompress",err);
			XSRETURN_UNDEF;
		}
		SvCUR_set(RETVAL, new_len);
	OUTPUT:
		RETVAL

SV*
X_compress_init(...)
	PREINIT:
		int i, err, level = 1, workFactor = 30;
		unsigned size = 8192;
		bz_object* bzo;
	CODE:
		/* parse named parameters */
		if(items % 2)
			croak("Compress::Bzip2::compress_init has odd parameter count");

		for(i = 0; i<items; i += 2)
		{
			char* key = SvPV_nolen(ST(i));

			if(!strcmp(key,"level"))
				level = SvIV(ST(i+1));
			else if(!strcmp(key,"workFactor"))
				workFactor = SvIV(ST(i+1));
			else if(!strcmp(key,"buffer"))
				size = SvUV(ST(i+1));
			else
				croak("Compress::Bzip2::compress_init unknown parameter '%s'",
				 key);
		}

		/* create compression stream object */
		RETVAL = stream_new(1,size,&bzo);
		if((err = BZ2_bzCompressInit(&bzo->bzs,level,0,workFactor)) < 0)
		{
			SvREFCNT_dec(RETVAL);
			bzFail(0,"BZ2_bzCompressInit",err);
			XSRETURN_UNDEF;
		}
	OUTPUT:
		RETVAL

SV*
X_decompress_init(...)
	PREINIT:
		unsigned size = 8192;
		int small = 0, err, i;
		bz_object* bzo;
	CODE:
		/* parse named parameters */
		if(items % 2)
			croak("Compress::Bzip2::decompress_init has odd parameter count");

		for(i = 0; i<items; i += 2)
		{
			char* key = SvPV_nolen(ST(i));

			if(!strcmp(key,"small"))
				small = SvIV(ST(i+1));
			else if(!strcmp(key,"buffer"))
				size = SvUV(ST(i+1));
			else
				croak("Compress::Bzip2::decompress_init unknown parameter '%s'",
				 key);
		}

		/* create decompression stream object */
		RETVAL = stream_new(0,size,&bzo);
		if((err = BZ2_bzDecompressInit(&bzo->bzs,0,small)) < 0)
		{
			SvREFCNT_dec(RETVAL);
			bzFail(0,"BZ2_bzDecompressInit",err);
			XSRETURN_UNDEF;
		}
	OUTPUT:
		RETVAL

void
X_error()
	PPCODE:
		switch(GIMME_V)
		{
		case G_VOID:
			warn("Compress::Bzip2::error called in void context");
			break;
		case G_SCALAR:
			EXTEND(SP,1);
			PUSHs(last_sverror ? last_sverror : &PL_sv_no);
			break;
		case G_ARRAY:
			EXTEND(SP,2);
			PUSHs(last_sverror ? last_sverror : &PL_sv_no);
			PUSHs(sv_2mortal(newSViv(last_bzerror)));
			break;
		}


MODULE = Compress::Bzip2   PACKAGE = Compress::Bzip2::stream   PREFIX = X_

SV*
X_add(bzo, in);
		bz_object* bzo
		SV* in
	PREINIT:
		STRLEN len;
		char* data;
		int err;
	CODE:
		if(bzo->compress)
			stream_compress(bzo,in,&RETVAL,0);
		else
			stream_decompress(bzo,in,&RETVAL,0);

		if(!RETVAL)
			XSRETURN_UNDEF;

	OUTPUT:
		RETVAL

SV*
X_finish(bzo, in = 0)
		bz_object* bzo
		SV* in
	CODE:
		if(bzo->compress)
			stream_compress(bzo,in,&RETVAL,1);
		else
			stream_decompress(bzo,in,&RETVAL,1);

		if(!RETVAL)
			XSRETURN_UNDEF;

	OUTPUT:
		RETVAL

SV*
X_input_size(bzo)
		bz_object* bzo
	CODE:
		if(bzo->bzs.total_in_hi32)
			RETVAL = newSVnv(bzo->bzs.total_in_hi32*4294967296.0+
							 bzo->bzs.total_in_lo32);
		else
			RETVAL = newSVuv(bzo->bzs.total_in_lo32);
	OUTPUT:
		RETVAL

SV*
X_output_size(bzo)
		bz_object* bzo
	CODE:
		if(bzo->bzs.total_out_hi32)
			RETVAL =
			 newSVnv(bzo->bzs.total_out_hi32*4294967296.0+
					 bzo->bzs.total_out_lo32);
		else
			RETVAL = newSVuv(bzo->bzs.total_out_lo32);
	OUTPUT:
		RETVAL

SV*
X_prefix(bzo)
		bz_object* bzo
	CODE:
		if(bzo->bzs.total_in_hi32)
			XSRETURN_UNDEF;
		else
		{
			unsigned in_len = bzo->bzs.total_in_lo32;
			char out[5];
			out[0] = 0xf0;
			out[1] = (in_len >> 24) & 0xff;
			out[2] = (in_len >> 16) & 0xff;
			out[3] = (in_len >>  8) & 0xff;
			out[4] = (in_len >>  0) & 0xff;
			RETVAL = newSVpvn(out,5);
		}
	OUTPUT:
		RETVAL

void
X_error(bzo)
		bz_object* bzo
	PPCODE:
		switch(GIMME_V)
		{
		case G_VOID:
			warn("Compress::Bzip2::stream::error called in void context");
			break;
		case G_SCALAR:
			EXTEND(SP,1);
			PUSHs(bzo->sverror ? bzo->sverror : &PL_sv_no);
			break;
		case G_ARRAY:
			EXTEND(SP,2);
			PUSHs(bzo->sverror ? bzo->sverror : &PL_sv_no);
			PUSHs(sv_2mortal(newSViv(bzo->bzerror)));
			break;
		}

void
X_DESTROY(bzo)
		bz_object* bzo
	CODE:
		if(bzo->compress)	
			BZ2_bzCompressEnd(&bzo->bzs);
		else
			BZ2_bzDecompressEnd(&bzo->bzs);
		if(bzo->sverror)
			SvREFCNT_dec(bzo->sverror);
		Safefree(bzo);


# vi:ts=4:noet
