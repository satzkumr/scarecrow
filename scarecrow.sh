#!/bin/bash

#
#Scarecrow - is a project which gives better views on Kafka Broker logs
#Author: Sathishkumar Manimoorthy
#


#Output Directory names goes here - Wont be created unless respective functions called
extraction_logleveldir_name=loglevel_extract_`date +%F`
extraction_classdir_name=classname_extract_`date +%F`

extractdir=`echo "$1" | cut -f 1 -d '.'`

#Command line options parsing goes here

function parse_command()
{
echo "parser"	
}

#Helper functions
function print_usage()
{
	printf "\nUsage : scarecrow.sh [--file] [options]"
        printf "\n--file option is mandatory and needs to be passed as [ --file <Kafka Broker Log> ]\n"
	print_line
        printf "\n[options] one of the below\n"
        printf "\n\t--extract-loglevel = Split based on the Logging level - Default, this option would splipt the logs based on INFO,WARN,ERROR,DEBUG,TRACE"
        printf "\n\t--extract-on-classname = Split the logs based on the Classnames - Default, this option will extract all the classes on the logs and split the messages"
	printf "\n\t--help = To print this help message\n"
	printf "\n"
}

#Helper function that prints line on every call

function print_line()
{
	for i in {1..40}
	do
		printf "==="
	done
}


#
# Function that extracts the log files based on the Logging level
#

function extract_on_loglevel()
{
	
 	brokerlogfile=$1
	logsplitdir=$extractdir/loglevel-split
	outputfile=$logsplitdir/$brokerlogfile
	
	mkdir -p $logsplitdir

	loglevels="INFO WARN ERROR FATAL DEBUG TRACE"
	for level in $loglevels
	do
		echo "Extracting logs for : $level level"
		grep $level $brokerlogfile > $outputfile.$level
	done;
}



#
# Function that split the log files based on the classnames
#

function extract_on_classname()
{
	brokerlogfile=$1
        logsplitdir=$extractdir/class-based-split

	mkdir -p $logsplitdir
	echo "Getting the classnames..."
	
	classnames=`awk -F ' ' '{print $4}' $brokerlogfile | sort | uniq | grep -e 'kafka.\|org.' | uniq`
	echo "Got the classnames...as : $classnames"
	
	#Iterate through the Classes and extract the log messages
	for class in $classnames
        do
                echo "Extracting logs for the class: $class"
                grep $class $brokerlogfile > $logsplitdir/$class
        done;
}


#
# Function that extracts the General broker related information
#

function extract_brokerinfo()
{
	brokerlogfile=$1
        infofile=$extractdir/broker_info
	
	#Extract Broker ID
	brokerid=`grep "kafka.server.KafkaServer: \[Kafka Server" $brokerlogfile | awk -F ' ' '{print $7}' | head -n 1`
	echo "BROKER ID: [$brokerid" > $infofile
	
	#Start stop messages
	
	extract_start_stop $1
	
}
#
# Function that gets start and stop time of Kafka broker if any found would be reported here
# This information would be added in general report of this kafka broker
#

function extract_start_stop()
{
	brokerlogfile=$1
	infofile=$extractdir/broker_info
	
	echo "START & STOP Information" >> $infofile	
	print_line >> $infofile
	printf "\n" >> $infofile
	grep "kafka.server.KafkaServer: \[Kafka Server" $brokerlogfile >>$infofile
	print_line >> $infofile
	printf "\n" >> $infofile
}

#
# Execution starts here!
#

function main()
{
	
	#Execution Starts here
	extract_on_loglevel $1
	extract_on_classname $1
	extract_brokerinfo $1
	#print_usage
}

main $1
