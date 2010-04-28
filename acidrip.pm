#!/usr/bin/perl -w

package acidrip;
require 5.000;
use strict;
use POSIX;    #needed for floor()
use AcidRip::interface;
use AcidRip::signals;
use AcidRip::messages;
use Data::Dumper;
use File::Basename;
use Gtk2::Helper;

sub gui_check ($) {
  if (/SKIN/) {
    my $msg = "You have set gui=yes in your config file. this is not a valid MPlayer option, only there for debugging. Remove it and use gmplayer instead for a gui!";
    message($msg);
    print $msg . "\n";
  }
}

sub set_warning_text ($$) {
  my $widget = shift;
  my $warn   = shift;
  $widget->modify_text( 'normal', Gtk2::Gdk::Color->new( $warn * 65535, 0, 0 ) );
}

sub hhmmss ($) {
  my $s    = shift;
  my $m    = floor $s / 60;
  my $mins = $m % 60;
  my $hour = floor $m / 60;
  return sprintf( "%d:%02d:%02d", $hour, $mins, $s % 60 );
}

sub split_track {
  if ( defined $::dvd->{'track'} && defined get_track()->{'chapter'}) {
    $::settings->{'blocks'} = undef;
    $::settings->{'blocks'} = ();
    my $start = $::settings->{'selected_chapters_start'} || 1;
    my $stop  = $::settings->{'selected_chapters_end'}   || get_track()->{'chapter'}[-1]->{'ix'};
    my $total_length = get_selection_length();

    my $length     = 0;
    my $this_block = 1;
    my $old_length = $length;
    $::settings->{'blocks'}[0] = $start - 1;

    foreach my $chapter ( $start .. $stop ) {
      my $this_chapter = get_chapter($chapter);
      my $target       = $total_length * $this_block / $::settings->{'total_blocks'};
      $length += $this_chapter->{'length'};
      $::settings->{'blocks'}[$this_block] = $chapter;
      $this_block++ if $old_length < $target && $length > $target;
      $old_length = $length;
    }

    $::settings->{'UI'} && set_warning_text( $::widgets->{'total_blocks_spin'}, ( scalar @{ $::settings->{'blocks'} } ) - 1 < $::settings->{'total_blocks'} ? 1 : 0 );
    my $msg = "Blocks: ";
    for ( 1 .. @{ $::settings->{'blocks'} } - 1 ) {
      $msg .= " $_=[" . ( $::settings->{'blocks'}[ $_ - 1 ] + 1 ) . "-" . ( $::settings->{'blocks'}[$_] ) . "] ";
    }
    message($msg);
    return @{ $::settings->{'blocks'} };
  }
	elsif ( defined $::dvd->{'track'}) {
		message("Can't split video files, only DVD's") if $::dvd->{'source'} eq 'file';
		message("Can't split track - No chapters on this DVD track") if $::dvd->{'source'} eq "dvd";
	}
  else {
    message("Can't split track - No DVD loaded!");
  }
}

sub converttoint {
  my $total = 0;
  my $i;
  my $data = shift;
  for ( $i = 0 ; $i < length($data) ; $i++ ) {
    my $c = substr( $data, $i, 1 );
    my $value = 256**$i * ord($c);
    $total += $value;
  }
  return $total;
}

sub get_track {
  my $ix = shift || $::settings->{'selected_track'};
  return -1 if ! defined $::dvd->{'track'};
  return -1 if ! scalar @{$::dvd->{'track'}};

  foreach ( @{ $::dvd->{'track'} } ) {
    return $_ if $ix == $_->{'ix'};
  }
  return -1;
}

sub get_track_param ($) {
	my $param = shift;
	my $track = get_track();
	if (ref($track) eq 'HASH' and defined $track->{$param}) {
		return $track->{$param} 
	} else {
		return -1
	}
}

sub get_audio {
  my $ix = shift;
  my $track = get_track( shift || $::settings->{'selected_track'} );
  foreach ( @{ $track->{'audio'} } ) {
    return $_ if $ix == $_->{'ix'};
  }
  return -1;
}

sub get_chapter {
  my $ix = shift;
  my $track = get_track( shift || $::settings->{'selected_track'} );
  foreach ( @{ $track->{'chapter'} } ) {
    return $_ if $ix == $_->{'ix'};
  }
  return -1;
}

sub get_cell {
  my $ix = shift;
  my $track = get_track( shift || $::settings->{'selected_track'} );
  foreach ( @{ $track->{'cell'} } ) {
    return $_ if $ix == $_->{'ix'};
  }
  return -1;
}

sub message {
  my ( $data, $tag ) = @_;

  if ( defined $::widgets ) {
    my $context_id = $::widgets->{'status_bar'}->get_context_id('acidrip');
    $::widgets->{'status_bar'}->pop($context_id);
    $::widgets->{'status_bar'}->push( $context_id, $data );
    my $iter = $::widgets->{'mencoder_output_text'}->get_buffer->get_end_iter;
    if ($tag) {
      $::widgets->{'mencoder_output_text'}->get_buffer->insert_with_tags_by_name( $iter, "AcidRip message - $data\n", $tag );
    }
    else {
      $::widgets->{'mencoder_output_text'}->get_buffer->insert( $iter, "AcidRip message - $data\n" );
    }
  }
  else {
    print "AcidRip message - $data\n";
  }
}

sub load_settings_to_interface {
  foreach my $value ( keys %{$::settings} ) {
    $::widgets->{ $value . "_entry" }->set_text( $::settings->{$value} )
      if defined( $::widgets->{ $value . "_entry" } )
      and $value ne $::widgets->{ $value . "_entry" }->get_text;
    $::widgets->{ $value . "_spin" }->set_value( $::settings->{$value} )
      if defined( $::widgets->{ $value . "_spin" } )
      and $value ne $::widgets->{ $value . "_spin" }->get_value_as_int;
    $::widgets->{ $value . "_check" }->set_active( $::settings->{$value} )
      if defined( $::widgets->{ $value . "_check" } );
    $::widgets->{ $value . "_option" }->set_history( $::settings->{$value} )
      if ( $::settings->{$value} =~ /^\d+$/ )
      and defined( $::widgets->{ $value . "_option" } );
  }
}

sub set_setting ($$) {
  my ( $name, $data ) = @_;
  $::settings->{$name} = $data;
  $::widgets->{ $name . "_entry" }->set_text($data)
    if defined $::widgets->{ $name . "_entry" } and $data ne $::widgets->{ $name . "_entry" }->get_text;    # and $::widgets->{$name . "_entry"}->get('editable');
  $::widgets->{ $name . "_spin" }->set_value($data)
    if defined $::widgets->{ $name . "_spin" } and $data ne $::widgets->{ $name . "_spin" }->get_value;     #and $::widgets->{$name . "_spin"}->get('editable');
}

