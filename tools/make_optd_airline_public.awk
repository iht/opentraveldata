##
# That AWK script re-formats the full details of airlines
# derived from a few sources:
#  * OPTD-maintained lists of:
#    * Best known airlines:                 optd_airline_best_known_so_far.csv
#    * Alliance memberships:                optd_airline_alliance_membership.csv
#    * No longer valid airlines:            optd_airline_no_longer_valid.csv
#    * Nb of flight-dates:                  ref_airline_nb_of_flights.csv
#  * Referential Data:                      dump_from_ref_airline.csv
#  * [Future] Geonames list of airlines:    dump_from_geonames.csv
#
# Sample output lines:
# alc-oneworld^^^^^*O^0^Oneworld^^^^^^^en|Oneworld|^
# alc-skyteam^^^^^*S^0^Skyteam^^^^^^^en|Skyteam|^
# alc-star-alliance^^^^^*A^0^Star Alliance^^^^^^^en|Star Alliance|^
# air-air-france^^1933-10-07^^AFR^AF^57^Air France^^Skyteam^Member^^http://en.wikipedia.org/wiki/Air_France^270088^en|Air France|^CDG=ORY
# air-british-airways^^1974-03-31^^BAW^BA^125^British Airways^^OneWorld^Member^^http://en.wikipedia.org/wiki/British_Airways^299158^en|British Airways|^LGW=LHR
# air-lufthansa^^1955-01-01^^DLH^LH^220^Lufthansa^^Star Alliance^Member^^http://en.wikipedia.org/wiki/Lufthansa^411417^en|Lufthansa|^FRA=MUC
# air-easyjet^^1995-01-01^^EZY^U2^888^easyJet^^^^^http://en.wikipedia.org/wiki/EasyJet^433807^en|easyJet|^AMS
#

##
# Helper functions
@include "awklib/geo_lib.awk"


##
#
BEGIN {
    # Global variables
    error_stream = "/dev/stderr"
    awk_file = "make_optd_airline_public.awk"

    # Generated file for name differences
    if (air_name_ref_diff_file == "") {
	air_name_ref_diff_file = "optd_airline_diff_w_ref.csv"
    }
    if (air_name_alc_diff_file == "") {
	air_name_alc_diff_file = "optd_airline_diff_w_alc.csv"
    }

    # Initialisation
    delete aln_name
    delete aln_name2
    delete flt_freq

    # Header
    printf ("%s", "pk^env_id^validity_from^validity_to^3char_code^2char_code")
    printf ("%s", "^num_code^name^name2")
    printf ("%s", "^alliance_code^alliance_status^type")
    printf ("%s", "^wiki_link^flt_freq^alt_names^bases")
    printf ("%s", "\n")

    #
    today_date = mktime ("YYYY-MM-DD")
    unknown_idx = 1
}

##
# OPTD-maintained list of alliance memberships
#
# Sample input lines:
# alliance_name^alliance_type^airline_iata_code_2c^airline_name^from_date^to_date^env_id
# Skyteam^Member^AF^Air France^2000-06-22^^
# OneWorld^Member^BA^British Airways^1999-02-01^^
# Star Alliance^Member^LH^Lufthansa^1999-05-01^^

# By requiring the env_id field to be empty, only active alliance memberships are considered.

/^([A-Za-z ]+)\^([A-Za-z]+)\^([*A-Z0-9]{2})\^(.+)\^[0-9-]*\^[0-9-]*\^$/ {
    # Alliance name
    alliance_name = $1

    # Alliance membership type
    alliance_type = $2

    # Airline IATA 2-character code
    air_code_2c = $3

    # Airline Name
    air_name = $4

    # Sanity check
    if (air_alliance_all_names[air_code_2c] != "") {
	print ("[" awk_file "][" FNR "] !!!! Error, '" air_name		\
	       "' airline (" air_code_2c ") already registered for the " \
	       air_alliance_all_names[air_code_2c] " alliance.\n"	\
	       "Full line: " $0) > error_stream
    }

    # Register the alliance membership details
    air_alliance_types[air_code_2c] = alliance_type
    air_alliance_all_names[air_code_2c] = alliance_name
    air_alliance_air_names[air_code_2c] = air_name

    # DEBUG
    # print ("Airline: " air_name " (" air_code_2c ") => Alliance: "	\
    #	   alliance_name " (" alliance_type ")")
}

##
# OPTD-maintained list of flight-date frequencies
#
# Sample input lines:
# airline_code_2c^flight_freq
# AA^1166458
# BA^296328
# WI^13
/^([*A-Z0-9]{2})\^([0-9]+)$/ {

    if (NF == 2) {
	# IATA 2-char code
	code_2char = $1

	# Flight-date frequencies
	flt_freq[code_2char] = $2

    } else {
		print ("[" awk_file "] !!!! Error for row #" FNR ", having " NF \
			   " fields: " $0) > error_stream
    }
}

