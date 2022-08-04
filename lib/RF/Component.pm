package RF::Component;

use strict;
use warnings;
use Carp;
use 5.010;

use Math::Complex;
use Math::Matrix::Complex;

our %valid_opts = map { $_ => 1 } qw/
		measurements
		z
		n_ports
		comments
		filename
		model
		value
		value_unit
		value_code_regex
		value_literal_regex
		/;

sub new
{
	my ($class, %args) = @_;

	foreach (keys %args)
	{
		croak "$class: invalid class option: $_ => $args{$_}" if !defined($valid_opts{$_});
	}

	my $self = bless(\%args, $class);

	if (defined($self->{value}) && ($self->{value_code_regex} || $self->{value_literal_regex}))
	{
		croak "Cannot define both value and value_(code|literal)_regex";
	}

	# Assume the part "model" is the filemodel without the .sNp suffix:
	if (defined $self->{filename})
	{
		my $model = $self->{filename};
		$model =~ s!^.*/|\.s\dp$!!ig;
		$self->{model} //= $model;
	}

	if (defined($self->{value_unit}) && $self->{value_unit} !~ /^[fpnumkmGTPE]?[FHR]$/)
	{
		croak "invalid unit: expected sU where 's' is an si prefix (fpnumkmGTPE) and U is (F)arad, (H)enry, or (R) for ohms";
	}

	if (defined($self->{model}) && $self->{value_code_regex} && !$self->{value_literal_regex})
	{
		$self->{value} = _parse_model_value_code($self->{model},
			$self->{value_code_regex},
			$self->{value_unit});
	}
	elsif (defined($self->{model}) && $self->{value_literal_regex} && !$self->{value_code_regex})
	{
		$self->{value} = _parse_model_value_literal($self->{model}, $self->{value_literal_regex});
	}
	elsif (!defined($self->{model}) && ($self->{value_literal_regex} || $self->{value_code_regex}))
	{
		croak "model number must be defined if you pass value_literal_regex or value_code_regex"
	}
	elsif (defined($self->{model}) && $self->{value_literal_regex} && $self->{value_code_regex})
	{
		croak "value_literal_regex and value_code_regex are mutually exclusive, use only one.";
	}
	else {} # model can be passed without a regex, but then value cannot be defined.


	if (defined($self->{value}) && $self->{value} !~ /^\d+\.?\d*|\d*\.?\d+$/)
	{
		croak("component value is not numeric: $self->{value}");
	}

	if ((defined($self->{value}) && !defined($self->{value_unit})) || 
		(!defined($self->{value}) && defined($self->{value_unit})))
	{
		croak "value must be defined when value_unit is defined, and vice-versa.";
	}

	return $self;
}

# Takes a port# (not an array index), so $component->z0(1) is the impedance at port1.
sub z0
{
	my ($self, $port) = @_;

	$port //= 1;

	my $z = $self->{z}[$port-1];

	croak "z0 is not defined for port $port" if (!defined $z);

	return $z;
}

sub n_ports { return shift->{n_ports}; }

sub model { return shift->{model}; }

sub value { return shift->{value}; }
sub value_unit { return shift->{value_unit}; }

