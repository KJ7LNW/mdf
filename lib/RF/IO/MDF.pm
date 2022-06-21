package RF::IO::MDF;

use strict;
use warnings;
use 5.010;
use Carp;

use RF::Component;
use RF::IO::Touchstone;

sub mdf_save
{
	my ($filename, %opts) = @_;

	my ($components, $fmt, $type, $fd) = @opts{qw/components format type/};

	open(my $out, ">", $filename) or croak "$filename: $!";

	my $n_ports;
	my $n = 0;
	foreach my $c (@$components)
	{
		$n_ports //= $c->n_ports;

		croak "All files must have the same number of ports." if $n_ports != $c->n_ports;

		print $out sprintf('VAR %s="%d. %.2f %s"',
			$c->value_unit,
			$n,
			$c->value,
			$c->model) . "\n";

		print $out "BEGIN ACDATA\n";

		my $pct_line = "% F";
		for (my $i = 1; $i <= $n_ports; $i++)
		{
			for (my $j = 1; $j <= $n_ports; $j++)
			{
				$pct_line .= sprintf(" S[%d,%d](Complex)", $j, $i);
			}
		}
		
		print $out "$pct_line\n";

		RF::IO::Touchstone::snp_save_fd(component => $c, fd => $out, %opts);
		print $out "END\n\n";
		$n++;
	}

	close($out);
}

sub mdf_load
{
	croak 'not implemented';
}

1;
