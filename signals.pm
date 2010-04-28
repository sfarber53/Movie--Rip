#!/usr/bin/perl -w

package acidrip;
require 5.005;
use strict;
use Data::Dumper;

use AcidRip::acidrip;
use File::Basename;

sub quit_acidrip {
		
  if ( $::settings->{'mencoder_pid'} > 0 ) {
    my $confirm = Gtk2::MessageDialog->new( $::widgets->{'acidrip'}, [qw/modal destroy-with-parent/], 'question', 'yes-no', "Are you sure you want to stop the encoding process?" );
    my $m = $::settings->{'mencoder_pid'} + 1;
    if ( $confirm->run eq 'yes' ) {
			kill 'INT', $::settings->{'mencoder_pid'};
      kill 'INT', $m if `ps $m | grep mencoder` || `ps $m | grep mplayer`;
			Gtk2->main_quit;
		}
    $confirm->destroy;
	} else {
    Gtk2->main_quit;
  }
  
}

sub on_select_audio {
  my ( $widget, $this_audio ) = @_;
  $::settings->{'selected_audio'} = $this_audio;
  if ( $this_audio > 0 ) {
    my $audio = get_audio($this_audio);
    message("selected_audio changed to $this_audio - Channels $audio->{'channels'} frequency $audio->{'frequency'} quant. $audio->{'quantization'}");
    set_bitrate();
  }
}

sub on_mpegfile_option_changed {
  my $widget = shift;
  $::settings->{'mpegfile'} = $widget->get_history;
  message( "********************\nMPEG container selected. Please note that you MUST use a compatible mpeg1 video stream, "
      . "select lavc video output, using vcodec=mpeg1video. For a useful output you will probably want to choose a suitable encoding matrix."
      . "for example, create a kvcd file with vcodec=mpeg1video:keyint=25:mbd=2:vrc_minrate=300:vrc_maxrate=2400:vrc_buf_size=320:"
      . "intra_matrix=8,9,12,22,26,27,29,34,9,10,14,26,27,29,34,37,12,14,18,27,29,34,37,38,22,"
      . "26,27,31,36,37,38,40,26,27,29,36,39,38,40,48,27,29,34,37,38,40,48,58,29,34,37,38,40,"
      . "48,58,69,34,37,38,40,48,58,69,79:inter_matrix=16,18,20,22,24,26,28,30,18,20,22,24,26,"
      . "28,30,32,20,22,24,26,28,30,32,34,22,24,26,30,32,32,34,36,24,26,28,32,34,34,36,38,26,"
      . "28,30,32,34,36,38,40,28,30,32,34,36,38,42,42,30,32,34,36,38,40,42,44\nAnd don't forget to set VALID scale values etc...\n********************" )
    if $::settings->{'mpegfile'};
  message( "Filetype changed to " . ( $::settings->{'mpegfile'} ? ".mpg - READ DEBUG COMMENT! --->" : ".avi" ) );
}

sub on_select_subp {
  my ( $widget, $this_subp ) = @_;
  $::settings->{'selected_subp'} = $this_subp;
  message("Selected_subp changed to $::settings->{'selected_subp'}");
}

