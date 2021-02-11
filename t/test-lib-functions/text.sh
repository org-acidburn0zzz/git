# Included by test-lib.sh via test-lib-functions.sh
#
# Debugging functions, not intended to be present in submitted
# patches. Be sure to remove their use before submitting.

# Stop execution and start a shell.
test_pause () {
	"$SHELL_PATH" <&6 >&5 2>&7
}

# Wrap git with a debugger. Adding this to a command can make it easier
# to understand what is going on in a failing test.
#
# Examples:
#     debug git checkout master
#     debug --debugger=nemiver git $ARGS
#     debug -d "valgrind --tool=memcheck --track-origins=yes" git $ARGS
debug () {
	case "$1" in
	-d)
		GIT_DEBUGGER="$2" &&
		shift 2
		;;
	--debugger=*)
		GIT_DEBUGGER="${1#*=}" &&
		shift 1
		;;
	*)
		GIT_DEBUGGER=1
		;;
	esac &&
	GIT_DEBUGGER="${GIT_DEBUGGER}" "$@" <&6 >&5 2>&7
}
