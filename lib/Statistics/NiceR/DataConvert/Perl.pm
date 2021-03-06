package Statistics::NiceR::DataConvert::Perl;
$Statistics::NiceR::DataConvert::Perl::VERSION = '0.03';
use strict;
use warnings;

use Inline with => qw(Statistics::NiceR::Inline::Rinline);
use PDL::Lite; # XXX using PDL
use Statistics::NiceR::DataConvert::Perl::Inline C => 'DATA';
use Scalar::Util qw(reftype blessed);
use Scalar::Util::Numeric qw(isint isfloat);
use List::AllUtils;
use Statistics::NiceR::Error;

sub convert_r_to_perl {
	my ($self, $data) = @_;
	if( Statistics::NiceR::DataConvert->check_r_sexp($data) ) {
		if( $data->r_class eq 'character' ) {
			return convert_r_to_perl_charsxp(@_);
		} elsif( $data->r_class eq 'list' ) {
			return convert_r_to_perl_vecsxp(@_);
		}
	}
	Statistics::NiceR::Error::Conversion::RtoPerl->throw;
}

sub convert_r_to_perl_charsxp {
	my ($self, $data) = @_;
	return make_perl_string( $data );
}

sub convert_r_to_perl_vecsxp {
	my ($self, $data) = @_;
	my $names_r = $data->attrib('names');
	if( defined $names_r ) {
		#my $names_perl = Statistics::NiceR::DataConvert->convert_r_to_perl($names_r);
		#warn "R list has names attribute which needs to be processed"; # TODO
	}
	return [ map {
			my $curr = $_;
			  ref $curr eq 'Statistics::NiceR::Sexp'
			? Statistics::NiceR::DataConvert->convert_r_to_perl($curr)
			: $curr
		} @{ make_list( $data ) } ];
}

sub convert_perl_to_r {
	my ($self, $data) = @_;
	if( not defined $data ) {
		return convert_perl_to_r_undef(@_);
	} elsif( Statistics::NiceR::DataConvert->check_r_sexp($data) ) {
		return convert_perl_to_r_sexp(@_);
	} elsif( isint($data) ) {
		return convert_perl_to_r_integer(@_);
	} elsif( isfloat($data) ) {
		return convert_perl_to_r_float(@_);
	} else {
		if( blessed($data) ) {
			# boolean, Data::Perl, etc.
			...
		} elsif( ref $data ) {
			if( reftype($data) eq 'ARRAY' ) {
				if ( @$data == 0 ) {
					# empty list
					return convert_perl_to_r_arrayref(@_);
				} elsif( List::AllUtils::all { ref($_) eq '' && isint($_) } @$data ) {
					return convert_perl_to_r_integer(@_);
				} elsif( List::AllUtils::all { ref($_) eq '' && isfloat($_) } @$data ) {
					return convert_perl_to_r_float(@_);
				} elsif( List::AllUtils::all { ref($_) eq '' } @$data ) {
					# list of string scalars
					return convert_perl_to_r_string(@_);
				} else {
					return convert_perl_to_r_arrayref(@_);
				}
			} elsif( reftype($data) eq 'HASH' ) {
				# use R's env()
				...
			} elsif( reftype($data) eq 'SCALAR' ) {
				...
			}
		} else {
			# scalar (not a reference), string
			# XXX I think
			return convert_perl_to_r_string(@_);
		}
	}
	Statistics::NiceR::Error::Conversion::PerltoR->throw;
}

sub convert_perl_to_r_undef {
	my ($self, $data) = @_;
	return $data; # this is handled at the typemap level
}

sub convert_perl_to_r_string {
	my ($self, $data) = @_;
	return make_r_string($data);
}

sub convert_perl_to_r_arrayref {
	my ($self, $data) = @_;
	return make_vecsxp([ map {
		my $curr = $_;
		Statistics::NiceR::DataConvert->convert_perl_to_r($_) } @$data ]);
}

sub convert_perl_to_r_sexp {
	my ($self, $data) = @_;
	return $data;
}

sub convert_perl_to_r_integer {
	my ($self, $data) = @_;
	# XXX using PDL
	Statistics::NiceR::DataConvert::PDL->convert_perl_to_r( PDL::Core::long($data) );
}