sub on_select_track {
  my ( $selection, $model ) = @_;
  my $x;
  my @newitem = $selection->get_selected_rows;
  my $length;

  return if not defined $newitem[0];

  my $newitem    = ( $newitem[0]->get_indices )[0] + 1;
  my $this_track = get_track($newitem);

  # count total and collapse if odd?
  $::settings->{'selected_chapters_start'} = 0;
  $::settings->{'selected_chapters_end'}   = 0;
  foreach (@newitem) {
    ( $selection->get_tree_view )->collapse_all if ( $_->get_depth == 1 && defined $this_track->{'chapter'} );
    if ( $_->get_depth == 2 ) {
      $::settings->{'selected_chapters_start'} = ( $_->get_indices )[1] + 1 if $::settings->{'selected_chapters_start'} == 0;
      $::settings->{'selected_chapters_end'} = ( $_->get_indices )[1] + 1;
    }
  }
  $::settings->{'selected_track'} = $this_track->{'ix'};

  if ( $::settings->{'selected_chapters_start'} && defined $this_track->{'chapter'} ) {
    $::settings->{'length'} = hhmmss( get_selection_length( $::settings->{'selected_chapters_start'}, $::settings->{'selected_chapters_end'} ) );
    $::widgets->{'selected_track_label'}->set_text(
      "Selected Track $::settings->{'selected_track'} " . "Ch $::settings->{'selected_chapters_start'}-$::settings->{'selected_chapters_end'} - " . $::settings->{'length'} );
  }
  else {
    $::settings->{'length'} = hhmmss( $this_track->{'length'} );
    $::widgets->{'selected_track_label'}->set_text( "Selected Track $newitem - " . $::settings->{'length'} );
  }

  #load the correct audio entries for the menu
  my $audio_menu = Gtk2::Menu->new;
  $::widgets->{'audio_track_option'}->set_menu($audio_menu);
  my $default_audio = -1;
  my $audio_item;
  if ( $::dvd->{'source'} eq "dvd" ) {
    foreach ( reverse( @{ $this_track->{'audio'} } ) ) {
      if ( defined $_->{'langcode'} || defined $_->{'language'} ) {
        $default_audio = $_->{'ix'} if $_->{'langcode'} eq $::settings->{'language'} || $_->{'language'} eq $::settings->{'language'};
      }
    }

    foreach my $this_audio ( @{ $this_track->{'audio'} } ) {
      my $label = $this_audio->{'ix'};
      $label .= ": " . $this_audio->{'language'} if defined $this_audio->{'language'};
      if ( defined $this_audio->{'content'} ) {
        $label = $label . ": " . $this_audio->{'content'} if $this_audio->{'content'} ne "Undefined";
      }
      $audio_item = Gtk2::MenuItem->new($label);
      $audio_item->signal_connect( 'activate', \&on_select_audio, $this_audio->{'ix'} );
      $audio_menu->append($audio_item);
      $audio_item->show;
    }
  }
  $audio_item = Gtk2::MenuItem->new("<None>");
  $audio_item->signal_connect( 'activate', \&on_select_audio, -2 );
  $audio_menu->prepend($audio_item);
  $audio_item->show;

  $audio_item = Gtk2::MenuItem->new( "<Default> " . $::settings->{'language'} );
  $audio_item->signal_connect( 'activate', \&on_select_audio, $default_audio );
  $audio_menu->prepend($audio_item);
  $audio_item->show;
  $::widgets->{'audio_track_option'}->set_history(0);

  my $subp_menu = Gtk2::Menu->new;
  $::widgets->{'subp_option'}->set_menu($subp_menu);
  my $subp_item = Gtk2::MenuItem->new("<None>");
  $subp_item->signal_connect( 'select', \&on_select_subp, -1 );
  $subp_menu->append($subp_item);
  $subp_item->show;
  $::widgets->{'subp_option'}->set_history(0);

  foreach my $this_subp ( @{ $this_track->{'subp'} } ) {
    my $subp_ix = $this_subp->{'ix'};
    my $label   = $subp_ix . ": " . $this_subp->{'language'};
    $label .= ": " . $this_subp->{'content'} if $this_subp->{'content'} ne "Undefined";
    $subp_item = new_with_label Gtk2::MenuItem($label);
    $subp_item->signal_connect( 'activate', \&on_select_subp, $subp_ix );
    $subp_menu->append($subp_item);
    $subp_item->show;
  }
  set_bitrate();
	split_track() if $::dvd->{'source'} eq "dvd" and $::settings->{'total_blocks'} > 1;
}

sub on_scale_lock_check_clicked {
  my $widget = shift;
  $::widgets->{'scale_height_spin'}->set_sensitive( !$widget->get_active );
  if ( $widget->get_active ) {
    $::widgets->{'scale_height_spin'}->hide;
    $::widgets->{'scale_height_estimate_entry'}->show;
    $::widgets->{'scale_height_spin'}->set_value("-2");
  }
  else {
    $::widgets->{'scale_height_spin'}->show;
    $::widgets->{'scale_height_estimate_entry'}->hide;
    $::widgets->{'scale_height_spin'}->set_value( $::widgets->{'scale_height_estimate_entry'}->get_text );
  }
}

sub on_filesize_changed {
  my $free      = 0;
  my $size      = $::settings->{'filesize'} * $::settings->{'total_blocks'};
  my $directory = dirname( substitute_filename( $::settings->{'filename'} ) );
  open( DF, "df $directory |" ) if -w $directory;
  return if not -w $directory;
  while (<DF>) {
    my @array = split /\s+/;
    $free = $array[3] / 1024 if $. != 1;
  }
  close DF;
  $free = sprintf( "%d", $free );
  set_warning_text( $::widgets->{'filesize_spin'}, $free <= $size ? 1 : 0 );
  my $warn_block = $::settings->{'total_blocks'} > 1 ? 1 : 0;
  set_warning_text( $::widgets->{'total_blocks_spin'}, $free <= $size ? $warn_block : 0 );
  $::settings->{'enough_space'} = $free <= $size ? 0 : 1;
  set_bitrate();
}

