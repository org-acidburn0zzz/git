# Included by test-lib.sh via test-lib-functions.sh
#
# Text munging functions, e.g. wrappers for perl, tr, sed
# etc. one-liners.

lf_to_nul () {
	perl -pe 'y/\012/\000/'
}

nul_to_q () {
	perl -pe 'y/\000/Q/'
}

q_to_nul () {
	perl -pe 'y/Q/\000/'
}

q_to_cr () {
	tr Q '\015'
}

q_to_tab () {
	tr Q '\011'
}

qz_to_tab_space () {
	tr QZ '\011\040'
}

append_cr () {
	sed -e 's/$/Q/' | tr Q '\015'
}

remove_cr () {
	tr '\015' Q | sed -e 's/Q$//'
}

# Converts base-16 data into base-8. The output is given as a sequence of
# escaped octals, suitable for consumption by 'printf'.
hex2oct () {
	perl -ne 'printf "\\%03o", hex for /../g'
}

# convert function arguments or stdin (if not arguments given) to pktline
# representation. If multiple arguments are given, they are separated by
# whitespace and put in a single packet. Note that data containing NULs must be
# given on stdin, and that empty input becomes an empty packet, not a flush
# packet (for that you can just print 0000 yourself).
packetize () {
	if test $# -gt 0
	then
		packet="$*"
		printf '%04x%s' "$((4 + ${#packet}))" "$packet"
	else
		perl -e '
			my $packet = do { local $/; <STDIN> };
			printf "%04x%s", 4 + length($packet), $packet;
		'
	fi
}

# Parse the input as a series of pktlines, writing the result to stdout.
# Sideband markers are removed automatically, and the output is routed to
# stderr if appropriate.
#
# NUL bytes are converted to "\\0" for ease of parsing with text tools.
depacketize () {
	perl -e '
		while (read(STDIN, $len, 4) == 4) {
			if ($len eq "0000") {
				print "FLUSH\n";
			} else {
				read(STDIN, $buf, hex($len) - 4);
				$buf =~ s/\0/\\0/g;
				if ($buf =~ s/^[\x2\x3]//) {
					print STDERR $buf;
				} else {
					$buf =~ s/^\x1//;
					print $buf;
				}
			}
		}
	'
}

# Read up to "$1" bytes (or to EOF) from stdin and write them to stdout.
test_copy_bytes () {
	perl -e '
		my $len = $ARGV[1];
		while ($len > 0) {
			my $s;
			my $nread = sysread(STDIN, $s, $len);
			die "cannot read: $!" unless defined($nread);
			last unless $nread;
			print $s;
			$len -= $nread;
		}
	' - "$1"
}
