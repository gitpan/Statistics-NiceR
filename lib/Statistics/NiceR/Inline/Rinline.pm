package Statistics::NiceR::Inline::Rinline;
$Statistics::NiceR::Inline::Rinline::VERSION = '0.01';
use strict;
use warnings;
use File::Basename;
use File::Spec;
use File::Which;
use Statistics::NiceR::Error;

sub import {
	Statistics::NiceR::Error::RInterpreter->throw("R executable not found") unless which('R');
	unless( $ENV{R_HOME} ) {
		my $Rhome = `R RHOME`;
		chomp $Rhome;
		$ENV{R_HOME} = $Rhome;
	}
}

sub Inline {
	return unless $_[-1] eq 'C';
	import();
	my $R_inc = `R CMD config --cppflags`;
	my $R_libs   = `R CMD config --ldflags`;
	my $dir = File::Spec->rel2abs( dirname(__FILE__) );
	+{
		INC => $R_inc,
		LIBS => $R_libs,
		TYPEMAPS => File::Spec->catfile( $dir, 'typemap' ),
		AUTO_INCLUDE => q{
			#include <Rinternals.h>
			#include <Rembedded.h>
			#include <R_ext/Parse.h> },
	};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statistics::NiceR::Inline::Rinline

=head1 VERSION

version 0.01

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