sub substitute_filename ($) {
  my $filename = shift;
  my $f = substr( $::settings->{'title'}, 0, 1 );
  $filename =~ s/%N/$::settings->{'selected_track'}/g;                                                      # track Number
  $filename =~ s/%f/$f/g;                                                                                   # First letter of title
  $filename =~ s/%T/$::settings->{'title'}/g;                                                               # Title
  $filename =~ s/%L/$::settings->{'length'}/g;                                                              # Length
  $filename =~ s/%b/$::settings->{'video_bitrate'}/g;                                                       # bitrate
  $filename =~ s/%l/$::settings->{'language'}/g;                                                            # language
  $filename =~ s/%w/$::settings->{'scale_width'}/g;                                                         # width
  $filename =~ s/%h/$::settings->{'scale_height'}/g;                                                        # height
  return $filename;
}

sub get_parameters {
  split_track() if $::settings->{'total_blocks'} > 1;
  set_bitrate() if $::settings->{'this_block'} > 0;

  my %menc   = ();
  my $length = get_track()->{'length'};

  $menc{'video_options'} = $::settings->{'video_options'};
  $menc{'video'}         = "-ovc $::settings->{'video_codec'}";

  $menc{'info'} = "-info srcform=\"DVD ripped by acidrip.sf.net\"";
  $menc{'info'} .= ":name=\"$::settings->{'info_name'}\""           if defined $::settings->{'info_name'}      && $::settings->{'info_name'}      ne '';
  $menc{'info'} .= ":comment=\"$::settings->{'info_comment'}\""     if defined $::settings->{'info_comment'}   && $::settings->{'info_comment'}   ne '';
  $menc{'info'} .= ":artist=\"$::settings->{'info_artist'}\""       if defined $::settings->{'info_artist'}    && $::settings->{'info_artist'}    ne '';
  $menc{'info'} .= ":subject=\"$::settings->{'info_subject'}\""     if defined $::settings->{'info_subject'}   && $::settings->{'info_subject'}   ne '';
  $menc{'info'} .= ":genre=\"$::settings->{'info_genre'}\""         if defined $::settings->{'info_genre'}     && $::settings->{'info_genre'}     ne '';
  $menc{'info'} .= ":copyright=\"$::settings->{'info_copyright'}\"" if defined $::settings->{'info_copyright'} && $::settings->{'info_copyright'} ne '';

  if ( $::settings->{'video_codec'} eq 'lavc' ) {
    $menc{'video'} = "-ovc lavc -lavcopts $::settings->{'lavc_options'}:vbitrate=$::settings->{'video_bitrate'}";
    $menc{'video'} .= ":vpass=$::settings->{'video_pass'}" if $::settings->{'video_passes'} > 1;
  }
  if ( $::settings->{'video_codec'} eq 'divx4' ) {
    $menc{'video'} = "-ovc divx4 -divx4opts $::settings->{'divx4_options'}:br=$::settings->{'video_bitrate'}";
    $menc{'video'} .= ":pass=$::settings->{'video_pass'}" if $::settings->{'video_passes'} > 1;
  }
  if ( $::settings->{'video_codec'} eq 'xvid' ) {
    $menc{'video'} = "-ovc xvid -xvidencopts bitrate=$::settings->{'video_bitrate'}";
    $menc{'video'} .= ":$::settings->{'xvid_options'}" if $::settings->{'xvid_options'} ne "";
    $menc{'video'} .= ":pass=$::settings->{'video_pass'}" if $::settings->{'video_passes'} > 1;
  }
  if ( $::settings->{'video_codec'} eq 'nuv' ) {
    $menc{'video'} = "-ovc nuv -nuvopts $::settings->{'nuv_options'}";
  }

  if ( $::dvd->{'source'} eq "dvd" ) {
    $menc{'dvdplay'} = "dvd://$::settings->{'selected_track'}";
    $menc{'dvdplay'} .= " -dvd-device $::settings->{'dvd_device'}" if $::settings->{'dvd_device'} ne '';
    $menc{'dvdmenc'} = $menc{'dvdplay'};

    if ( $::settings->{'mplayer_version'} < 1 ) {
      $menc{'dvdmenc'} = "-dvd $::settings->{'selected_track'}";
      $menc{'dvdmenc'} .= " -dvd-device $::settings->{'dvd_device'}" if $::settings->{'dvd_device'} ne '';
    }
    if ( $::settings->{'mplayer_version'} < 0.9 ) {
      $menc{'dvdplay'} = "-dvd $::settings->{'selected_track'}";
      $menc{'dvdplay'} .= " -dvd-device $::settings->{'dvd_device'}" if $::settings->{'dvd_device'} ne '';
    }
  }
  else {
    $menc{'dvdplay'} = quotemeta( get_track()->{'filename'} );
    $menc{'dvdmenc'} = quotemeta( get_track()->{'filename'} );
  }

  $menc{'audio_track'} = '';
  $menc{'audio_track'} = "-alang $::settings->{'language'}" if ( $::settings->{'selected_audio'} == -1 );
  $menc{'audio_track'} = "-nosound" if ( $::settings->{'selected_audio'} == -2 );
  $menc{'audio_track'} = join( " ", "-aid", $::settings->{'selected_audio'} + 127 ) if ( $::settings->{'selected_audio'} > 0 );

  $menc{'audio'} = "-oac $::settings->{'audio_codec'}";
  $menc{'audio'} .= " -lameopts $::settings->{'audio_mp3lame_options'}" if $::settings->{'audio_codec'} eq 'mp3lame';
  $menc{'audio'} .= " -lavcopts $::settings->{'audio_lavc_options'}"    if $::settings->{'audio_codec'} eq 'lavc';
	$menc{'audio'} = '' if ( $::settings->{'selected_audio'} == -2 );

  $menc{'basename'} = substitute_filename( $::settings->{'filename'} );
  $menc{'basename'} = $menc{'basename'} . "-" . $::settings->{'this_block'} if $::settings->{'this_block'};

  $menc{'output'} = $::settings->{'video_pass'} == 1 ? "/dev/null" : $menc{'basename'} . ( $::settings->{'mpegfile'} ? ".mpg" : ".avi" );

  $menc{'af'} = $::settings->{'audio_gain'} == 0 ? "" : "-af volume=" . $::settings->{'audio_gain'} . ":sc";
  $menc{'af'} = '' if ( $::settings->{'selected_audio'} == -2 );

  $menc{'mpegfile'} = $::settings->{'mpegfile'} ? "-of mpeg" : "";

  $menc{'subp'} = $::settings->{'selected_subp'} > -1 ? "-sid " . ( $::settings->{'selected_subp'} - 1 ) : "";

  $menc{'subout'} = $::settings->{'vobsubout'} ? "-vobsubout $menc{'basename'}" : "";

  $menc{'scale'} = $::settings->{'scale_enable'} ? "scale=$::settings->{'scale_width'}:$::settings->{'scale_height'}" : "";

  $menc{'crop'} =
    $::settings->{'crop_enable'} ? "crop=$::settings->{'crop_width'}:$::settings->{'crop_height'}:$::settings->{'crop_horizontal'}:$::settings->{'crop_vertical'}" : '';

  $menc{'vf'} = ( $::settings->{'mplayer_version'} < 1 ) ? "-vop" : "-vf";

  $menc{'vf_pre'} = $::settings->{'vf_pre'} if $::settings->{'vf_pre_enable'} && $::settings->{'vf_pre'} ne '';

  $menc{'vf_post'} = $::settings->{'vf_post'} if $::settings->{'vf_post_enable'} && $::settings->{'vf_post'} ne '';

  my $cw = $::settings->{'crop_width'}  || get_track()->{'width'};
  my $ch = $::settings->{'crop_height'} || get_track()->{'height'};

  my @vfoptions;
  if ( $::settings->{'mplayer_version'} < 1 ) {
    push( @vfoptions, $menc{'vf_post'} ) if $menc{'vf_post'};
    push( @vfoptions, $menc{'scale'} )   if $menc{'scale'};
    push( @vfoptions, $menc{'crop'} )    if $menc{'crop'};
    push( @vfoptions, $menc{'vf_pre'} )  if $menc{'vf_pre'};

    $menc{'embed'} =
      $::settings->{'embed_preview'}
      ? " -vop scale=" . $::widgets->{'preview_socket'}->allocation->width . ":-2,$menc{'crop'} -wid " . $::widgets->{'preview_socket'}->get_id
      : ( @vfoptions ? "$menc{'vf'} " . join( ",", @vfoptions ) : '' );
  }
  else {
    push( @vfoptions, $menc{'vf_pre'} )  if $menc{'vf_pre'};
    push( @vfoptions, $menc{'crop'} )    if $menc{'crop'};
    push( @vfoptions, $menc{'scale'} )   if $menc{'scale'};
    push( @vfoptions, $menc{'vf_post'} ) if $menc{'vf_post'};

    $menc{'crop'} .= "," if $menc{'crop'};

    $menc{'embed'} =
      $::settings->{'embed_preview'}
      ? " -vf $menc{'crop'}scale=" . $::widgets->{'preview_socket'}->allocation->width . ":-2 -wid " . $::widgets->{'preview_socket'}->get_id
      : ( @vfoptions ? "$menc{'vf'} " . join( ",", @vfoptions ) : '' );
  }
	
  $menc{'vf_filters'} = ($::settings->{'video_codec'} ne 'copy' && scalar(@vfoptions)) ? "$menc{'vf'} " . join( ",", @vfoptions ) : "";

  $menc{'chapter'} = '';
  if ( $::settings->{'total_blocks'} > 1 && $::settings->{'this_block'} > 0 && $::dvd->{'source'} eq "dvd") {
    $menc{'chapter'} = "-chapter " . ( $::settings->{'blocks'}[ $::settings->{'this_block'} - 1 ] + 1 ) . "-" . $::settings->{'blocks'}[ $::settings->{'this_block'} ];
    $length = get_selection_length( $::settings->{'blocks'}[ $::settings->{'this_block'} - 1 ] + 1, $::settings->{'blocks'}[ $::settings->{'this_block'} ] );
  }
  elsif ( $::settings->{'selected_chapters_start'} > 0 && $::settings->{'selected_chapters_end'} > 0 && $::dvd->{'source'} eq "dvd") {
    $menc{'chapter'} = "-chapter $::settings->{'selected_chapters_start'}-$::settings->{'selected_chapters_end'}";
    $length = get_selection_length( $::settings->{'selected_chapters_start'}, $::settings->{'selected_chapters_end'} );
  }

  my $frames = $::settings->{'ppc_bug'} ? 100 : 10;
  my $sstep = "-sstep " . int $length / ( 3 * $frames ) + 1;
  $sstep = "-ss " . int $length / 3 if $::settings->{'ppc_bug'};
  $menc{'frames'} = "-frames $frames $sstep";

  my $basename = basename substitute_filename( $::settings->{'filename'} );
  $menc{'cache'} = $::settings->{'cache_directory'} . "/" . $basename . "-cache";
  $menc{'cache'} = $::settings->{'cache_directory'} . "/" . $basename . "-" . $::settings->{'this_block'} . "-cache" if $::settings->{'this_block'};

  $menc{'more_options'} = $::settings->{'more_options'};

  return %menc;
}