sub on_bpp_changed {
  my $widget  = shift;
  my $bpp     = $widget->get_text || 0;
  my $message = "Bits per pixel is ";
  my $warn;

  if    ( $bpp < 0.10 ) { $message .= "FAR too low!!, increase file size or reduce resolution";                      $warn = 1 }
  elsif ( $bpp < 0.15 ) { $message .= "quite low, output will probably suck, increase filesize or lower resolution"; $warn = 0.5 }
  elsif ( $bpp < 0.20 ) { $message .= "alright, output will be a bit blocky, but generally ok.";                     $warn = 0 }
  elsif ( $bpp < 0.25 ) { $message .= "super, output should look pretty good";                                       $warn = 0 }
  elsif ( $bpp < 0.30 ) { $message .= "quite high, not much to gain here. might want a slightly higher resolution";  $warn = 0.5 }
  else { $message .= "very high, you'll waste the space, try a bigger resolution"; $warn = 1 }

  set_warning_text( $widget, $warn );

  $::widgets->{'tooltips'}->set_tip( $widget, $message );
}

sub on_crop_detect_button_clicked {
  message("Crop detection in progress... please wait");

  while ( Gtk2->events_pending() ) { Gtk2->main_iteration() }

  my $crop = "fail";
  my $crop_output;
  ( $crop, $crop_output ) = find_crop( $::settings->{'selected_track'} );
  $::widgets->{'mencoder_output_text'}->get_buffer->insert_with_tags_by_name( $::widgets->{'mencoder_output_text'}->get_buffer->get_end_iter, $crop_output, 'mplayer' );

  if ( defined $crop && $crop =~ /crop=(\d+):(\d+):(\d+):(\d+)/ ) {
    set_setting( 'crop_width',      $1 );
    set_setting( 'crop_height',     $2 );
    set_setting( 'crop_horizontal', $3 );
    set_setting( 'crop_vertical',   $4 );
    message('Crop detection completed');
  }
  else { message( 'Crop detection failed, is the DVD loaded?', 'error' ) }
}

sub on_crop_preview_button_clicked {
  if ( defined $::dvd->{'track'} ) {
    $::widgets->{'stop_preview_button'}->show;
    $::widgets->{'preview_button'}->hide;
    $::widgets->{'preview_socket_frame'}->show;
    $::widgets->{'preview_logo'}->hide if defined $::widgets->{'preview_logo'};

    #fork proofing
    open STDIN, '/dev/null' or message("Can't read /dev/null: $!. May fail if in background");

    message("Preview command: ");
    message("Previewing crop window");
    while ( Gtk2->events_pending() ) { Gtk2->main_iteration() }

    my $mplayer_output = '';

    my $preview = get_command("preview");

    message("Preview command: $preview");
    message("Previewing crop window");

    $/ = "\r";
    $::settings->{'mencoder_pid'} = open( PREVIEW, "$preview 2>&1 |" );
    while (<PREVIEW>) {
      $::widgets->{'preview_socket'}->set_size_request( $1, $2 ) if /\s=>\s(\d+)x(\d+)/ && $::settings->{'embed_preview'};
      $mplayer_output .= $_ if $_ !~ /crop|^A:/;
      while ( Gtk2->events_pending() ) { Gtk2->main_iteration() }
    }
    $/ = "\n";
    close PREVIEW;
    message($mplayer_output);
    message("Preview finished");
    $::widgets->{'stop_preview_button'}->hide;
    $::widgets->{'preview_button'}->show;
    $::widgets->{'preview_socket_frame'}->hide;
    $::widgets->{'preview_logo'}->show if defined $::widgets->{'preview_logo'};

  }
  else { message("Preview failed, is the DVD loaded?") }
}

sub on_info_field_select {
  my ( $widget, $value ) = @_;
  $::widgets->{'info_name_entry'}->hide;
  $::widgets->{'info_artist_entry'}->hide;
  $::widgets->{'info_genre_entry'}->hide;
  $::widgets->{'info_subject_entry'}->hide;
  $::widgets->{'info_comment_entry'}->hide;
  $::widgets->{'info_copyright_entry'}->hide;
  $::widgets->{ 'info_' . $value . '_entry' }->show;
}

