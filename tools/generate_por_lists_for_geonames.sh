#!/bin/bash

displayGeonamesDetails() {
	if [ -z "${OPTDDIR}" ]
	then
		export OPTDDIR=~/dev/geo/optdgit/refdata
	fi
	if [ -z "${MYCURDIR}" ]
	then
		export MYCURDIR=`pwd`
	fi
	echo
	echo "The data dump from Geonames can be obtained from the OpenTravelData project"
	echo "(http://github.com/opentraveldata/opentraveldata). For instance:"
	echo "MYCURDIR=`pwd`"
	echo "OPTDDIR=${OPTDDIR}"
	echo "mkdir -p ~/dev/geo"
	echo "cd ~/dev/geo"
	echo "git clone git://github.com/opentraveldata/opentraveldata.git optdgit"
	echo "cd optdgit/refdata/geonames/data"
	echo "./getDataFromGeonamesWebsite.sh  # it may take several minutes"
	echo "cd por/admin"
	echo "./aggregateGeonamesPor.sh # it may take several minutes (~10 minutes)"
	if [ "${TMP_DIR}" = "/tmp/por/" ]
	then
		echo "mkdir -p ${TMP_DIR}"
	fi
	echo "cd ${MYCURDIR}"
	echo "${OPTDDIR}/tools/extract_por_with_iata_icao.sh # it may take several minutes"
	echo "It produces both a por_all_iata_YYYYMMDD.csv and a por_noiata_YYYYMMDD.csv files."
	echo "The former has to be copied into the dump_from_geonames.csv file."
	echo "${OPTDDIR}/tools/preprepare_geonames_dump_file.sh"
	echo "\cp -f ${OPTDDIR}/opentraveldata/optd_por_best_known_so_far.csv ${TMP_DIR}"
	echo "\cp -f ${OPTDDIR}/opentraveldata/ref_airport_pageranked.csv ${TMP_DIR}"
	echo "\cp -f ${OPTDDIR}/opentraveldata/optd_por_public.csv ${TMP_DIR}optd_airports.csv"
	echo "${OPTDDIR}/tools/update_airports_csv_after_getting_geonames_iata_dump.sh"
	echo "ls -l ${TMP_DIR}"
	echo
}

displayRefDetails() {
    ##
    # Snapshot date
	SNAPSHOT_DATE=`date "+%Y%m%d"`
	SNAPSHOT_DATE_HUMAN=`date`
	echo
	echo "####### Note #######"
	echo "# Additional data files may be obtained from this project"
	echo "# (http://<gitorious/bitbucket>/dataanalysis/dataanalysis.git). For instance:"
	echo "DAREF=~/dev/dataanalysis/dataanalysisgit/data_generation"
	echo "mkdir -p ~/dev/dataanalysis"
	echo "cd ~/dev/dataanalysis"
	echo "git clone git://<gitorious/bitbucket>/dataanalysis/dataanalysis.git dataanalysisgit"
	echo "cd \${DAREF}/REF"
	echo "# The following script fetches a SQLite file, holding reference data,"
	echo "# and translates it into three MySQL-compatible SQL files:"
	echo "./fetch_sqlite_ref.sh # it may take several minutes"
	echo "# It produces three create_*_ref_*${SNAPSHOT_DATE}.sql files, which are then"
	echo "# used by the following script, in order to load the reference data into MySQL:"
	echo "./create_ref_user.sh"
	echo "./create_ref_db.sh"
	echo "./create_all_tables.sh geo ref_ref ${SNAPSHOT_DATE}"
	if [ "${TMP_DIR}" = "/tmp/por/" ]
	then
		echo "mkdir -p ${TMP_DIR}"
	fi
	echo "cd ${MYCURDIR}"
	echo "# The MySQL CITY table has then to be exported into a CSV file."
	echo "\${DAREF}/por/extract_ref_por.sh geo ref_ref"
	echo "\cp -f ${TMP_DIR}por_all_ref_${SNAPSHOT_DATE}.csv ${TMP_DIR}dump_from_ref_city.csv"
	echo "\cp -f ${OPTDDIR}/opentraveldata/optd_por_best_known_so_far.csv ${TMP_DIR}"
	echo "\cp -f ${OPTDDIR}/opentraveldata/ref_airport_popularity.csv ${TMP_DIR}"
	echo "\cp -f ${OPTDDIR}/opentraveldata/optd_por.csv ${TMP_DIR}optd_airports.csv"
	echo "\${DAREF}/update_airports_csv_after_getting_ref_city_dump.sh"
	echo "ls -l ${TMP_DIR}"
	echo "#####################"
	echo
}

