#!/bin/bash

# Create the public version of the OPTD-maintained list of POR, from:
# - optd_por_best_known_so_far.csv
# - optd_por_no_longer_valid.csv
# - ref_airport_pageranked.csv
# - optd_tz_light.csv
# - optd_por_tz.csv
# - optd_cont.csv
# - optd_usdot_wac.csv
# - dump_from_ref_city.csv
# - dump_from_geonames.csv
#
# => optd_por_public.csv
#

##
# Temporary path
TMP_DIR="/tmp/por"

##
# Path of the executable: set it to empty when this is the current directory.
EXEC_PATH=`dirname $0`
# Trick to get the actual full-path
pushd ${EXEC_PATH} > /dev/null
EXEC_FULL_PATH=`popd`
popd > /dev/null
EXEC_FULL_PATH=`echo ${EXEC_FULL_PATH} | sed -e 's|~|'${HOME}'|'`
#
CURRENT_DIR=`pwd`
if [ ${CURRENT_DIR} -ef ${EXEC_PATH} ]
then
	EXEC_PATH="."
	TMP_DIR="."
fi
# If the Geonames dump file is in the current directory, then the current
# directory is certainly intended to be the temporary directory.
if [ -f ${GEO_RAW_FILENAME} ]
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
# Sanity check: that (executable) script should be located in the
# tools/ sub-directory of the OpenTravelData project Git clone
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
# OPTD sub-directories
DATA_DIR=${OPTD_DIR}opentraveldata/
TOOLS_DIR=${OPTD_DIR}tools/

##
# Log level
LOG_LEVEL=3

##
# File of best known coordinates
OPTD_POR_FILENAME=optd_por_best_known_so_far.csv
OPTD_POR_FILE=${DATA_DIR}${OPTD_POR_FILENAME}
# File of no longer valid IATA entries
OPTD_NOIATA_FILENAME=optd_por_no_longer_valid.csv
OPTD_NOIATA_FILE=${DATA_DIR}${OPTD_NOIATA_FILENAME}

##
# Light (and inaccurate) version of the country-related time-zones
OPTD_TZ_CNT_FILENAME=optd_tz_light.csv
OPTD_TZ_CNT_FILE=${DATA_DIR}${OPTD_TZ_CNT_FILENAME}
# Time-zones derived from the closest city in Geonames: more accurate,
# only when the geographical coordinates are themselves accurate of course
OPTD_TZ_POR_FILENAME=optd_por_tz.csv
OPTD_TZ_POR_FILE=${DATA_DIR}${OPTD_TZ_POR_FILENAME}

##
# Mapping between the Countries and their corresponding continent
OPTD_CNT_FILENAME=optd_cont.csv
OPTD_CNT_FILE=${DATA_DIR}${OPTD_CNT_FILENAME}

##
# US DOT World Area Codes (WAC) for countries and states
OPTD_USDOT_FILENAME=optd_usdot_wac.csv
OPTD_USDOT_FILE=${DATA_DIR}${OPTD_USDOT_FILENAME}

##
# PageRank values
OPTD_PR_FILENAME=ref_airport_pageranked.csv
OPTD_PR_FILE=${DATA_DIR}${OPTD_PR_FILENAME}

##
# Geonames (to be found, as temporary files, within the ../tools directory)
GEONAME_RAW_FILENAME=dump_from_geonames.csv
#
GEONAME_RAW_FILE=${TOOLS_DIR}${GEONAME_RAW_FILENAME}
# Geonames with primary key (generated by the
# ../tools/prepare_geonames_dump_file.sh script)
GEONAME_WPK_FILENAME=wpk_${GEONAME_RAW_FILENAME}
#
GEONAME_WPK_FILE=${TOOLS_DIR}${GEONAME_WPK_FILENAME}
# Sorted and cut (also generated by the above script)
GEONAME_SORTED_FILENAME=sorted_${GEONAME_WPK_FILENAME}
GEONAME_CUT_SORTED_FILENAME=cut_${GEONAME_SORTED_FILENAME}
#
GEONAME_SORTED_FILE=${TOOLS_DIR}${GEONAME_SORTED_FILENAME}
GEONAME_CUT_SORTED_FILE=${TOOLS_DIR}${GEONAME_CUT_SORTED_FILENAME}