sub on_setting_finished {
  my $widget = shift;
  my $name   = $::widgets->get_widget_name($widget);
  $name =~ /([\w_]+)_\w+/;
  my $data = $1;
  my $ref  = ref $widget;
  my $value;

  if    ( $ref eq "Gtk2::Entry" )      { $value = $widget->get_text }
  elsif ( $ref eq "Gtk2::SpinButton" ) { $value = $widget->get_value_as_int }
  elsif ( $ref eq "Gtk2::CheckButton" || $ref eq "Gtk2::ToggleButton" ) {
    if ( $widget->get_active ) { $value = 1 }
    else { $value = 0 }
  }

  message("$data has been set to $value") if $::settings->{$data} ne $value || $ref eq "Gtk2::SpinButton";
  $::settings->{$data} = $value;
  on_setting_changed($widget);

  return 0;
}

sub enable_crop_control {
  my $value = shift;
  $::widgets->{'crop_width_spin'}->set_sensitive($value);
  $::widgets->{'crop_width_label'}->set_sensitive($value);
  $::widgets->{'crop_height_spin'}->set_sensitive($value);
  $::widgets->{'crop_height_label'}->set_sensitive($value);
  $::widgets->{'crop_vertical_spin'}->set_sensitive($value);
  $::widgets->{'crop_vertical_label'}->set_sensitive($value);
  $::widgets->{'crop_horizontal_spin'}->set_sensitive($value);
  $::widgets->{'crop_horizontal_label'}->set_sensitive($value);
  $::widgets->{'crop_detect_button'}->set_sensitive($value);
  $::settings->{'crop_width'}  = $value ? $::widgets->{'crop_width_spin'}->get_value  : 0;
  $::settings->{'crop_height'} = $value ? $::widgets->{'crop_height_spin'}->get_value : 0;
  set_bpp();
}

sub enable_scale_control {
  my $value = shift;
  $::widgets->{'scale_width_spin'}->set_sensitive($value);
  $::widgets->{'scale_width_label'}->set_sensitive($value);
  $::widgets->{'scale_height_spin'}->set_sensitive($value);
  $::widgets->{'scale_height_label'}->set_sensitive($value);
  $::widgets->{'scale_height_estimate_entry'}->set_sensitive($value);
  $::widgets->{'scale_lock_check'}->set_sensitive($value);
  $::settings->{'scale_width'}  = $value ? $::widgets->{'scale_width_spin'}->get_value  : 0;
  $::settings->{'scale_height'} = $value ? $::widgets->{'scale_height_spin'}->get_value : 0;
  set_bpp();
}

sub on_option_changed {
  my $widget = shift;
  my $value  = shift;
  my $menu   = $widget->get_parent;
  my $name   = $::widgets->get_widget_name($menu);
  $name =~ /([\w_]+)_\w+/;
  $name = $1;
  $::settings->{$name} = $value;
  message("$1 has been set to $value");

  if ( $name eq "video_codec" ) {
    message( $::settings->{'available_video'}{$value} );
    my $enable = ( $value eq "lavc" || $value eq "xvid" || $value eq "divx4" );
    $::widgets->{'video_bitrate_entry'}->set_sensitive($enable);
    $::widgets->{'video_bitrate_label'}->set_sensitive($enable);
    $::widgets->{'video_bitrate_lock_check'}->set_sensitive($enable);
    $::widgets->{'video_bpp_entry'}->set_sensitive($enable);
    $::widgets->{'video_bpp_label'}->set_sensitive($enable);
    $::widgets->{'video_passes_spin'}->set_sensitive($enable);
    $::widgets->{'video_passes_label'}->set_sensitive($enable);
    $::widgets->{'filesize_spin'}->set_sensitive($enable);

    $enable = ( $enable || $value eq "nuv" );
    $::widgets->{'video_options_entry'}->set_text( $::settings->{ $value . '_options' } or "" );
    $::widgets->{'video_options_entry'}->set_sensitive($enable);
    $::widgets->{'video_options_label'}->set_sensitive($enable);

    $enable = ( $value ne "copy" );
    enable_crop_control($enable);
    enable_scale_control($enable);
    $::widgets->{'crop_enable_check'}->set_sensitive($enable);
    $::widgets->{'crop_detect_button'}->set_sensitive($enable);
    $::widgets->{'scale_enable_check'}->set_sensitive($enable);
    $::widgets->{'vf_pre_enable_check'}->set_sensitive($enable);
    $::widgets->{'vf_post_enable_check'}->set_sensitive($enable);
    $::widgets->{'vf_pre_entry'}->set_sensitive($enable);
    $::widgets->{'vf_post_entry'}->set_sensitive($enable);
  }
  if ( $name eq "audio_codec" ) {
    message( $::settings->{'available_audio'}{$value} );
    my $enable = ( $value eq "mp3lame" or $value eq "lavc" );
    $::widgets->{'audio_options_entry'}->set_sensitive($enable);
    $::widgets->{'audio_options_label'}->set_sensitive($enable);
    $::widgets->{'audio_gain_label'}->set_sensitive( $::settings->{"audio_codec"} ne "copy" );
    $::widgets->{'audio_gain_spin'}->set_sensitive( $::settings->{"audio_codec"}  ne "copy" );
    $::widgets->{'audio_options_entry'}->set_text( $::settings->{ "audio_" . $value . "_options" } or "" );
  }
  set_bpp();
}