##
# Input file names
REF_RAW_FILENAME=dump_from_ref_city.csv
GEO_OPTD_FILENAME=optd_por_best_known_so_far.csv
GEONAMES_FILENAME=dump_from_geonames.csv
PR_OPTD_FILENAME=ref_airport_pageranked.csv
FOR_GEONAMES_FILENAME=por_in_iata_but_missing_from_geonames.csv

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
# If the REF dump file is in the current directory, then the current
# directory is certainly intended to be the temporary directory.
if [ -f ${REF_RAW_FILENAME} ]
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
# Log level
LOG_LEVEL=4

##
# Input files
REF_RAW_FILE=${TOOLS_DIR}${REF_RAW_FILENAME}
GEO_OPTD_FILE=${DATA_DIR}${GEO_OPTD_FILENAME}
GEONAMES_FILE=${TMP_DIR}${GEONAMES_FILENAME}
PR_OPTD_FILE=${DATA_DIR}${PR_OPTD_FILENAME}

##
# Reference data files
REF_CAP_FILENAME=cap_${REF_RAW_FILENAME}
REF_RAW_HEADER_FILENAME=${REF_RAW_FILENAME}.tmp.hdr
#
REF_CAP_FILE=${TMP_DIR}${REF_CAP_FILENAME}
REF_RAW_HEADER_FILE=${TMP_DIR}${REF_RAW_HEADER_FILENAME}

##
# OPTD
SORTED_PR_OPTD_FILENAME=sorted_${PR_OPTD_FILENAME}
#
SORTED_PR_OPTD_FILE=${TMP_DIR}${SORTED_PR_OPTD_FILENAME}

##
# Combination of Geonames and reference data
GEO_COMB_FILENAME=${GEONAMES_FILENAME}.withref
CUT_GEO_COMB_FILENAME=${GEO_COMB_FILENAME}.cut
GEO_COMB_FILE=${TMP_DIR}${GEO_COMB_FILENAME}
CUT_GEO_COMB_FILE=${TMP_DIR}${CUT_GEO_COMB_FILENAME}

##
# Geonames
GEONAMES_FILE_MISSING=${TMP_DIR}wpk_${GEONAMES_FILENAME}.missing
GEONAMES_FILE_TMP=${TMP_DIR}${GEONAMES_FILENAME}.tmp
FOR_GEONAMES_FILE=${TMP_DIR}${FOR_GEONAMES_FILENAME}
FOR_GEONAMES_PR_FILE=${TMP_DIR}pageranked_${FOR_GEONAMES_FILENAME}

##
# Cleaning
if [ "$1" = "--clean" ]
then
	if [ "${TMP_DIR}" = "/tmp/por" ]
	then
		\rm -rf ${TMP_DIR}
	else
		\rm -f ${FOR_GEONAMES_FILE} ${FOR_GEONAMES_PR_FILE} ${REF_CAP_FILE}
		\rm -f ${GEO_COMB_FILE} ${CUT_GEO_COMB_FILE} ${REF_RAW_HEADER_FILE}

	fi
	exit
fi


##
#
if [ "$1" = "-h" -o "$1" = "--help" ]
then
	echo
	echo "Usage: $0 [<refdata directory of the OpenTravelData project Git clone> [<Reference CITY data file> [<log level>]]]"
	echo "  - Default refdata directory for the OpenTravelData project Git clone: '${OPTD_DIR}'"
	echo "  - Default path for the OPTD-maintained file of best known coordinates: '${GEO_OPTD_FILE}'"
	echo "  - Default path for the reference CITY data file: '${REF_RAW_FILE}'"
	echo "  - Default log level: ${LOG_LEVEL}"
	echo "    + 0: No log; 1: Critical; 2: Error; 3; Notification; 4: Debug; 5: Verbose"
	echo "  - Generated files:"
	echo "    + '${REF_CAP_FILE}'"
	echo "    + '${FOR_GEONAMES_FILE}'"
	echo "    + '${FOR_GEONAMES_PR_FILE}'"
	echo
	exit
fi
#
if [ "$1" = "-g" -o "$1" = "--geonames" ]
then
	displayGeonamesDetails
	exit
fi
if [ "$1" = "-r" -o "$1" = "--ref" ]
then
	displayRefDetails
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

if [ ! -f "${GEONAMES_FILE_MISSING}" ]
then
	echo
	echo "[$0:$LINENO] The '${GEONAMES_FILE_MISSING}' file does not exist."
	echo "Hint: launch the ${EXEC_PATH}compare_por_files.sh script."
	echo
	exit -1
fi


##
# Reference data file with geographical coordinates
if [ "$2" != "" ]
then
	REF_RAW_FILE="$2"
	REF_RAW_FILENAME=`basename ${REF_RAW_FILE}`
	REF_CAP_FILENAME=cap_${REF_RAW_FILENAME}
	if [ "${REF_RAW_FILE}" = "${REF_RAW_FILENAME}" ]
	then
		REF_RAW_FILE="${TMP_DIR}${REF_RAW_FILE}"
	fi
fi
REF_CAP_FILE=${TMP_DIR}${REF_CAP_FILENAME}

