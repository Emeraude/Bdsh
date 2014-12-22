#!/bin/bash

SUCCESS=0;
FAILURE=1;
print_key=0;
current_value_for_key='undefined';
file_name='sh.db';
separator="\0";

function syntax_error()
{
    echo -e 'Syntax error :\nUsage : ./bdsh.sh [-k] [-f file_name] (put key|$key value|$key) | (del key|$key [value|$key]) | (select [expr|$key]) | flush';
    exit $FAILURE;
}

function key_error()
{
    echo -e "No such key : $1";
    exit $FAILURE;
}

function get_key_value()
{
    if [ "$(echo $1 | cut -c 1)" == '$' ]
    then
	key=$(echo $1 | cut -c 2-);
    else
	key=$1;
    fi
    if [ "$(grep -a "^$key$separator" "$file_name" | cut -d $separator -f1)" == "$key" ]
    then
	current_value_for_key=$(cat "$file_name" | grep "^$key" | cut -d $separator -f2);
    else
	key_error $key;
    fi
}

function delete_key()
{
    get_key_value "$1";
    grep -v "^$key$separator" "$file_name" | cut -d ':' -f1 > /tmp/"$file_name";
    mv /tmp/"$file_name" "$file_name";
}

# TODO
function db_put()
{
    if [ $# -ne 2 ]
    then
	syntax_error;
    else
	if [ "$(echo $1 | cut -c 1)" == '$' ]
	then
	    get_key_value "$1";
	    # existing key
	    echo "existing key";
	    # replace it
	else
	    echo "$1"$separator"$2" >> "$file_name";
	fi
    fi
}

# TODO
function db_del()
{
    if [ $# -eq 1 ]
    then
	delete_key "$1";
	echo "$1"$separator >> "$file_name";
    elif [ $# -eq 2 ]
    then
	if [ "$(echo $1 | cut -c 1)" == '$' ]
	then
	    echo -en;
	else
	    echo -en;
	fi
    else
	syntax_error;
    fi
}

function db_select()
{
    if [ $# -eq 1 ]
    then
	if [ "$(echo $1 | cut -c 1)" == '$' ]
	then
	    get_key_value "$1";
	    if [ $print_key -eq 1 ]
	    then
		echo -n $key'=';
	    fi
	    echo $current_value_for_key;
	else
	    lines=$(cut -d $separator -f1 < "$file_name" | grep $1);
	    for line in ${lines[@]}
	    do
		get_key_value "$line";
		if [ $print_key -eq 1 ]
		then
		    echo -n $key'=';
		fi
		echo $current_value_for_key;
	    done
	fi
    else
	if [ $print_key -eq 1 ]
	then
	    tr $separator '=' < "$file_name";
	else
	    cut -d $separator -f2 < "$file_name";
	fi
    fi
    exit $SUCCESS;
}

function db_flush()
{
    echo -n > "$file_name";
    exit $SUCCESS;
}

#TODO manage it in each case (-k after other options)
av=("$@");
i=0;
while [ $i -lt $# ]
do
    a=${av[$i]};
    if [ "$a" == '-k' ] || [ "$a" == '--key' ]
    then
	print_key=1;
    elif [ "$a" == '-f' ] || [ "$a" == '--file' ]
    then
	if [ `expr $i + 2` -gt $# ]
	then
	    syntax_error;
	fi
	file_name=${av[`expr $i + 1`]};
	i=`expr $i + 1`;
    elif [ "$a" == 'put' ]
    then
	db_put ${av[`expr $i + 1`]} ${av[`expr $i + 2`]};
    elif [ "$a" == 'select' ]
    then
	db_select ${av[`expr $i + 1`]} ${av[`expr $i + 2`]};
    elif [ "$a" == 'del' ]
    then
	db_del ${av[`expr $i + 1`]} ${av[`expr $i + 2`]};
    elif [ "$a" == 'flush' ]
    then
	db_flush;
    fi
    i=`expr $i + 1`;
done
