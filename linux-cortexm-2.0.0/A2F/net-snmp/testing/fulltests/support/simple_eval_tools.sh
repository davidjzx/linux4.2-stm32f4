#
# eval_tools.sh
#
# Output functions for script tests.  Source this from other test scripts
# to establish a standardized repertory of test functions.
#
#
# Except where noted, all functions return:
#	0	On success,	(Bourne Shell's ``true'')
#	non-0	Otherwise.
#
# Input arguments to each function are documented with each function.
#
#
# XXX  Suggestions:
#	DEBUG ON|OFF
#	dump CAPTURE output to stdout as well as to junkoutputfile.
#

#
# Only allow ourselves to be eval'ed once
#
if [ "x$EVAL_TOOLS_SH_EVALED" != "xyes" ]; then
    EVAL_TOOLS_SH_EVALED=yes

#
# Variables used in global environment of calling script.
#
failcount=0
testnum=0
errnum=0
junkoutputfilebase="$SNMP_TMPDIR/output-`basename $0`$$"
junkoutputfile=$junkoutputfilebase
outputcount=0
separator="-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
if [ -z "$OK_TO_SAVE_RESULT" ] ; then
OK_TO_SAVE_RESULT=1
export OK_TO_SAVE_RESULT
fi


#
# HEADER: returns a single line when SNMP_HEADERONLY mode and exits.
#
HEADER() {
    if [ "x$SNMP_HEADERONLY" != "x" ]; then
        echo test $*
	exit 0;
    else
	{ echo "# testing $*"; echo ""; } >> $SNMP_TMPDIR/invoked
    fi
}


#------------------------------------ -o-
#
OUTPUT() {	# <any_arguments>
	cat <<GRONK


$*


GRONK
}

CAN_USLEEP() {
   if [ "$SNMP_CAN_USLEEP" = 0 -o "$SNMP_CAN_USLEEP" = 0 ] ; then
     return $SNMP_CAN_USLEEP
   fi
   sleep .1 > /dev/null 2>&1
   if [ $? = 0 ] ; then
     SNMP_CAN_USLEEP=1
   else
     SNMP_CAN_USLEEP=0
   fi
   export SNMP_CAN_USLEEP
}


#------------------------------------ -o-
#
SUCCESS() {	# <any_arguments>
	[ "$failcount" -ne 0 ] && return
	cat <<GROINK

SUCCESS: $*

GROINK
}



#------------------------------------ -o-
#
FAILED() {	# <return_value>, <any_arguments>
	[ "$1" -eq 0 ] && return
	shift

	failcount=`expr $failcount + 1`
	cat <<GRONIK

FAILED: $*

GRONIK
}

#------------------------------------ -o-
#
SKIP() {
	REMOVETESTDATA
	echo "1..0 # SKIP $*"
	exit 0
}

ISDEFINED() {
	grep "^#define $1" ${builddir}/include/net-snmp/net-snmp-config.h ${builddir}/include/net-snmp/agent/mib_module_config.h ${builddir}/include/net-snmp/agent/agent_module_config.h > /dev/null
}

SKIPIFNOT() {
	ISDEFINED "$1" || SKIP "$1 is not defined"
}

SKIPIF() {
	ISDEFINED "$1" && SKIP "$1 is defined"
}

#------------------------------------ -o-
#
VERIFY() {	# <path_to_file(s)>
	local	missingfiles=

	for f in $*; do
		[ -e "$f" ] && continue
		echo "FAILED: Cannot find file \"$f\"."
		missingfiles=true
	done

	[ "$missingfiles" = true ] && exit 1000
}

NEWOUTPUTFILE() {
        outputcount=`expr $outputcount + 1`
        junkoutputfile="${junkoutputfilebase}-$outputcount"
}

#------------------------------------ -o-
#
STARTTEST() {
        NEWOUTPUTFILE
	[ ! -e "$junkoutputfile" ] && {
		touch $junkoutputfile
		return
	}
	echo "FAILED: Output file already exists: \"$junkoutputfile\"."
	exit 1000
}


#------------------------------------ -o-
#
STOPTEST() {
	rm -f "$junkoutputfile"
}


#------------------------------------ -o-
#
REMOVETESTDATA() {
#	ECHO "removing $SNMP_TMPDIR  "
	rm -rf $SNMP_TMPDIR
}

#------------------------------------ -o-
#
OUTPUTENVVARS() {
    echo "SNMPCONFPATH=$SNMPCONFPATH" >> $1
    echo "SNMP_PERSISTENT_DIR=$SNMP_PERSISTENT_DIR" >> $1
    echo "MIBDIRS=$MIBDIRS" >> $1
    echo "PATH=$PATH" >> $1
    echo "export SNMPCONFPATH" >> $1
    echo "export SNMP_PERSISTENT_DIR" >> $1
    echo "export MIBDIRS" >> $1
    echo "export PATH" >> $1
}
    