# Sets trivial data, and UI manipulation
sub on_setting_changed {
  my $widget = shift;
  my $name   = $::widgets->get_widget_name($widget);
  $name =~ /([\w_]+)_\w+/;
  my $data = $1;
  my $ref  = ref $widget;
  my $value;
  my $boolean;
  my $encode = 1;

  if    ( $ref eq "Gtk2::Entry" )      { $value = $widget->get_text }
  elsif ( $ref eq "Gtk2::SpinButton" ) { $value = $widget->get_value_as_int }
  elsif ( $ref eq "Gtk2::CheckButton" || $ref eq "Gtk2::ToggleButton" ) {
    if ( $widget->get_active ) { $value = 1 }
    else { $value = 0 }
  }
  $::settings->{$data} = $value;

  if ( $widget eq $::widgets->{'video_bitrate_spin'} ) {
    set_bitrate() if $::settings->{'video_bitrate_lock'};
    set_bpp();
  }
  if ( $widget eq $::widgets->{'filesize_spin'} ) {
    set_bitrate() if defined $::dvd->{'track'};
  }
  if ( $widget eq $::widgets->{'total_blocks_spin'} ) {

    #on_filesize_changed();
    split_track() if defined $::dvd->{'track'};

    #set_bitrate() if defined $::dvd->{'track'};
  }
  if ( $widget eq $::widgets->{'tooltips_check'} ) {
    if ( $widget->get_active ) {
      $::widgets->{'tooltips'}->enable;
    }
    else {
      $::widgets->{'tooltips'}->disable;
    }
  }
  if ( $widget eq $::widgets->{'crop_enable_check'} ) {
    enable_crop_control( $::widgets->{'crop_enable_check'}->get_active && $encode );
  }
  if ( $widget eq $::widgets->{'scale_enable_check'} ) {
    enable_scale_control( $::widgets->{'scale_enable_check'}->get_active && $encode );
  }
  if ( $widget eq $::widgets->{'vf_pre_enable_check'} ) {
    $boolean = $::widgets->{'vf_pre_enable_check'}->get_active && $encode;
    $::widgets->{'vf_pre_entry'}->set_sensitive($boolean);
  }
  if ( $widget eq $::widgets->{'vf_post_enable_check'} ) {
    $boolean = $::widgets->{'vf_post_enable_check'}->get_active && $encode;
    $::widgets->{'vf_post_entry'}->set_sensitive($boolean);
  }
  if ( $widget eq $::widgets->{'video_bitrate_lock_check'} ) {
    if ($value) {
      $::widgets->{'video_bitrate_spin'}->show;
      $::widgets->{'video_bitrate_entry'}->hide;
      $::widgets->{'filesize_spin'}->hide;
      $::widgets->{'filesize_entry'}->show;
      $::widgets->{'filesize_entry'}->set_text( $::widgets->{'filesize_spin'}->get_value_as_int );
      set_bitrate();
    }
    else {
      $::widgets->{'video_bitrate_spin'}->hide;
      $::widgets->{'video_bitrate_entry'}->show;
      $::widgets->{'filesize_spin'}->show;
      $::widgets->{'filesize_entry'}->hide;
      $::widgets->{'video_bitrate_entry'}->set_text( $::widgets->{'video_bitrate_spin'}->get_value_as_int );
    }
  }
  if ( $widget eq $::widgets->{'video_options_entry'} ) {
    $::settings->{ $::settings->{'video_codec'} . "_options" } = $::widgets->{'video_options_entry'}->get_text;
  }
  if ( $widget eq $::widgets->{'audio_options_entry'} ) {
    $::settings->{ "audio_" . $::settings->{'audio_codec'} . "_options" } = $::widgets->{'audio_options_entry'}->get_text;
    set_bitrate();
  }
  if ( $widget eq $::widgets->{'scale_width_spin'}
    || $widget eq $::widgets->{'scale_height_spin'}
    || $widget eq $::widgets->{'crop_width_spin'}
    || $widget eq $::widgets->{'crop_height_spin'}
    || $widget eq $::widgets->{'crop_horizontal_spin'}
    || $widget eq $::widgets->{'crop_vertical_spin'} )
  {
    set_bpp();
  }
  if ( $widget eq $::widgets->{'filename_entry'} ) {
    my $fullname  = substitute_filename($value) . $::settings->{'mpegfile'};
    my $directory = dirname($fullname);
    $::widgets->{'view_button'}->set_sensitive( -r $fullname ? 1 : 0 );    # Allow view if the file is readable.
    set_warning_text( $widget, -w $directory ? 0 : 1 );
    message("No permission to write to output directory!") if -w $directory ? 0 : 1;
    on_filesize_changed();
  }
  if ( $widget eq $::widgets->{'crop_width_spin'} ) {
    my $wo = get_track_param('width');
    $::widgets->{'crop_horizontal_spin'}->set_adjustment( new Gtk2::Adjustment( 0, 0, $wo - $value, 1, 50, 200 ) );
    set_bpp();
  }
  if ( $widget eq $::widgets->{'crop_horizontal_spin'} ) {
    my $wo = get_track_param('width');
    $::widgets->{'crop_width_spin'}->set_adjustment( new Gtk2::Adjustment( 0, 0, $wo - $value, 1, 50, 200 ) );
    set_bpp();
  }
  if ( $widget eq $::widgets->{'crop_height_spin'} ) {
    my $wo = get_track()->{'height'};
    $::widgets->{'crop_vertical_spin'}->set_adjustment( new Gtk2::Adjustment( 0, 0, $wo - $value, 1, 50, 200 ) );
    set_bpp();
  }
  if ( $widget eq $::widgets->{'crop_vertical_spin'} ) {
    my $wo = get_track_param('height');
    $::widgets->{'crop_height_spin'}->set_adjustment( new Gtk2::Adjustment( 0, 0, $wo - $value, 1, 50, 200 ) );
    set_bpp();
  }
  if ( $widget eq $::widgets->{'cache_directory_entry'} ) {
    set_warning_text( $widget, -w $value ? 0 : 1 );
  }
  if ( $widget eq $::widgets->{'dvd_device_entry'} ) {
    set_warning_text( $widget, -r $value ? 0 : 1 );
  }
  if ( $widget eq $::widgets->{'audio_gain_spin'} ) {
  }
  1;
}

