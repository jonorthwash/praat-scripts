# This script saves each interval in the selected IntervalTier of a TextGrid to a separate WAV sound file.
# The source sound must be a LongSound object, and both the TextGrid and 
# the LongSound must have identical names and they have to be selected 
# before running the script.
# Files are named with the corresponding interval labels (plus a running index number when necessary).
#
# NOTE: You have to take care yourself that the interval labels do not contain forbidden characters!!!!
# 
# This script is distributed under the GNU General Public License.
# Orignial from http://www.helsinki.fi/~lennes/praat-scripts/public/save_labeled_intervals_to_wav_sound_files.praat
# Copyright 8.3.2002 Mietta Lennes
# Current version last modified 2018-06-10 by Jonathan North Washington
#

form Save intervals to small WAV sound files
	comment Directory of sound files
	text sound_directory /data/Documents/projects/2018-06 Astana/NU_s9_Eng3/
	sentence Sound_file_extension .wav
	comment Directory of TextGrid files
	text textGrid_directory /data/Documents/projects/2018-06 Astana/NU_s9_Eng3/
	sentence TextGrid_file_extension .TextGrid
	comment Which IntervalTier in the TextGrids would you like to process?
	text Tiername word
	comment Starting and ending at which interval? 
	integer Start_from 1
	integer End_at_(0=last) 0
	boolean Exclude_empty_labels 1
	boolean Exclude_intervals_labeled_as_xxx 1
	boolean Exclude_intervals_starting_with_dot_(.) 1
	comment Give a small margin for the files if you like:
	positive Margin_(seconds) 0.01
	comment Give the folder where to save the sound files:
	sentence Folder /data/Documents/projects/2018-06 Astana/
	comment Give an optional prefix for all filenames:
	sentence Prefix TMP_
	comment Fields to include in filename:
	sentence OtherFields condition repetition
	comment Give an optional suffix for all filenames (before .wav):
	sentence Suffix 
endform

Create Strings as file list... list 'sound_directory$'*'sound_file_extension$'
numberOfFiles = Get number of strings

for ifile to numberOfFiles
	filename$ = Get string... ifile
	# A sound file is opened from the listing:
	Read from file... 'sound_directory$''filename$'
	# Starting from here, you can add everything that should be 
	# repeated for every sound file that was opened:
	soundname$ = selected$ ("Sound", 1)
	# Open a TextGrid by the same name:
	gridfile$ = "'textGrid_directory$''soundname$''textGrid_file_extension$'"
	if fileReadable (gridfile$)
		Read from file... 'gridfile$'
		# Find the tier number that has the label given in the form:
##gridname$ = selected$ ("TextGrid", 1)
##soundname$ = selected$ ("LongSound", 1)
#select TextGrid 'gridname$'
		# Find the tier number that has the label given in the form:
		call GetTier 'tiername$' tier

		numberOfIntervals = Get number of intervals... tier
		if start_from > numberOfIntervals
			exit There are not that many intervals in the IntervalTier!
		endif
		if end_at > numberOfIntervals
			end_at = numberOfIntervals
		endif
		if end_at = 0
			end_at = numberOfIntervals
		endif

		# Default values for variables
		files = 0
		intervalstart = 0
		intervalend = 0
		interval = 1
		intname$ = ""
		intervalfile$ = ""
		endoffile = Get finishing time

		# ask if the user wants to go through with saving all the files:
		for interval from start_from to end_at
			xxx$ = Get label of interval... tier interval
			check = 0
			if xxx$ = "xxx" and exclude_intervals_labeled_as_xxx = 1
				check = 1
			endif
			if xxx$ = "" and exclude_empty_labels = 1
				check = 1
			endif
			if left$ (xxx$,1) = "." and exclude_intervals_starting_with_dot = 1
				check = 1
			endif
			if check = 0
			   files = files + 1
			endif
		endfor
		interval = 1
		pause 'files' sound files will be saved. Continue?

		# Loop through all intervals in the selected tier of the TextGrid
		for interval from start_from to end_at
			select TextGrid 'soundname$'
			intname$ = ""
			intname$ = Get label of interval... tier interval
			check = 0
			if intname$ = "xxx" and exclude_intervals_labeled_as_xxx = 1
				check = 1
			endif
			if intname$ = "" and exclude_empty_labels = 1
				check = 1
			endif
			if left$ (intname$,1) = "." and exclude_intervals_starting_with_dot = 1
				check = 1
			endif
			if check = 0
				intervalstart = Get starting point... tier interval
					if intervalstart > margin
						intervalstart = intervalstart - margin
					else
						intervalstart = 0
					endif
	
				intervalend = Get end point... tier interval
					if intervalend < endoffile - margin
						intervalend = intervalend + margin
					else
						intervalend = endoffile
					endif
				midpoint = intervalstart + ((intervalend - intervalstart)/2)
			
				# set up other fields for adding to the filename
				select TextGrid 'soundname$'
				separator$ = " "
				@split (separator$, otherFields$)
				num_fields = split.length
				if num_fields > 0
					fieldsline$ = ""
					for f from 1 to num_fields
						thisfield$ = split.array$[f]
						call GetTier 'thisfield$' thisTierNum
						thisTierInterval = Get interval at time... thisTierNum midpoint
						thisIntervalValue$ = Get label of interval... thisTierNum thisTierInterval
						fieldsline$ = "'fieldsline$'_'thisIntervalValue$'"
						#pause "'thisfield$': 'thisTierNum', 'midpoint', 'thisIntervalValue$'"
					endfor
				else
					fieldsline$ = ""
				endif

				select Sound 'soundname$'
				Extract part... intervalstart intervalend parabolic 1.0 no
				filename$ = intname$

				intervalfile$ = "'folder$'" + "'prefix$'" + "'filename$'" + "'fieldsline$'" + "'suffix$'" + ".wav"
				indexnumber = 0
				while fileReadable (intervalfile$)
					indexnumber = indexnumber + 1
					intervalfile$ = "'folder$'" + "'prefix$'" + "'filename$'" + "'fieldsline$'" + "'suffix$''indexnumber'" + ".wav"
				endwhile
				Write to WAV file... 'intervalfile$'
				Remove
			endif
		endfor
	endif
endfor

#-------------
# This procedure finds the number of a tier that has a given label.
# from original name collect_formant_data_from_files.praat.txt
# copyright 4.7.2003 Mietta Lennes, GPL-licensed
# 
procedure GetTier name$ variable$
        numberOfTiers = Get number of tiers
        itier = 1
        repeat
                tier$ = Get tier name... itier
                itier = itier + 1
        until tier$ = name$ or itier > numberOfTiers
        if tier$ <> name$
                'variable$' = 0
        else
                'variable$' = itier - 1
        endif

	if 'variable$' = 0
		exit The tier called 'name$' is missing from the file 'soundname$'!
	endif

endproc


# From http://www.ucl.ac.uk/~ucjt465/scripts/praat/populate_tier.praat
## GPLv3 ©Jose J. Atria 2014-02-14
# From http://www.ucl.ac.uk/~ucjt465/scripts/praat.html#split
procedure split (.sep$, .str$)
  .seplen = length(.sep$)
  .length = 0
  repeat
    .strlen = length(.str$)
    .sep = index(.str$, .sep$)
    if .sep > 0
      .part$ = left$(.str$, .sep-1)
      .str$ = mid$(.str$, .sep+.seplen, .strlen)
    else
      .part$ = .str$
    endif
    .length = .length+1
    .array$[.length] = .part$
  until .sep = 0
endproc
