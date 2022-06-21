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

		# In the AWR and Keysight example formats the %F line comes _after_
		# the "# HZ" line from the original s2p.  Fixing this requires hooking
		# the touchstone code somewhere or re-processing the MDF so since it works
		# in AWR we'll leave it for now.  If you have trouble with the MDF output
		# then swap the #HZ and %F lines.  If it works after the swap then we 
		# really need to fix this.
		# References:
		#    https://awrcorp.com/download/faq/english/docs/users_guide/data_file_formats.html#d0e5542
		#    https://edadocs.software.keysight.com/display/ads2009/Working+with+Data+Files#WorkingwithDataFiles-1135104
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