sub comments { return @{ shift->{comments} // [] }; }

sub measurements { return @{ shift->{measurements} // [] }; }


sub get_measurement
{
	my ($self, $hz) = @_;

	my $prev;
	my $cur;
	for my $s (@{ $self->{measurements} })
	{
		$cur = $s;
		#print "hz=$hz cur=" . $cur->hz . "\n";
		if ($cur->hz >= $hz)
		{
			last;
		}

		$prev = $cur;
	}

	# Exact match, return this one:
	return $cur if ($cur->hz == $hz);

	# If a higher frequency than the last frequency was requested then
	# we cannot handle the request, return undef:
	return undef if ($prev == $cur);

	croak "unable to find Hz for evaluation at $hz" if (!defined $prev);

	my $prev_hz = $prev->hz;
	my $cur_hz = $cur->hz;


	#print "prev: $prev_hz=" . $prev->tostring('ma') . "\n";
	#print "cur : $cur_hz=" . $cur->tostring('ma') . "\n";

	my $hz_diff = $cur_hz - $prev_hz;

	my $hz_off = $hz - $prev_hz;

	# Return the complex matrix scaled $p percent of the way between $prev and $cur:
	# https://math.stackexchange.com/q/4451400/983059
	my $p = ($hz - $prev_hz)/$hz_diff;
	my $ret = (1-$p)*$prev->params + $p*$cur->params;

	# If interpolated, instatiate a new class instance
	# and make sure it is the same class type because
	# 'params' could be S-, Y-, Z-params, etc.
	return $cur->clone(ref($cur), params => $ret, hz => $hz);
}

sub parallel
{
	my ($self, $c) = @_;

	my $cnew = RF::Component->new(%$self, model => $self->model . "," . $c->model, value => undef );

	my @new_measurements;
	foreach my $m1 ($self->measurements)
	{
		my $m2 = $c->get_measurement($m1->hz);

		next if !defined $m2;

		my $p = $m1->parallel($m2);
		$p->{component} = $cnew;
		push @new_measurements, $p;
	}

	$cnew->{measurements} = \@new_measurements;

	return $cnew;
}

sub _parse_model_value_code
{
	my ($model, $regex, $unit) = @_;

	# The return of this function will scale the value to these well-known
	# unit types: pF|nF|uF|uH|nH|R|Ohm|Ohms
	# See industry naming conventions:
	#
	# - https://www.ttelectronics.com/TTElectronics/media/ProductFiles/ApplicationNotes/TN003-Methods-for-Coding-Resistor-Values-in-Part-Numbers.pdf
	# - https://electronics.stackexchange.com/questions/624513/inductor-and-capacitor-3-digit-exponent-value-codes-is-there-a-standard

	my %scale;
	if (lc($unit) eq 'pf') {
		$scale{R} = 1;
		$scale{N} = 1e3;
	}
	elsif (lc($unit) eq 'nf') {
		$scale{R} = 1e-3;
		$scale{N} = 1;
	}
	elsif (lc($unit) eq 'uf') {
		$scale{R} = 1e-6;
		$scale{N} = 1e-3;
	}
	elsif (lc($unit) eq 'uh') {
		$scale{R} = 1;
		$scale{N} = 1e-3;
	}
	elsif (lc($unit) eq 'nh') {
		$scale{R} = 1e3;
		$scale{N} = 1;
	}
	elsif (lc($unit) eq 'r' || lc($unit) =~ /ohms?/) {
		$scale{R} = 1;
		$scale{L} = 1e-3;
	}
	else
	{
		croak("unknown base unit for component (pF|nF|uF|uH|nH|R|Ohm|Ohms): $unit");
	}

	my $val;
	if ($model =~ /$regex/i && $1)
	{
		$val = $1;
	}
	else
	{
		carp "value_code_regex does not match: $model !~ $regex";
		return undef;
	}

	# Decimal point: 1R3 = 1.3 Ohms, 1N3 = 1.3 nH, etc.
	if ( $val =~ s/([A-Z])/./i )
	{
		my $scale = $1;
		croak "Undefined scaling type $scale for value: $val" if (!defined($scale{$scale}));

		# These are strings, so put leading/trailing zeros at the decimal:
		$val =~ s/^\./0./;
		$val =~ s/\.$/.0/;

		# Could be a string, so make it a float:
		$val *= $scale{$scale};
	}
	elsif ( $val =~ s/^(\d+)(\d)$/$1/ )
	{
		# "R" is always the base-unit scaler, so we have to multiply it in case
		# there is no alpha "decimal" point:
		$val = $1 * (10 ** $2) * $scale{R};
	}
	else
	{
		croak("$model: Value code could not be determined: '$val'");
	}

	return $val;
}

sub _parse_model_value_literal
{
	my ($model, $regex) = @_;
	my $val;

	if ( $model =~ /$regex/i && $1 )
	{
		$val = $1;
	}

	return $val;
}