##
# REF (to be found, as temporary files, within the ../tools directory)
REF_RAW_FILENAME=dump_from_ref_city.csv
#
REF_RAW_FILE=${TOOLS_DIR}${REF_RAW_FILENAME}
# REF with primary key (generated by the
# ../tools/prepare_ref_dump_file.sh script)
REF_WPK_FILENAME=wpk_${REF_RAW_FILENAME}
#
REF_WPK_FILE=${TOOLS_DIR}${REF_WPK_FILENAME}
# Sorted and cut (also generated by the above script)
REF_SORTED_FILENAME=sorted_${REF_WPK_FILENAME}
REF_CUT_SORTED_FILENAME=cut_${REF_SORTED_FILE}
#
REF_SORTED_FILE=${TOOLS_DIR}${REF_SORTED_FILENAME}
REF_CUT_SORTED_FILE=${TOOLS_DIR}${REF_CUT_SORTED_FILENAME}

##
# Innovata (to be found, as temporary files, within the ../tools directory)
INNO_RAW_FILENAME=dump_from_innovata.csv
#
INNO_RAW_FILE=${TOOLS_DIR}${INNO_RAW_FILENAME}

##
# Target (generated files)
OPTD_POR_PUBLIC_FILENAME=optd_por_public.csv
OPTD_ONLY_POR_FILENAME=optd_only_por.csv
OPTD_ONLY_POR_NEW_FILE=${OPTD_ONLY_POR_FILE}.new
#
OPTD_POR_PUBLIC_FILE=${DATA_DIR}${OPTD_POR_PUBLIC_FILENAME}
OPTD_ONLY_POR_FILE=${DATA_DIR}${OPTD_ONLY_POR_FILENAME}

##
# Temporary
OPTD_POR_WITH_NOHD=${OPTD_POR_FILE}.wohd
OPTD_NOIATA_WITH_NOHD=${OPTD_NOIATA_FILE}.wohd
OPTD_POR_WITH_GEO=${OPTD_POR_FILE}.withgeo
OPTD_POR_WITH_GEOREF=${OPTD_POR_FILE}.withgeoref
OPTD_POR_WITH_GEOREFALT=${OPTD_POR_FILE}.withgeorefalt
OPTD_POR_WITH_NO_CTY_NAME=${OPTD_POR_FILE}.withnoctyname
OPTD_POR_PUBLIC_WO_NOIATA_FILE=${OPTD_POR_FILE}.wonoiata
OPTD_POR_PUBLIC_WO_NOIATA_WITH_NOHD=${OPTD_POR_FILE}.wonoiata.wohd
OPTD_POR_PUBLIC_W_NOIATA_UNSORTED_WOHD=${OPTD_POR_FILE}.wnoiata.wohd
OPTD_POR_PUBLIC_W_NOIATA_UNSORTED_FILE=${OPTD_POR_FILE}.wnoiata.unsorted
GEONAME_RAW_FILE_TMP=${GEONAME_RAW_FILE}.alt


##
# Sanity check
if [ ! -d ${TOOLS_DIR} ]
then
	echo
	echo "[$0:$LINENO] The tools/ sub-directory ('${TOOLS_DIR}') does not exist or is not accessible."
	echo "Check that your Git clone of the OpenTravelData is complete."
	echo
	exit -1
fi
if [ ! -f ${TOOLS_DIR}prepare_geonames_dump_file.sh ]
then
	echo
	echo "[$0:$LINENO] The Geonames dump file preparation script ('${TOOLS_DIR}prepare_geonames_dump_file.sh') does not exist or is not accessible."
	echo "Check that your Git clone of the OpenTravelData is complete."
	echo
	exit -1
fi
if [ ! -f ${TOOLS_DIR}prepare_ref_dump_file.sh ]
then
	echo
	echo "[$0:$LINENO] The REF file preparation script ('${TOOLS_DIR}prepare_ref_dump_file.sh') does not exist or is not accessible."
	echo "Check that your Git clone of the OpenTravelData is complete."
	echo
	exit -1
fi


##
# Usage helper
#
if [ "$1" = "-h" -o "$1" = "--help" ]
then
	echo
	echo "That script generates the public version of the OPTD-maintained list of POR (points of reference)"
	echo
	echo "Usage: $0 [<log level (0: quiet; 5: verbose)>]"
	echo " - Default log level (from 0 to 5): ${LOG_LEVEL}"
	echo
	echo "* Input data files"
	echo "------------------"
	echo " - OPTD-maintained file of best known coordinates: '${OPTD_POR_FILE}'"
	echo " - OPTD-maintained file of non longer valid IATA POR: '${OPTD_NOIATA_FILE}'"
	echo " - OPTD-maintained file of PageRanked POR: '${OPTD_PR_FILE}'"
	echo " - OPTD-maintained file of country-related time-zones: '${OPTD_TZ_CNT_FILE}'"
	echo " - OPTD-maintained file of POR-related time-zones: '${OPTD_TZ_POR_FILE}'"
	echo " - OPTD-maintained file of country-continent mapping: '${OPTD_CNT_FILE}'"
	echo " - OPTD-maintained file of US DOT World Area Codes (WAC): '${OPTD_USDOT_FILE}'"
	echo " - REF data dump file: '${REF_RAW_FILE}'"
	echo " - Geonames data dump file: '${GEONAME_RAW_FILE}'"
	echo
	echo "* Output data file"
	echo "------------------"
	echo " - OPTD-maintained public file of POR: '${OPTD_POR_PUBLIC_FILE}'"
	echo " - OPTD-maintained list of non-IATA/outlier POR: '${OPTD_ONLY_POR_FILE}'"
	echo
	exit