sub on_save_settings_button_clicked {
  message("Settings saved");
  $::settings->save_settings;
}

sub on_restore_defaults_button_clicked {
  $::settings->restore_settings;
  load_settings_to_interface();
}

sub progress_dialog_show {
  if ( $::widgets->{'cache_menc_vbox'}->parent == $::widgets->{'right_vbox'} ) {
    $::widgets->{'acidrip'}->hide;
    $::widgets->{'right_vbox'}->remove( $::widgets->{'cache_menc_vbox'} );
    $::widgets->{'progress_vbox'}->add( $::widgets->{'cache_menc_vbox'} );

    $::widgets->{'status_hbox'}->remove( $::widgets->{'status_bar'} );
    $::widgets->{'progress_vbox'}->add( $::widgets->{'status_bar'} );

    $::widgets->{'progress_dialog'}->show;
  }
}

sub progress_dialog_hide {
  if ( $::widgets->{'cache_menc_vbox'}->parent == $::widgets->{'progress_vbox'} ) {
    $::widgets->{'progress_dialog'}->hide;
    $::widgets->{'progress_vbox'}->remove( $::widgets->{'cache_menc_vbox'} );
    $::widgets->{'right_vbox'}->pack_start( $::widgets->{'cache_menc_vbox'}, 0, 1, 0 );

    $::widgets->{'progress_vbox'}->remove( $::widgets->{'status_bar'} );
    $::widgets->{'status_hbox'}->add( $::widgets->{'status_bar'} );

    $::widgets->{'acidrip'}->show;
  }
}

sub on_queue_clear_button_clicked {
  $::playlist->clear;
  rebuild_queue_text();

  $::widgets->{'queue_export_button'}->set_sensitive( @{$::playlist} ? 1 : 0 );
  $::widgets->{'queue_clear_button'}->set_sensitive( @{$::playlist}  ? 1 : 0 );
}

sub on_queue_export_button_clicked {
  if ( open( QUEUEFILE, '>', "$ENV{HOME}/acidrip.sh" ) ) {
    print QUEUEFILE "#!/bin/sh\necho \"***********************************************************\"\n"
      . "echo \"Automated script created by AcidRip - http://acidrip.sf.net\"\n"
      . "echo \"***********************************************************\"\n";
    my $text = $::widgets->{'queue_text'}->get_buffer->get_text( $::widgets->{'queue_text'}->get_buffer->get_bounds, 0 );
    $text =~ s/-v\s//g;
    print QUEUEFILE $text;
    close QUEUEFILE;
    chmod 0755, "$ENV{HOME}/acidrip.sh";
    message("Queue exported to $ENV{HOME}/acidrip.sh");
  }
  else {
    message("Error opening queue output file");
  }
}

