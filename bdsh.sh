#!/bin/sh

SUCCESS=0;
FAILURE=1;
print_key=0;
current_value_for_key='undefined';
true_arg='';
file_name='sh.db';
separator="\0";

syntax_error() {
    #TODO : color (man style) (only after "Syntax error :")
    echo -e 'Syntax error :\nUsage : ./bdsh.sh [-k] [-f file_name] (put key|$key value|$key) | (del key|$key [value|$key]) | (select [expr|$key]) | flush' 1>&2;
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
    echo -en ${1/'-'/'\x2D'} >> "$file_name";
    echo -en "$separator" >> "$file_name";
    echo -e ${2/'-'/'\x2D'} >> "$file_name";
}

delete_key() {
    check_file_writable;
    #CAN WE DO IT BETTER ?
    sed -i  "/^$1\x0/d" "$file_name";
    return $SUCCESS;
}

edit_value() {
    delete_key "$1";
    write_value "$1" "$2";
}

check_if_exact_key_exist() {
    cut -d '' -f1 < "$file_name" | grep -nawF -- "$1" > /dev/null || return $FAILURE && return $SUCCESS;
}

get_line_number_by_exact_line() {
    grep -nawF -- "$1$2" "$file_name" | cut -d ':' -f1;
}

get_line_number_by_exact_key() {
    cut -d '' -f1 < "$file_name" | grep -nawF -- "$1" | cut -d ':' -f1;
}

get_value_by_exact_key() {
    check_if_exact_key_exist "$1" && head "$file_name" -n "$(get_line_number_by_exact_key "$1")" | tail -n 1 | cut -d '' -f2 || return $FAILURE && return $SUCESS;
}

get_true_arg() {
    if [ "${1:0:1}" == '$' ]
    then
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
	line=$(get_line_number_by_exact_line) || break;
	sed -i "$line"d "$file_name";
    else
	syntax_error;
    fi
    exit $SUCCESS;
}

db_select() {
    if [ $# -eq 1 ]
    then
	if [ "$(echo $1 | cut -c 1)" == '$' ]
	then
	    get_value_by_exact_key "$1";
	    if [ $print_key -eq 1 ]
	    then
		echo -n $key'=';
	    fi
	    echo "$current_value_for_key";
	else
	    if [ $print_key -eq 1 ]
	    then
		# make a loop
		sed -n "/^.*$1.*\x0/p" "$file_name" | tr "$separator" '=';
	    else
		# make a loop
		sed -n "/^.*$1.*\x0/p" "$file_name" | cut -d '' -f2;
	    fi
	fi
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
    #TODO : make it cleaner
    cmd="db_$1"
    shift 1;
    "$cmd" "$@";
else
    syntax_error;
fi
