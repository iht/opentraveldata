#!/bin/bash
#
# One parameter is optional for this script:
# - the file-path of the data dump file extracted from Innovata.
#

displayGeonamesDetails() {
    if [ -z "${OPTDDIR}" ]
    then
	export OPTDDIR=~/dev/geo/optdgit/data/geonames/data
    fi
    if [ -z "${MYCURDIR}" ]
    then
	export MYCURDIR=`pwd`
    fi
    echo
    echo "The data dump from Geonames can be obtained from the OpenTravelData project"
    echo "(http://github.com/opentraveldata/optd). For instance:"
    echo "MYCURDIR=`pwd`"
    echo "OPTDDIR=${OPTDDIR}"
    echo "mkdir -p ~/dev/geo"
    echo "cd ~/dev/geo"
    echo "git clone git://github.com/opentraveldata/opentraveldata.git optdgit"
    echo "cd optdgit/data/geonames/data"
    echo "./getDataFromGeonamesWebsite.sh  # it may take several minutes"
    echo "cd por/admin"
    echo "./aggregateGeonamesPor.sh # it may take several minutes (~10 minutes)"
    if [ "${TMP_DIR}" = "/tmp/por/" ]
    then
	echo "mkdir -p ${TMP_DIR}"
    fi
    echo "cd ${MYCURDIR}"
    echo "${OPTDDIR}/tools/extract_por_with_iata_icao.sh # it may take several minutes"
    echo "It produces both a por_all_iata_YYYYMMDD.csv and a por_all_noicao_YYYYMMDD.csv files,"
    echo "which have to be aggregated into the dump_from_geonames.csv file."
    echo "${OPTDDIR}/tools/preprepare_geonames_dump_file.sh"
    echo "\cp -f ${OPTDDIR}/opentraveldata/optd_por_best_known_so_far.csv ${TMP_DIR}"
    echo "\cp -f ${OPTDDIR}/opentraveldata/ref_airport_pageranked.csv ${TMP_DIR}"
    echo "\cp -f ${OPTDDIR}/opentraveldata/optd_por_public.csv ${TMP_DIR}optd_airports.csv"
    echo "${OPTDDIR}/tools/update_airports_csv_after_getting_geonames_iata_dump.sh"
    echo "ls -l ${TMP_DIR}"
    echo
}

displayInnovataDetails() {
    ##
    # Snapshot date
    SNAPSHOT_DATE=`date "+%Y%m%d"`
    SNAPSHOT_DATE_HUMAN=`date`
    echo
    echo "####### Note #######"
    echo "# The data dump from Innovata has to be obtained from Innovata directly."
    echo "# The Innovata dump file ('${INN_RAW_FILENAME}') should be in the ${INN_DIR} directory:"
    ls -la ${INN_DIR}
    echo "#####################"
    echo
}

##
# Input file names
INN_RAW_FILENAME=stations.dat
GEO_OPTD_FILENAME=optd_por_best_known_so_far.csv

##
# Temporary path
TMP_DIR="/tmp/por"
MYCURDIR=`pwd`

##
# Path of the executable: set it to empty when this is the current directory.
EXEC_PATH=`dirname $0`
# Trick to get the actual full-path
EXEC_FULL_PATH=`pushd ${EXEC_PATH}`
EXEC_FULL_PATH=`echo ${EXEC_FULL_PATH} | cut -d' ' -f1`
EXEC_FULL_PATH=`echo ${EXEC_FULL_PATH} | sed -e 's|~|'${HOME}'|'`
#
CURRENT_DIR=`pwd`
if [ ${CURRENT_DIR} -ef ${EXEC_PATH} ]
then
    EXEC_PATH="."
    TMP_DIR="."
fi
# If the Innovata dump file is in the current directory, then the current
# directory is certainly intended to be the temporary directory.
if [ -f ${INN_RAW_FILENAME} ]
then
    TMP_DIR="."
fi
EXEC_PATH="${EXEC_PATH}/"
TMP_DIR="${TMP_DIR}/"

if [ ! -d ${TMP_DIR} -o ! -w ${TMP_DIR} ]
then
    \mkdir -p ${TMP_DIR}
fi

