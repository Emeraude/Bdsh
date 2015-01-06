#!/bin/sh

SUCCESS=0;
FAILURE=1;
print_key=0;
true_arg='';
file_name='sh.db';
separator="\0";

syntax_error() {
    echo -e "Syntax error :\nUsage : ${0##*/} [-k] [-f file_name] (put key|$key value|$key) | (del key|$key [value|$key]) | (select [expr|$key]) | flush" 1>&2;
    exit $FAILURE;
}

key_error() {
    echo  "No such key : $1" 1>&2;
    exit $FAILURE;
}

file_error() {
    echo "No base found : $file_name" 1>&2;
    exit $FAILURE;
}

check_file_exist() {
    [ -f "$file_name" ] || file_error && return $SUCCESS;
}

check_file_writable() {
    [ -w "$file_name" ] || file_error && return $SUCCESS;
}

check_file_readable() {
    [ -r "$file_name" ] || file_error && return $SUCCESS;
}

check_file_create() {
    [ -f "$file_name" ] || echo -n > "$file_name" || file_error && return $SUCCESS;
}

write_value() {
    check_file_writable;
    oldIFS=$IFS;
    IFS='';
    key="$(sed -e s/\\\\0/\\\\\\\\0/g <<< $1)";
    val="$(sed -e s/\\\\0/\\\\\\\\0/g <<< $2)";
    echo -en ${key/'-'/'\x2D'} >> "$file_name";
    echo -en "$separator" >> "$file_name";
    echo -e ${val/'-'/'\x2D'} >> "$file_name";
    IFS=$oldIFS;
}

delete_key() {
    check_file_writable;
    sed -i -- "/^$1\x0/d" "$file_name";
    return $SUCCESS;
}

edit_value() {
    delete_key "$1";
    write_value "$1" "$2";
}

check_if_exact_key_exist() {
    cut -d '' -f1 < "$file_name" | grep -nwF -- "$1" > /dev/null || return $FAILURE && return $SUCCESS;
}

get_line_numbers_by_key() {
    cut -d '' -f1 < "$file_name" | grep -n -- "$1" | cut -d ':' -f1;
}

get_line_number_by_exact_line() {
    cat -v -- "$file_name" | grep -nawF -- "$1^@$2" | cut -d ':' -f1;
}

get_line_number_by_exact_key() {
    cut -d '' -f1 < "$file_name" | grep -nwF -- "$1" | cut -d ':' -f1;
}

get_line_by_line_number() {
    head -n "$1" -- "$file_name" | tail -n 1;
}

get_value_by_line_number() {
    get_line_by_line_number "$1" | cut -d '' -f2;
}

get_value_by_exact_key() {
    check_if_exact_key_exist "$1" && head -n "$(get_line_number_by_exact_key "$1")" -- "$file_name" | tail -n 1 | cut -d '' -f2 || return $FAILURE && return $SUCESS;
}

get_true_arg() {
    if [ "${1:0:1}" == '$' ]
    then
	check_file_readable;
	check_key="${1:1:${#1}}";
	if check_if_exact_key_exist $check_key
	then
	    true_arg=$(get_value_by_exact_key $check_key);
	else
	    key_error "$check_key";
	fi
    else
	true_arg="$1";
    fi
}

db_put() {
    if [ $# -ne 2 ]
    then
	syntax_error;
    else
	check_file_create;
	get_true_arg "$1";
	key="$true_arg";
	get_true_arg "$2";
	val="$true_arg";
	if check_if_exact_key_exist "$key"
	then
	    edit_value "$key" "$val";
	else
	    write_value "$key" "$val";
	fi
    fi
    exit $SUCCESS;
}

db_del() {
    if [ $# -eq 1 ]
    then
	get_true_arg "$1";
	check_if_exact_key_exist "$1" && edit_value "$true_arg" '';
    elif [ $# -eq 2 ]
    then
	get_true_arg "$1";
	key="$true_arg";
	get_true_arg "$2";
	val="$true_arg";
	# break if error ?
	for line in $(get_line_number_by_exact_line "$key" "$val")
	do
	    sed -i -- "$line"d "$file_name";
	done
    else
	syntax_error;
    fi
    exit $SUCCESS;
}

db_select() {
    if [ $# -eq 1 ]
    then
	get_true_arg "$1";
	for line in $(get_line_numbers_by_key "$true_arg")
	do
	    if [ $print_key -eq 1 ]
	    then
		get_line_by_line_number "$line" | tr "$separator" '=';
	    else
		get_value_by_line_number "$line";
	    fi
	done
    elif [ $# -eq 0 ]
    then
	check_file_readable;
	if [ $print_key -eq 1 ]
	then
	    tr "$separator" '=' < "$file_name";
	else
	    cut -d '' -f2 < "$file_name";
	fi
    else
	syntax_error;
    fi
    exit $SUCCESS;
}

db_flush() {
    echo -n > "$file_name";
    exit $SUCCESS;
}

while getopts "kf:" option "$@"
do
    case $option in
	k)
	    print_key=1;
	    ;;
	f)
	    file_name="$OPTARG";
	    ;;
	\?)
	    syntax_error;
	    ;;
    esac
done

shift $((OPTIND-1));

if [ "$1" == 'put' ] || [ "$1" == 'del' ] || [ "$1" == 'select' ] || [ "$1" == 'flush' ]
then
    cmd="db_$1"
    shift 1;
    "$cmd" "$@";
else
    syntax_error;
fi
