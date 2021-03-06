package Statistics::NiceR::DataConvert;
$Statistics::NiceR::DataConvert::VERSION = '0.03';
use strict;
use warnings;

use Statistics::NiceR::Sexp;
use Statistics::NiceR::DataConvert::PDL;
use Statistics::NiceR::DataConvert::Perl;
use Statistics::NiceR::DataConvert::DataFrame;
use Statistics::NiceR::DataConvert::Factor;
use Scalar::Util qw(blessed);
use Statistics::NiceR::Error;

sub convert_r_to_perl {
	my ($klass, $data) = @_;
	return unless $klass->check_r_sexp($data);
	for my $p (qw(Statistics::NiceR::DataConvert::PDL Statistics::NiceR::DataConvert::Perl Statistics::NiceR::DataConvert::Factor Statistics::NiceR::DataConvert::DataFrame) ) {
		my $ret;
		eval {
			no strict 'refs';
			$ret = &{"${p}::convert_r_to_perl"}(@_);
			1;
		} and return $ret;
		die $@ unless ref $@ && $@->isa('Statistics::NiceR::Error::Conversion::RtoPerl');
	}
	Statistics::NiceR::Error::Conversion::RtoPerl->throw('No suitable conversion found');
}

sub check_r_sexp {
	my ($klass, $data) = @_;
	blessed($data) && $data->isa('Statistics::NiceR::Sexp')
}

sub convert_perl_to_r {
	for my $p (qw(Statistics::NiceR::DataConvert::Factor Statistics::NiceR::DataConvert::PDL Statistics::NiceR::DataConvert::DataFrame Statistics::NiceR::DataConvert::Perl) ) {
		my $ret;
		eval {
			no strict 'refs';
			$ret = &{"${p}::convert_perl_to_r"}(@_);
			1;
		} and return $ret;
		die $@ unless ref $@ && $@->isa('Statistics::NiceR::Error::Conversion::PerltoR');
	}
	Statitics::NiceR::Error::Conversion::PerltoR->throw('No suitable conversion found');
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statistics::NiceR::DataConvert

=head1 VERSION

version 0.03

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
