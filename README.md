SYNOPSIS
========

Merge .s2p files into a single .mdf file for optimization in Microwave Office!

You can use the Octopart API to build an MDF with parts that are actually in stock!

GETTING STARTED
===============

	cpanm RF::Component API::Octopart
	git clone https://github.com/KJ7LNW/mdf.git
	cd mdf
	./mdf --help


USAGE
=====

usage: ./mdf [options] --var-code 'var\_name=MODEL-(...).s2p' file1.s2p [file2...] -o mymdf.mdf

--output|-o      <file>        Output filename, required.
	If the filename is '-' then output will be written to stdout

Note that regular expressions matching filenames are always case-insensitive:

--var-code|-V    <regex>       Either of --var-code or --var-literal are required.
	Specifies the variable to be assigned and a regular expression to match
	the capacitance code (or other unit): NNX or NRN. X is the exponent, N
	is a numeric value.

	If a capacitor code is 111 then it will calculate 11*10^1 == 110 pF.  A
	code of 1N4 or 14N would be 1.4 or 14.0, respectively. The unit 'pF' in
	the example is excluded from the code.

	The above (...) must match the code or literal to be placed in the MDF
	variable. Example:
		--var-code 'C_pF=MODEL-(...).s2p'
	
--var-literal|-L <regex>       Either of --var-code or --var-literal are required.
	The var-literal version is the same as --var-code but does not
	calcualte the code, it takes the value verbatim.  For example, some
	inductors specify the number of turns in their s2p filename:
		--var-literal 'L_turns=MODEL-([0-9]+)T.s2p'

--reverse-sort|-r              Sort MDF values in reverse.

--not-unique|-U                Make values NOT unique
--unique|-u                    Make values unique (default)
	Choose only the first matching code if multiple of the same code are
	found.  Note that file ordering may be relevant when using the --unique
	constraint:

	If you wish to prioritize the tolerance code (or other coded metric)
	then order the file list in tolerance order.  So long as the names are
	the same except the tolerance code you could glob the tolerance code
	with braces ordered by tolerance as follows:

		GQM1555C2D???{B,C}*.s2p

	Where '???' is the value code, 'B' is +/- 0.1pF and 'C' is +/- 0.25pF
	for this example muRata part. (Note that [BC] style globbing does not
	work because the charectar class does not enforce ordering, nor does it
	support multi-charectar codes.)

	According to the muRata part guide the tolerance codes this glob lists
	in ascending order:
		GQM1555C2D???{W,B,C,D,F,G,J,K,M}*.s2p
		[ https://search.murata.co.jp/Ceramy/image/img/A01X/partnumbering_e_01.pdf ]

	Of course this technique can be used for any S2P component and is not
	specific to the manufacturer or type of component (L, C, R, etc).
	Refer to your manufacturer's documentation to choose the right
	tolerance ordering for your application.

--model-suffix|-m <suffix>  Append a string to each model

	It may be useful to append a string to the filename model when querying
	Octopart.  For example, if the Coilcraft filename is 0402-DC7N6 then a
	model-suffix of 'XG' would indicate a 2% tolerance instead of the 'XJ'
	which is a 5% tolerance.

	This string is also added to the VAR line in the .mdf.

--octopart|-O               Enable Octopart stock querying
	You will need to place your API token in ~/.octopart/token .  Queries are
	cached in ~/.octopart/cache/ to minimize redundant API requests but you
	may wish to clear that directory out periodically since stock numbers will
	become stale.

	Get your API token here: https://octopart.com/api

--octopart-filter|-F <filter_opts>    This option implies -O.
	The <filter_opts> are comma-separated values passed to the
	API::Octopart class.  These are common filter options to remember:

		min_qty=<n>    - Minimum stock quantity, per vendor.

		max_moq=<n>    - Maximum "minimum order quantity"
			This is the max MOQ you will accept as being in
			stock.  For example, a 5000-part reel might be more
			than you want for prototyping so set this to 10 or
			100.

		seller=<regex> - Seller's name (regular expression)
			This is a regular expression so something like
			'Mouser|Digi-key' is valid.

		mfg=<regex>    - Manufacturer name (regular expression)
			Specifying the mfg name is useful if your part model
			number is similar to those of other manufacturers.

		currency=<s>   - 'USD' for US dollars
			Defaults to include all currencies

	Example: ./mdf -O -F 'max_moq=100,min_qty=10,seller=Mouser|Digi-key'	

	See `perldoc API::Octopart` (or perldoc lib/API/Octopart.pm) for details.

--octopart-include-specs|-I Request product specs in the API call.
	Currently ./mdf does not do anything with product specs, but if you have
	an Octopart PRO account then you can enable this option ;)

--octopart-show-stock|-S    Show stock summaries
	Calling this option more than once increases the stock detail.  A
	single -S shows final summary and two -SS shows per-product per-seller
	stock detail.

--limit|-l    <N>           Limit number of file evaluations to N.
	This is useful for debugging your regex with -vvv.  Glob all the files
	you want but limit to N so you only make a few Octopart queries while
	testing.

--verbose|-v                Multiple -v's increase verbosity.
	At least 4x -v's will print detailed Octopart responses.

--quiet|-q                  Suppress warnings, but does not suppress verbosity.


ACKNOWLEDGEMENTS
================

Thanks to Hannah Mortimer for help writing the early first-draft of this program.
Thanks to Zeke, @KJ7NLL for inspring this program to help optimize for our HAM Radio projects!