#------------------------------------ -o-
# Captures output from command, and returns the command's exit code.
loggedvars=0
CAPTURE() {	# <command_with_arguments_to_execute>
    NEWOUTPUTFILE

    # track invoked command per test when verbose
    if [ $SNMP_VERBOSE -gt 0 ]; then
        OUTPUTENVVARS $junkoutputfile.invoked
        echo $* >> $junkoutputfile.invoked
    fi

    if [ $loggedvars = 0 ]; then
        OUTPUTENVVARS $SNMP_TMPDIR/invoked
        loggedvars=1
    fi
    echo $* >> $SNMP_TMPDIR/invoked

	if [ $SNMP_VERBOSE -gt 0 ]; then
		cat <<KNORG

EXECUTING: $*

KNORG

	fi
	echo "RUNNING: $*" > $junkoutputfile
	( $* 2>&1 ) >> $junkoutputfile 2>&1
	RC=$?

	if [ $SNMP_VERBOSE -gt 1 ]; then
		echo "Command Output: "
		echo "MIBDIR $MIBDIRS $MIBS"
		echo "$separator"
		cat $junkoutputfile | sed 's/^/  /'
		echo "$separator"
	fi
	return $RC
}

#------------------------------------ -o-
# Delay to let processes settle
DELAY() {
    if [ "$SNMP_SLEEP" != "0" ] ; then
	sleep $SNMP_SLEEP
    fi
}

SAVE_RESULTS() {
   real_return_value=$return_value
}

#
# Checks the output result against what we expect.
#   Sets return_value to 0 or 1.
#
EXPECTRESULT() {
  if [ $OK_TO_SAVE_RESULT -ne 0 ] ; then
    if [ "$snmp_last_test_result" = "$1" ]; then
	return_value=0
    else
	return_value=1
    fi
  fi
}

CHECKCOUNT() {
   CHECKFILECOUNT "$junkoutputfile" $@
}

CHECKVALUEIS() {
    value1=$1
    value2=$2
    if [ "x$value1" = "x$value2" ]; then
      GOOD "$3"
    else
      BAD "$3"
    fi
}

CHECKVALUEISNT() {
    value1=$1
    value2=$2
    if [ "x$value1" = "x$value2" ]; then
      BAD "$3"
    else
      GOOD "$3"
    fi
}

#------------------------------------ -o-
# Returns: Count of matched lines.
#
CHECKFILECOUNT() {	# <pattern_to_match>
    chkfile=$1
    ckfcount=$2
    shift
    shift
    if [ $SNMP_VERBOSE -gt 0 ]; then
	echo -n "checking output for \"$*\"..."
    fi

    if [ -f $chkfile ]; then
	rval=`grep -c "$*" "$chkfile" 2>/dev/null`
    else
        COMMENT "Note: file $chkfile does not exist and we were asked to check it"
	rval=0
    fi

    if [ $SNMP_VERBOSE -gt 0 ]; then
	echo "$rval matches found"
    fi

    snmp_last_test_result=$rval
    EXPECTRESULT $ckfcount  # default
    if [ "$ckfcount" != "noerror" ]; then
      if [ "$ckfcount" = "atleastone" ]; then
        if [ "$rval" -ne "0" ]; then
            GOOD "found $ckfcount copies of '$*' in output ($chkfile); needed one"
        else
            BAD "found $rval copies of '$*' in output ($chkfile); expected 1"
            COMMENT "Outputfile: $chkfile"
        fi
      else
        if [ "$rval" = "$ckfcount" ]; then
           GOOD "found $ckfcount copies of '$*' in output ($chkfile)"
        else
           BAD "found $rval copies of '$*' in output ($chkfile); expected $ckfcount"
           COMMENT "Outputfile: $chkfile"
        fi
      fi
    fi
    return $rval
}

CHECK() {
    CHECKCOUNT 1 $@
}

CHECKFILE() {
    file=$1
    shift
    CHECKFILECOUNT $file 1 $@
}

CHECKTRAPD() {
    CHECKFILE $SNMP_SNMPTRAPD_LOG_FILE $@
}

CHECKTRAPDCOUNT() {
    count=$1
    shift
    CHECKFILECOUNT $SNMP_SNMPTRAPD_LOG_FILE $count $@
}

CHECKTRAPDORDIE() {
    CHECKORDIE $@ $SNMP_SNMPTRAPD_LOG_FILE
}

