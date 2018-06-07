# This script goes through sound and TextGrid files in a directory,
# opens each pair of Sound and TextGrid, and for each labelled
# segment in the specified Tier:
# - measures duration of each segment,
# - measures f0 mean across middle 60%,
# - measures f0 max and min across whole segment,
# - measures intensity mean across middle 60%,
# - measures max intensity across whole segment,
# - outputs label of the segment in the main tier,
# - outputs lables of other tiers at the midpoint of the specified tier,
# and saves results to a text file.
#
# To make some other or additional analyses, you can modify the script
# yourself... it should be reasonably well commented! ;)
#
# This script is distributed under the GNU General Public License v3.
# Based on a script GPL-released script copyright 4.7.2003 Mietta Lennes
# original name collect_formant_data_from_files.praat.txt
# This version by Jonathan Washington, last revised 2018-06-06

# Analyze formant values from labeled segments in files
form Measure duration and pitch, and get segment labels
	comment Directory of sound files
	text sound_directory /data/Documents/projects/2018-06 Astana/NU_s9_Eng3/
	sentence Sound_file_extension .wav
	comment Directory of TextGrid files
	text textGrid_directory /data/Documents/projects/2018-06 Astana/NU_s9_Eng3/
	sentence TextGrid_file_extension .TextGrid
	comment Full path of the resulting text file:
	text resultfile /data/Documents/projects/2018-06 Astana/NU_s9_Eng3/durationresults.txt
	comment Which tier do you want to measure?
	sentence Tier vowel
	comment What other tiers to record?
	sentence otherTiers word POS syllable stress vowel condition repetition
	comment Pitch analysis parameters
	real pitch_time_step 0.0
	positive min_pitch 75.0
	positive max_pitch 600.0
	comment Formant analysis parameters
	positive formant_time_step 0.01
	integer Maximum_number_of_formants 5
	positive Maximum_formant_(Hz) 5500_(=adult female)
	positive Window_length_(s) 0.025
	real Preemphasis_from_(Hz) 50
endform

# Here, you make a listing of all the sound files in a directory.
# The example gets file names ending with ".wav" from D:\tmp\

Create Strings as file list... list 'sound_directory$'*'sound_file_extension$'
numberOfFiles = Get number of strings

# Check if the result file exists:
if fileReadable (resultfile$)
	pause The result file 'resultfile$' already exists! Do you want to overwrite it?
	filedelete 'resultfile$'
endif


separator$ = " "
titleline$ = ""
@split (separator$, otherTiers$)
total_tiers = split.length
for t to total_tiers
	thisTier$ = split.array$[t]
	titleline$ = "'titleline$'	'thisTier$'"
endfor

# Write a row with column titles to the result file:
# (remember to edit this if you add or change the analyses!)

titleline$ = "filename	'titleline$'	vowel	duration	f0	f0max	f0min	f1	f2	f3	intensity	intensity_max'newline$'"
fileappend "'resultfile$'" 'titleline$'

# Go through all the sound files, one by one:

for ifile to numberOfFiles
	filename$ = Get string... ifile
	# A sound file is opened from the listing:
	Read from file... 'sound_directory$''filename$'
#	# Starting from here, you can add everything that should be 
#	# repeated for every sound file that was opened:
	soundname$ = selected$ ("Sound", 1)
#	To Formant (burg)... time_step maximum_number_of_formants maximum_formant window_length preemphasis_from
	# Open a TextGrid by the same name:
	gridfile$ = "'textGrid_directory$''soundname$''textGrid_file_extension$'"
	if fileReadable (gridfile$)
		Read from file... 'gridfile$'
		# Find the tier number that has the label given in the form:
		call GetTier 'tier$' tier
		numberOfIntervals = Get number of intervals... tier

		# make a Pitch object
		select Sound 'soundname$'
		To Pitch... pitch_time_step min_pitch max_pitch

		# make an Intensity object
		select Sound 'soundname$'
		To Intensity... min_pitch pitch_time_step

		# make a Formant object
		select Sound 'soundname$'
		To Formant (burg)... formant_time_step maximum_number_of_formants maximum_formant window_length preemphasis_from

		select TextGrid 'soundname$'
		# Pass through all intervals in the selected tier:
		for interval to numberOfIntervals
			label$ = Get label of interval... tier interval
			if label$ <> ""
				# if the interval has an unempty label, get its start and end:
				start = Get starting point... tier interval
				end = Get end point... tier interval
				midpoint = (start + end) / 2
				duration = end - start
				# set middle 60% start and end
				midstart = start + (0.2 * duration)
				midend = end - (0.2 * duration)


				# get the formant values at that interval
				select Formant 'soundname$'
				f1 = Get value at time... 1 midpoint Hertz Linear
				f2 = Get value at time... 2 midpoint Hertz Linear
				f3 = Get value at time... 3 midpoint Hertz Linear

				# load intensity object
				select Intensity 'soundname$'
				# get the mean intensity
				meanIntensity = Get value at time... midstart midend energy
				# get max intensity in range
				maxIntensity = Get maximum... start end Cubic


				# load pitch object
				select Pitch 'soundname$'
				
				# get the mean pitch for middle 60% span
				pitch = Get mean... midstart midend Hertz
				if pitch = undefined
					pitch = -1
				endif

				# get max pitch in span
				maxPitch = Get maximum... start end Hertz None
				if maxPitch = undefined
					maxPitch = -1
				endif

				# get max pitch in span
				minPitch = Get minimum... start end Hertz None
				if minPitch = undefined
					minPitch = -1
				endif

				select TextGrid 'soundname$'
				# get values of other tiers
				otherValues$ = ""
				for t to total_tiers
					thisTier$ = split.array$[t]
					#Get interval at time... 
					call GetTier 'thisTier$' thisTierNum
					#numberOfIntervals = Get number of intervals... tier
					thisTierInterval = Get interval at time... thisTierNum midpoint
					thisIntervalValue$ = Get label of interval... thisTierNum thisTierInterval
					otherValues$ = "'otherValues$'	'thisIntervalValue$'"
				endfor

				# Save result to text file:
				#resultline$ = soundname$

				resultline$ = "'soundname$'	'otherValues$'	'label$'	'duration'	'pitch'	'maxPitch'	'minPitch'	'f1'	'f2'	'f3'	'meanIntensity'	'maxIntensity''newline$'"

				fileappend "'resultfile$'" 'resultline$'
				select TextGrid 'soundname$'
			endif
		endfor
		# Remove the TextGrid object from the object list
		select TextGrid 'soundname$'
		plus Pitch 'soundname$'
		plus Formant 'soundname$'
		plus Intensity 'soundname$'
		Remove
	endif
	# Remove the temporary objects from the object list
	select Sound 'soundname$'
	#plus Formant 'soundname$'
	#plus TextGrid 'soundname$'
	#plus Pitch 'soundname$'
	Remove
	select Strings list
	# and go on with the next sound file!
endfor

Remove


#-------------
# This procedure finds the number of a tier that has a given label.

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