sub get_command {
  my $command = shift;
  my %menc    = get_parameters();

  return
"$::settings->{'mencoder'} $menc{'cache'} $menc{'audio'} $menc{'audio_track'} $menc{'video'} $menc{'vf_filters'} $menc{'more_options'} $menc{'af'} $menc{'audio_track'} $menc{'mpegfile'} -o \"$menc{'output'}\""
    if $command eq "mencoder" && $::settings->{'cache'} && $::dvd->{'source'} eq "dvd";

  return
"$::settings->{'mencoder'} $menc{'dvdmenc'} $menc{'chapter'} $menc{'audio_track'} $menc{'subp'} $menc{'subout'} $menc{'info'} $menc{'audio'} $menc{'af'} $menc{'video'} $menc{'vf_filters'}  $menc{'mpegfile'} $menc{'more_options'} -o \"$menc{'output'}\""
    if $command eq "mencoder";

  return "$::settings->{'mplayer'} $menc{'dvdplay'} $menc{'audio_track'} $menc{'af'} $menc{'chapter'} $menc{'frames'}	-nocache $menc{'embed'}"
    if $command eq "preview" && $::settings->{'flickbook_preview'} && !$::settings->{'ppc_bug'};

  return "$::settings->{'mplayer'} $menc{'embed'} $menc{'dvdplay'} $menc{'af'} $menc{'audio_track'} $menc{'chapter'} $menc{'subp'} -nocache"
    if $command eq "preview";

  return "$::settings->{'mplayer'} -quiet \"$menc{'output'}\""
    if $command eq "view";

  return "$::settings->{'mplayer'} $menc{'dvdplay'} $menc{'chapter'} -v -v -dumpstream -dumpfile \"$menc{'cache'}\""
    if $command eq "cache";

  return "$::settings->{'mplayer'} $menc{'vf'} cropdetect $menc{'dvdplay'} -nosound -vo null $menc{'frames'} -nocache"
    if $command eq "cropdetect";

  return "$::settings->{'mencoder'} $menc{'cache'} $menc{'audio'} $menc{'audio_track'} $menc{'af'} -ovc frameno -o frameno.avi"
    if $command eq "mencoder_frameno" && $::settings->{'cache'};

  return "$::settings->{'mencoder'} $menc{'dvdmenc'} $menc{'chapter'} $menc{'audio'} $menc{'audio_track'} $menc{'af'} -ovc frameno -o frameno.avi"
    if $command eq "mencoder_frameno";

  return "$::settings->{'mencoder'} $menc{'cache'} -oac copy $menc{'video'} $menc{'vf_filters'} $menc{'more_options'} $menc{'audio_track'} $menc{'mpegfile'} -o \"$menc{'output'}\""
    if $command eq "mencoder_3pass" && $::settings->{'cache'};

  return
"$::settings->{'mencoder'} $menc{'dvdmenc'} $menc{'chapter'} $menc{'subp'} $menc{'subout'} $menc{'info'} -oac copy $menc{'video'} $menc{'vf_filters'}  $menc{'mpegfile'} $menc{'more_options'} -o \"$menc{'output'}\""
    if $command eq "mencoder_3pass";

  return "unlink \"$menc{'cache'}\"" if $command eq "del_cache";

  return "command not found!";
}