if [ ! -f "${REF_RAW_FILE}" ]
then
	echo
	echo "[$0:$LINENO] The '${REF_RAW_FILE}' file does not exist."
	echo
	if [ "$2" = "" ]
	then
		displayRefDetails
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
# Capitalise the names
REF_CAPITILISER=${EXEC_PATH}ref_capitalise.awk
awk -F'^' -v log_level=${LOG_LEVEL} -f ${REF_CAPITILISER} ${REF_RAW_FILE} \
	> ${REF_CAP_FILE}

##
# Header
HDR_1="iata_code^ticketing_name^detailed_name^teleticketing_name^extended_name^city_name^rel_city_code^is_airport^state_code^rel_country_code^rel_region_code^rel_continent_code^rel_time_zone_grp^latitude^longitude^numeric_code^is_commercial^location_type"
HDR_2="${HDR_1}^page_rank"

##
# Extract the header into a temporary file
grep "^iata_code\(.\+\)" ${REF_CAP_FILE} > ${REF_RAW_HEADER_FILE}

# Remove the header
sed -i -e "s/^iata_code\(.\+\)//g" ${REF_CAP_FILE}
sed -i -e "/^$/d" ${REF_CAP_FILE}

##
# Extract only the IATA code from the file
cut -d'^' -f2 ${GEONAMES_FILE_MISSING} > ${GEONAMES_FILE_TMP}
\mv -f ${GEONAMES_FILE_TMP} ${GEONAMES_FILE_MISSING}

##
# Check that all the POR are in the reference data file.
join -t'^' -a 2 ${REF_CAP_FILE} ${GEONAMES_FILE_MISSING} > ${GEO_COMB_FILE}
awk -F'^' '{if (NF != 18) {printf ($0 "\n")}}' ${GEO_COMB_FILE} \
	> ${CUT_GEO_COMB_FILE}
# If there are any non-referenced entries, suggest to remove them.
NB_NON_REF_ROWS=`wc -l ${CUT_GEO_COMB_FILE} | cut -d' ' -f1`
if [ ${NB_NON_REF_ROWS} -gt 0 ]
then
	echo
	echo "${NB_NON_REF_ROWS} POR are not in the reference data, but present in the ${GEONAMES_FILE_MISSING} file. To see them:"
	echo "less ${CUT_GEO_COMB_FILE}"
	echo "Remove those entries from the ${GEONAMES_FILE_MISSING} file:"
	echo "vi ${GEONAMES_FILE_MISSING}"
	echo
	exit -1
fi

##
# Generate the file for Geonames
join -t'^' -a 2 ${REF_CAP_FILE} ${GEONAMES_FILE_MISSING} > ${FOR_GEONAMES_FILE}
NB_ROWS=`wc -l ${FOR_GEONAMES_FILE} | cut -d' ' -f1`

##
# Generate a version with the PageRanked POR
sort -t'^' -k1,1 ${PR_OPTD_FILE} > ${SORTED_PR_OPTD_FILE}
join -t'^' -a 1 ${FOR_GEONAMES_FILE} ${SORTED_PR_OPTD_FILE} > ${GEONAMES_FILE_TMP}
awk -F'^' '{printf ($0); if (NF == 18) {print ("^0.01")} else {print ("")}}' \
	${GEONAMES_FILE_TMP} > ${FOR_GEONAMES_PR_FILE}
#echo "head -3 ${GEONAMES_FILE_TMP} ${FOR_GEONAMES_PR_FILE}"
sort -t'^' -k19nr,19 ${FOR_GEONAMES_PR_FILE} > ${GEONAMES_FILE_TMP}
\mv -f ${GEONAMES_FILE_TMP} ${FOR_GEONAMES_PR_FILE}

##
# Re-add the headers
cat ${REF_RAW_HEADER_FILE} ${FOR_GEONAMES_FILE} > ${GEONAMES_FILE_TMP}
\mv -f ${GEONAMES_FILE_TMP} ${FOR_GEONAMES_FILE}
\rm -f ${FOR_GEONAMES_FILE}.hdr

echo "${HDR_2}" > ${FOR_GEONAMES_FILE}.hdr
cat ${FOR_GEONAMES_FILE}.hdr ${FOR_GEONAMES_PR_FILE} > ${GEONAMES_FILE_TMP}
\mv -f ${GEONAMES_FILE_TMP} ${FOR_GEONAMES_PR_FILE}
\rm -f ${FOR_GEONAMES_FILE}.hdr

##
# Reporting
echo
echo "Reporting"
echo "---------"
echo "Both the ${FOR_GEONAMES_FILE} and ${FOR_GEONAMES_PR_FILE} files have been generated from ${REF_RAW_FILE} and ${GEONAMES_FILE_MISSING}."
echo "${NB_ROWS} rows are in the reference data, but missing from Geonames."
echo "gzip ${FOR_GEONAMES_FILE} ${FOR_GEONAMES_PR_FILE}"
echo