CHECKAGENT() {
    CHECKFILE $SNMP_SNMPD_LOG_FILE $@
}

CHECKAGENTCOUNT() {
    count=$1
    shift
    CHECKFILECOUNT $SNMP_SNMPD_LOG_FILE $count $@
}

WAITFORAGENTSHUTTINGDOWN() {
    if [ "x$OSTYPE" != "xmsys" ]; then
        WAITFORAGENT "shutting down"
    else
	CAN_USLEEP
	if [ $SNMP_CAN_USLEEP = 1 ] ; then
	  sleeptime=`expr $SNMP_SLEEP '*' 50`
	else 
	  sleeptime=`expr $SNMP_SLEEP '*' 5`
	fi
        snmpd_pid=`cat $SNMP_SNMPD_PID_FILE`
        while [ $sleeptime -gt 0 ] && kill -0 "$snmpd_pid" 2>/dev/null; do
            if [ $SNMP_CAN_USLEEP = 1 ]; then
                sleep .1
            else
                sleep 1
            fi
            sleeptime=`expr $sleeptime - 1`
        done
    fi
}

WAITFORAGENT() {
    WAITFOR "$@" $SNMP_SNMPD_LOG_FILE
}

WAITFORTRAPD() {
    WAITFOR "$@" $SNMP_SNMPTRAPD_LOG_FILE
}

WAITFOR() {
  ## save the previous save state and test result
    save_state=$OK_TO_SAVE_RESULT
    save_test=$snmp_last_test_result
    OK_TO_SAVE_RESULT=0

    sleeptime=$SNMP_SLEEP
    oldsleeptime=$SNMP_SLEEP
    if [ "$1" != "" ] ; then
	CAN_USLEEP
	if [ $SNMP_CAN_USLEEP = 1 ] ; then
	  sleeptime=`expr $SNMP_SLEEP '*' 50`
          SNMP_SLEEP=.1
	else 
	  sleeptime=`expr $SNMP_SLEEP '*' 5`
	  SNMP_SLEEP=1
	fi
        while [ $sleeptime -gt 0 ] ; do
	  if [ "$2" = "" ] ; then
            CHECKCOUNT noerror "$@"
          else
	    CHECKFILECOUNT "$2" noerror "$1"
	  fi
          if [ "$snmp_last_test_result" != "" ] ; then
              if [ "$snmp_last_test_result" -gt 0 ] ; then
	         break;
              fi
	  fi
          DELAY
          sleeptime=`expr $sleeptime - 1`
        done

	# the above multi-check/sleep doesn't report errors out of TAP
        # this final check will report only 1 
	if [ "$2" = "" ] ; then
          CHECKCOUNT atleastone "$@"
        else
	  CHECKFILECOUNT "$2" atleastone "$1"
	fi
        SNMP_SLEEP=$oldsleeptime
    else
        if [ $SNMP_SLEEP -ne 0 ] ; then
	    sleep $SNMP_SLEEP
        fi
    fi

  ## restore the previous save state and test result
    OK_TO_SAVE_RESULT=$save_state
    snmp_last_test_result=$save_test
}

GOOD() {
    testnum=`expr $testnum + 1`
    echo "ok $testnum - $1"
    echo "# ok $testnum - $1" >> $SNMP_TMPDIR/invoked
}

BAD() {
    testnum=`expr $testnum + 1`
    errnum=`expr $errnum + 1`
    echo "not ok $testnum - $1"
    echo "# not ok $testnum - $1" >> $SNMP_TMPDIR/invoked
}

COMMENT() {
    echo "# $@"
    echo "# $@" >> $SNMP_TMPDIR/invoked
}

# WAITFORORDIE "grep string" ["file"]
WAITFORORDIE() {
    WAITFOR "$1" "$2"
    if [ "$snmp_last_test_result" != 0 ] ; then
        BAD
        FINISHED
    fi
    GOOD
}

# CHECKORDIE "grep string" ["file"] .. FAIL if "grep string" is *not* found
CHECKORDIE() {
    if [ "x$2" = "x" ]; then
      CHECKFILE "$junkoutputfile" "$1"
    else
      CHECKFILECOUNT "$2" 1 "$1"
    fi
}

# CHECKANDDIE "grep string" ["file"] .. FAIL if "grep string" *is* found
CHECKANDDIE() {
    if [ "x$2" = "x" ]; then
      CHECKFILECOUNT "$junkoutputfile" 0 "$1"
    else
      CHECKFILECOUNT "$2" 0 "$1"
    fi
}