sub set_bitrate {
  return -1 if !defined $::dvd->{'track'};
  my $length;
  my $size;
  my $bitrate    = 0;
  my $audio_rate = 128;
  my $this_track = get_track();

  if ( $::settings->{'audio_codec'} eq 'mp3lame' && $::settings->{'audio_mp3lame_options'} =~ /br=(\d+)/ ) {
    $audio_rate = $1;
  }
  elsif ( $::settings->{'audio_codec'} eq 'lavc' && $::settings->{'audio_lavc_options'} =~ /abitrate=(\d+)/ ) {
    $audio_rate = $1;
  }
  elsif ( $::settings->{'audio_codec'} eq 'copy' ) {
    my $channels = $this_track->{'audio'}[ $::settings->{'selected_audio'} ]->{'channels'};
    $audio_rate = 192 if $channels == 2;
    $audio_rate = 384 if $channels == 6;
  }

  if ( $::settings->{'this_block'} ) {
    $length = get_selection_length( $::settings->{'blocks'}[ $::settings->{'this_block'} - 1 ] + 1, $::settings->{'blocks'}[ $::settings->{'this_block'} ] );
    $size = $::settings->{'filesize'};
  }
  elsif ( $::settings->{'total_blocks'} > 1 ) {
    $length = get_selection_length();
    $size = $::settings->{'filesize'} * ( scalar @{ $::settings->{'blocks'} } - 1 );
  }
  else {
    $length = get_selection_length();
    $size   = $::settings->{'filesize'};
  }

  if ( $::settings->{'video_bitrate_lock'} ) {
    set_filesize( $length, $audio_rate );
		set_bpp();
    return -1;
  }

  if ( $size == 0 || $length == 0 || $size !~ /^\d+$/ ) { $bitrate = -1 }
  else { $bitrate = int( ( ( $size * 8192 ) / $length ) - $audio_rate ) }
  $bitrate = 5000 if $bitrate > 5000;
  if ( $bitrate < 0 ) { message("Error setting bitrate") }
  set_setting( 'video_bitrate', $bitrate );
  set_bpp();
}

sub set_filesize ($$) {
  my $length     = shift;
  my $audio_rate = shift;
  my $bitrate    = $::widgets->{'video_bitrate_spin'}->get_value_as_int;
  my $size;

  if ( $bitrate == 0 || $length == 0 || $audio_rate !~ /^\d+$/ ) {
    $size = -1;
  }
  else {
    $size = int( ( ( $audio_rate + $bitrate ) * $length ) / 8192 );
  }
  if ( $size < 0 ) { message("Error estimating filesize") }
  set_setting( 'filesize', $size );

  #set_bpp();
}

sub set_bpp {
  return -1 if ! defined $::dvd->{'track'};
  return -1 if ! scalar @{$::dvd->{'track'}};

  my $bpp = 0;
  my $fps = get_track()->{'fps'} || -1;
  my $wo  = get_track()->{'width'} || -1;
  my $ho  = get_track()->{'height'} || -1;
  my $ws  = $::settings->{'scale_width'} || $wo;
  my $hs  = $::settings->{'scale_height'} || $ho;
  my $br  = $::settings->{'video_bitrate'};
  my $wc  = $::settings->{'crop_width'} || $wo;
  my $hc  = $::settings->{'crop_height'} || $ho;
  my $aa  = 0;
  if ( defined get_track()->{'aspect'} ) {
    my $aa = eval( get_track()->{'aspect'} );    #eval to allow fraction string to equate to a float
  }
  $aa = $wo / $ho if !$aa;

  if ( defined $aa && $br * $hc * $wc * $wo * $ho * $fps )    # moronic test for potential divide by zero!
  {
    $hs = $hs || $hc;
    $ws = $ws || $ho * $wc * $aa / $wo;
    $hs = $hc if $hs == -1;
    $ws = $wc if $ws == -1;
    $hs = ( $hc * $wo * $ws ) / ( $wc * $ho * $aa ) if $hs == -2;
    $ws = ( $wc * $ho * $hs * $aa ) / ( $hc * $wo ) if $ws == -2;

    $ws = sprintf( "%i", $ws );
    $hs = sprintf( "%i", $hs );
    $bpp = sprintf( "%.3f", ( $br * 1000 ) / ( $hs * $ws * $fps ) ) if $ws * $hs;

    if ( defined $::widgets && $ws > 0 && $hs > 0 ) {
      $::widgets->{'scale_height_estimate_entry'}->set_text($hs);
      $::widgets->{'video_bpp_entry'}->set_text($bpp);
    }
  }
  return $ws, $hs, $wc, $hc, $wo, $ho;
}

