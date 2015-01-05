#!/bin/sh

init_args()
{
  bdsh="$0"
  if [ $# -ne 2 ]
  then
    echo "USAGE :" 1>&2
    echo "  $0 exec_bdsh test_file" 1>&2
    echo "  exec_bdsh and test_file must be in current directory !" 1>&2
    exit 1
  fi
  exec_bdsh=`basename "$1"`
  test_file=`basename "$2"`
  if [ ! -f "$exec_bdsh" ]
  then
    echo "$exec_bdsh not found in current directory !" 1>&2
    exit 1
  fi
  if [ ! -x "$exec_bdsh" ]
  then
    echo "Can't execute $exec_bdsh !" 1>&2
    exit 1
  fi
  if [ ! -f "$test_file" ]
  then
    echo "$test_file not found in current directory !" 1>&2
    exit 1
  fi
}

verif_script()
{
  l=`head -1 $exec_bdsh`
  if [ "$l" != "#!/bin/sh" ]
  then
    echo "$exec_bdsh is not a shell script."
    echo "Note : -42"
    exit 0
  fi
}

clean_db()
{
  echo "Cleaning the database sh.db..."
  echo -n "" > sh.db
}

comment()
{
  c=`echo "$1" | cut -c2-`
  echo -n "# "
  echo "$c" | sed s/'^:'// | sed s/'^ *'// | cut -c-40
}

my_exec()
{
  cmd="$1"
  arg1="" ; arg2="" ; arg3="" ; arg4="" ; arg5=""
  nb_arg=0
  while [ "$cmd" != "" ]
  do
    nb_arg=`expr $nb_arg + 1`
    c=`echo "x$cmd" | cut -c2`
    while [ "$c" == " " ]
    do
      cmd=`echo "x$cmd" | cut -c3-`
      c=`echo "x$cmd" | cut -c2`
    done
    if [ "$c" == "'" ]
    then
      cmd=`echo "x$cmd" | cut -c3-`
      c=`echo "x$cmd" | cut -c2`
      while [ "$c" != "'" ]
      do
        m="`eval echo '"'"$"arg"$nb_arg"'"'`"$c""
        eval arg$nb_arg='$m'
        cmd=`echo "x$cmd" | cut -c3-`
        c=`echo "x$cmd" | cut -c2`
      done
    elif [ "$c" == '"' ]
    then
      cmd=`echo "x$cmd" | cut -c3-`
      c=`echo "x$cmd" | cut -c2`
      while [ "$c" != '"' ]
      do
        m="`eval echo '"'"$"arg"$nb_arg"'"'`"$c""
        eval arg$nb_arg='$m'
        cmd=`echo "x$cmd" | cut -c3-`
        c=`echo "x$cmd" | cut -c2`
      done
    else
      while [ "$c" != " " -a "$c" != "" ]
      do
        m="`eval echo "$"arg"$nb_arg"`"$c""
        eval arg$nb_arg="$m"
        cmd=`echo "x$cmd" | cut -c3-`
        c=`echo "x$cmd" | cut -c2`
      done
    fi
    cmd=`echo "x$cmd" | cut -c3-`
  done
  if [ "$nb_arg" == "0" ]
  then
    ./$exec_bdsh > $tmp 2>&1
  elif [ "$nb_arg" == "1" ]
  then
    ./$exec_bdsh "$arg1" > $tmp 2>&1
  elif [ "$nb_arg" == "2" ]
  then
    ./$exec_bdsh "$arg1" "$arg2" > $tmp 2>&1
  elif [ "$nb_arg" == "3" ]
  then
    ./$exec_bdsh "$arg1" "$arg2" "$arg3" > $tmp 2>&1
  elif [ "$nb_arg" == "4" ]
  then
    ./$exec_bdsh "$arg1" "$arg2" "$arg3" "$arg4" > $tmp 2>&1
  elif [ "$nb_arg" == "5" ]
  then
    ./$exec_bdsh "$arg1" "$arg2" "$arg3" "$arg4" "$arg5" > $tmp 2>&1
  fi
}

launch_test()
{
  for line in `cat "$test_file"`
  do
    c=`echo "$line" | cut -c1`
    if [ "$c" == "#" ]
    then
      comment "$line"
    else
      test_number=`echo "$line" | cut -f1 -d":"`
      test_command=`echo "$line" | cut -f2 -d":"`
      nb_result=`echo "$line" | cut -f3 -d":"`
      echo "---------- TEST $test_number  ---------------------"
      echo "COMMAND : $test_command"
      if [ "$nb_result" == "-1" ]
      then
        echo "RESULT : Syntax error"
      elif [ "$nb_result" == "0" ]
      then
        echo "RESULT : No output"
      else
        last_field=`expr $nb_result + 3`
	echo "RESULT : $nb_result line"
        echo "$line" | cut -f4-$last_field -d ':' | tr ":" "\n" | sed s/'^'/'  - '/g
      fi
      tmp="moul.trace.$$"
      OIFS=$IFS
      IFS=' '
      my_exec "$test_command"
      return_exec=$?
      IFS=$OIFS
      if [ ! -f "$tmp" ]
      then
        echo "Unable to create temporary file." 1>&2
        exit 1
      fi
      nb_result_trace=`cat "$tmp" | wc -l`
      if [ "$nb_result" == "-1" ]
      then
        if [ "$return_exec" == "1" ]
        then
	  error_message=`cat "$tmp" | head -1 | cut -f1 -d:`
          error_message="$error_message"
	  error_result=`echo "$line" | cut -f4 -d:`
          if [ "$error_message" != "$error_result" ]
          then
		    echo "YOUR RESULT : Error"
            x=0
            while [ $x -eq 0 ]
            do
              echo "Hits c to continue, d to display trace, x to exit"
              echo -n "=> "
              read choice
              choice=`echo "$choice" | cut -c1`
              if [ "$choice" == "x" -o "$choice" == "X" ]
              then
                rm $tmp
                exit 1
              fi
              if [ "$choice" == "d" -o "$choice" == "D" ]
              then
                cat $tmp
                echo "Error message must start with : '$error_result'"
              fi
              if [ "$choice" == "c" -o "$choice" == "C" ]
              then
				rm "$tmp"
                x=1
              fi
            done
          else
            echo "YOUR RESULT : Ok"
          fi
        else
          echo "YOUR RESULT : Error"
          x=0
          while [ $x -eq 0 ]
          do
            echo "Hits c to continue, d to display trace, x to exit"
            echo -n "=> "
            read choice
            choice=`echo "$choice" | cut -c1`
            if [ "$choice" == "x" -o "$choice" == "X" ]
            then
              rm $tmp
              exit 1
            fi
            if [ "$choice" == "d" -o "$choice" == "D" ]
            then
              cat $tmp
              echo "RETURN VALUE : $return_exec"
            fi
            if [ "$choice" == "c" -o "$choice" == "C" ]
            then
              rm $tmp
              x=1
            fi
          done
        fi
      elif [ "$nb_result_trace" -ne "$nb_result" ]
      then
        echo "YOUR RESULT : Error"
        x=0
        while [ $x -eq 0 ]
        do
          echo "Hits c to continue, d to display trace, x to exit"
          echo -n "=> "
          read choice
          choice=`echo "$choice" | cut -c1`
          if [ "$choice" == "x" -o "$choice" == "X" ]
          then
            rm $tmp
            exit 1
          fi
          if [ "$choice" == "d" -o "$choice" == "D" ]
          then
            cat $tmp
          fi
          if [ "$choice" == "c" -o "$choice" == "C" ]
          then
            rm $tmp
            x=1
          fi
        done
      elif [ $nb_result_trace -gt 0 -o $nb_result -gt 0 ]
      then
        echo "$line" | cut -f4-$last_field -d ':' | tr ":" "\n" > $tmp.ok
        diff $tmp $tmp.ok > $tmp.diff
        if [ $? -ne 0 ]
        then
          echo "YOUR RESULT : Error"
          x=0
          while [ $x -eq 0 ]
          do
            echo "Hits c to continue, d to display trace, x to exit"
            echo -n "=> "
            read choice
            choice=`echo "$choice" | cut -c1`
            if [ "$choice" == "x" -o "$choice" == "X" ]
            then
              rm $tmp $tmp.ok $tmp.diff
              exit 0
            fi
            if [ "$choice" == "d" -o "$choice" == "D" ]
            then
              echo "Your Result :"
              cat $tmp
              echo "Diff :"
              cat $tmp.diff
            fi
            if [ "$choice" == "c" -o "$choice" == "C" ]
            then
              rm $tmp $tmp.ok $tmp.diff
              x=1
            fi
          done
        else
          rm $tmp $tmp.ok $tmp.diff
          echo "YOUR RESULT : Ok"
        fi
      else
        rm $tmp
        echo "YOUR RESULT : Ok"
      fi
    fi
  done
}

rm *trace* 2>/dev/null
IFS=$'\n'
init_args $*
echo "Testing $exec_bdsh with $test_file test file..."
verif_script
clean_db
launch_test
echo "-----------------------------------------"
echo "End"
exit 0
