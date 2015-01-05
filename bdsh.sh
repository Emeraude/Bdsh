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

write_value() {
    if [ -f $file_name ]
    then
	echo -n "$1" >> "$file_name";
	echo -en "$separator" >> "$file_name";
	echo "$2" >> "$file_name";
    else
	file_error;
    fi
}

delete_key() {
    grep -vaP "^$key$separator" "$file_name" > /tmp/"$file_name";
    cat /tmp/"$file_name" > "$file_name";
}

edit_value() {
    delete_key "$1";
    write_value "$1" "$2";
}

get_true_arg() {
    if [ "$(echo $1 | cut -c 1)" == '$' ]
    then
	key=$(echo $1 | cut -c 2-);
	if [ "$(grep -aP "^$key$separator" "$file_name" | cut -d '' -f1)" == "$key" ]
	then
	    true_arg=$(grep -aP "^$key$separator" "$file_name" | cut -d '' -f2);
	else
	    key_error "$key";
	fi
    else
	true_arg="$1";
    fi
}

get_key_value() {
    if [ "$(echo $1 | cut -c 1)" == '$' ]
    then
	key=$(echo $1 | cut -c 2-);
    else
	key="$1";
    fi
    if [ "$(grep -a "^$key" "$file_name" | cut -d '' -f1)" == "$key" ]
    then
	current_value_for_key=$(grep -a "^$key" "$file_name" | cut -d '' -f2);
    else
	key_error "$key";
    fi
}

db_put() {
    if [ $# -ne 2 ]
    then
	syntax_error;
    else
	echo -n >> "$file_name";
	get_true_arg "$1";
	key="$true_arg";
	get_true_arg "$2";
	val="$true_arg";
	if [ $(grep -aP "^$key$separator" "$file_name" | wc -l) -ne 0 ]
	then
	    echo -n;
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
	echo $true_arg;
	delete_key "$true_arg";
	write_value "$1" '';
    elif [ $# -eq 2 ]
    then
	get_true_arg "$1";
	key="$true_arg";
	get_true_arg "$2";
	val="$true_arg";
	grep -vaP "^$key$separator$val$" "$file_name" > /tmp/"$file_name";
	mv /tmp/"$file_name" "$file_name";
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
	    get_key_value "$1";
	    if [ $print_key -eq 1 ]
	    then
		echo -n $key'=';
	    fi
	    echo "$current_value_for_key";
	else
	    if [ $print_key -eq 1 ]
	    then
		grep -aP "$1" "$file_name" | tr "$separator" '=';
	    else
		grep -aP "$1" "$file_name" | cut -d '' -f2;
	    fi
	fi
    elif [ $# -eq 0 ]
    then
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