##
# Sanity check: that (executable) script should be located in the tools/
# sub-directory of the OpenTravelData project Git clone
EXEC_DIR_NAME=`basename ${EXEC_FULL_PATH}`
if [ "${EXEC_DIR_NAME}" != "tools" ]
then
    echo
    echo "[$0:$LINENO] Inconsistency error: this script ($0) should be located in the refdata/tools/ sub-directory of the OpenTravelData project Git clone, but apparently is not. EXEC_FULL_PATH=\"${EXEC_FULL_PATH}\""
    echo
    exit -1
fi

##
# OpenTravelData directory
OPTD_DIR=`dirname ${EXEC_FULL_PATH}`
OPTD_DIR="${OPTD_DIR}/"

##
# OPTD sub-directory
DATA_DIR=${OPTD_DIR}opentraveldata/
TOOLS_DIR=${OPTD_DIR}tools/

##
# Innovata sub-directory
INN_DIR=${OPTD_DIR}data/Innovata/

##
# Log level
LOG_LEVEL=4

##
# Input files
INN_RAW_FILE=${INN_DIR}${INN_RAW_FILENAME}
GEO_OPTD_FILE=${DATA_DIR}${GEO_OPTD_FILENAME}

##
# Innovata
INN_RAW_BASE_FILENAME=`basename ${INN_RAW_FILENAME} .dat`
INN_RAW_CSV_FILENAME=${INN_RAW_BASE_FILENAME}.csv
INN_DMP_FILENAME=dump_from_innovata.csv
INN_WPK_FILENAME=wpk_${INN_DMP_FILENAME}
SORTED_INN_WPK_FILENAME=sorted_${INN_WPK_FILENAME}
SORTED_CUT_INN_WPK_FILENAME=cut_${SORTED_INN_WPK_FILENAME}
#
INN_DMP_FILE=${TMP_DIR}${INN_DMP_FILENAME}
INN_WPK_FILE=${TMP_DIR}${INN_WPK_FILENAME}
SORTED_INN_WPK_FILE=${TMP_DIR}${SORTED_INN_WPK_FILENAME}
SORTED_CUT_INN_WPK_FILE=${TMP_DIR}${SORTED_CUT_INN_WPK_FILENAME}


##
# Cleaning
if [ "$1" = "--clean" ]
then
    if [ "${TMP_DIR}" = "/tmp/por" ]
    then
	\rm -rf ${TMP_DIR}
    else
	\rm -f ${SORTED_INN_WPK_FILE} ${SORTED_CUT_INN_WPK_FILE}
	\rm -f ${INN_WPK_FILE}
    fi
    exit
fi


##
#
if [ "$1" = "-h" -o "$1" = "--help" ]
then
    echo
    echo "Usage: $0 [<refdata directory of the OpenTravelData project Git clone> [<Innovata data dump file> [<log level>]]]"
    echo "  - Default refdata directory for the OpenTravelData project Git clone: '${OPTD_DIR}'"
    echo "  - Default path for the OPTD-maintained file of best known coordinates: '${GEO_OPTD_FILE}'"
    echo "  - Default path for the Innovata data dump file: '${INN_RAW_FILE}'"
    echo "  - Default log level: ${LOG_LEVEL}"
    echo "    + 0: No log; 1: Critical; 2: Error; 3; Notification; 4: Debug; 5: Verbose"
    echo "  - Generated files:"
    echo "    + '${INN_DMP_FILE}'"
    echo "    + '${INN_WPK_FILE}'"
    echo "    + '${SORTED_INN_WPK_FILE}'"
    echo "    + '${SORTED_CUT_INN_WPK_FILE}'"
    echo
    exit
fi
#
if [ "$1" = "-g" -o "$1" = "--geonames" ]
then
    displayGeonamesDetails
    exit
fi
if [ "$1" = "-r" -o "$1" = "--innovata" ]
then
    displayInnovataDetails
    exit
fi

