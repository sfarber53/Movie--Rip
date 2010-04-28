package acidrip_messages;

$messages = {
	'language' => 'English',
	'default'  => 'English',
	'messages' => {
		'English' => {
			'scale_width_spin' 						=> "Width of the video output, default 480, smaller width will encode faster.",
 		 	'scale_height_spin'						=> "Height of the video output, default -2: calculates aspect based on crop and dvd information",
 	 		'crop_width_spin'							=> "Width of the crop, relative to original dvd video stream",
 	 		'crop_height_spin'						=> "Height of the crop, relative to the original dvd video stream",
 	 		'crop_vertical_spin'					=> "Vertical offset from top of video",
 	 		'crop_horizontal_spin'				=> "Horizontal offset from left side of video",
 		 	'crop_enable_check'						=> "Turn cropping on/off",
			'scale_enable_check'					=> "Turn video scaling on/off" ,
			'crop_detect_button'					=> "Detect optimum crop values" ,
			'video_codec_option'					=> "Video output format to be used" ,
			'video_options_entry'					=> "Options specific to the selected video output" ,
			'video_bitrate_entry'					=> "Bitrate calculated to satify filesize. can be edited if desired" ,
			'subp_option'									=> "Subpicture to be used" ,
			'read_dvd_button'							=> "Read the DVD or directory" ,
			'video_passes_spin'						=> "Number of encoding passes. Check MPlayer docs for details on 2 or 3 pass encoding." ,
			'dvd_device_entry'						=> "Location of the DVD drive or other directory" ,
			'autoload_check'							=> "Automatically scan DVD or directory and crop (if enabled) when program is loaded. (Remember to save settings!)" ,
			'overwrite_check'							=> "Overwrite files if they already exist... woahh careful!" ,
			'audio_codec_option'					=> "Audio output format to be used" ,
			'audio_options_entry'					=> "Options specific to selected audio output" ,
			'audio_track_option'					=> "Audio track to use" ,
			'filename_entry'							=> "Name of output file:\n%T\tTrack title\n%N\tTrack number\n%L\ttrack length\n%f\tfirst title letter\n%w\tWidth\n%h\tHeight\n%b\tVideo bitrate\n%l\tLanguage" ,
			'filesize_spin'								=> "Desired size of file(s), select typical values, or enter your own. If value is RED then you do not have enough space in the given location. Disabled if bitrate lock is checked"  ,
			'save_button'									=> "Store useful settings in $ENV{HOME}/.acidriprc" ,
			'restore_button'							=> "Restore default settings" ,
			'start_button'								=> "Begin encoding with current settings" ,
			'stop_button'									=> "Stop encoding" ,
			'view_button'									=> "Play back output file" ,
			'dvd_tree'										=> "Contents of currently loaded DVD or directory" ,
			'mencoder_output_show_button'	=> "Show lots of lovely information about what's going on, useful for troubleshooting." ,
			'mencoder_output_hide_button'	=> "Hide all of this junk..." ,
			'mencoder_output_save_button'	=> "Save all output information to $ENV{HOME}/acidrip.log." ,
			'video_bitrate_lock_check'		=> "Lock bitrate from automatic updating" ,
			'scale_lock_check'						=> "Lock height relative to width" ,
			'mencoder_output_clear_button'=> "Clear all output information" ,
			'video_bpp_entry'							=> "Estimated bits per pixel. Ideally you want to hit around 0.25 with a decent divx codec" ,
			'more_options_entry'					=> "Somewhere for any other options to go that are not handled here" ,
			'total_blocks_spin'						=> "Automatically split dvd into a given number of files by chapter boundaries" ,
			'mencoder_entry'							=> "Specify a set location for mencoder or similar, e.g. \"/mnt/nfs/usr/bin/mencoder\" or even \"nice mencoder\"" ,
			'language_entry'							=> "Set preferred language for audio, reload DVD to take effect." ,
			'cache_directory_entry'				=> "Specify a set location for caching the DVD title to, e.g. \"/tmp\". You do NOT need to cache the dvd." ,
			'cache_check'									=> "To cache or not to cache. Useful if you're impatient and can\'t leave the disc for more than 30 mins... other than that..." ,
			'precache_check'							=> "Caches all tracks before any encoding, otherwise tracks are cached and deleted at encode time." ,
			'compact_check'								=> "Show only encoding status when encoding title, smaller and less chance of accidentally stopping it!" ,
			'enforce_space_check'					=> "Refuse to encode if there appears to not be enough space in output directory (encoding only, not caching)" ,
			'vf_pre_enable_check'					=> "vf options to apply to video before cropping / scaling - see mplayer docs" ,
			'vf_post_enable_check'				=> "vf options to apply to video after cropping / scaling - see mplayer docs" ,
			'info_field_option'						=> "Set various attributes with the avi file. Few players besides MPlayer use this information." ,
			'ppc_bug_check'								=> "Mencoder\'s -sstep option doesn't work on PPC, use alternate (less reliable) crop method" ,
			'flickbook_preview_check'			=> "Previews film with selected still shots instead of entire playback (not possible if using ppc bug)" ,
			'vobsubout_check'							=> "Dump subtitles to seperate file instead of rendering directly to the video." ,
			'embed_preview_check'					=> "Show preview in space above, rather than a full size detached window" ,
			'eject_check'									=> "Eject DVD when finished" ,
			'queue_button'								=> "Add current setting to the queue" ,
			'vcd_type_option'							=> "Load specifications for chosen VCD standard" ,
			'vcd_format_option'						=> "Video size for VCD" ,
			'audio_gain_spin'							=> "Audio gain (dB) -200 = silence, +40 = x1000!" ,
			'quit_button'									=> "Quit AcidRip" ,
			'shutdown_check'							=> "Shutdown machine when encoding is completed" 
		},
		'Francais' => {
			'acidrip' => 'le acidrip'
		},
		'Deutsch' => {
			'acidrip' => 'das acidrip'
		}
	}
};

sub new {
  my $class    = shift;
	my $language = shift;
  bless( $messages, $class );
	$messages->{'language'} = $language;
	$messages->get_languages;
  return $messages;
}

sub msg {
	my $messages = shift;
	my $name = shift;
	return $messages->{'messages'}->{$messages->{'language'}}->{$name} 
		if defined $messages->{'messages'}->{$messages->{'language'}}->{$name};
	return $messages->{'messages'}->{$messages->{'default'}}->{$name}
	  if defined $messages->{'messages'}->{$messages->{'default'}}->{$name};
  return $name;
}

sub get_languages {
	my $messages = shift;
	return keys %{$messages->{'messages'}}
}

1;
