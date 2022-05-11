#!/usr/bin/perl

use strict;

use JSON;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;


#my $resp = get_part('GQM1555C2DR90BB01D');
my $resp = get_part('RC0805FR-0710KL');


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
print Dumper \@results;

exit 0; ########################################################################################
sub get_part
{
my $cap = q(
{
  "data": {
    "search": {
      "results": [
        {
          "part": {
            "manufacturer": {
              "name": "Murata"
            },
            "mpn": "GQM1555C2DR90BB01D",
            "specs": [
              {
                "units": "fF",
                "value": "900"
              },
              {
                "units": "",
                "value": "0402"
              },
              {
                "units": "",
                "value": "C0G"
              },
              {
                "units": "µm",
                "value": "550"
              },
              {
                "units": "mm",
                "value": "1"
              },
              {
                "units": "",
                "value": "Production"
              },
              {
                "units": "",
                "value": "IN PRODUCTION"
              },
              {
                "units": "",
                "value": "Ceramic"
              },
              {
                "units": "°C",
                "value": "125"
              },
              {
                "units": "°C",
                "value": "-55"
              },
              {
                "units": "",
                "value": "Surface Mount"
              },
              {
                "units": "",
                "value": "Compliant"
              },
              {
                "units": "ppm/°C",
                "value": "30"
              },
              {
                "units": "µm",
                "value": "500"
              },
              {
                "units": "V",
                "value": "200"
              },
              {
                "units": "V",
                "value": "200"
              },
              {
                "units": "µm",
                "value": "500"
              }
            ],
            "sellers": [
              {
                "company": {
                  "name": "Avnet"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&c=1&country=US&ct=offers&ppid=71326755&sid=5822&sig=030f73d&vpid=755012462",
                    "inventory_level": 0,
                    "prices": [
                      {
                        "price": 0.14628,
                        "currency": "USD",
                        "quantity": 10000
                      },
                      {
                        "price": 0.14204,
                        "currency": "USD",
                        "quantity": 20000
                      },
                      {
                        "price": 0.1378,
                        "currency": "USD",
                        "quantity": 40000
                      }
                    ]
                  }
                ]
              },
              {
                "company": {
                  "name": "Mouser"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&c=1&country=US&ct=offers&ppid=71326755&sid=2401&sig=0fcade6&vpid=480418367",
                    "inventory_level": 0,
                    "prices": [
                      {
                        "price": 0.68,
                        "currency": "USD",
                        "quantity": 1
                      },
                      {
                        "price": 0.479,
                        "currency": "USD",
                        "quantity": 10
                      },
                      {
                        "price": 0.479,
                        "currency": "USD",
                        "quantity": 50
                      },
                      {
                        "price": 0.315,
                        "currency": "USD",
                        "quantity": 100
                      },
                      {
                        "price": 0.199,
                        "currency": "USD",
                        "quantity": 1000
                      },
                      {
                        "price": 0.163,
                        "currency": "USD",
                        "quantity": 10000
                      }
                    ]
                  }
                ]
              },
              {
                "company": {
                  "name": "Digi-Key"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&c=1&country=US&ct=offers&ppid=71326755&sid=459&sig=09b68a3&vpid=253362330",
                    "inventory_level": 0,
                    "prices": [
                      {
                        "price": 0.16324,
                        "currency": "USD",
                        "quantity": 10000
                      }
                    ]
                  }
                ]
              },
              {
                "company": {
                  "name": "Farnell"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&c=1&country=US&ct=offers&ppid=71326755&sid=819&sig=06605bc&vpid=530790739",
                    "inventory_level": 0,
                    "prices": [
                      {
                        "price": 0.124,
                        "currency": "GBP",
                        "quantity": 10000
                      }
                    ]
                  }
                ]
              }
            ]
          }
        },
        {
          "part": {
            "manufacturer": {
              "name": "Murata"
            },
            "mpn": "GQM1555C2DR90BB01J",
            "specs": [
              {
                "units": "fF",
                "value": "900"
              },
              {
                "units": "",
                "value": "0402"
              },
              {
                "units": "µm",
                "value": "550"
              },
              {
                "units": "mm",
                "value": "1"
              },
              {
                "units": "",
                "value": "Production"
              },
              {
                "units": "",
                "value": "IN PRODUCTION"
              },
              {
                "units": "",
                "value": "Ceramic"
              },
              {
                "units": "°C",
                "value": "125"
              },
              {
                "units": "°C",
                "value": "-55"
              },
              {
                "units": "ppm/°C",
                "value": "30"
              },
              {
                "units": "µm",
                "value": "500"
              },
              {
                "units": "V",
                "value": "200"
              },
              {
                "units": "V",
                "value": "200"
              },
              {
                "units": "µm",
                "value": "500"
              }
            ],
            "sellers": [
              {
                "company": {
                  "name": "Avnet"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&c=1&country=US&ct=offers&ppid=96287611&sid=5822&sig=0ced32f&vpid=755012463",
                    "inventory_level": 0,
                    "prices": [
                      {
                        "price": 0.14204,
                        "currency": "USD",
                        "quantity": 50000
                      }
                    ]
                  }
                ]
              }
            ]
          }
        },
        {
          "part": {
            "manufacturer": {
              "name": "Murata"
            },
            "mpn": "GQM1555C2DR90BB01W",
            "specs": [
              {
                "units": "fF",
                "value": "900"
              },
              {
                "units": "",
                "value": "0402"
              },
              {
                "units": "µm",
                "value": "550"
              },
              {
                "units": "mm",
                "value": "1"
              },
              {
                "units": "",
                "value": "Production"
              },
              {
                "units": "",
                "value": "IN PRODUCTION"
              },
              {
                "units": "",
                "value": "Ceramic"
              },
              {
                "units": "°C",
                "value": "125"
              },
              {
                "units": "°C",
                "value": "-55"
              },
              {
                "units": "ppm/°C",
                "value": "30"
              },
              {
                "units": "µm",
                "value": "500"
              },
              {
                "units": "V",
                "value": "200"
              },
              {
                "units": "V",
                "value": "200"
              },
              {
                "units": "µm",
                "value": "500"
              }
            ],
            "sellers": []
          }
        }
      ]
    }
  }
});

