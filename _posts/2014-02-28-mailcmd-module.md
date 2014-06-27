---
title:  Bash module mailcmd
layout: post
author: Wolfgang Resch
---

I combined what i described in the [previous post]({% post_url 2014-02-27-bash-nohup-disown-child %})
with a bit of error checking
and an email upon job completion in this module that i source from my
.bashrc.  Note that it depends on another module which provides the
`log_info` and `log_error` functions. I provide stub functions for
these in this file.  I will describe those separately in more detail
(it involves some exec'ed redirections), but they can easily be
replaced by some very simple functions.  It's pretty self-explanatory.
It creates a log file that may optionally be included in the body of
the email message notifying the user of the completion of the task.


```bash
MAILCMD_DEFAULT_EMAIL="wresch@mail.nih.gov"
MAILCMD_DEFAULT_LOG="mailcmd.log"

function log_info {
    echo "INFO |$@" >&2
}

function log_error {
    echo "ERROR|$@" >&2
}


function mailcmd_usage() {
    cat <<EOF
Usage:
   mailcmd [options] cmd
 
Options:
   -a     email address [an occur more than once for
          multiple addresses]
   -l     name of logfile
   -i     include log file in message
   -h     display this help message
 
Executes command and mails exit status (and optionally the logfile)
with appropriate header to addresses.  Watch out: -l and -a both need
arguments. if none are given the first word of the command may be
mistaken for argument.
 
EOF
}
 
function mailcmd() {
    if [ $# -eq 0 ]; then
        mailcmd_usage
        return 1
    fi
    OPTIND=1
    local address=""
    local log=""
    local mail_log="false"
    while getopts ":a:l:hi" opt; do
        case $opt in
            a) address="$address $OPTARG" ;;
            l) log="$OPTARG" ;;
            i) mail_log="true" ;;
           \?)
                log_error "Invalid option: -${OPTARG-}" >&2
                mailcmd_usage
                return 1
                ;;
            h)
                mailcmd_usage
                return 0
                ;;
            *)
                mailcmd_usage
                return 1
                ;;
        esac
    done
    if [[ -z "$address" ]]; then address="$MAILCMD_DEFAULT_EMAIL"; fi
    if [[ -z "$log" ]]; then log="$MAILCMD_DEFAULT_LOG"; fi
 
    log_info "Addresses: $address"
    log_info "Logfile:   $log"
    shift $(( $OPTIND - 1 ))
    local cmd="$@"
    log_info "Command:   $cmd"
    if [[ -z "$cmd" ]]; then
        log_error "no command provided"
        return 1
    fi
    echo -n "Proceed? [y/n]"
    local ans="n"
    read ans
    case "$ans" in
        y*|Y*) log_info "Starting command" ;;
        *) return 1 ;;
    esac
    if [[ "$mail_log" == "true" ]]; then
        ( "$@" &> $log  \
            && cat $log | mail -s "[SUCCESS] $cmd" $address \
            || cat $log | mail -s "[FAIL   ] $cmd" $address & )
    else
        ( "$@" &> $log  \
            && echo "see log file: $log @ $(hostname)" | mail -s "[SUCCESS] $cmd" $address \
            || echo "see log file: $log @ $(hostname)" | mail -s "[FAIL   ] $cmd" $address & )
    fi
    return 0
}
```