#------------------------------------ -o-
# Returns: Count of matched lines.
#
CHECKEXACT() {	# <pattern_to_match_exactly>
	rval=`grep -wc "$*" "$junkoutputfile" 2>/dev/null`
	snmp_last_test_result=$rval
	EXPECTRESULT 1  # default
	return $rval
}

CONFIGAGENT() {
    if [ "x$SNMP_CONFIG_FILE" = "x" ]; then
	echo "$0: failed because var: SNMP_CONFIG_FILE wasn't set"
	exit 1;
    fi
    echo $* >> $SNMP_CONFIG_FILE
}

CONFIGTRAPD() {
    if [ "x$SNMPTRAPD_CONFIG_FILE" = "x" ]; then
	echo "$0: failed because var: SNMPTRAPD_CONFIG_FILE wasn't set"
	exit 1;
    fi
    echo $* >> $SNMPTRAPD_CONFIG_FILE
}

CONFIGAPP() {
    if [ "x$SNMPAPP_CONFIG_FILE" = "x" ]; then
	echo "$0: failed because var: SNMPAPP_CONFIG_FILE wasn't set"
	exit 1;
    fi
    echo $* >> $SNMPAPP_CONFIG_FILE
}

#
# common to STARTAGENT and STARTTRAPD
# log command to "invoked" file
# delay after command to allow for settle
#
STARTPROG() {
    if [ "x$DYNAMIC_ANALYZER" != "x" ]; then
        COMMAND="$DYNAMIC_ANALYZER $COMMAND"
    fi
    if [ $SNMP_VERBOSE -gt 1 ]; then
	echo "$CFG_FILE contains: "
	if [ -f $CFG_FILE ]; then
	    cat $CFG_FILE
	else
	    echo "[no config file]"
	fi
    fi
    if test -f $CFG_FILE; then
	COMMAND="$COMMAND -C -c $CFG_FILE"
    fi
    if [ "x$PORT_SPEC" != "x" ]; then
        COMMAND="$COMMAND $PORT_SPEC"
    fi
    if [ $SNMP_VERBOSE -gt 0 ]; then
	echo "running: $COMMAND"
    fi
    echo $COMMAND >> $SNMP_TMPDIR/invoked
    if [ $SNMP_VERBOSE -gt 0 ]; then
        OUTPUTENVVARS $LOG_FILE.command
        echo $COMMAND >> $LOG_FILE.command
    fi
    if [ "x$OSTYPE" = "xmsys" ]; then
      $COMMAND > $LOG_FILE.stdout 2>&1 &
      ## COMMAND="cmd.exe //c start //min $COMMAND"
      ## start $COMMAND > $LOG_FILE.stdout 2>&1
    else
      $COMMAND > $LOG_FILE.stdout 2>&1
    fi
}

#------------------------------------ -o-
STARTAGENT() {
    SNMPDSTARTED=1
    COMMAND="snmpd $SNMP_FLAGS -r -U -p $SNMP_SNMPD_PID_FILE -Lf $SNMP_SNMPD_LOG_FILE $AGENT_FLAGS"
    CFG_FILE=$SNMP_CONFIG_FILE
    LOG_FILE=$SNMP_SNMPD_LOG_FILE
    PORT_SPEC="$SNMP_SNMPD_PORT"
    if [ "x$SNMP_TRANSPORT_SPEC" != "x" ]; then
        PORT_SPEC="${SNMP_TRANSPORT_SPEC}:${SNMP_TEST_DEST}${PORT_SPEC}"
    fi
    STARTPROG
    WAITFORAGENT "NET-SNMP version"
}

#------------------------------------ -o-
STARTTRAPD() {
    TRAPDSTARTED=1
    COMMAND="snmptrapd -d -p $SNMP_SNMPTRAPD_PID_FILE -Lf $SNMP_SNMPTRAPD_LOG_FILE $TRAPD_FLAGS"
    CFG_FILE=$SNMPTRAPD_CONFIG_FILE
    LOG_FILE=$SNMP_SNMPTRAPD_LOG_FILE
    PORT_SPEC="$SNMP_SNMPTRAPD_PORT"
    if [ "x$SNMP_TRANSPORT_SPEC" != "x" ]; then
        PORT_SPEC="${SNMP_TRANSPORT_SPEC}:${SNMP_TEST_DEST}${PORT_SPEC}"
    fi
    STARTPROG
    WAITFORTRAPD "NET-SNMP version"
}

## sending SIGHUP for reconfiguration
#
HUPPROG() {
    if [ -f $1 ]; then
        if [ "x$OSTYPE" = "xmsys" ]; then
          COMMAND='echo "Skipping SIGHUP (not supported by kill.exe on MinGW)"'
        else
          COMMAND="kill -HUP `cat $1`"
        fi
	echo $COMMAND >> $SNMP_TMPDIR/invoked
	$COMMAND > /dev/null 2>&1
    fi
}

