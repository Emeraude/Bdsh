#!/bin/sh

SUCCESS=0;
FAILURE=1;
print_key=0;
file_name='sh.db';
separator=$(echo -en "\002");

function syntax_error()
{
    echo -e 'Syntax error :\nUsage : ./bdsh.sh [-k] [-f file_name] (put key|$key value|$key) | (del key|$key [value|$key]) | (select [expr|$key]) | flush';
    exit $FAILURE;
}

function db_put()
{
    if [ $# -lt 2 ]
    then
	syntax_error;
    else
	existing_key=$(cat $file_name | grep "^$1" | cut -d $separator -f1);
	if [ "$existing_key" == "$1" ]
	then
	    echo "existing key";
	    # replace it
	else
	    echo "$1"$separator"$2" >> $file_name;
	fi
    fi
}

function db_del()
{
    echo "not implemented yet";
}

function db_select()
{
    echo "not implemented yet";
}

function db_flush()
{
    echo -n > $file_name;
    exit $SUCCESS;
}

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
    elif [ "$a" == 'flush' ]
    then
	db_flush;
    fi
    i=`expr $i + 1`;
done