my $res = q(
{
  "data": {
    "search": {
      "results": [
        {
          "part": {
            "manufacturer": {
              "name": "Yageo"
            },
            "mpn": "RC0805FR-0710KL",
            "specs": [
              {
                "units": "",
                "value": "0805",
                "display_value": "0805",
                "attribute": {
                  "id": "842",
                  "name": "Case/Package",
                  "shortname": "case_package",
                  "group": "Physical"
                }
              },
              {
                "units": "",
                "value": "0805",
                "display_value": "0805",
                "attribute": {
                  "id": "572",
                  "name": "Case Code (Imperial)",
                  "shortname": "casecode_imperial_",
                  "group": "Physical"
                }
              },
              {
                "units": "",
                "value": "2012",
                "display_value": "2012",
                "attribute": {
                  "id": "769",
                  "name": "Case Code (Metric)",
                  "shortname": "casecode_metric_",
                  "group": "Physical"
                }
              },
              {
                "units": "",
                "value": "Thick Film",
                "display_value": "Thick Film",
                "attribute": {
                  "id": "371",
                  "name": "Composition",
                  "shortname": "composition",
                  "group": "Technical"
                }
              },
              {
                "units": "mm",
                "value": "1.25",
                "display_value": "1.25 mm",
                "attribute": {
                  "id": "291",
                  "name": "Depth",
                  "shortname": "depth",
                  "group": "Dimensions"
                }
              },
              {
                "units": "",
                "value": "Moisture Resistant",
                "display_value": "Moisture Resistant",
                "attribute": {
                  "id": "587",
                  "name": "Features",
                  "shortname": "features",
                  "group": "Technical"
                }
              },
              {
                "units": "µm",
                "value": "500",
                "display_value": "500 µm",
                "attribute": {
                  "id": "468",
                  "name": "Height",
                  "shortname": "height",
                  "group": "Dimensions"
                }
              },
              {
                "units": "",
                "value": "Lead Free",
                "display_value": "Lead Free",
                "attribute": {
                  "id": "724",
                  "name": "Lead Free",
                  "shortname": "leadfree",
                  "group": "Compliance"
                }
              },
              {
                "units": "mm",
                "value": "2",
                "display_value": "2 mm",
                "attribute": {
                  "id": "755",
                  "name": "Length",
                  "shortname": "length",
                  "group": "Dimensions"
                }
              },
              {
                "units": "°C",
                "value": "155",
                "display_value": "155 °C",
                "attribute": {
                  "id": "849",
                  "name": "Max Operating Temperature",
                  "shortname": "maxoperatingtemperature",
                  "group": "Technical"
                }
              },
              {
                "units": "mW",
                "value": "125",
                "display_value": "125 mW",
                "attribute": {
                  "id": "663",
                  "name": "Max Power Dissipation",
                  "shortname": "maxpowerdissipation",
                  "group": "Technical"
                }
              },
              {
                "units": "",
                "value": "Not",
                "display_value": "Not",
                "attribute": {
                  "id": "478",
                  "name": "Military Standard",
                  "shortname": "militarystandard",
                  "group": "Technical"
                }
              },
              {
                "units": "°C",
                "value": "-55",
                "display_value": "-55 °C",
                "attribute": {
                  "id": "456",
                  "name": "Min Operating Temperature",
                  "shortname": "minoperatingtemperature",
                  "group": "Technical"
                }
              },
              {
                "units": "",
                "value": "Surface Mount",
                "display_value": "Surface Mount",
                "attribute": {
                  "id": "773",
                  "name": "Mount",
                  "shortname": "mount",
                  "group": "Physical"
                }
              },
              {
                "units": "",
                "value": "2",
                "display_value": "2",
                "attribute": {
                  "id": "329",
                  "name": "Number of Pins",
                  "shortname": "numberofpins",
                  "group": "Physical"
                }
              },
              {
                "units": "",
                "value": "2",
                "display_value": "2",
                "attribute": {
                  "id": "784",
                  "name": "Number of Terminations",
                  "shortname": "numberofterminations",
                  "group": "Technical"
                }
              },
              {
                "units": "",
                "value": "Tape & Reel",
                "display_value": "Tape & Reel",
                "attribute": {
                  "id": "412",
                  "name": "Packaging",
                  "shortname": "packaging",
                  "group": "Technical"
                }
              },
              {
                "units": "mW",
                "value": "125",
                "display_value": "125 mW",
                "attribute": {
                  "id": "257",
                  "name": "Power Rating",
                  "shortname": "powerrating",
                  "group": "Technical"
                }
              },
              {
                "units": "",
                "value": "No SVHC",
                "display_value": "No SVHC",
                "attribute": {
                  "id": "683",
                  "name": "REACH SVHC",
                  "shortname": "reachsvhc",
                  "group": "Compliance"
                }
              },
              {
                "units": "kΩ",
                "value": "10",
                "display_value": "10 kΩ",
                "attribute": {
                  "id": "440",
                  "name": "Resistance",
                  "shortname": "resistance",
                  "group": "Technical"
                }
              },
              {
                "units": "",
                "value": "Compliant",
                "display_value": "Compliant",
                "attribute": {
                  "id": "610",
                  "name": "RoHS",
                  "shortname": "rohs",
                  "group": "Compliance"
                }
              },
              {
                "units": ", ",
                "value": "8533210045, 8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|85",
                "display_value": "8533210045, 8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|8533210045|85",
                "attribute": {
                  "id": "973",
                  "name": "Schedule B",
                  "shortname": "scheduleB",
                  "group": "Technical"
                }
              },
              {
                "units": "ppm/°C",
                "value": "100",
                "display_value": "100 ppm/°C",
                "attribute": {
                  "id": "321",
                  "name": "Temperature Coefficient",
                  "shortname": "temperaturecoefficient",
                  "group": "Technical"
                }
              },
              {
                "units": "",
                "value": "SMD/SMT",
                "display_value": "SMD/SMT",
                "attribute": {
                  "id": "717",
                  "name": "Termination",
                  "shortname": "termination",
                  "group": "Technical"
                }
              },
              {
                "units": "%",
                "value": "1",
                "display_value": "1 %",
                "attribute": {
                  "id": "342",
                  "name": "Tolerance",
                  "shortname": "tolerance",
                  "group": "Technical"
                }
              },
              {
                "units": "V",
                "value": "150",
                "display_value": "150 V",
                "attribute": {
                  "id": "457",
                  "name": "Voltage Rating",
                  "shortname": "voltagerating",
                  "group": "Technical"
                }
              },
              {
                "units": "V",
                "value": "150",
                "display_value": "150 V",
                "attribute": {
                  "id": "340",
                  "name": "Voltage Rating (AC)",
                  "shortname": "voltagerating_ac_",
                  "group": "Technical"
                }
              },
              {
                "units": "mm",
                "value": "1.2446",
                "display_value": "1.2446 mm",
                "attribute": {
                  "id": "576",
                  "name": "Width",
                  "shortname": "width",
                  "group": "Dimensions"
                }
              }
            ],
            "sellers": [
              {
                "company": {
                  "name": "Arrow Electronics"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=1106&sig=0f57c9a&vpid=486429293",
                    "inventory_level": 315000,
                    "prices": [
                      {
                        "price": 0.0055,
                        "currency": "USD",
                        "quantity": 5000
                      }
                    ]
                  }
                ]
              },
              {
                "company": {
                  "name": "RS Components"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=10022&sig=0e09263&vpid=575956787",
                    "inventory_level": 435000,
                    "prices": [
                      {
                        "price": 0.007,
                        "currency": "USD",
                        "quantity": 5000
                      },
                      {
                        "price": 0.005,
                        "currency": "GBP",
                        "quantity": 5000
                      }
                    ]
                  }
                ]
              },
              {
                "company": {
                  "name": "Newark"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=2402&sig=0d5b6a2&vpid=480760968",
                    "inventory_level": 315000,
                    "prices": [
                      {
                        "price": 0.003,
                        "currency": "USD",
                        "quantity": 1
                      },
                      {
                        "price": 0.003,
                        "currency": "USD",
                        "quantity": 5000
                      }
                    ]
                  },
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=2402&sig=0add978&vpid=20052559",
                    "inventory_level": 84589,
                    "prices": [
                      {
                        "price": 0.1,
                        "currency": "USD",
                        "quantity": 1
                      },
                      {
                        "price": 0.029,
                        "currency": "USD",
                        "quantity": 10
                      },
                      {
                        "price": 0.023,
                        "currency": "USD",
                        "quantity": 25
                      },
                      {
                        "price": 0.018,
                        "currency": "USD",
                        "quantity": 50
                      },
                      {
                        "price": 0.012,
                        "currency": "USD",
                        "quantity": 100
                      }
                    ]
                  },
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=2402&sig=0845ff0&vpid=115424325",
                    "inventory_level": 2552,
                    "prices": [
                      {
                        "price": 0.145,
                        "currency": "USD",
                        "quantity": 1
                      },
                      {
                        "price": 0.073,
                        "currency": "USD",
                        "quantity": 25
                      },
                      {
                        "price": 0.046,
                        "currency": "USD",
                        "quantity": 50
                      },
                      {
                        "price": 0.033,
                        "currency": "USD",
                        "quantity": 100
                      },
                      {
                        "price": 0.025,
                        "currency": "USD",
                        "quantity": 250
                      },
                      {
                        "price": 0.019,
                        "currency": "USD",
                        "quantity": 500
                      },
                      {
                        "price": 0.014,
                        "currency": "USD",
                        "quantity": 1000
                      },
                      {
                        "price": 0.011,
                        "currency": "USD",
                        "quantity": 2500
                      }
                    ]
                  }
                ]
              },
              {
                "company": {
                  "name": "Future Electronics"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=2454&sig=0a394db&vpid=416981991",
                    "inventory_level": 10965000,
                    "prices": [
                      {
                        "price": 0.0086,
                        "currency": "USD",
                        "quantity": 5000
                      }
                    ]
                  }
                ]
              },
              {
                "company": {
                  "name": "TTI"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=950&sig=0e7354a&vpid=241765704",
                    "inventory_level": 14745000,
                    "prices": [
                      {
                        "price": 0.0046,
                        "currency": "USD",
                        "quantity": 5000
                      }
                    ]
                  }
                ]
              },
              {
                "company": {
                  "name": "Mouser"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=2401&sig=0ce41c7&vpid=114830364",
                    "inventory_level": 5912588,
                    "prices": [
                      {
                        "price": 0.1,
                        "currency": "USD",
                        "quantity": 1
                      },
                      {
                        "price": 0.029,
                        "currency": "USD",
                        "quantity": 10
                      },
                      {
                        "price": 0.029,
                        "currency": "USD",
                        "quantity": 50
                      },
                      {
                        "price": 0.012,
                        "currency": "USD",
                        "quantity": 100
                      },
                      {
                        "price": 0.006,
                        "currency": "USD",
                        "quantity": 1000
                      },
                      {
                        "price": 0.005,
                        "currency": "USD",
                        "quantity": 2500
                      },
                      {
                        "price": 0.003,
                        "currency": "USD",
                        "quantity": 5000
                      },
                      {
                        "price": 0.003,
                        "currency": "USD",
                        "quantity": 10000
                      }
                    ]
                  }
                ]
              },
              {
                "company": {
                  "name": "Digi-Key"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=459&sig=02e3450&vpid=114983200",
                    "inventory_level": 4046192,
                    "prices": [
                      {
                        "price": 0.1,
                        "currency": "USD",
                        "quantity": 1
                      },
                      {
                        "price": 0.042,
                        "currency": "USD",
                        "quantity": 10
                      },
                      {
                        "price": 0.017,
                        "currency": "USD",
                        "quantity": 100
                      },
                      {
                        "price": 0.00762,
                        "currency": "USD",
                        "quantity": 1000
                      },
                      {
                        "price": 0.00661,
                        "currency": "USD",
                        "quantity": 2500
                      }
                    ]
                  },
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=459&sig=04eb09a&vpid=114983201",
                    "inventory_level": 4046192,
                    "prices": [
                      {
                        "price": 0.1,
                        "currency": "USD",
                        "quantity": 1
                      },
                      {
                        "price": 0.042,
                        "currency": "USD",
                        "quantity": 10
                      },
                      {
                        "price": 0.017,
                        "currency": "USD",
                        "quantity": 100
                      },
                      {
                        "price": 0.00762,
                        "currency": "USD",
                        "quantity": 1000
                      },
                      {
                        "price": 0.00661,
                        "currency": "USD",
                        "quantity": 2500
                      }
                    ]
                  },
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=459&sig=0a63e25&vpid=115141490",
                    "inventory_level": 4046192,
                    "prices": [
                      {
                        "price": 0.00546,
                        "currency": "USD",
                        "quantity": 5000
                      }
                    ]
                  }
                ]
              },
              {
                "company": {
                  "name": "Rutronik"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=18993&sig=0521083&vpid=114985233",
                    "inventory_level": 2015000,
                    "prices": [
                      {
                        "price": 0.00317,
                        "currency": "EUR",
                        "quantity": 5000
                      },
                      {
                        "price": 0.0034,
                        "currency": "USD",
                        "quantity": 5000
                      },
                      {
                        "price": 0.0025,
                        "currency": "EUR",
                        "quantity": 15000
                      },
                      {
                        "price": 0.0026,
                        "currency": "USD",
                        "quantity": 15000
                      },
                      {
                        "price": 0.00237,
                        "currency": "EUR",
                        "quantity": 25000
                      },
                      {
                        "price": 0.0025,
                        "currency": "USD",
                        "quantity": 25000
                      },
                      {
                        "price": 0.00233,
                        "currency": "EUR",
                        "quantity": 150000
                      },
                      {
                        "price": 0.0025,
                        "currency": "USD",
                        "quantity": 150000
                      }
                    ]
                  }
                ]
              },
              {
                "company": {
                  "name": "Verical"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=5489&sig=0df40b3&vpid=803896193",
                    "inventory_level": 315000,
                    "prices": [
                      {
                        "price": 0.0055,
                        "currency": "USD",
                        "quantity": 5000
                      }
                    ]
                  }
                ]
              },
              {
                "company": {
                  "name": "Avnet"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&c=1&country=US&ct=offers&ppid=40301103&sid=5822&sig=0bc43d7&vpid=762071737",
                    "inventory_level": 0,
                    "prices": [
                      {
                        "price": 0.00227,
                        "currency": "USD",
                        "quantity": 5000
                      },
                      {
                        "price": 0.00224,
                        "currency": "USD",
                        "quantity": 10000
                      },
                      {
                        "price": 0.00217,
                        "currency": "USD",
                        "quantity": 20000
                      }
                    ]
                  }
                ]
              },
              {
                "company": {
                  "name": "Farnell"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=819&sig=014db97&vpid=480514650",
                    "inventory_level": 365000,
                    "prices": [
                      {
                        "price": 0.003,
                        "currency": "GBP",
                        "quantity": 5000
                      },
                      {
                        "price": 0.0029,
                        "currency": "GBP",
                        "quantity": 25000
                      }
                    ]
                  },
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=819&sig=0e3a2df&vpid=508509789",
                    "inventory_level": 85269,
                    "prices": [
                      {
                        "price": 0.022,
                        "currency": "GBP",
                        "quantity": 10
                      },
                      {
                        "price": 0.009,
                        "currency": "GBP",
                        "quantity": 100
                      },
                      {
                        "price": 0.0065,
                        "currency": "GBP",
                        "quantity": 500
                      },
                      {
                        "price": 0.004,
                        "currency": "GBP",
                        "quantity": 1000
                      },
                      {
                        "price": 0.0039,
                        "currency": "GBP",
                        "quantity": 2500
                      }
                    ]
                  },
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=819&sig=05e8970&vpid=540533804",
                    "inventory_level": 85269,
                    "prices": [
                      {
                        "price": 0.0065,
                        "currency": "GBP",
                        "quantity": 500
                      },
                      {
                        "price": 0.004,
                        "currency": "GBP",
                        "quantity": 1000
                      },
                      {
                        "price": 0.0039,
                        "currency": "GBP",
                        "quantity": 2500
                      }
                    ]
                  },
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=819&sig=0de5260&vpid=209561686",
                    "inventory_level": 2552,
                    "prices": [
                      {
                        "price": 0.0091,
                        "currency": "GBP",
                        "quantity": 5000
                      }
                    ]
                  },
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=819&sig=0fa9b2e&vpid=532285470",
                    "inventory_level": 0,
                    "prices": [
                      {
                        "price": 0.0091,
                        "currency": "GBP",
                        "quantity": 5000
                      },
                      {
                        "price": 0.0066,
                        "currency": "GBP",
                        "quantity": 10000
                      }
                    ]
                  }
                ]
              },
              {
                "company": {
                  "name": "element14 APAC"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=11744&sig=010ca0f&vpid=480532346",
                    "inventory_level": 364500,
                    "prices": [
                      {
                        "price": 0.008,
                        "currency": "SGD",
                        "quantity": 5000
                      }
                    ]
                  },
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=11744&sig=0cb93ae&vpid=480880130",
                    "inventory_level": 157653,
                    "prices": [
                      {
                        "price": 0.043,
                        "currency": "SGD",
                        "quantity": 10
                      },
                      {
                        "price": 0.018,
                        "currency": "SGD",
                        "quantity": 100
                      },
                      {
                        "price": 0.009,
                        "currency": "SGD",
                        "quantity": 1000
                      },
                      {
                        "price": 0.008,
                        "currency": "SGD",
                        "quantity": 2500
                      }
                    ]
                  },
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=11744&sig=02f7d85&vpid=537583848",
                    "inventory_level": 157653,
                    "prices": [
                      {
                        "price": 0.018,
                        "currency": "SGD",
                        "quantity": 500
                      },
                      {
                        "price": 0.009,
                        "currency": "SGD",
                        "quantity": 1000
                      },
                      {
                        "price": 0.008,
                        "currency": "SGD",
                        "quantity": 2500
                      }
                    ]
                  },
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=11744&sig=0bb6934&vpid=179884189",
                    "inventory_level": 2552,
                    "prices": [
                      {
                        "price": 0.148,
                        "currency": "SGD",
                        "quantity": 1
                      },
                      {
                        "price": 0.043,
                        "currency": "SGD",
                        "quantity": 10
                      },
                      {
                        "price": 0.018,
                        "currency": "SGD",
                        "quantity": 100
                      },
                      {
                        "price": 0.009,
                        "currency": "SGD",
                        "quantity": 1000
                      },
                      {
                        "price": 0.008,
                        "currency": "SGD",
                        "quantity": 2500
                      },
                      {
                        "price": 0.007,
                        "currency": "SGD",
                        "quantity": 5000
                      }
                    ]
                  },
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=11744&sig=04ba7aa&vpid=541915181",
                    "inventory_level": 0,
                    "prices": [
                      {
                        "price": 19.92,
                        "currency": "SGD",
                        "quantity": 1
                      },
                      {
                        "price": 17.85,
                        "currency": "SGD",
                        "quantity": 5
                      },
                      {
                        "price": 15.9,
                        "currency": "SGD",
                        "quantity": 10
                      }
                    ]
                  },
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=11744&sig=0b93c61&vpid=532416374",
                    "inventory_level": 0,
                    "prices": [
                      {
                        "price": 0.009,
                        "currency": "SGD",
                        "quantity": 5000
                      }
                    ]
                  }
                ]
              },
              {
                "company": {
                  "name": "Avnet Europe"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=15544&sig=088d736&vpid=115144696",
                    "inventory_level": 4505000,
                    "prices": [
                      {
                        "price": 0.00196,
                        "currency": "EUR",
                        "quantity": 5000
                      },
                      {
                        "price": 0.00175,
                        "currency": "EUR",
                        "quantity": 10000
                      },
                      {
                        "price": 0.0017,
                        "currency": "EUR",
                        "quantity": 20000
                      },
                      {
                        "price": 0.00165,
                        "currency": "EUR",
                        "quantity": 30000
                      },
                      {
                        "price": 0.00163,
                        "currency": "EUR",
                        "quantity": 40000
                      },
                      {
                        "price": 0.00156,
                        "currency": "EUR",
                        "quantity": 50000
                      },
                      {
                        "price": 0.00153,
                        "currency": "EUR",
                        "quantity": 500000
                      }
                    ]
                  }
                ]
              },
              {
                "company": {
                  "name": "Arrow.cn"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=28928&sig=0263c53&vpid=652876005",
                    "inventory_level": 315000,
                    "prices": [
                      {
                        "price": 0.0423,
                        "currency": "CNY",
                        "quantity": 5000
                      },
                      {
                        "price": 0.0055,
                        "currency": "USD",
                        "quantity": 5000
                      }
                    ]
                  }
                ]
              },
              {
                "company": {
                  "name": "TTI Europe"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=27804&sig=04f2893&vpid=766418885",
                    "inventory_level": 10570000,
                    "prices": [
                      {
                        "price": 0.0069,
                        "currency": "EUR",
                        "quantity": 5000
                      },
                      {
                        "price": 0.00375,
                        "currency": "EUR",
                        "quantity": 10000
                      },
                      {
                        "price": 0.00367,
                        "currency": "EUR",
                        "quantity": 25000
                      }
                    ]
                  }
                ]
              },
              {
                "company": {
                  "name": "SOS electronic"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=26036&sig=07885a4&vpid=225579794",
                    "inventory_level": 45000,
                    "prices": [
                      {
                        "price": 0.0015,
                        "currency": "EUR",
                        "quantity": 5000
                      }
                    ]
                  }
                ]
              },
              {
                "company": {
                  "name": "GreenChips"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=28947&sig=06908aa&vpid=768557953",
                    "inventory_level": 209773,
                    "prices": []
                  }
                ]
              },
              {
                "company": {
                  "name": "AGS Devices"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=28783&sig=0ddfcfd&vpid=608943858",
                    "inventory_level": 3033,
                    "prices": []
                  }
                ]
              },
              {
                "company": {
                  "name": "Win Source Electronics"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=21513&sig=090ce18&vpid=785654254",
                    "inventory_level": 15000,
                    "prices": [
                      {
                        "price": 0.004,
                        "currency": "USD",
                        "quantity": 12500
                      },
                      {
                        "price": 0.003,
                        "currency": "USD",
                        "quantity": 33335
                      },
                      {
                        "price": 0.003,
                        "currency": "USD",
                        "quantity": 50000
                      },
                      {
                        "price": 0.003,
                        "currency": "USD",
                        "quantity": 66670
                      },
                      {
                        "price": 0.003,
                        "currency": "USD",
                        "quantity": 83335
                      },
                      {
                        "price": 0.003,
                        "currency": "USD",
                        "quantity": 100000
                      }
                    ]
                  }
                ]
              },
              {
                "company": {
                  "name": "NAC Semi"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=11310&sig=08302e5&vpid=414145106",
                    "inventory_level": 13610000,
                    "prices": [
                      {
                        "price": 0.0137,
                        "currency": "USD",
                        "quantity": 15000
                      },
                      {
                        "price": 0.0126,
                        "currency": "USD",
                        "quantity": 13610000
                      }
                    ]
                  }
                ]
              },
              {
                "company": {
                  "name": "Component Sense"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=13184&sig=0c6de51&vpid=137243495",
                    "inventory_level": 55000,
                    "prices": [
                      {
                        "price": 0.02,
                        "currency": "USD",
                        "quantity": 1250
                      },
                      {
                        "price": 0.018,
                        "currency": "USD",
                        "quantity": 5000
                      },
                      {
                        "price": 0.016,
                        "currency": "USD",
                        "quantity": 10000
                      }
                    ]
                  }
                ]
              },
              {
                "company": {
                  "name": "Voyager Components"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=2424&sig=024c203&vpid=590662332",
                    "inventory_level": 3470,
                    "prices": [
                      {
                        "price": 0.6,
                        "currency": "USD",
                        "quantity": 1
                      },
                      {
                        "price": 0.51005,
                        "currency": "USD",
                        "quantity": 347
                      },
                      {
                        "price": 0.45005,
                        "currency": "USD",
                        "quantity": 1214
                      },
                      {
                        "price": 0.39005,
                        "currency": "USD",
                        "quantity": 1907
                      },
                      {
                        "price": 0.36,
                        "currency": "USD",
                        "quantity": 3470
                      }
                    ]
                  }
                ]
              },
              {
                "company": {
                  "name": "Ameya360"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=27291&sig=0fd04be&vpid=409666064",
                    "inventory_level": 50000,
                    "prices": []
                  }
                ]
              },
              {
                "company": {
                  "name": "Eastek"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=27349&sig=02383f6&vpid=804354885",
                    "inventory_level": 4755000,
                    "prices": [
                      {
                        "price": 0.0021,
                        "currency": "USD",
                        "quantity": 5000
                      }
                    ]
                  }
                ]
              },
              {
                "company": {
                  "name": "Semi Source"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=28295&sig=0bd9350&vpid=495403690",
                    "inventory_level": 618,
                    "prices": []
                  }
                ]
              },
              {
                "company": {
                  "name": "Freelance Electronics"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=13062&sig=00c3572&vpid=455503182",
                    "inventory_level": 4200,
                    "prices": [
                      {
                        "price": 0.01531,
                        "currency": "USD",
                        "quantity": 1
                      },
                      {
                        "price": 0.01218,
                        "currency": "USD",
                        "quantity": 883
                      },
                      {
                        "price": 0.01148,
                        "currency": "USD",
                        "quantity": 1765
                      },
                      {
                        "price": 0.01067,
                        "currency": "USD",
                        "quantity": 2647
                      },
                      {
                        "price": 0.00951,
                        "currency": "USD",
                        "quantity": 3529
                      }
                    ]
                  }
                ]
              },
              {
                "company": {
                  "name": "Demsay Elektronik"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=29033&sig=05652be&vpid=711576576",
                    "inventory_level": 142,
                    "prices": []
                  }
                ]
              },
              {
                "company": {
                  "name": "Cytech Systems"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=28703&sig=089307d&vpid=806256595",
                    "inventory_level": 1000,
                    "prices": []
                  }
                ]
              },
              {
                "company": {
                  "name": "ComS.I.T. Europe - USA - Asia"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=9966&sig=09e3557&vpid=674528576",
                    "inventory_level": 20000,
                    "prices": []
                  }
                ]
              },
              {
                "company": {
                  "name": "IBS Electronics"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=2452&sig=02ac6aa&vpid=122365867",
                    "inventory_level": 5000,
                    "prices": [
                      {
                        "price": 0.18,
                        "currency": "USD",
                        "quantity": 1
                      }
                    ]
                  }
                ]
              },
              {
                "company": {
                  "name": "Sourcengine"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&c=1&country=US&ct=offers&ppid=40301103&sid=29311&sig=08eb6ee&vpid=807192477",
                    "inventory_level": 4505000,
                    "prices": []
                  }
                ]
              },
              {
                "company": {
                  "name": "CXDA Electronics"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=29334&sig=0b6db06&vpid=787737253",
                    "inventory_level": 177141,
                    "prices": []
                  }
                ]
              },
              {
                "company": {
                  "name": "Utmel Electronic"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=29008&sig=0f93f0e&vpid=618311202",
                    "inventory_level": 4029,
                    "prices": []
                  }
                ]
              },
              {
                "company": {
                  "name": "Flip Electronics (Recertified)"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=29095&sig=0309bf5&vpid=806659244",
                    "inventory_level": 1520000,
                    "prices": []
                  }
                ]
              },
              {
                "company": {
                  "name": "Epos Electronics"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=31329&sig=018c04f&vpid=810721422",
                    "inventory_level": 17000,
                    "prices": []
                  }
                ]
              },
              {
                "company": {
                  "name": "IBuyXS"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&c=1&country=US&ct=offers&ppid=40301103&sid=28982&sig=061ce75&vpid=781220709",
                    "inventory_level": 17800,
                    "prices": []
                  }
                ]
              },
              {
                "company": {
                  "name": "NetSource Technology"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=13909&sig=0fd5343&vpid=646951080",
                    "inventory_level": 3648,
                    "prices": []
                  }
                ]
              },
              {
                "company": {
                  "name": "Quest"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=2412&sig=001089c&vpid=116520165",
                    "inventory_level": 99165,
                    "prices": [
                      {
                        "price": 0.032,
                        "currency": "USD",
                        "quantity": 1
                      },
                      {
                        "price": 0.02,
                        "currency": "USD",
                        "quantity": 157
                      },
                      {
                        "price": 0.012,
                        "currency": "USD",
                        "quantity": 1001
                      },
                      {
                        "price": 0.006,
                        "currency": "USD",
                        "quantity": 4168
                      },
                      {
                        "price": 0.0052,
                        "currency": "USD",
                        "quantity": 33334
                      },
                      {
                        "price": 0.0048,
                        "currency": "USD",
                        "quantity": 96155
                      }
                    ]
                  }
                ]
              },
              {
                "company": {
                  "name": "Rotakorn"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=24049&sig=0956be9&vpid=278114510",
                    "inventory_level": 120000,
                    "prices": []
                  }
                ]
              },
              {
                "company": {
                  "name": "Florida Circuit"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=12378&sig=031522f&vpid=801312491",
                    "inventory_level": 292,
                    "prices": []
                  }
                ]
              },
              {
                "company": {
                  "name": "Extreme Components"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=29167&sig=001f9a5&vpid=808717698",
                    "inventory_level": 5,
                    "prices": []
                  }
                ]
              },
              {
                "company": {
                  "name": "Select Technology"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=11359&sig=0c5340e&vpid=193013519",
                    "inventory_level": -3,
                    "prices": []
                  }
                ]
              },
              {
                "company": {
                  "name": "Classic Components"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&c=1&country=US&ct=offers&ppid=40301103&sid=26773&sig=0319995&vpid=244103268",
                    "inventory_level": 2723,
                    "prices": []
                  }
                ]
              },
              {
                "company": {
                  "name": "Sourceability"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=28281&sig=06f1769&vpid=495278533",
                    "inventory_level": 1249521,
                    "prices": []
                  }
                ]
              },
              {
                "company": {
                  "name": "Abacus Technologies"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=25917&sig=08e8b74&vpid=195845881",
                    "inventory_level": 0,
                    "prices": []
                  }
                ]
              },
              {
                "company": {
                  "name": "Component Electronics"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=17279&sig=07ea1ce&vpid=576947762",
                    "inventory_level": 6800,
                    "prices": [
                      {
                        "price": 0.23077,
                        "currency": "USD",
                        "quantity": 1
                      }
                    ]
                  }
                ]
              },
              {
                "company": {
                  "name": "TME"
                },
                "offers": [
                  {
                    "click_url": "https://octopart.com/click/track?ai4=168975&country=US&ct=offers&ppid=40301103&sid=1532&sig=0c33893&vpid=116114178",
                    "inventory_level": 440201,
                    "prices": [
                      {
                        "price": 0.01461,
                        "currency": "EUR",
                        "quantity": 100
                      },
                      {
                        "price": 0.00427,
                        "currency": "EUR",
                        "quantity": 1000
                      },
                      {
                        "price": 0.00228,
                        "currency": "EUR",
                        "quantity": 5000
                      },
                      {
                        "price": 0.00213,
                        "currency": "EUR",
                        "quantity": 15000
                      },
                      {
                        "price": 0.00206,
                        "currency": "EUR",
                        "quantity": 50000
                      }
                    ]
                  }
                ]
              }
            ]
          }
        },
        {
          "part": {
            "manufacturer": {
              "name": "Yageo"
            },
            "mpn": "RC0805-FR-07-10KL",
            "specs": [],
            "sellers": []
          }
        },
        {
          "part": {
            "manufacturer": {
              "name": "Yageo"
            },
            "mpn": "RC0805FR-0710K(L)",
            "specs": [],
            "sellers": []
          }
        }
      ]
    }
  }
}
);
	return from_json($res);
}