fi


##
# Cleaning
#
if [ "$1" = "--clean" ]
then
	\rm -f ${OPTD_POR_WITH_GEO} ${OPTD_ONLY_POR_NEW_FILE} \
		${OPTD_POR_WITH_GEOREF} ${OPTD_POR_WITH_GEOREFALT} \
		${OPTD_POR_PUBLIC_WO_NOIATA_FILE} \
		${OPTD_POR_PUBLIC_WO_NOIATA_WITH_NOHD} \
		${OPTD_POR_PUBLIC_W_NOIATA_UNSORTED_WOHD} \
		${OPTD_POR_PUBLIC_W_NOIATA_UNSORTED_FILE} \
		${OPTD_NOIATA_WITH_NOHD} \
		${OPTD_POR_WITH_NO_CTY_NAME} ${OPTD_POR_FILE_HEADER} ${OPTD_POR_WITH_NOHD} \
		${GEONAME_WPK_FILE} ${GEONAME_RAW_FILE_TMP} \
		${GEONAME_SORTED_FILE} ${GEONAME_CUT_SORTED_FILE} \
		${REF_SORTED_FILE} ${REF_CUT_SORTED_FILE} \
		${OPTD_ONLY_POR_NEW_FILE}

	bash prepare_geonames_dump_file.sh --clean || exit -1
	bash prepare_ref_dump_file.sh --clean || exit -1
	exit
fi


##
# Log level
if [ "$1" != "" ]
then
	LOG_LEVEL="$1"
fi


##
# Preparation
bash prepare_geonames_dump_file.sh ${OPTD_DIR} ${LOG_LEVEL} || exit -1
bash prepare_ref_dump_file.sh ${OPTD_DIR} ${TOOLS_DIR} ${LOG_LEVEL} || exit -1

##
#
if [ ! -f ${GEONAME_SORTED_FILE} ]
then
	echo
	echo "[$0:$LINENO] The '${GEONAME_SORTED_FILE}' file does not exist."
	echo
	exit -1
fi
if [ ! -f ${REF_SORTED_FILE} ]
then
	echo
	echo "[$0:$LINENO] The '${REF_SORTED_FILE}' file does not exist."
	echo
	exit -1
fi

##
# Save the extra alternate names (from field #34 onwards)
cut -d'^' -f1,34- ${GEONAME_SORTED_FILE} > ${GEONAME_RAW_FILE_TMP}
# Remove the extra alternate names (see the line above)
cut -d'^' -f1-33 ${GEONAME_SORTED_FILE} > ${GEONAME_CUT_SORTED_FILE}

##
# Remove the header
sed -e "s/^pk\(.\+\)//g" ${OPTD_POR_FILE} > ${OPTD_POR_WITH_NOHD}
sed -i -e "/^$/d" ${OPTD_POR_WITH_NOHD}

##
# Aggregate all the data sources into a single file
#
# ${OPTD_POR_FILE} (optd_por_best_known_so_far.csv) and
# ${GEONAME_CUT_SORTED_FILE} (../tools/cut_sorted_wpk_dump_from_geonames.csv)
# are joined on the primary key (i.e., IATA code - location type):
join -t'^' -a 1 -1 1 -2 1 ${OPTD_POR_WITH_NOHD} ${GEONAME_CUT_SORTED_FILE} \
	> ${OPTD_POR_WITH_GEO}

# ${OPTD_POR_WITH_GEO} (optd_por_best_known_so_far.csv.withgeo) and
# ${GEONAME_CUT_SORTED_FILE} (sorted_wpk_dump_from_ref_city.csv) are joined on
# the primary key (i.e., IATA code - location type):
join -t'^' -a 1 -1 1 -2 1 ${OPTD_POR_WITH_GEO} ${REF_SORTED_FILE} \
	> ${OPTD_POR_WITH_GEOREF}

# ${OPTD_POR_WITH_GEOREF} (optd_por_best_known_so_far.csv.withgeoref) and
# ${GEONAME_RAW_FILE_TMP} (../tools/dump_from_geonames.csv.alt) are joined on
# the primary key (i.e., IATA code - location type):
join -t'^' -a 1 -1 1 -2 1 ${OPTD_POR_WITH_GEOREF} ${GEONAME_RAW_FILE_TMP} \
	> ${OPTD_POR_WITH_GEOREFALT}

