# Included by test-lib.sh via test-lib-functions.sh
#
# File functions, e.g. wrappers for "test [-e|-s|-f|...]", "wc -l"
# etc.

# ... test -f
test_path_is_file () {
	test "$#" -ne 1 && BUG "1 param"
	if ! test -f "$1"
	then
		echo "File $1 doesn't exist"
		false
	fi
}

# ... test -d
test_path_is_dir () {
	test "$#" -ne 1 && BUG "1 param"
	if ! test -d "$1"
	then
		echo "Directory $1 doesn't exist"
		false
	fi
}

# test -d && is_empty()
test_dir_is_empty () {
	test "$#" -ne 1 && BUG "1 param"
	test_path_is_dir "$1" &&
	if test -n "$(ls -a1 "$1" | egrep -v '^\.\.?$')"
	then
		echo "Directory '$1' is not empty, it contains:"
		ls -la "$1"
		return 1
	fi
}

# ... test -e
test_path_exists () {
	test "$#" -ne 1 && BUG "1 param"
	if ! test -e "$1"
	then
		echo "Path $1 doesn't exist"
		false
	fi
}

# ... ! test -e
test_path_is_missing () {
	test "$#" -ne 1 && BUG "1 param"
	if test -e "$1"
	then
		echo "Path exists:"
		ls -ld "$1"
		if test $# -ge 1
		then
			echo "$*"
		fi
		false
	fi
}

# ... test -s
test_must_be_empty () {
	test "$#" -ne 1 && BUG "1 param"
	test_path_is_file "$1" &&
	if test -s "$1"
	then
		echo "'$1' is not empty, it contains:"
		cat "$1"
		return 1
	fi
}

# ... ! test -s
test_file_not_empty () {
	test "$#" = 2 && BUG "2 param"
	if ! test -s "$1"
	then
		echo "'$1' is not a non-empty file."
		false
	fi
}

test_file_size () {
	test "$#" -ne 1 && BUG "1 param"
	test-tool path-utils file-size "$1"
}

# This function helps systems where core.filemode=false is set.
# Use it instead of plain 'chmod +x' to set or unset the executable bit
# of a file in the working directory and add it to the index.
test_chmod () {
	chmod "$@" &&
	git update-index --add "--chmod=$@"
}

# Get the modebits from a file or directory, ignoring the setgid bit (g+s).
# This bit is inherited by subdirectories at their creation. So we remove it
# from the returning string to prevent callers from having to worry about the
# state of the bit in the test directory.
test_modebits () {
	ls -ld "$1" | sed -e 's|^\(..........\).*|\1|' \
			  -e 's|^\(......\)S|\1-|' -e 's|^\(......\)s|\1x|'
}

# test_line_count checks that a file has the number of lines it
# ought to. For example:
#
#	test_expect_success 'produce exactly one line of output' '
#		do something >output &&
#		test_line_count = 1 output
#	'
#
# is like "test $(wc -l <output) = 1" except that it passes the
# output through when the number of lines is wrong.
test_line_count () {
	if test $# != 3
	then
		BUG "not 3 parameters to test_line_count"
	elif ! test $(wc -l <"$3") "$1" "$2"
	then
		echo "test_line_count: line count for $3 !$1 $2"
		cat "$3"
		return 1
	fi
}

# Tests for the hidden file attribute on Windows
test_path_is_hidden () {
	test_have_prereq MINGW ||
	BUG "test_path_is_hidden can only be used on Windows"

	# Use the output of `attrib`, ignore the absolute path
	case "$("$SYSTEMROOT"/system32/attrib "$1")" in *H*?:*) return 0;; esac
	return 1
}