sub get_available_codecs {
  my $count = 0;

  #my $item;
  my $menc = $::settings->{'mencoder'};
  system "$menc >/dev/null 2>&1";
  print "MEncoder was not found! Acidrip is utterly useless without it! go install!\n" if $? >> 8 != 1;
  if ( open( MENC_VIDEO, "$menc -ovc help 2>&1 |" ) ) {
    while (<MENC_VIDEO>) {
      $::settings->{'mplayer_version'} = $1 if $_ =~ /MEncoder\s(\d\.\d)/;
      if ( $_ =~ /\s+(\w+)\s+-\s+(.+)/ ) {
        $::settings->{'available_video'}{$1} = "$1 - $2";
        if ( defined $::widgets and $1 ne "frameno" ) {
          my $item = new Gtk2::MenuItem("$1");
          $::widgets->{'video_codec_option'}->get_menu->append($item);
          $item->signal_connect( 'activate', \&on_option_changed, $1 );

          $::widgets->{'video_options_entry'}->set_text( $::settings->{ $::settings->{'video_codec'} . '_options' } or "" );
          $::widgets->{'video_codec_option'}->set_history($count) if $1 eq $::settings->{'video_codec'};
          $count++;
        }
      }
    }
    $::widgets->{'video_codec_option'}->show_all if defined $::widgets;
    close MENC_VIDEO;
  }
  else { message("Mencoder codec test failed. Is MPlayer installed properly?") }

  if ( open( MENC_AUDIO, "$menc -oac help 2>&1 |" ) ) {
    my $got_mp3 = 0;
    $count = 0;
    while (<MENC_AUDIO>) {
      if ( $_ =~ /\s+(\w+)\s+-(.*)/ ) {
        $::settings->{'available_audio'}{$1} = "$1 - $2";
        $got_mp3 = 1 if $1 eq "mp3lame" or $1 eq "lavc";
        if ( defined $::widgets ) {
          my $item = new Gtk2::MenuItem("$1");
          ( $::widgets->{'audio_codec_option'}->get_menu )->append($item);
          $item->signal_connect( 'activate', \&on_option_changed, $1 );
        }

        $::widgets->{'audio_options_entry'}->set_text( $::settings->{ "audio_" . $::settings->{'audio_codec'} . '_options' } or '' );
        $::widgets->{'audio_codec_option'}->set_history($count) if $1 eq $::settings->{'audio_codec'};
        $count++;
      }
    }
    $::widgets->{'audio_codec_option'}->show_all if defined $::widgets;
    print "AcidRip could NOT find MP3 support in MPlayer! if you do want MP3 sound in your films,"
      . "you will need to recompile MPlayer accordingly. See the docs on the MPlayer site.\n\n"
      if !$got_mp3;
    close MENC_AUDIO;
  }
  else { message("Mencoder codec test failed. Is MPlayer installed properly?") }
}

sub kill_mplayer {
  if ( $::settings->{'mencoder_pid'} > 0 ) {
    my $m = $::settings->{'mencoder_pid'} + 1;
    kill 'INT', $::settings->{'mencoder_pid'};
    kill 'INT', $m if `ps $m | grep mencoder` || `ps $m | grep mplayer`;
    message("Encoding stopped.");
    $::settings->{'mencoder_pid'} = -1;
  }
  else {
    message("Nothing to stop!");
  }
}

sub get_selection_length {
  my ( $start, $end ) = @_;
  my $length = 0;
  if ( defined get_track()->{'chapter'} ) {
    $start = ( $::settings->{'selected_chapters_start'} || 1 ) if !$start;
    $end = ( $::settings->{'selected_chapters_end'} || get_track->{'chapter'}[-1]->{'ix'} ) if !$end;
    for my $chapter ( $start .. $end ) {
      $length += get_chapter($chapter)->{'length'};
    }
  }
  else {
    $length = get_track_param('length');
  }
  return $length;
}

sub read_source ($) {
  my $path = shift;
  if ( -b $path || -c $path ) {
    return read_disc($path);
  }
  elsif ( -d $path ) {
    my $return = read_disc($path);
    if ($return) {
      return read_src_file($path);
    }
    else {
      return $return;
    }
  }
  else {
    return read_src_file($path);
  }
}

sub read_disc ($) {
  use vars qw(%lsdvd);
  my $dvd_device = shift;
  system("$::settings->{'lsdvd'} -h > /dev/null 2> /dev/null");
  if ( !$? ) {
    eval(`$::settings->{'lsdvd'} -xp $dvd_device 2>/dev/null`);
    if ( !$? ) {
      $::dvd                = {%lsdvd};
      $Data::Dumper::Indent = 0;
      my $lsout = Dumper { %lsdvd };
      $::widgets->{'mencoder_output_text'}->get_buffer->insert_with_tags_by_name( $::widgets->{'mencoder_output_text'}->get_buffer->get_end_iter, $lsout . "\n", 'lsdvd' );
      $::dvd->{'status'}    = "DVD read ok";
      $::dvd->{'source'}    = "dvd";
      $Data::Dumper::Indent = 2;
    }
    else {
      $::dvd = undef;
    }
  }
  else {
    $::dvd = undef;
  }
  $::dvd->{'status'} = "lsdvd not found"             if $? >> 8 == 127;
  $::dvd->{'status'} = "DVD device not found"        if $? >> 8 == 1;
  $::dvd->{'status'} = "DVD not found. Drive empty?" if $? >> 8 == 2;
  system( "eject " . $dvd_device ) if $? >> 8 == 2 && $::settings->{'eject'};
  $::dvd->{'status'} = "Can't read DVD. Not a valid DVD drive!" if $? >> 8 == 3;
  $::dvd->{'status'} = "Can't read DVD track. Faulty Disc?"     if $? >> 8 == 4;

  return $?;
}