##
# Re-format the aggregated entries. See ${REDUCER} for more details and samples.
echo
echo "Aggregation Step"
echo "----------------"
echo
REDUCER=make_optd_por_public.awk
time awk -F'^' -v non_optd_por_file="${OPTD_ONLY_POR_FILE}" -f ${REDUCER} \
	 ${OPTD_PR_FILE} ${OPTD_TZ_CNT_FILE} ${OPTD_TZ_POR_FILE} ${OPTD_CNT_FILE} \
	 ${OPTD_USDOT_FILE} ${OPTD_POR_WITH_GEOREFALT} \
	 > ${OPTD_POR_WITH_NO_CTY_NAME}

##
# Write the UTF8 and ASCII names of the city served by every travel-related
# point of reference (POR).
echo
echo "City addition Step"
echo "------------------"
echo
CITY_WRITER=add_city_name.awk
time awk -F'^' -f ${CITY_WRITER} \
	${OPTD_POR_WITH_NO_CTY_NAME} ${OPTD_POR_WITH_NO_CTY_NAME} \
	> ${OPTD_POR_PUBLIC_WO_NOIATA_FILE}

##
# Extract the header into temporary files
OPTD_POR_FILE_HEADER=${OPTD_POR_FILE}.tmp.hdr
grep "^iata_code\(.\+\)" ${OPTD_POR_PUBLIC_WO_NOIATA_FILE} \
	> ${OPTD_POR_FILE_HEADER}

# Remove the headers
sed -e "s/^iata_code\(.\+\)//g" ${OPTD_POR_PUBLIC_WO_NOIATA_FILE} \
	> ${OPTD_POR_PUBLIC_WO_NOIATA_WITH_NOHD}
sed -i -e "/^$/d" ${OPTD_POR_PUBLIC_WO_NOIATA_WITH_NOHD}

sed -e "s/^iata_code\(.\+\)//g" ${OPTD_NOIATA_FILE} > ${OPTD_NOIATA_WITH_NOHD}
sed -i -e "/^$/d" ${OPTD_NOIATA_WITH_NOHD}


##
# Add the non longer valid IATA entries.
echo
echo "No longer valid IATA Step"
echo "-------------------------"
echo
NOIATA_ADDER=add_noiata_por.awk
time awk -F'^' -f ${NOIATA_ADDER} \
	${OPTD_POR_PUBLIC_WO_NOIATA_WITH_NOHD} ${OPTD_NOIATA_WITH_NOHD} \
	> ${OPTD_POR_PUBLIC_W_NOIATA_UNSORTED_WOHD}

##
# Sort the final file
echo
echo "Sorting Step"
echo "------------"
echo
# Sort on the IATA code, feature code and Geonames ID, in that order
time sort -t'^' -k1,1 -k42,42 -k5,5 ${OPTD_POR_PUBLIC_W_NOIATA_UNSORTED_WOHD} \
	> ${OPTD_POR_PUBLIC_W_NOIATA_UNSORTED_FILE}
cat ${OPTD_POR_FILE_HEADER} ${OPTD_POR_PUBLIC_W_NOIATA_UNSORTED_FILE} \
	> ${OPTD_POR_PUBLIC_FILE}


##
# Remove the header
\rm -f ${OPTD_POR_FILE_HEADER}

##
# Reporting
#
echo
echo "Reporting Step"
echo "--------------"
echo
echo "wc -l ${OPTD_POR_FILE} ${OPTD_POR_PUBLIC_FILE} ${OPTD_POR_PUBLIC_W_NOIATA_UNSORTED_FILE} ${OPTD_POR_PUBLIC_W_NOIATA_UNSORTED_WOHD} ${OPTD_POR_PUBLIC_WO_NOIATA_WITH_NOHD} ${OPTD_POR_PUBLIC_WO_NOIATA_FILE} ${OPTD_POR_WITH_GEO} ${OPTD_POR_WITH_GEOREF} ${OPTD_POR_WITH_GEOREFALT} ${OPTD_POR_WITH_NO_CTY_NAME}"
if [ -f ${OPTD_ONLY_POR_NEW_FILE} ]
then
	NB_LINES_OPTD_ONLY=`wc -l ${OPTD_ONLY_POR_NEW_FILE}`
	echo
	echo "See also the '${OPTD_ONLY_POR_NEW_FILE}' file, which contains ${NB_LINES_OPTD_ONLY} lines:"
	echo "less ${OPTD_ONLY_POR_NEW_FILE}"
fi
echo