HUPAGENT() {
    HUPPROG $SNMP_SNMPD_PID_FILE
    if [ "x$OSTYPE" != "xmsys" ]; then
        WAITFORAGENT "restarted"
    fi
}

HUPTRAPD() {
    HUPPROG $SNMP_SNMPTRAPD_PID_FILE
    if [ "x$OSTYPE" != "xmsys" ]; then
        WAITFORTRAPD "restarted"
    fi
}


## used by STOPAGENT and STOPTRAPD
# delay before kill to allow previous action to finish
#    this is especially important for interaction between
#    master agent and sub agent.
STOPPROG() {
    if [ -f $1 ]; then
        if [ "x$OSTYPE" = "xmsys" ]; then
          COMMAND="kill.exe `cat $1`"
        else
          COMMAND="kill -TERM `cat $1`"
        fi
	echo $COMMAND >> $SNMP_TMPDIR/invoked
	$COMMAND > /dev/null 2>&1
    fi
}

#------------------------------------ -o-
#
STOPAGENT() {
    SAVE_RESULTS
    STOPPROG $SNMP_SNMPD_PID_FILE
    WAITFORAGENTSHUTTINGDOWN
    if [ $SNMP_VERBOSE -gt 1 ]; then
	echo "Agent Output:"
	echo "$separator [stdout]"
	cat $SNMP_SNMPD_LOG_FILE.stdout
	echo "$separator [logfile]"
	cat $SNMP_SNMPD_LOG_FILE
	echo "$separator"
    fi
}

#------------------------------------ -o-
#
STOPTRAPD() {
    SAVE_RESULTS
    STOPPROG $SNMP_SNMPTRAPD_PID_FILE
    if [ "x$OSTYPE" != "xmsys" ]; then
        WAITFORTRAPD "Stopped"
    fi
    if [ $SNMP_VERBOSE -gt 1 ]; then
	echo "snmptrapd Output:"
	echo "$separator [stdout]"
	cat $SNMP_SNMPTRAPD_LOG_FILE.stdout
	echo "$separator [logfile]"
	cat $SNMP_SNMPTRAPD_LOG_FILE
	echo "$separator"
    fi
}

#------------------------------------ -o-
#
FINISHED() {

    ## no more changes to test result.
    OK_TO_SAVE_RESULT=0

    if [ "$SNMPDSTARTED" = "1" ] ; then
      STOPAGENT
    fi
    if [ "$TRAPDSTARTED" = "1" ] ; then
      STOPTRAPD
    fi
    for pfile in $SNMP_TMPDIR/*pid* ; do
        if [ "x$pfile" = "x$SNMP_TMPDIR/*pid*" ]; then
            BAD "(no pid file(s) found) "
            break
        fi
        if [ ! -f $pfile ]; then
            BAD "('$pfile' disappeared) "
            continue
        fi
	pid=`cat $pfile`
        # When not running on MinGW, check whether snmpd is still running.
        if [ "x$OSTYPE" = "xmsys" ] || { ps -e 2>/dev/null | egrep "^[	 ]*$pid[	 ]+" > /dev/null 2>&1; }; then
            if [ "x$OSTYPE" != "xmsys" ]; then
                SNMP_SAVE_TMPDIR=yes
            fi
            if [ "x$OSTYPE" = "xmsys" ]; then
              COMMAND="kill.exe $pid"
            else
              COMMAND="kill -9 $pid"
            fi
	    echo $COMMAND "($pfile)" >> $SNMP_TMPDIR/invoked
	    $COMMAND > /dev/null 2>&1
	    return_value=1
	fi
    done

    # report the number of tests done
    GOOD "got to FINISHED"
    echo "1..$testnum"

    if [ "x$errnum" != "x0" ]; then
	if [ -s core ] ; then
	    # XX hope that only one prog cores !
	    cp core $SNMP_TMPDIR/core.$$
	    rm -f core
	fi
	echo "$headerStr...FAIL" >> $SNMP_TMPDIR/invoked
	exit 1
    fi

    echo "$headerStr...ok" >> $SNMP_TMPDIR/invoked

    if [ "x$SNMP_SAVE_TMPDIR" != "xyes" ]; then
	REMOVETESTDATA
    fi
    exit 0
}

#------------------------------------ -o-
#
VERBOSE_OUT() {
    if [ $SNMP_VERBOSE > $1 ]; then
	shift
	echo "$*"
    fi
}

fi # Only allow ourselves to be eval'ed once