sub read_src_file ($) {
  my %files;
  my $path = shift;
  $files{'device'} = $path;
  $files{'source'} = "file";

  open IDENTIFY, "$::settings->{'mplayer'} -identify -ao null -vo null -frames 0 $path" . ( -d $path ? '/*' : '' ) . " 2>&1 |";

  while (<IDENTIFY>) {
    $files{'track'}[ scalar @{ $files{'track'} } ]{'filename'} = $1 if /ID_FILENAME=(.+)/;
    $files{'track'}[ scalar @{ $files{'track'} } - 1 ]{'ix'} = scalar @{ $files{'track'} } if /ID_FILENAME=(.+)/;
   	$files{'track'}[ scalar @{ $files{'track'} } - 1 ]{'fps'}    = $1 if /ID_VIDEO_FPS=(.+)/;
    $files{'track'}[ scalar @{ $files{'track'} } - 1 ]{'width'}  = $1 if /ID_VIDEO_WIDTH=(.+)/;
    $files{'track'}[ scalar @{ $files{'track'} } - 1 ]{'height'} = $1 if /ID_VIDEO_HEIGHT=(.+)/;
    $files{'track'}[ scalar @{ $files{'track'} } - 1 ]{'aspect'} = $1 if /ID_VIDEO_ASPECT=(.+)/ && $1;
    $files{'track'}[ scalar @{ $files{'track'} } - 1 ]{'format'} = ( $1 eq '0x10000001' ? "MPEG1" : ( $1 eq '0x10000002' ? "MPEG2" : $1 ) ) if /ID_VIDEO_FORMAT=(.+)/;
    $files{'track'}[ scalar @{ $files{'track'} } - 1 ]{'bitrate'} = $1 if /ID_VIDEO_BITRATE=(.+)/ && $1;
    $files{'track'}[ scalar @{ $files{'track'} } - 1 ]{'audio'}[0]{'format'}    = $1 if /ID_AUDIO_CODEC=(.+)/;
    $files{'track'}[ scalar @{ $files{'track'} } - 1 ]{'audio'}[0]{'ix'}        = 1  if /ID_AUDIO_CODEC=(.+)/;
    $files{'track'}[ scalar @{ $files{'track'} } - 1 ]{'audio'}[0]{'aformat'}   = $1 if /ID_AUDIO_FORMAT=(.+)/;
    $files{'track'}[ scalar @{ $files{'track'} } - 1 ]{'audio'}[0]{'bitrate'}   = $1 if /ID_AUDIO_BITRATE=(.+)/;
    $files{'track'}[ scalar @{ $files{'track'} } - 1 ]{'audio'}[0]{'frequency'} = $1 if /ID_AUDIO_RATE=(.+)/;
    $files{'track'}[ scalar @{ $files{'track'} } - 1 ]{'audio'}[0]{'channels'}  = $1 if /ID_AUDIO_NCH=(.+)/;
    if (/ID_LENGTH=(.+)/) { # this is the final line in the output, so might as well demlimit the files
      $files{'track'}[ scalar @{ $files{'track'} } - 1 ]{'length'} = $1;
      if ( defined $files{'track'}[ scalar @{ $files{'track'} } - 1 ]{'format'} && 
						defined $files{'track'}[ scalar @{ $files{'track'} } - 1 ]{'fps'} &&
						defined $files{'track'}[ scalar @{ $files{'track'} } - 1 ]{'bitrate'} &&
						$files{'track'}[ scalar @{ $files{'track'} } - 1 ]{'format'} ne 'DVSD') {
        message("Scanning file \'$files{'track'}[scalar @{$files{'track'}} -1]{'filename'}\'");
      }
      else {
        pop @{ $files{'track'} };
      }
    }
    while ( Gtk2->events_pending() ) { Gtk2->main_iteration() }
	}
	
  close IDENTIFY;
  $::dvd = {%files};
  if ( defined $files{'track'} ) {
    $::dvd->{'status'} = scalar @{ $files{'track'} } . " file" . ( scalar @{ $files{'track'} } != 1 ? 's' : '' ) . " read OK";
  }
  else {
    $::dvd->{'status'} = "No valid files found";
    $::dvd->{'status'} = "No read access to $path" if !-r $path;
    $::dvd->{'status'} = "$path does not exist!" if !-e $path;
  }

  return 0;
}

sub find_crop ($) {
  open STDIN, '/dev/null' or message("Can't read /dev/null: $!. May fail if in background");

  my $crop_output;
  if ( defined $::dvd->{'track'} ) {
    my %crop;
    message( "Running " . get_command("cropdetect") );
    open( CROP, get_command("cropdetect") . " 2>&1 |" );
    while (<CROP>) {
      if ( $_ =~ /Crop area.*\s(crop=\d*:\d*:\d*:\d*)/ ) { $crop{$1}++ }
      $crop_output .= $_;
      gui_check($_);
    }
    my @order = sort { $crop{$b} <=> $crop{$a} } keys %crop;
    close CROP;
    return ( $order[0], $crop_output );
  }
  else { return ( -1, "crop detect failed" ) }
}

sub rebuild_queue_text {
  my $buffer = $::widgets->{'queue_text'}->get_buffer;
  $buffer->delete( $buffer->get_bounds );

  for ( 1 .. @{$::playlist} ) {
    my %item = %{ @{$::playlist}[ $_ - 1 ] };
    $buffer->insert( $buffer->get_end_iter, $item{'command'} . "\n" );
  }
}

sub queued_encode_events {	
	my $events = 0;
	foreach my $event (@{$::playlist}) {
		my %e= %{$event};
		if ( $e{'command'} =~ /mencoder/ || $e{'command'} =~ /mplayer/ ) {
			$events++;
		}
	}
	return $events;
}

sub push_playlist_queue {
  message("Pushed events onto queue");

  if ( !defined $::dvd->{'track'} ) {
    message("Hey, you gotta load DVD or file(s) first!");
    return -1;
  }

  my %menc = get_parameters();

  if ( -e $menc{'output'} && !$::settings->{'overwrite'} && $menc{'output'} ne "/dev/null" ) {
    message("File already exists, refusing to overwrite");
    return -1;
  }
  my $directory = dirname( substitute_filename( $::settings->{'filename'} ) );
  if ( !-d $directory ) {
    message("Output directory does not exist!");
    return -1;
  }
  if ( !-w $directory ) {
    message("Can't write to output directory!");
    return -1;
  }
  if ( ( !$::settings->{'enough_space'} ) && $::settings->{'enforce_space'} ) {
    message("Not enough space in output directory!");
    return -1;
  }

  # Encode file
  for ( 1 .. $::settings->{'total_blocks'} ) {
    $::settings->{'this_block'} = $_ if $::settings->{'total_blocks'} > 1;

    if ( $::settings->{'cache'} && $::dvd->{'source'} eq "dvd" ) {
			$::settings->{'total_events'}++;
      $::playlist->prepend( get_command('cache'), 'cache', "Caching title..." ) if $::settings->{'precache'};
      $::playlist->append( get_command('cache'), 'cache', "Caching title..." ) if !$::settings->{'precache'};
      $::playlist->append( "eject $::settings->{'dvd_device'}", 'system', 'Ejecting DVD' )
        if $::settings->{'eject'} && $::dvd->{'source'} eq "dvd" && (
        ( $::settings->{'this_block'} == $::settings->{'total_blocks'} && !$::settings->{'precache'} ) ||    # last block on precache
        ( $::settings->{'this_block'} == 1                             && $::settings->{'precache'} )  ||    # first block of normal cache
        $::settings->{'total_blocks'} == 1                                                                   # single block
        );
    }

    my $message = "Encoding film";
    $message .= ", Block " . $::settings->{'this_block'} . " of " . $::settings->{'total_blocks'} if $::settings->{'this_block'} > 0;

    my $twopassable = ( $::settings->{'video_codec'} eq "lavc" || $::settings->{'video_codec'} eq "divx4" || $::settings->{'video_codec'} eq "xvid" );

    $::playlist->append( "unlink frameno.avi 2> /dev/null", 'system', "Removing frameno.avi if it exists" )
        if $::settings->{'this_block'} == 1 || $::settings->{'total_blocks'} == 1;
    
		if ( $::settings->{'video_passes'} > 1 && $twopassable ) {
      
      $::playlist->append( get_command("mencoder_frameno"), 'encode', $message . ", frameno pass..." ) if $::settings->{'video_passes'} == 3;

      $::settings->{'video_pass'} = 1;
      $::playlist->append( get_command( "mencoder" . ( $::settings->{'video_passes'} == 3 ? "_3pass" : "" ) ), 'encode', $message . ", 1st pass..." );
			
      $::settings->{'video_pass'} = 2;
      $::playlist->append( get_command( "mencoder" . ( $::settings->{'video_passes'} == 3 ? "_3pass" : "" ) ), 'encode', $message . ", 2nd pass..." );
			
      $::playlist->append( "unlink frameno.avi 2> /dev/null", 'system', "Removing frameno.avi" ) if $::settings->{'video_passes'} == 3;

      $::playlist->append( "unlink divx2pass.log  2> /dev/null", 'system', "Removing divx2pass.log" );
    }
    else {
      $::playlist->append( get_command("mencoder"), 'encode', $message );
    }
    $::playlist->append( get_command("del_cache"), 'system', "Deleting cache file" ) if $::settings->{'cache'} && $::settings->{'del_cache'} && $::dvd->{'source'} eq "dvd";
  }
  $::playlist->append( "eject $::settings->{'dvd_device'} 2> /dev/null", 'system', 'Ejecting DVD' ) if $::settings->{'eject'} && !$::settings->{'cache'};
  $::playlist->append( "shutdown -h now", 'system', 'Shutting down... bye!' ) if $::settings->{'shutdown'};
}