##
# The OpenTravelData refdata/ sub-directory contains, among other things,
# the OPTD-maintained list of POR file with geographical coordinates.
if [ "$1" != "" ]
then
    if [ ! -d $1 ]
    then
	echo
	echo "[$0:$LINENO] The first parameter ('$1') should point to the refdata/ sub-directory of the OpenTravelData project Git clone. It is not accessible here."
	echo
	exit -1
    fi
    OPTD_DIR_DIR=`dirname $1`
    OPTD_DIR_BASE=`basename $1`
    OPTD_DIR="${OPTD_DIR_DIR}/${OPTD_DIR_BASE}/"
    DATA_DIR=${OPTD_DIR}opentraveldata/
    TOOLS_DIR=${OPTD_DIR}tools/
    GEO_OPTD_FILE=${DATA_DIR}${GEO_OPTD_FILENAME}
fi

if [ ! -f "${GEO_OPTD_FILE}" ]
then
    echo
    echo "[$0:$LINENO] The '${GEO_OPTD_FILE}' file does not exist."
    echo
    if [ "$1" = "" ]
    then
	displayGeonamesDetails
    fi
    exit -1
fi

##
# Innovata data dump file with geographical coordinates
if [ "$2" != "" ]
then
    INN_RAW_FILE="$2"
    INN_RAW_BASE_FILENAME=`basename ${INN_RAW_FILE} .dat`
    INN_RAW_CSV_FILENAME=${INN_RAW_BASE_FILENAME}.csv
    INN_WPK_FILENAME=wpk_${INN_RAW_CSV_FILENAME}
    SORTED_INN_WPK_FILENAME=sorted_${INN_WPK_FILENAME}
    SORTED_CUT_INN_WPK_FILENAME=cut_${SORTED_INN_WPK_FILENAME}
    if [ "${INN_RAW_FILE}" = "${INN_RAW_FILENAME}" ]
    then
	INN_RAW_FILE="${TMP_DIR}${INN_RAW_FILE}"
    fi
fi
INN_WPK_FILE=${TMP_DIR}${INN_WPK_FILENAME}
SORTED_INN_WPK_FILE=${TMP_DIR}${SORTED_INN_WPK_FILENAME}
SORTED_CUT_INN_WPK_FILE=${TMP_DIR}${SORTED_CUT_INN_WPK_FILENAME}

if [ ! -f "${INN_RAW_FILE}" ]
then
    echo
    echo "[$0:$LINENO] The '${INN_RAW_FILE}' file does not exist."
    echo
    if [ "$2" = "" ]
    then
	displayInnovataDetails
    fi
    exit -1
fi

##
# Log level
if [ "$3" != "" ]
then
    LOG_LEVEL="$3"
fi


##
# Generate a second version of the file with the OPTD primary key
# (integrating the location type)
OPTD_PK_ADDER=${TOOLS_DIR}inn_pk_creator.awk
awk -F'^' -v log_level=${LOG_LEVEL} -f ${OPTD_PK_ADDER} \
    ${GEO_OPTD_FILE} ${INN_RAW_FILE} > ${INN_WPK_FILE}
#sort -t'^' -k1,1 ${INN_WPK_FILE}

##
# Generate a dump file in a format pretty much the same
# as for reference data and Geonames
cut -d'^' -f 2- ${INN_WPK_FILE} > ${INN_DMP_FILE}

##
# Remove the header (first line)
INN_WPK_FILE_TMP=${INN_WPK_FILE}.tmp
sed -e "s/^pk\(.\+\)//g" ${INN_WPK_FILE} > ${INN_WPK_FILE_TMP}
sed -i -e "/^$/d" ${INN_WPK_FILE_TMP}

##
# That version of the Innovata dump file (without primary key) is sorted
# according to the IATA code.
sort -t'^' -k 1,1 ${INN_WPK_FILE_TMP} > ${SORTED_INN_WPK_FILE}
\rm -f ${INN_WPK_FILE_TMP}

##
# Only four columns/fields are kept in that version of the file:
# the primary key, airport/city IATA code and the geographical coordinates
# (latitude, longitude).
cut -d'^' -f 1,2,8,9 ${SORTED_INN_WPK_FILE} > ${SORTED_CUT_INN_WPK_FILE}

##
# Reporting
echo
echo "Preparation step"
echo "----------------"
echo "The '${INN_DMP_FILE}', '${INN_WPK_FILE}', '${SORTED_INN_WPK_FILE}' and '${SORTED_CUT_INN_WPK_FILE}' files have been derived from '${INN_RAW_FILE}'."
echo