sub on_queue_button_clicked {
  push_playlist_queue();
  rebuild_queue_text();

  $::widgets->{'queue_export_button'}->set_sensitive( @{$::playlist} ? 1 : 0 );
  $::widgets->{'queue_clear_button'}->set_sensitive( @{$::playlist}  ? 1 : 0 );
}

sub on_start_button_clicked {
  $::widgets->{'queue_button'}->clicked if !@{$::playlist};
  my @cache_files = [];
  my $return      = 0;

  $::widgets->{'cache_menc_vbox'}->show;
  $::widgets->{'stop_button'}->show;
  $::widgets->{'start_button'}->hide;
  $::widgets->{'preview_button'}->set_sensitive(0);
  $::widgets->{'progress_dialog_show_button'}->set_sensitive(1);

  progress_dialog_show if $::settings->{'compact'};

  #Play contents of Playlist until ended or an error occurs
  message( "Playlist contains " . @{$::playlist} . " item(s)" );
	$::settings->{'total_events'} = queued_encode_events();
  while ( @{$::playlist} ) {
    $return = pop_playlist_queue();
    last if $return;
    rebuild_queue_text();
  }

  #Clear any dead items stuck on the playlist
  if ( @{$::playlist} ) {
    message( "Clearing " . @{$::playlist} . " remaining playlist items" );
    $::widgets->{'queue_clear_button'}->clicked;
  }
  else {
    message("Playlist completed");
  }

  progress_dialog_hide if $::settings->{'compact'};
  $::widgets->{'stop_button'}->hide;
  $::widgets->{'start_button'}->show;
  $::widgets->{'preview_button'}->set_sensitive(1);
  $::widgets->{'progress_dialog_show_button'}->set_sensitive(0);
  
	$::widgets->{'acidrip'}->set_title(msg("acidrip"));
	$::widgets->{'progress_dialog'}->set_title(msg("acidrip"));
  
	message(
    $return ? ( ( $return >> 8 ) == 1 ? "Mencoder interrupted by user" : "Mencoder exited with an error code " . ( $return >> 8 ) ) : "Encoding finished, hope it worked..." );
  $::settings->{'mencoder_pid'} = 0;
	$::settings->{'this_block'} = 0;
  set_bitrate();
}

sub on_stop_button_clicked {
  my $confirm = Gtk2::MessageDialog->new( $::widgets->{'acidrip'}, [qw/modal destroy-with-parent/], 'question', 'yes-no', "Are you sure you want to stop the encoding process?" );
  if ( $confirm->run eq 'yes' ) {
    kill_mplayer();
  }
  $confirm->destroy;
}

sub on_stop_preview_button_clicked {
  kill_mplayer();
}

sub on_mencoder_output_show_button_clicked {
  $::widgets->{'mencoder_output_frame'}->show_all;
  $::widgets->{'mencoder_output_show_button'}->hide;
}

sub on_mencoder_output_hide_button_clicked {
  $::widgets->{'mencoder_output_frame'}->hide;
  $::widgets->{'mencoder_output_show_button'}->show_all;
  $::widgets->{'status_hbox'}->show_all;
}

sub on_mencoder_output_save_button_clicked {
  if ( open( LOGFILE, '>', "$ENV{HOME}/acidrip.log" ) ) {
    print LOGFILE $::widgets->{'mencoder_output_text'}->get_buffer->get_text( $::widgets->{'mencoder_output_text'}->get_buffer->get_bounds, 0 );
    close LOGFILE;
    message("Output log saved to $ENV{HOME}/acidrip.log");
  }
  else {
    message("Error opening output file");
  }
}

sub on_mencoder_output_saveall_button_clicked {
  $::widgets->{'mencoder_output_save_button'}->set_sensitive( !$::widgets->{'mencoder_output_saveall_button'}->get_active );
  if ( $::widgets->{'mencoder_output_saveall_button'}->get_active ) {
    open( LOGFILE, '>', "$ENV{HOME}/acidrip.log" );
    print LOGFILE $::widgets->{'mencoder_output_text'}->get_buffer->get_text( $::widgets->{'mencoder_output_text'}->get_buffer->get_bounds, 0 );
  }
  else { close LOGFILE }
}

sub on_mencoder_output_clear_button_clicked {
  message("Log information cleared");
  $::widgets->{'mencoder_output_text'}->get_buffer->delete( $::widgets->{'mencoder_output_text'}->get_buffer->get_bounds );
}