sub pop_playlist_queue {
  my %item = $::playlist->get();
  message( "Running " . $item{'command'} );
  message( $item{'message'} );
  encode( $item{'command'} ) if $item{'type'} eq 'encode';
  cache( $item{'command'} )  if $item{'type'} eq 'cache';
  system( $item{'command'} ) if $item{'type'} eq 'system';
  $item{'type'} ne 'system' ? return $? : return 0;
}

sub cache {

  #fork proofing
  open STDIN, '/dev/null' or message("Can't read /dev/null: $!. May fail if in background");

  my $cache = shift;
  $cache =~ /"(.+)"/;
  my $file      = $1;
  my $this_cell = -1;
  my $size      = 0;
  my $start_chapter;
  my $stop_chapter;
  my $this_track = get_track();

  if ( $::settings->{'total_blocks'} > 1 ) {		
		$cache =~/-(\d+)-cache/;
	  $start_chapter = $::settings->{'blocks'}[ $1 - 1 ] + 1;
    $stop_chapter  = $::settings->{'blocks'}[ $1 ];
  }
  else {
    $start_chapter = $::settings->{'selected_chapters_start'};
    $stop_chapter  = $::settings->{'selected_chapters_end'};
    $start_chapter = 1 if $start_chapter == 0;
    $stop_chapter  = $this_track->{'chapter'}[-1]->{'ix'} if $stop_chapter == 0;
  }
  my $total_chapters = $stop_chapter - $start_chapter + 1;
	my $this_event = $::settings->{'total_events'} - queued_encode_events();
  $::settings->{'mencoder_pid'} = open( CACHE, "nice $cache 2>&1 |" );
  while (<CACHE>) {
    if (/### CELL (\d+)/) {
      if ( $this_cell != $1 + 1 ) {
        $this_cell = $1 + 1;
        my $this_chapter = 0;
      LOOP: foreach ( reverse( @{ $this_track->{'chapter'} } ) ) {
          $this_chapter = $_->{'ix'};
          last LOOP if $_->{'startcell'} <= $this_cell;
        }
				$::widgets->{'cache_chapter'}->set_text( sprintf( "%d (%d/%d)", $this_chapter, $this_chapter + 1 - $start_chapter, $total_chapters ) );
				my $progress = sprintf("%d", ($this_event - 1 + ($this_chapter - $start_chapter) / $total_chapters)*100/$::settings->{'total_events'});
				$::widgets->{'acidrip'}->set_title(msg("acidrip") . ' - ' . $progress . '%');
				$::widgets->{'progress_dialog'}->set_title(msg("acidrip") . ' - ' . $progress . '%');
      }
      $::widgets->{'cache_size'}->set_text( sprintf( "%d", ( -s $file ) / 1048576 ) . "Mb" ) if -e $file;
    }
    while ( Gtk2->events_pending() ) { Gtk2->main_iteration() }
  }
  close CACHE;
	
  return $file;
}

sub encode {

  #fork proofing
  open STDIN, '/dev/null' or message("Can't read /dev/null: $!. May fail if in background");

  my $menc = shift;

  if ( defined $::widgets ) {
    my $buffer = $::widgets->{'mencoder_output_text'}->get_buffer;
    my ( $sec, $fps, $size, $time, $rate, $prog ) = ( 0, 0, 0, 0, 0, -1 );
		my $this_event = $::settings->{'total_events'} - queued_encode_events();
  
    if ( $::settings->{'mencoder_pid'} = open( MENCODER, "$menc 2>&1 |" ) ) {
      $/ = "\r";
			while (<MENCODER>) {
        if (/^Pos:\s*(\d+)(?:.\d)?s\s+(\d+)f\s+\(\s*(\d+)%\)\s+(\d+(?:\.\d+)fps)\sTrem:\s+(\d+min)\s+(\d+mb).+\[([\d:]+)\]/) {
          if ( $1 ne $sec )  { $sec  = $1; $::widgets->{'menc_seconds'}->set_text( hhmmss($1) ) }
          if ( $4 ne $fps )  { $fps  = $4; $::widgets->{'menc_fps'}->set_text($4) }
          if ( $6 ne $size ) { $size = $6; $::widgets->{'menc_filesize'}->set_text($6) }
          if ( $5 ne $time ) { $time = $5; $::widgets->{'menc_time'}->set_text($5) }
          if ( $7 ne $rate ) { $rate = $7; $::widgets->{'menc_bitrate'}->set_text($7) }
          if ( $3 ne $prog ) {
						$prog = $3; 
						$::widgets->{'menc_progress'}->set_fraction( $3 / 100 ); 
				    my $progress = sprintf("%d", ($this_event - 1 + ($3/100))*100/$::settings->{'total_events'});
				    $::widgets->{'acidrip'}->set_title(msg("acidrip") . ' - ' . $progress . '%');
						$::widgets->{'progress_dialog'}->set_title(msg("acidrip") . ' - ' . $progress . '%');
					}
        }
        else { s/\r/\n/g; $buffer->insert_with_tags_by_name( $buffer->get_end_iter, $_, 'mplayer' ) }
        while ( Gtk2->events_pending() ) { Gtk2->main_iteration() }
      }
      $/ = "\n";
    }
    else { message( "Mencoder failed, is it properly installed?", 'error' ) }
  }
  else {
    message( "Mencoder failed, is it properly installed?", 'error' ) if !( $::settings->{'mencoder_pid'} = open( MENCODER, "$menc" ) );
  }
  $::widgets->{'view_button'}->set_sensitive( -r ( substitute_filename( $::settings->{'filename'} . ( $::settings->{'mpegfile'} ? ".mpg" : ".avi" ) ) ) ? 1 : 0 );
  close MENCODER;
}

