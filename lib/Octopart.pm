#!/usr/bin/perl

package Octopart;
use strict;

use JSON;
use LWP::UserAgent;
use Digest::MD5 qw(md5_hex);

use Data::Dumper;


sub get_part_stock
{
	my ($self, $part, %opts) = @_;
	
	my $p = $self->get_part_detail($part);

	return $self->_parse_part_stock($p);
}

sub _parse_part_stock
{
	my ($self, $resp, %opts) = @_;

	my @results;
	foreach my $r (@{ $resp->{data}{search}{results} })
	{
		$r = $r->{part};
		next if (!scalar(@{ $r->{specs} // [] }));

		my %part = (
			mfg => $r->{manufacturer}{name},
			specs => {
				map { 
					defined($_->{attribute}{shortname}) 
						? ($_->{attribute}{shortname} => $_->{value} . "$_->{units}")
						: (
							$_->{units} 
								? ($_->{units} => $_->{value})
								: ($_->{value} => 'true')
						)
				} @{ $r->{specs} }
			},
		);

		# Seller stock and MOQ pricing:
		my %ss;
		foreach my $s (@{ $r->{sellers} })
		{
			foreach my $o (@{ $s->{offers} })
			{
				$ss{$s->{company}{name}}{stock} = $o->{inventory_level};
				foreach my $p (@{ $o->{prices} })
				{
					next unless $p->{currency} eq 'USD';
					my $moq = $p->{quantity};

					$ss{$s->{company}{name}}{price_tier}{$p->{quantity}} = $p->{price};

					if (!defined($ss{$s->{company}{name}}{moq}) ||
						$ss{$s->{company}{name}}{moq} > $moq)
					{
						$ss{$s->{company}{name}}{moq} = $moq;
						$ss{$s->{company}{name}}{moq_price} = $p->{price}
					}
				}
			}
			
		}
		$part{sellers} = \%ss;

		push @results, \%part;
	}

	# Delete 
	foreach my $r (@results)
	{
		foreach my $c (keys %{ $r->{sellers} })
		{
			if ($r->{sellers}{$c}{stock} == 0
				|| !defined($r->{sellers}{$c}{price_tier})
				|| $r->{sellers}{$c}{moq} > 10
			   )
			{
				delete $r->{sellers}{$c};
			}
		}
	}

	return \@results;
}

sub new
{
	my ($class, %args) = @_;

	return bless(\%args, $class);
}

sub octo_query
{
	my ($self, $q) = @_;
	my $part = shift;


	my $content;

	my $h = md5_hex($q);
	my $hashfile = "$self->{cache}/$h.query";

	if ($self->{cache} && -e $hashfile)
	{
		system('mkdir', '-p', $self->{cache}) if (! -d $self->{cache});



		if (open(my $in, $hashfile))
		{
			local $/;
			$content = <$in>;
			close($in);
		}
	}
	else
	{
		my $ua = LWP::UserAgent->new( agent => 'mdf-perl/1.0',);

		if ($self->{ua_debug})
		{
			$ua->add_handler(
			  "request_send",
			  sub {
			    my $msg = shift;              # HTTP::Message
			    $msg->dump( maxlength => 0 ); # dump all/everything
			    return;
			  }
			);

			$ua->add_handler(
			  "response_done",
			  sub {
			    my $msg = shift;                # HTTP::Message
			    $msg->dump( maxlength => 512 ); # dump max 512 bytes (default is 512)
			    return;
			  }
			);
		}

		my $req = HTTP::Request->new('POST' => 'https://octopart.com/api/v4/endpoint',
			 HTTP::Headers->new(
				'Host' => 'octopart.com',
				'Content-Type' => 'application/json',
				'Accept' => 'application/json',
				'Accept-Encoding' => 'gzip, deflate',
				'token' => $self->{token},
				'DNT' => 1,
				'Origin' => 'https://octopart.com',
				),
			encode_json( { query => $q }));

		my $response = $ua->request($req);

		if (!$response->is_success) {
			die $response->status_line;
		}

		$content = $response->decoded_content;

		if ($self->{cache})
		{
			open(my $out, ">", $hashfile) or die "$hashfile: $!";
			print $out $content;
			close($out);
		}
	}

	return from_json($content);
}

sub get_part_detail
{
	my ($self, $part) = @_;

	return $self->octo_query( qq(
		query {
		  search(q: "$part", limit: 3) {
		    results {
		      part {
			manufacturer {
			  name
			}
			mpn
			specs {
			  units
			  value
			  display_value
			  attribute {
			    id
			    name
			    shortname
			    group
			  }
			}
			# Brokers are non-authorized dealers. See: https://octopart.com/authorized
			sellers(include_brokers: false) {
			  company {
			    name
			  }
			  offers {
			    click_url
			    inventory_level
			    prices {
			      price
			      currency
			      quantity
			    }
			  }
			}
		      }
		    }
		  }
		}
	));
}

1;
