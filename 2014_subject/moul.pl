#!/usr/bin/perl



$test_file="test.bdsh";
$exe_bdsh="./bdsh.sh";
$ktrace_file="/tmp/user_bdsh_$$.out";
$allowed_cmd_bin="/afs/epitech.net/users/proj/bdsh/public/bdsh/allowed_cmd";

$binsh=`head -1 $exe_bdsh`;
print "Testing shell script ... => $binsh";
if ("$binsh" ne "#!/bin/sh\n")
 { print "$exe_bdsh is not a shell script.\n"; exit; }

print "Cleaning the database sh.db...\n";
`rm -f sh.db ; touch sh.db`;

if ( "$ARGV[0]" ne "" )
{ $test_file = "$ARGV[0]"; }

open(TEST_FILE,"$test_file") or die "Can't open test file $test_file\n";

while (<TEST_FILE>)
{
    chomp;
#    print "#", $_, "#\n" ;
    @infos = split /:/ ;
    if ("$infos[0]" ne "#") {
	foreach $i (@infos)
	{
	    $i =~ s/%n/\n/g ;
	    $i =~ s/%d/:/g ;
	    $i =~ s/%p/%/g ;
	}
	$err_answer = 0;
	if ($infos[2] <0) { $infos[2] = - $infos[2]; $err_answer = 1; }

	print "\n=> Test    : " , $infos[0] , "\n";
	print "=> Command : " , $infos[1] , "\n";

	$command = "$exe_bdsh $infos[1]";
#    print $command,"\n";
# bsd version
#	@lines = `/usr/bin/ktrace -t c -i -d -f $ktrace_file /bin/sh $command 2>&1`;
# linux version
	@lines = `/usr/bin/strace -f -o $ktrace_file /bin/sh $command 2>&1`;

	$nb_lines = @lines;
	print "=> Expected: " , $infos[2] , " line(s)\n";
	print "=> Received: " , $nb_lines , " line(s)\n";
	$ok = 1;
	if ($infos[2] != $nb_lines) { $ok = 0; }
	$i = 0;
	while ($i != $infos[2])
	{
	    chop $lines[$i];
	    if ($err_answer == 1)
	     { @tab_temp = split /:/,$lines[$i]; $lines[$i] = $tab_temp[0]; }
	    if ($lines[$i] ne $infos[3+$i]) { $ok = 0; };
	    print "=>         : " , $lines[$i] , " <=> ", $infos[3+$i] , "\n";
	    $i ++;
	}

# BSD
#	@lines = `/usr/bin/kdump -f $ktrace_file | /usr/bin/awk '{print \$2;}' | /bin/sort -u | $allowed_cmd_bin` ;
# Linux
	@lines = `/bin/grep execve\\( $ktrace_file | cut -d\\" -f2 | /bin/sort -u | $allowed_cmd_bin` ;
	$nb_lines = @lines;
	if ($nb_lines != 0)
	{
	    printf("=> %d unauthorized program :\n",$nb_lines);
	    foreach $i (@lines) { printf("  %s\n",$i); }
	    $ok = 0;
	}
	`rm -f $ktrace_file`;

	if ($ok == 1)
	{
	    print "=> TEST OK\n" ;
	}
	else
	{
	    print "=> TEST BAD\n";
	    exit ;
	}
    }
}


printf("\n\n You successfully passed all tests.\n");