##
# OPTD-maintained list of airline details
#
# Sample input lines:
#
# pk^env_id^validity_from^validity_to^3char_code^2char_code^num_code^name^name2^alliance_code^alliance_status^type(Cargo;Pax scheduled;Dummy;Gds;charTer;Ferry;Rail)^wiki_link^alt_names^bases
# air-abc-aerolineas^^2005-12-01^^AIJ^4O^837^Interjet^ABC Aerolíneas^^^^http://en.wikipedia.org/wiki/Interjet^en|Interjet|=en|ABC Aerolíneas|^MEX=TLC
# gds-abacus^^^^^1B^0^Abacus^Abacus^^^G^^en|Abacus|=en|Abacus|^
# tec-bird-information-systems^^^^^1R^0^Bird Information Systems^^^^^^en|Bird Information Systems|^
# trn-accesrail^^^^^9B^450^AccesRail^^^^R^http://en.wikipedia.org/wiki/9B^en|AccesRail|^
/^([a-z]{3}-[a-z0-9\-]+)\^([0-9]*)\^([0-9]{4}-[0-9]{2}-[0-9]{2})?\^([0-9]{4}-[0-9]{2}-[0-9]{2})?\^([A-Z0-9]{3})?\^([A-Z0-9*]{2})?\^/ {

    if (NF == 15) {
		# Unified code
		pk = $1

		# Envelope ID
		env_id = $2

		# Validity from
		valid_from = $3

		# Validity to
		valid_to = $4

		# 3-char (ICAO) code
		code_3char = $5

		# 2-char (IATA) code
		code_2char = $6

		# Ticketing code
		code_tkt = $7

		# Name
		name = $8

		# Name2
		name2 = $9

		# Alliance code (taken from optd_airline_alliance_membership.csv)
		alc_code = air_alliance_all_names[code_2char]

		# Alliance status (taken from optd_airline_alliance_membership.csv)
		alc_status = air_alliance_types[code_2char]

		# Airline type
		type = $12

		# Wikipedia link
		wiki_link = $13

		# Alternate names
		alt_names = $14

		# Airport bases / hubs
		bases = $15

        # Retrieve the flight-date frequency, if existing,
		# and if the airline is still active
		air_freq = ""
		if (code_2char != "" && env_id == "") {
			air_freq = flt_freq[code_2char]
		}

		# Build the output line
		current_line = pk "^" env_id "^" valid_from "^" valid_to	\
			"^" code_3char "^" code_2char "^" code_tkt				\
			"^" name "^" name2 "^" alc_code "^" alc_status "^" type	\
			"^" wiki_link "^" air_freq "^" alt_names "^" bases

		# Print the full line
		print (current_line)

		# Register the airline names
		if (code_2char != "" && env_id == "") {
			aln_name[code_2char] = name
			aln_name2[code_2char] = name2
		}
		if (code_3char != "" && env_id == "") {
			aln_name[code_3char] = name
			aln_name2[code_3char] = name2
		}

		# Alliance name from the OPTD-maintained file of alliance
		# membership
		if (code_2char != "" && env_id == "") {
			air_name_from_alliance = air_alliance_air_names[code_2char]

			# Difference for the airline names between the files
			# of best known details and that of the alliance list
			if (air_name_from_alliance != "" &&		\
				name != air_name_from_alliance) {
				print (code_2char "^" code_3char			\
					   "^" name "^" air_name_from_alliance) \
					> air_name_alc_diff_file
			}
		}

    } else {
		print ("[" awk_file "] !!!! Error for row #" FNR ", having " NF \
			   " fields: " $0) > error_stream
    }
}

##
# Aggregated content from reference data
#
# Sample input lines:
# *A^^*A^0^Star Alliance^
# *O^^*O^0^Oneworld^
# *S^^*S^0^Skyteam^
# AF^AFR^AF^57^Air France^Air France
# AFR^AFR^AF^57^Air France^Air France
# BA^BAW^BA^125^British Airways^British A/W
# BAW^BAW^BA^125^British Airways^British A/W
# DLH^DLH^LH^220^Lufthansa^Lufthansa
# LH^DLH^LH^220^Lufthansa^Lufthansa
#
/^([*A-Z0-9]{2,3})\^([A-Z]{3})?\^([*A-Z0-9]{2})\^([0-9]+)\^/ {

    if (NF == 6) {
	# Primary key
	pk = $1

	# IATA 3-character code
	iata_code_3c = $2

	# IATA 2-character code
	iata_code_2c = $3

	# Numeric code
	numeric_code = $4

	# Names
	air_name = $5
	air_name_alt = $6

	# Alliance details
	alliance_type = air_alliance_types[iata_code_2c] 
	alliance_name = air_alliance_all_names[iata_code_2c]

	# Unified code ^ IATA 3-char-code ^ IATA 2-char-code ^ Numeric code
	current_line = pk "^" iata_code_3c "^" iata_code_2c "^" numeric_code 

	# ^ Name ^ Alternate name
	current_line = current_line "^" air_name "^" air_name_alt

	# ^ Alliance name ^ Alliance membership type
	current_line = current_line "^" alliance_name "^" alliance_type

	# Difference between OPTD and reference data
	optd_name = aln_name[pk]
	optd_name2 = aln_name2[pk]
	if (air_name != optd_name) {
	    print (pk "^1^" optd_name "<>" air_name)	\
		> air_name_ref_diff_file
	}
	if (air_name_alt != optd_name2) {
	    print (pk "^2^" optd_name2 "<>" air_name_alt)	\
		> air_name_ref_diff_file
	}

	# Print the full line (old version, as is)
	# print (current_line)

    } else {
	print ("[" awk_file "] !!!! Error for row #" FNR ", having " NF \
	       " fields: " $0) > error_stream
    }

}

END {
    # DEBUG
}