sub convert_perl_to_r_float {
	my ($self, $data) = @_;
	# XXX using PDL
	Statistics::NiceR::DataConvert::PDL->convert_perl_to_r( PDL::core::double($data) );
}


1;

=pod

=encoding UTF-8

=head1 NAME

Statistics::NiceR::DataConvert::Perl

=head1 VERSION

version 0.03

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
__C__

SEXP make_vecsxp( SV* sexp_sv ) {
	size_t len;
	AV* sexp_av;
	SEXP vec = R_NilValue;
	size_t i;

	SV* sv_sexp_elt;
	IV ptrsexp_elt;
	SEXP r_sexp_elt;

	if( SvTYPE(SvRV(sexp_sv)) == SVt_PVAV ) {
		sexp_av = (AV*) SvRV(sexp_sv);
		len = av_len(sexp_av) + 1;

		PROTECT( vec = allocVector( VECSXP, len ) );
		for( i = 0; i < len; i++ ) {
			sv_sexp_elt = *( av_fetch(sexp_av, i, 0) ); /* get SV out of array */
			ptrsexp_elt = SvIV( (SV*) SvRV(sv_sexp_elt) ); /* get integer pointer out of SV */
			PROTECT( r_sexp_elt = INT2PTR(SEXP, ptrsexp_elt ) ); /* cast the integer to a pointer */
			SET_VECTOR_ELT( vec, i, r_sexp_elt );
		}
	}
	/* TODO throw exception if not an arrayref */

	return vec;
}

SEXP make_r_string( SV* p_char ) {
	size_t len;
	AV* p_av;
	size_t i;
	SEXP r_char = R_NilValue;

	SV* sv_elt; /* Perl element */
	char* char_elt;
	SEXP r_elt; /* R element */

	if( SvTYPE(SvRV(p_char)) == SVt_PVAV ) {
		p_av = (AV*) SvRV(p_char);
		len = av_len(p_av) + 1;

		PROTECT( r_char = allocVector( STRSXP, len ) );
		for( i = 0; i < len; i++ ) {
			sv_elt = *( av_fetch(p_av, i, 0) ); /* get SV out of array */
			char_elt = SvPV_nolen( sv_elt ); /* get string out of SV */
			PROTECT( r_elt = mkChar(char_elt) ); /* turn string into R CHARSXP */
			SET_STRING_ELT(r_char, i, r_elt );
		}
	} else {
		/* TODO make sure that this is an SVt_PV */
		PROTECT( r_char = allocVector( STRSXP, 1 ) );
		char_elt = SvPV_nolen( p_char );
		PROTECT( r_elt = mkChar(char_elt) );
		SET_STRING_ELT(r_char, i, r_elt );
	}

	return r_char;
}

SV* make_perl_string( SEXP r_char ) {
	size_t len;
	size_t i;
	AV* l;
	SV* sv_tmp;
	const char* s;
	size_t s_len;

	len = LENGTH(r_char);
	if( 0 == len ) {
		return &PL_sv_undef;
	} else if( 1 == len ) {
		s = CHAR(STRING_ELT(r_char, 0));
		s_len = strlen(s);
		return SvREFCNT_inc( newSVpv(s, s_len) );
	} else {
		l = newAV();
		av_extend(l, len - 1); /* pre-allocate */
		for( i = 0; i < len; i++ ) {
			s = CHAR(STRING_ELT(r_char, i));
			s_len = strlen(s);

			sv_tmp = newSVpv(s, s_len);
			av_store(l, i, SvREFCNT_inc(sv_tmp));
		}
		return newRV_inc((SV*)l);
	}

	return &PL_sv_undef; /* shouldn't get here */
}

SV* make_list( SEXP r_list ) {
	size_t len;
	size_t i;
	SEXP e;
	SV* sv_tmp;
	AV* l;

	len = LENGTH(r_list);
	l = newAV();
	av_extend(l, len - 1); /* pre-allocate */
	for( i = 0; i < len; i++ ) {
		e = VECTOR_ELT(r_list, i);

		sv_tmp = sv_newmortal();
		sv_setref_pv(sv_tmp, "Statistics::NiceR::Sexp", (void*)e);

		av_store(l, i, SvREFCNT_inc(sv_tmp));
	}
	return newRV_inc((SV*)l);

}