package acidrip_settings;

use vars qw($defaults);

$defaults = {
  'dvd_device'              => '/dev/dvd',
  'selected_track'          => 0,
  'selected_chapters_start' => 0,
  'selected_chapters_end'   => 0,
  'filesize'                => 700,
  'total_blocks'            => 1,
  'this_block'              => 0,
  'blocks'                  => [],
  'selected_audio'          => -1,
  'selected_subp'           => -1,                                # Remember, the GUI is 1 based, mplayer is 0 based.
  'audio_codec'             => 'mp3lame',
  'audio_gain'              => 0,
  'audio_options'           => '',
  'audio_mp3lame_options'   => 'abr:br=128',
  'audio_lavc_options'      => 'acodec=mp3:abitrate=128',
  'video_codec'             => 'lavc',
  'lavc_options'            => 'vcodec=mpeg4:vhq:v4mv:vqmin=2',
  'divx4_options'           => '',
  'xvid_options'            => 'chroma_opt:vhq=4:bvhq=1:quant_type=mpeg',
  'vuv_options'             => '',
  'video_options'           => '',
  'video_bitrate'           => 0,
  'video_bitrate_lock'      => 0,
  'filename'                => $ENV{HOME} . '/%T',
  'title'                   => 'unknown',
  'mpegfile'                => 0,
  'length'                  => 0,
  'scale_enable'            => 1,
  'scale_auto'              => 1,
  'scale_height'            => -2,
  'scale_width'             => 480,
  'crop_enable'             => 1,
  'crop_height'             => 0,
  'crop_width'              => 0,
  'crop_vertical'           => 0,
  'crop_horizontal'         => 0,
  'vf_pre'                  => 'pp=de',
  'vf_pre_enable'           => 1,
  'vf_post'                 => '',
  'vf_post_enable'          => 0,
  'video_pass'              => 0,
  'video_passes'            => 1,
  'more_options'            => '',
  'language'                => 'English',
  'mencoder'                => 'mencoder',
  'mplayer'                 => 'mplayer',
  'lsdvd'                   => 'lsdvd',
  'available_audio'         => {},
  'available_video'         => {},
  'mencoder_pid'            => 0,
  'autoload'                => 0,
  'overwrite'               => 0,
  'enforce_space'           => 1,
  'cache'                   => 0,
  'precache'                => 1,
  'cache_directory'         => '/tmp/',
  'del_cache'               => 0,
  'tooltips'                => 1,
  'busy'                    => 0,
  'UI'                      => 1,
  'compact'                 => 1,
  'enough_space'            => 1,
  'ppc_bug'                 => 0,
  'embed_preview'           => 1,
  'eject'                   => 0,
  'vobsubout'               => 0,
  'mplayer_version'         => 1,
  'flickbook_preview'       => 0,
  'export_script'           => 0,
  'info_artist'             => '',
  'info_genre'              => '',
  'info_name'               => '',
  'info_copyright'          => '',
  'info_subject'            => '',
  'shutdown'                => 0,
	'ui_language'             => 'English',
	'total_events'            => 0
};

sub new {
  my $class    = shift;
  my $settings = {};
  foreach my $key ( keys %{$defaults} ) { $settings->{$key} = $defaults->{$key} }
  bless( $settings, $class );
  return $settings;
}

sub get_default ($$) {
  my ( $settings, $value ) = @_;
  return $defaults->{$value} if ( defined $settings->{$value} );
  return "unknown setting! - $value";
}

sub restore_settings {
  my $settings = shift;
  foreach my $key ( keys %{$defaults} ) { $settings->{$key} = $defaults->{$key} unless $key eq "selected_track" }
  return $settings;
}

sub save_settings {
  my $settings = shift;
  my @save     = (
    'dvd_device',    'filesize',     'filename',          'audio_codec',        'audio_mp3lame_options', 'audio_lavc_options',
    'video_codec',   'scale_enable', 'autoload',          'mpegfile',           'eject',                 'scale_auto',
    'scale_height',  'scale_width',  'crop_enable',       'language',           'mencoder',              'mplayer',
    'lsdvd',         'tooltips',     'video_passes',      'video_bitrate_lock', 'lavc_options',          'xvid_options',
    'divx4_options', 'more_options', 'total_blocks',      'overwrite',          'cache',                 'cache_directory',
    'vf_pre_enable', 'audio_gain',   'vf_post_enable',    'vf_pre',             'vf_post',               'del_cache',
    'ppc_bug',       'compact',      'flickbook_preview', 'enforce_space',      'vobsubout',             'video_bitrate',
	  'ui_language'
  );
  if ( open( CONFIGFILE, '>', "$ENV{HOME}/.acidriprc" ) ) {
    foreach my $key (@save) {
      print CONFIGFILE "$key = $settings->{$key}\n" if $settings->{$key} ne '';
    }
    close CONFIGFILE;
  }
  else {
    acidrip::message("Can't open config file for writing!\n");
  }
}

sub load_settings {
  my $settings = shift;
  if ( open( CONFIGFILE, "$ENV{HOME}/.acidriprc" ) ) {
    while (<CONFIGFILE>) {
      if ( $_ =~ /(\w+)\s=\s(.+)/ ) { $settings->{$1} = $2 }
    }
    close CONFIGFILE;
  }
  else {
    acidrip::message("No configuration file found, nevermind.");
  }
  return $settings;
}

package acidrip_playlist;

use Data::Dumper;

sub new {
  bless( [], shift );
}

sub append {
  my $playlist = shift;
  my %item;
  $item{'command'} = shift;
  $item{'type'}    = shift;    # system, encode, cache, eval
  $item{'message'} = shift;
  push( @{$playlist}, \%item );
}

sub prepend {
  my $playlist = shift;
  my %item;
  $item{'command'} = shift;
  $item{'type'}    = shift;    # system, encode, cache, eval
  $item{'message'} = shift;
  unshift( @{$playlist}, \%item );
}

sub clear {
  my $playlist = shift;
  while ( @{$::playlist} ) {
    shift @{$::playlist};
  }
}

sub get {
  my $playlist = shift;
  return %{ shift @{$playlist} };
}

1;