sub on_view_button_clicked {

  #fork proofing
  open STDIN, '/dev/null' or message("Can't read /dev/null: $!. May fail if in background");

  message("Playing back encoded track...");
  my $mplayer_output;
  open( VIEW, get_command("view") . " 2>&1 |" ) || ( message("mplayer preview failed, is it installed?") );
  while (<VIEW>) {
    $mplayer_output .= $_;
    while ( Gtk2->events_pending() ) { Gtk2->main_iteration() }
  }
  message($mplayer_output);
  message("Playing back encoded track... Finished");
}

sub on_read_dvd_button_clicked {
  my ( $button, $widgets ) = @_;
  my $model;
  my $dvd_tree = $::widgets->{'dvd_tree'};
  message("Reading DVD / file(s)... please wait");
	$model = Gtk2::TreeStore->new( 'Glib::String', 'Glib::String' );
  $dvd_tree->set_model($model);

  my $ret;

  while ( Gtk2->events_pending() ) { Gtk2->main_iteration() }

  $ret = read_source( $::settings->{'dvd_device'} );

  message( $::dvd->{'status'}, $ret ? "error" : "" );
  if ( defined $::dvd->{'track'} ) {
    my $selection = $dvd_tree->get_selection;

    foreach my $this_track ( @{ $::dvd->{'track'} } ) {
      my $iter = $model->append(undef);
      my $ix   = $this_track->{'ix'};
      if ( $::dvd->{'source'} eq "dvd" ) {    # DVD input
        $selection->set_mode('multiple');
        $model->set( $iter, 0, $ix, 1, $ix . ": " . hhmmss( $this_track->{'length'} ) );
        foreach my $this_chapter ( @{ $this_track->{'chapter'} } ) {
          $model->set( $model->append($iter), 0, $this_chapter->{'ix'}, 1, $this_chapter->{'ix'} . ": " . hhmmss( $this_chapter->{'length'} ) );
        }
      }
      else {                                  # File input
        $selection->set_mode('single');
        $model->set( $iter, 0, $ix, 1, basename( $this_track->{'filename'} ) );
        $model->set( $model->append($iter), 0, 0, 1,
              "V: "
            . $this_track->{'format'} . ' '
            . $this_track->{'width'} . "x"
            . $this_track->{'height'} . ' '
            . (defined $this_track->{'bitrate'} ? int( $this_track->{'bitrate'} * .001 ) : "??" ) . "kbps" 
            . (defined $this_track->{'audio'}[0]{'format'} ? ( "\nA: " . $this_track->{'audio'}[0]{'format'} . ' '
              . (defined $this_track->{'audio'}[0]{'bitrate'} ? int( $this_track->{'audio'}[0]{'bitrate'} * .001) : "??" ) . "kbps@"
              . (defined $this_track->{'audio'}[0]{'frequency'} ? $this_track->{'audio'}[0]{'frequency'} * .001 : "??") . "kHz "
              . (defined $this_track->{'audio'}[0]{'channels'} ? $this_track->{'audio'}[0]{'channels'} : "?") . "ch" ) : ''));
      }
    }
    my $cell   = Gtk2::CellRendererText->new;
    my $column = Gtk2::TreeViewColumn->new_with_attributes( "content", $cell, 'text', 1 );

    $dvd_tree->remove_column( $dvd_tree->get_column(0) ) if ( scalar $dvd_tree->get_columns() );
    $dvd_tree->append_column($column);

    $selection->signal_connect( changed => \&on_select_track, $model );

    my $path = Gtk2::TreePath->new_from_string( defined $::dvd->{'longest_track'} ? $::dvd->{'longest_track'} - 1 : 0 );
    $selection->select_path($path);
    $dvd_tree->scroll_to_cell($path);
    $dvd_tree->show_all;

    $::widgets->{'total_blocks_spin'}->set_sensitive($::dvd->{'source'} eq "dvd");
    $::widgets->{'total_blocks_label'}->set_sensitive($::dvd->{'source'} eq "dvd");
    $::widgets->{'total_blocks_spin'}->set_value(1) if $::dvd->{'source'} ne "dvd";

    if ( defined $::dvd->{'title'} ) {
      my $name = $::dvd->{'title'};
      $name =~ tr/A-Z/a-z/;
      set_setting( 'title', $name );
    }

    $::widgets->{'preview_button'}->set_sensitive(1);
    $::widgets->{'start_button'}->set_sensitive(1);
    $::widgets->{'queue_button'}->set_sensitive(1);
  }
}

1;
