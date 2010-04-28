use Gtk2;
use Glib;
init Gtk2;
use File::Basename;

sub get_widget_name ($) {
  my $widgets     = shift;
  my $this_widget = shift;
  foreach ( keys %{$widgets} ) {
    return $_ if $widgets->{$_} == $this_widget;
  }
  return undef;
}

sub connect_signals ($$@) {
  my ( $widgets, $signal, $function, @data ) = @_;
  foreach (@data) {
    $widgets->{$_}->signal_connect( $signal, $function );
  }
}

sub create_stock_buttons {
  my $factory = Gtk2::IconFactory->new;
  $factory->add_default;
  my $style = new Gtk2::Style;
  my @items = (
    { stock_id => "ar_quit",     label => msg("Quit"),    icon => 'gtk-quit' },
    { stock_id => "ar_start",    label => msg("_Start"),  icon => 'gtk-convert' },
    { stock_id => "ar_load",     label => msg("Load"),    icon => 'gtk-refresh' },
    { stock_id => "ar_compact",  label => msg("Compact"), icon => 'gtk-goto-bottom' },
    { stock_id => "ar_view",     label => msg("View"),    icon => 'gtk-yes' },
    { stock_id => "ar_queue",    label => msg("_Queue"),  icon => 'gtk-add' },
    { stock_id => "ar_preview",  label => msg("Preview"), icon => 'gtk-zoom-in' },
    { stock_id => "ar_debug",    label => msg("Debug"),   icon => 'gtk-go-down' },
    { stock_id => "ar_clear",    label => msg("Clear"),   icon => 'gtk-clear' },
    { stock_id => "ar_log_save", label => msg("Save"),    icon => 'gtk-save' },
    { stock_id => "ar_export",   label => msg("Export"),  icon => 'gtk-save' },
    { stock_id => "ar_log_hide", label => msg("Hide"),    icon => 'gtk-go-up' },
    { stock_id => "ar_stop",     label => msg("Stop"),    icon => 'gtk-stop' }
  );
  Gtk2::Stock->add(@items);
  foreach (@items) {
    $factory->add( $_->{'stock_id'}, $style->lookup_icon_set( $_->{'icon'} ) );
  }
}

sub msg ($) {
	return $::messages->msg(shift);
}

sub new {
  my $class = shift;

  my $widgets;
  my $row_height = 4;

  create_stock_buttons();

  #
  # Construct a GtkWindow 'acidrip'
  $widgets->{'acidrip'} = new Gtk2::Window;
  $widgets->{'acidrip'}->set_title(msg("acidrip"));
  $widgets->{'acidrip'}->set_resizable(0);
  $widgets->{'acidrip'}->realize;

  #
  # Construct a GtkVBox 'status_vbox'
  $widgets->{'status_vbox'} = new Gtk2::VBox( 0, 0 );
  $widgets->{'acidrip'}->add( $widgets->{'status_vbox'} );
  $widgets->{'status_vbox'}->show;

  $widgets->{'main_table'} = new Gtk2::Table( 10, 2, 0 );
  $widgets->{'main_table'}->show;

  # Construct a GtkHBox 'main_hbox'
  $widgets->{'main_hbox'} = new Gtk2::HBox( 0, 0 );
  $widgets->{'status_vbox'}->add( $widgets->{'main_hbox'} );
  $widgets->{'main_hbox'}->show;

  #
  # Construct a GtkVBox 'left_vbox'
  $widgets->{'left_vbox'} = new Gtk2::VBox( 0, 0 );
  $widgets->{'main_hbox'}->add( $widgets->{'left_vbox'} );
  $widgets->{'left_vbox'}->show;

  #
  # Construct a GtkVBox 'notebook_vbox'
  $widgets->{'notebook_vbox'} = new Gtk2::VBox( 0, 0 );
  $widgets->{'notebook_vbox'}->show;

  #
  # notebook
  $widgets->{'notebook'} = new Gtk2::Notebook();
  $widgets->{'notebook'}->show;
  $widgets->{'notebook'}->set_border_width(2);
  $widgets->{'left_vbox'}->add( $widgets->{'notebook'} );
  $widgets->{'notebook'}->append_page( $widgets->{'notebook_vbox'}, new Gtk2::Label(msg("General")));

### GENERAL FRAME

  # Construct a GtkFrame 'general_frame'
  $widgets->{'general_frame'} = new Gtk2::Frame(msg('General'));
  $widgets->{'general_frame'}->set_shadow_type('etched_in');
  $widgets->{'notebook_vbox'}->add( $widgets->{'general_frame'} );
  $widgets->{'general_frame'}->show;
  $widgets->{'general_frame'}->set_border_width(2);

  #
  # Construct a GtkTable 'general_table'
  $widgets->{'general_table'} = new Gtk2::Table( 5, 4, 0 );
  $widgets->{'general_frame'}->add( $widgets->{'general_table'} );
  $widgets->{'general_table'}->set_row_spacings($row_height);
  $widgets->{'general_table'}->show;

  #
  # Construct a GtkLabel 'filename_label'
  $widgets->{'title_label'} = new Gtk2::Label(msg('Track title'));
  $widgets->{'general_table'}->attach( $widgets->{'title_label'}, 0, 1, 0, 1, ['fill'], [], 2, 2 );
  $widgets->{'title_label'}->show;
  $widgets->{'title_label'}->set_alignment( 0, 0 );

  #
  # Construct a GtkEntry 'filename'
  $widgets->{'title_entry'} = new Gtk2::Entry;
  $widgets->{'title_entry'}->show;
  $widgets->{'title_entry'}->set_size_request( 10, -1 );
  $widgets->{'general_table'}->attach( $widgets->{'title_entry'}, 1, 5, 0, 1, ['fill'], [], 2, 2 );

  #
  # Construct a GtkLabel 'filename_label'
  $widgets->{'filename_label'} = new Gtk2::Label(msg('Filename'));
  $widgets->{'general_table'}->attach( $widgets->{'filename_label'}, 0, 1, 1, 2, ['fill'], [], 2, 2 );
  $widgets->{'filename_label'}->show;

  #
  # Construct a GtkEntry 'filename'
  $widgets->{'filename_entry'} = new Gtk2::Entry;
  $widgets->{'filename_entry'}->show;
  $widgets->{'filename_entry'}->set_size_request( 10, -1 );
  $widgets->{'general_table'}->attach( $widgets->{'filename_entry'}, 1, 4, 1, 2, ['fill'], [], 2, 2 );

  $widgets->{'mpegfile_option'} = new Gtk2::OptionMenu;
  $widgets->{'mpegfile_menu'}   = new Gtk2::Menu;
  $widgets->{'mpegfile_option'}->set_menu( $widgets->{'mpegfile_menu'} );
  $widgets->{'mpegfile_menu'}->append( new Gtk2::MenuItem(".avi") );
  $widgets->{'mpegfile_menu'}->append( new Gtk2::MenuItem(".mpg") );
  $widgets->{'mpegfile_option'}->set_history( $::settings->{'mpegfile'} );
  $widgets->{'mpegfile_option'}->show_all;

  $widgets->{'general_table'}->attach( $widgets->{'mpegfile_option'}, 4, 5, 1, 2, ['fill'], [], 2, 2 );

  # Construct a GtkLabel 'filesize_label'
  $widgets->{'filesize_label'} = new Gtk2::Label(msg('File size'));
  $widgets->{'general_table'}->attach( $widgets->{'filesize_label'}, 0, 1, 2, 3, ['fill'], [], 2, 2 );
  $widgets->{'filesize_label'}->show;
  $widgets->{'filesize_label'}->set_alignment( 0, 0 );

  # Construct a GtkCombo 'filesize_spin'
  $widgets->{'filesize_adjust'} = new Gtk2::Adjustment( 700, 1, 9999, 1, 50, 1 );
  $widgets->{'filesize_spin'} = new Gtk2::SpinButton( $widgets->{'filesize_adjust'}, 1, 0 );
  $widgets->{'filesize_spin'}->set_size_request( 50, -1 );
  $widgets->{'general_table'}->attach( $widgets->{'filesize_spin'}, 1, 2, 2, 3, [ 'expand', 'fill' ], [], 2, 2 );
  $widgets->{'filesize_spin'}->show;

  $widgets->{'filesize_entry'} = new Gtk2::Entry;
  $widgets->{'general_table'}->attach( $widgets->{'filesize_entry'}, 1, 2, 2, 3, [ 'expand', 'fill' ], [], 2, 2 );
  $widgets->{'filesize_entry'}->set_size_request( 50, -1 );
  $widgets->{'filesize_entry'}->set_editable(0);

  $widgets->{'total_blocks_label'} = new Gtk2::Label(msg("# Files"));
  $widgets->{'general_table'}->attach( $widgets->{'total_blocks_label'}, 2, 4, 2, 3, ['fill'], [], 2, 2 );
  $widgets->{'total_blocks_label'}->show;

  $widgets->{'total_blocks_adjust'} = new Gtk2::Adjustment( 1, 1, 10, 1, 0, 1 );
  $widgets->{'total_blocks_spin'} = new Gtk2::SpinButton( $widgets->{'total_blocks_adjust'}, 1, 0 );
  $widgets->{'general_table'}->attach( $widgets->{'total_blocks_spin'}, 4, 5, 2, 3, ['fill'], [], 2, 2 );
  $widgets->{'total_blocks_spin'}->show;

  $widgets->{'info_label'} = new Gtk2::Label(msg('Info'));
  $widgets->{'general_table'}->attach( $widgets->{'info_label'}, 0, 1, 3, 4, ['fill'], [], 2, 2 );
  $widgets->{'info_label'}->set_alignment( 0, 0 );
  $widgets->{'info_label'}->show;

  $widgets->{'info_field_option'} = new Gtk2::OptionMenu;
  $widgets->{'info_field_menu'}   = new Gtk2::Menu;
  $widgets->{'info_field_option'}->set_menu( $widgets->{'info_field_menu'} );
  $widgets->{'info_field_option'}->set_size_request( 40, -1 );
  $widgets->{'general_table'}->attach( $widgets->{'info_field_option'}, 1, 2, 3, 4, ['fill'], [], 2, 2 );

  foreach ( msg("name"), msg("artist"), msg("subject"), msg("genre"), msg("copyright") ) {
    my $item = new Gtk2::MenuItem($_);
    $item->signal_connect( "activate", \&on_info_field_select, $_ );
    $widgets->{'info_field_menu'}->append($item);
  }
  $widgets->{'info_field_option'}->set_history(0);
  $widgets->{'info_field_option'}->show_all;

  $widgets->{'info_name_entry'} = new Gtk2::Entry;
  $widgets->{'general_table'}->attach( $widgets->{'info_name_entry'}, 2, 5, 3, 4, ['fill'], [], 2, 2 );
  $widgets->{'info_name_entry'}->set_size_request( 40, -1 );
  $widgets->{'info_name_entry'}->show;

  $widgets->{'info_artist_entry'} = new Gtk2::Entry;
  $widgets->{'general_table'}->attach( $widgets->{'info_artist_entry'}, 2, 5, 3, 4, ['fill'], [], 2, 2 );
  $widgets->{'info_artist_entry'}->set_size_request( 40, -1 );

  $widgets->{'info_subject_entry'} = new Gtk2::Entry;
  $widgets->{'general_table'}->attach( $widgets->{'info_subject_entry'}, 2, 5, 3, 4, ['fill'], [], 2, 2 );
  $widgets->{'info_subject_entry'}->set_size_request( 40, -1 );

  $widgets->{'info_genre_entry'} = new Gtk2::Entry;
  $widgets->{'general_table'}->attach( $widgets->{'info_genre_entry'}, 2, 5, 3, 4, ['fill'], [], 2, 2 );
  $widgets->{'info_genre_entry'}->set_size_request( 40, -1 );

  $widgets->{'info_copyright_entry'} = new Gtk2::Entry;
  $widgets->{'general_table'}->attach( $widgets->{'info_copyright_entry'}, 2, 5, 3, 4, ['fill'], [], 2, 2 );
  $widgets->{'info_copyright_entry'}->set_size_request( 40, -1 );

  $widgets->{'info_comment_entry'} = new Gtk2::Entry;
  $widgets->{'general_table'}->attach( $widgets->{'info_comment_entry'}, 2, 5, 3, 4, ['fill'], [], 2, 2 );
  $widgets->{'info_comment_entry'}->set_size_request( 40, -1 );

  $widgets->{'notebook_vbox'}->set_child_packing( $widgets->{'general_frame'}, 1, 1, 0, 'start' );

### AUDIO FRAME

  # Construct a GtkFrame 'audio_frame'
  $widgets->{'audio_frame'} = new Gtk2::Frame(msg('Audio'));
  $widgets->{'audio_frame'}->set_shadow_type('etched_in');
  $widgets->{'notebook_vbox'}->add( $widgets->{'audio_frame'} );
  $widgets->{'audio_frame'}->show;
  $widgets->{'audio_frame'}->set_border_width(2);

  #
  # Construct a GtkTable 'audio_table'
  $widgets->{'audio_table'} = new Gtk2::Table( 3, 5, 0 );
  $widgets->{'audio_frame'}->add( $widgets->{'audio_table'} );
  $widgets->{'audio_table'}->set_row_spacings($row_height);
  $widgets->{'audio_table'}->show;

  #
  # Construct a GtkLabel 'language_label'
  $widgets->{'audio_track_label'} = new Gtk2::Label(msg('Language'));
  $widgets->{'audio_table'}->attach( $widgets->{'audio_track_label'}, 0, 1, 0, 1, ['fill'], [], 2, 2 );
  $widgets->{'audio_track_label'}->show;
  $widgets->{'audio_track_label'}->set_alignment( 0, 0.5 );

  #
  # Construct a GtkCombo 'language_combo'
  $widgets->{'audio_track_option'} = new Gtk2::OptionMenu;
  $widgets->{'audio_track_menu'}   = new Gtk2::Menu;
  $widgets->{'audio_track_option'}->set_menu( $widgets->{'audio_track_menu'} );
  $widgets->{'audio_track_menu'}->append( Gtk2::MenuItem->new("<Default> $::settings->{'language'}") );
  $widgets->{'audio_table'}->attach( $widgets->{'audio_track_option'}, 1, 5, 0, 1, [ 'expand', 'fill' ], [], 2, 2 );
  $widgets->{'audio_track_option'}->show_all;
  $widgets->{'audio_track_option'}->set_history(0);

  #
  # Construct a GtkLabel 'audio_options_label'
  $widgets->{'audio_options_label'} = new Gtk2::Label(msg('Options'));
  $widgets->{'audio_table'}->attach( $widgets->{'audio_options_label'}, 0, 1, 2, 3, ['fill'], [], 2, 2 );
  $widgets->{'audio_options_label'}->show;
  $widgets->{'audio_options_label'}->set_alignment( 0, 0.5 );

  $widgets->{'audio_options_entry'} = new Gtk2::Entry;
  $widgets->{'audio_table'}->attach( $widgets->{'audio_options_entry'}, 1, 5, 2, 3, ['fill'], [], 2, 2 );
  $widgets->{'audio_options_entry'}->show;
  $widgets->{'audio_options_entry'}->set_size_request( 50, -1 );

  # Construct a GtkLabel 'audio_codec_label'
  $widgets->{'audio_codec_label'} = new Gtk2::Label(msg('Codec'));
  $widgets->{'audio_table'}->attach( $widgets->{'audio_codec_label'}, 0, 1, 1, 2, ['fill'], [], 2, 2 );
  $widgets->{'audio_codec_label'}->show;
  $widgets->{'audio_codec_label'}->set_alignment( 0, 0.5 );

  #
  # Construct a GtkCombo 'audio_codec_option'
  $widgets->{'audio_codec_option'} = new Gtk2::OptionMenu;
  $widgets->{'audio_codec_menu'}   = new Gtk2::Menu;
  $widgets->{'audio_codec_option'}->set_menu( $widgets->{'audio_codec_menu'} );
  $widgets->{'audio_table'}->attach( $widgets->{'audio_codec_option'}, 1, 3, 1, 2, [ 'expand', 'fill' ], [], 2, 2 );
  $widgets->{'audio_codec_option'}->show_all;
  $widgets->{'left_vbox'}->set_child_packing( $widgets->{'audio_frame'}, 1, 1, 0, 'start' );

  # Construct a GtkCombo 'audio_codec_option'
  $widgets->{'audio_gain_label'} = new Gtk2::Label(msg("Gain"));
  $widgets->{'audio_table'}->attach( $widgets->{'audio_gain_label'}, 3, 4, 1, 2, [ 'expand', 'fill' ], [], 2, 2 );
  $widgets->{'audio_gain_label'}->show;

  $widgets->{'audio_gain_adjust'} = new Gtk2::Adjustment( 0, -200, 40, 1, 5, 1 );
  $widgets->{'audio_gain_spin'} = new Gtk2::SpinButton( $widgets->{'audio_gain_adjust'}, 1, 0 );

  #$widgets->{'audio_gain_spin'}->set_size_request(40, -1);
  $widgets->{'audio_table'}->attach( $widgets->{'audio_gain_spin'}, 4, 5, 1, 2, [ 'expand', 'fill' ], [], 2, 2 );
  $widgets->{'audio_gain_spin'}->show;

  $widgets->{'mp3_type_label'} = new Gtk2::Label(msg("Type"));

  #$widgets->{'mp3_type_label'}->show;
  $widgets->{'audio_table'}->attach( $widgets->{'mp3_type_label'}, 3, 4, 1, 2, ['fill'], [], 2, 2 );
  $widgets->{'mp3_type_label'}->set_alignment( 0, 0.5 );

  $widgets->{'mp3_type_combo'} = new Gtk2::Combo;
  $widgets->{'audio_table'}->attach( $widgets->{'mp3_type_combo'}, 4, 5, 1, 2, ['fill'], [], 2, 2 );
  $widgets->{'mp3_type_combo'}->set_popdown_strings( 'abr', 'cbr', 'vbr' );

  #$widgets->{'mp3_type_combo'}->show;
  $widgets->{'mp3_type_combo'}->set_size_request( 50, -1 );

  $widgets->{'mp3_bitrate_label'} = new Gtk2::Label(msg("Bitrate"));

  #$widgets->{'mp3_bitrate_label'}->show;
  $widgets->{'audio_table'}->attach( $widgets->{'mp3_bitrate_label'}, 3, 4, 2, 3, ['fill'], [], 2, 2 );
  $widgets->{'mp3_bitrate_label'}->set_alignment( 0, 0.5 );

  $widgets->{'mp3_bitrate_entry'} = new Gtk2::Entry;

  #$widgets->{'mp3_bitrate_entry'}->show;
  $widgets->{'audio_table'}->attach( $widgets->{'mp3_bitrate_entry'}, 4, 5, 2, 3, ['fill'], [], 2, 2 );
  $widgets->{'mp3_bitrate_entry'}->set_size_request( 50, -1 );

  $widgets->{'mp3_quality_label'} = new Gtk2::Label(msg("Quality"));

  #$widgets->{'mp3_quality_label'}->show;
  $widgets->{'audio_table'}->attach( $widgets->{'mp3_quality_label'}, 3, 4, 2, 3, ['fill'], [], 2, 2 );
  $widgets->{'mp3_quality_label'}->set_alignment( 0, 0.5 );

  $widgets->{'mp3_quality_entry'} = new Gtk2::Entry;

  #$widgets->{'mp3_quality_entry'}->show;
  $widgets->{'audio_table'}->attach( $widgets->{'mp3_quality_entry'}, 4, 5, 2, 3, ['fill'], [], 2, 2 );
  $widgets->{'mp3_quality_entry'}->set_size_request( 50, -1 );

### SUBTITLES

  $widgets->{'misc_table'} = new Gtk2::Table( 4, 2, 0 );
  $widgets->{'misc_table'}->show;
  $widgets->{'misc_table'}->set_row_spacings($row_height);

  $widgets->{'misc_frame'} = new Gtk2::Frame(msg("Other stuff"));
  $widgets->{'misc_frame'}->add( $widgets->{'misc_table'} );
  $widgets->{'notebook_vbox'}->add( $widgets->{'misc_frame'} );
  $widgets->{'misc_frame'}->show;
  $widgets->{'misc_frame'}->set_border_width(2);

  $widgets->{'subp_label'} = new Gtk2::Label(msg('Subtitle'));
  $widgets->{'subp_label'}->show;
  $widgets->{'misc_table'}->attach( $widgets->{'subp_label'}, 0, 1, 0, 1, ['fill'], [], 4, 2 );

  $widgets->{'subp_option'} = new Gtk2::OptionMenu;
  $widgets->{'subp_menu'}   = new Gtk2::Menu;
  $widgets->{'subp_option'}->set_menu( $widgets->{'subp_menu'} );
  $widgets->{'subp_menu'}->append( Gtk2::MenuItem->new(msg("<None>")));
  $widgets->{'subp_option'}->show;
  $widgets->{'subp_option'}->set_history(0);
  $widgets->{'misc_table'}->attach( $widgets->{'subp_option'}, 1, 2, 0, 1, [ 'fill', 'expand' ], [], 2, 2 );

  $widgets->{'vobsubout_check'} = new Gtk2::CheckButton(msg('Sub File'));
  $widgets->{'vobsubout_check'}->show;
  $widgets->{'misc_table'}->attach( $widgets->{'vobsubout_check'}, 2, 3, 0, 1, ['fill'], [], 2, 2 );

  $widgets->{'more_options_entry'} = new Gtk2::Entry;
  $widgets->{'more_options_entry'}->show;
  $widgets->{'more_options_label'} = new Gtk2::Label(msg("Misc."));
  $widgets->{'more_options_label'}->set_alignment( 0, 0.5 );
  $widgets->{'more_options_label'}->show;

  $widgets->{'misc_table'}->attach( $widgets->{'more_options_label'}, 0, 1, 1, 2, ['fill'], [], 4, 2 );
  $widgets->{'misc_table'}->attach( $widgets->{'more_options_entry'}, 1, 4, 1, 2, [ 'fill', 'expand' ], [], 2, 2 );

### VIDEO

  # Construct a GtkFrame 'video_frame'
  $widgets->{'video_frame'} = new Gtk2::Frame(msg('Video'));
  $widgets->{'notebook'}->append_page( $widgets->{'video_frame'}, new Gtk2::Label(msg("Video")));
  $widgets->{'video_frame'}->show;
  $widgets->{'video_frame'}->set_border_width(2);

  # Construct a GtkTable 'video_table'
  $widgets->{'video_table'} = new Gtk2::Table( 10, 5, 0 );
  $widgets->{'video_table'}->set_row_spacings($row_height);
  $widgets->{'video_frame'}->add( $widgets->{'video_table'} );
  $widgets->{'video_table'}->show;

  $widgets->{'video_crop_seperator'} = new Gtk2::HSeparator;
  $widgets->{'video_crop_seperator'}->show;
  $widgets->{'video_table'}->attach( $widgets->{'video_crop_seperator'}, 0, 5, 3, 4, ['fill'], ['expand'], 2, 2 );

  # Construct a GtkCheckButton 'crop_enable_check'
  $widgets->{'crop_enable_check'} = new Gtk2::CheckButton(msg("Crop"));
  $widgets->{'video_table'}->attach( $widgets->{'crop_enable_check'}, 0, 1, 4, 5, ['fill'], ['expand'], 2, 2 );
  $widgets->{'crop_enable_check'}->set_active(1);
  $widgets->{'crop_enable_check'}->show;

  # Construct a GtkEntry 'crop_vertical_entry'
  $widgets->{'crop_vertical_adjust'} = new Gtk2::Adjustment( 0, 0, 720, 1, 50, 200 );
  $widgets->{'crop_vertical_spin'} = new Gtk2::SpinButton( $widgets->{'crop_vertical_adjust'}, 1, 0 );
  $widgets->{'video_table'}->attach( $widgets->{'crop_vertical_spin'}, 4, 5, 5, 6, [ 'expand', 'fill' ], ['expand'], 2, 2 );
  $widgets->{'crop_vertical_spin'}->show;
  $widgets->{'crop_vertical_spin'}->set_size_request( 40, -1 );

  # Construct a GtkEntry 'crop_horizontal_entry'
  $widgets->{'crop_horizontal_adjust'} = new Gtk2::Adjustment( 0, 0, 576, 1, 50, 200 );
  $widgets->{'crop_horizontal_spin'} = new Gtk2::SpinButton( $widgets->{'crop_horizontal_adjust'}, 1, 0 );
  $widgets->{'video_table'}->attach( $widgets->{'crop_horizontal_spin'}, 4, 5, 4, 5, [ 'expand', 'fill' ], ['expand'], 2, 2 );
  $widgets->{'crop_horizontal_spin'}->show;
  $widgets->{'crop_horizontal_spin'}->set_size_request( 40, -1 );

  # Construct a GtkEntry 'crop_width_entry'
  $widgets->{'crop_width_adjust'} = new Gtk2::Adjustment( 0, 0, 1000, 1, 50, 200 );
  $widgets->{'crop_width_spin'} = new Gtk2::SpinButton( $widgets->{'crop_width_adjust'}, 1, 0 );
  $widgets->{'video_table'}->attach( $widgets->{'crop_width_spin'}, 2, 3, 4, 5, [ 'expand', 'fill' ], ['expand'], 2, 2 );
  $widgets->{'crop_width_spin'}->show;
  $widgets->{'crop_width_spin'}->set_size_request( 40, -1 );

  # Construct a GtkEntry 'crop_height_entry'
  $widgets->{'crop_height_adjust'} = new Gtk2::Adjustment( 0, 0, 1000, 1, 50, 200 );
  $widgets->{'crop_height_spin'} = new Gtk2::SpinButton( $widgets->{'crop_height_adjust'}, 1, 0 );
  $widgets->{'video_table'}->attach( $widgets->{'crop_height_spin'}, 2, 3, 5, 6, [ 'expand', 'fill' ], ['expand'], 2, 2 );
  $widgets->{'crop_height_spin'}->show;
  $widgets->{'crop_height_spin'}->set_size_request( 40, -1 );

  # Construct a GtkLabel 'crop_vertical_label'
  $widgets->{'crop_vertical_label'} = new Gtk2::Label(msg('Vert'));
  $widgets->{'video_table'}->attach( $widgets->{'crop_vertical_label'}, 3, 4, 5, 6, ['fill'], ['expand'], 2, 2 );
  $widgets->{'crop_vertical_label'}->show;

  # Construct a GtkLabel 'crop_horizontal_label'
  $widgets->{'crop_horizontal_label'} = new Gtk2::Label(msg('Horiz'));
  $widgets->{'video_table'}->attach( $widgets->{'crop_horizontal_label'}, 3, 4, 4, 5, ['fill'], ['expand'], 2, 2 );
  $widgets->{'crop_horizontal_label'}->show;

  # Construct a GtkLabel 'crop_width_label'
  $widgets->{'crop_width_label'} = new Gtk2::Label(msg('Width'));
  $widgets->{'video_table'}->attach( $widgets->{'crop_width_label'}, 1, 2, 4, 5, ['fill'], ['expand'], 2, 2 );
  $widgets->{'crop_width_label'}->show;

  # Construct a GtkLabel 'crop_height_label'
  $widgets->{'crop_height_label'} = new Gtk2::Label(msg('Height'));
  $widgets->{'video_table'}->attach( $widgets->{'crop_height_label'}, 1, 2, 5, 6, ['fill'], ['expand'], 2, 2 );
  $widgets->{'crop_height_label'}->show;

  # Construct a GtkButton 'crop_detect_button'
  $widgets->{'crop_detect_button'} = new Gtk2::Button(msg('Detect'));
  $widgets->{'video_table'}->attach( $widgets->{'crop_detect_button'}, 0, 1, 5, 6, ['fill'], ['expand'], 2, 2 );
  $widgets->{'crop_detect_button'}->show;

  $widgets->{'video_scale_seperator'} = new Gtk2::HSeparator;
  $widgets->{'video_scale_seperator'}->show;
  $widgets->{'video_table'}->attach( $widgets->{'video_scale_seperator'}, 0, 5, 6, 7, ['fill'], ['expand'], 2, 2 );

  # Construct a GtkCheckButton 'scale_enable_check'
  $widgets->{'scale_enable_check'} = new Gtk2::CheckButton(msg('Scale'));
  $widgets->{'video_table'}->attach( $widgets->{'scale_enable_check'}, 0, 1, 7, 8, ['fill'], ['expand'], 2, 2 );
  $widgets->{'scale_enable_check'}->set_active(1);
  $widgets->{'scale_enable_check'}->show;

  # Construct a GtkLabel 'scale_width_label'
  $widgets->{'scale_width_label'} = new Gtk2::Label(msg('Width'));
  $widgets->{'video_table'}->attach( $widgets->{'scale_width_label'}, 1, 2, 7, 8, ['fill'], ['expand'], 2, 2 );
  $widgets->{'scale_width_label'}->show;

  #
  # Construct a GtkLabel 'scale_height_label'
  $widgets->{'scale_lock_check'} = new Gtk2::CheckButton(msg('Lock aspect'));
  $widgets->{'video_table'}->attach( $widgets->{'scale_lock_check'}, 3, 5, 7, 8, ['fill'], ['expand'], 2, 2 );
  $widgets->{'scale_lock_check'}->set_relief('none');
  $widgets->{'scale_lock_check'}->show;
  $widgets->{'scale_lock_check'}->set_active(1);

  $widgets->{'scale_height_label'} = new Gtk2::Label(msg('Height'));
  $widgets->{'video_table'}->attach( $widgets->{'scale_height_label'}, 1, 2, 8, 9, ['fill'], ['expand'], 2, 2 );
  $widgets->{'scale_height_label'}->show;

  #
  # Construct a GtkEntry 'scale_width_entry'
  $widgets->{'scale_width_adjust'} = new Gtk2::Adjustment( 1, -2, 1000, 1, 50, 200 );
  $widgets->{'scale_width_spin'} = new Gtk2::SpinButton( $widgets->{'scale_width_adjust'}, 1, 0 );
  $widgets->{'video_table'}->attach( $widgets->{'scale_width_spin'}, 2, 3, 7, 8, [ 'expand', 'fill' ], ['expand'], 2, 2 );
  $widgets->{'scale_width_spin'}->show;
  $widgets->{'scale_width_spin'}->set_size_request( 50, -1 );

  #
  # Construct a GtkEntry 'scale_height_entry'
  $widgets->{'scale_height_adjust'} = new Gtk2::Adjustment( 123, -2, 1000, 1, 50, 200 );
  $widgets->{'scale_height_spin'} = new Gtk2::SpinButton( $widgets->{'scale_height_adjust'}, 1, 0 );
  $widgets->{'video_table'}->attach( $widgets->{'scale_height_spin'}, 2, 3, 8, 9, [ 'expand', 'fill' ], ['expand'], 2, 2 );
  $widgets->{'scale_height_spin'}->hide;
  $widgets->{'scale_height_spin'}->set_size_request( 50, -1 );

  $widgets->{'scale_height_estimate_entry'} = new Gtk2::Entry;
  $widgets->{'scale_height_estimate_entry'}->set_text("0");
  $widgets->{'video_table'}->attach( $widgets->{'scale_height_estimate_entry'}, 2, 3, 8, 9, [ 'expand', 'fill' ], ['expand'], 2, 2 );
  $widgets->{'scale_height_estimate_entry'}->set_editable(0);
  $widgets->{'scale_height_estimate_entry'}->show;
  $widgets->{'scale_height_estimate_entry'}->set_size_request( 50, -1 );

  $widgets->{'video_filters_seperator'} = new Gtk2::HSeparator;
  $widgets->{'video_filters_seperator'}->show;
  $widgets->{'video_table'}->attach( $widgets->{'video_filters_seperator'}, 0, 5, 9, 10, ['fill'], ['expand'], 2, 2 );

  $widgets->{'vf_pre_enable_check'} = new Gtk2::CheckButton(msg("Pre filters"));
  $widgets->{'video_table'}->attach( $widgets->{'vf_pre_enable_check'}, 0, 2, 10, 11, [ 'expand', 'fill' ], ['expand'], 2, 2 );
  $widgets->{'vf_pre_enable_check'}->set_active(1);
  $widgets->{'vf_pre_enable_check'}->show;

  $widgets->{'vf_pre_entry'} = new Gtk2::Entry;
  $widgets->{'vf_pre_entry'}->set_size_request( 40, -1 );
  $widgets->{'video_table'}->attach( $widgets->{'vf_pre_entry'}, 2, 5, 10, 11, [ 'expand', 'fill' ], ['expand'], 2, 2 );
  $widgets->{'vf_pre_entry'}->show;

  $widgets->{'vf_post_enable_check'} = new Gtk2::CheckButton(msg("Post filters"));
  $widgets->{'video_table'}->attach( $widgets->{'vf_post_enable_check'}, 0, 2, 11, 12, [ 'expand', 'fill' ], ['expand'], 2, 2 );
  $widgets->{'vf_post_enable_check'}->set_active(1);
  $widgets->{'vf_post_enable_check'}->show;

  $widgets->{'vf_post_entry'} = new Gtk2::Entry;
  $widgets->{'video_table'}->attach( $widgets->{'vf_post_entry'}, 2, 5, 11, 12, [ 'expand', 'fill' ], ['expand'], 2, 2 );
  $widgets->{'vf_post_entry'}->show;
  $widgets->{'vf_post_entry'}->set_size_request( 40, -1 );

  # Construct a GtkLabel 'codec_label'
  $widgets->{'codec_label'} = new Gtk2::Label(msg('Codec'));
  $widgets->{'video_table'}->attach( $widgets->{'codec_label'}, 0, 1, 0, 1, ['fill'], ['expand'], 2, 2 );
  $widgets->{'codec_label'}->show;
  $widgets->{'codec_label'}->set_alignment( 0, 0.5 );

  #
  # Construct a GtkCombo 'codec_combo'
  $widgets->{'video_codec_option'} = new Gtk2::OptionMenu;
  $widgets->{'video_codec_menu'}   = new Gtk2::Menu;
  $widgets->{'video_codec_option'}->set_menu( $widgets->{'video_codec_menu'} );
  $widgets->{'video_table'}->attach( $widgets->{'video_codec_option'}, 1, 3, 0, 1, [ 'expand', 'fill' ], ['expand'], 2, 2 );
  $widgets->{'video_codec_option'}->show;
  $widgets->{'video_codec_option'}->set_size_request( 40, -1 );

  #
  # Construct a GtkLabel 'lavc_label'
  $widgets->{'video_options_label'} = new Gtk2::Label(msg('Options'));
  $widgets->{'video_table'}->attach( $widgets->{'video_options_label'}, 0, 1, 1, 2, ['fill'], ['expand'], 2, 2 );
  $widgets->{'video_options_label'}->show;
  $widgets->{'video_options_label'}->set_alignment( 0, 0.5 );

  #
  # Construct a GtkEntry 'codec_options_entry'
  $widgets->{'video_options_entry'} = new Gtk2::Entry;
  $widgets->{'video_table'}->attach( $widgets->{'video_options_entry'}, 1, 5, 1, 2, [ 'expand', 'fill' ], ['expand'], 2, 2 );
  $widgets->{'video_options_entry'}->show;

  $widgets->{'video_bitrate_label'} = new Gtk2::Label(msg('Bitrate'));
  $widgets->{'video_bitrate_label'}->show;
  $widgets->{'video_bitrate_label'}->set_alignment( 0, 0.5 );
  $widgets->{'video_table'}->attach( $widgets->{'video_bitrate_label'}, 0, 1, 2, 3, ['fill'], ['expand'], 2, 2 );

  $widgets->{'video_bitrate_entry'} = new Gtk2::Entry;
  $widgets->{'video_bitrate_entry'}->set_editable(0);
  $widgets->{'video_bitrate_entry'}->set_size_request( 50, -1 );
  $widgets->{'video_table'}->attach( $widgets->{'video_bitrate_entry'}, 1, 2, 2, 3, ['fill'], ['expand'], 2, 2 );
  $widgets->{'video_bitrate_entry'}->show;

  $widgets->{'video_bitrate_adjust'} = new Gtk2::Adjustment( 1, 1, 5000, 1, 50, 1 );
  $widgets->{'video_bitrate_spin'} = new Gtk2::SpinButton( $widgets->{'video_bitrate_adjust'}, 1, 0 );
  $widgets->{'video_table'}->attach( $widgets->{'video_bitrate_spin'}, 1, 2, 2, 3, ['fill'], ['expand'], 2, 2 );

  #$widgets->{'video_bitrate_spin'}->show;
  $widgets->{'video_bitrate_spin'}->set_size_request( 50, -1 );

  $widgets->{'video_bitrate_lock_check'} = new Gtk2::CheckButton(msg('Lock'));
  $widgets->{'video_bitrate_lock_check'}->show;
  $widgets->{'video_table'}->attach( $widgets->{'video_bitrate_lock_check'}, 2, 3, 2, 3, ['fill'], ['expand'], 2, 2 );

  $widgets->{'video_passes_adjust'} = new Gtk2::Adjustment( 1, 1, 3, 1, 1, 1 );
  $widgets->{'video_passes_spin'} = new Gtk2::SpinButton( $widgets->{'video_passes_adjust'}, 1, 0 );
  $widgets->{'video_passes_spin'}->show;
  $widgets->{'video_passes_label'} = new Gtk2::Label(msg("Passes"));
  $widgets->{'video_passes_label'}->show;
  $widgets->{'video_table'}->attach( $widgets->{'video_passes_label'}, 3, 4, 0, 1, ['fill'], ['expand'], 2, 2 );
  $widgets->{'video_table'}->attach( $widgets->{'video_passes_spin'},  4, 5, 0, 1, ['fill'], ['expand'], 2, 2 );

  $widgets->{'video_bpp_label'} = new Gtk2::Label(msg("Bits/Px"));
  $widgets->{'video_bpp_label'}->show;
  $widgets->{'video_bpp_entry'} = new Gtk2::Entry;
  $widgets->{'video_bpp_entry'}->show;
  $widgets->{'video_bpp_entry'}->set_editable(0);
  $widgets->{'video_bpp_entry'}->set_size_request( 40, -1 );
  $widgets->{'video_table'}->attach( $widgets->{'video_bpp_label'}, 3, 4, 2, 3, ['fill'], ['expand'], 2, 2 );
  $widgets->{'video_table'}->attach( $widgets->{'video_bpp_entry'}, 4, 5, 2, 3, ['fill'], ['expand'], 2, 2 );

  # Construct a GtkVBox 'right_vbox'
  $widgets->{'right_vbox'} = new Gtk2::VBox( 0, 0 );
  $widgets->{'main_hbox'}->add( $widgets->{'right_vbox'} );
  $widgets->{'right_vbox'}->show;

  ### right hand notebook

  #$widgets->{'right_notebook'} = new Gtk2::Notebook();
  #$widgets->{'right_notebook'}->show;
  #$widgets->{'right_notebook'}->set_border_width(2);
  #$widgets->{'right_vbox'}->add($widgets->{'right_notebook'});

  ### DVD TREE

  # Construct a GtkFrame 'dvd_tree_frame'
  $widgets->{'dvd_tree_frame'} = new Gtk2::Frame(msg('Video source'));

  #$widgets->{'dvd_tree_frame'}->set_label_align(0, 0);
  $widgets->{'right_vbox'}->add( $widgets->{'dvd_tree_frame'} );

  #$widgets->{'right_notebook'}->append_page($widgets->{'dvd_tree_frame'}, new Gtk2::Label("DVD"));
  $widgets->{'dvd_tree_frame'}->show;
  $widgets->{'dvd_tree_frame'}->set_border_width(2);

  #
  # Construct a GtkVBox 'dvd_tree_vbox'
  $widgets->{'dvd_tree_vbox'} = new Gtk2::VBox( 0, 0 );
  $widgets->{'dvd_tree_frame'}->add( $widgets->{'dvd_tree_vbox'} );
  $widgets->{'dvd_tree_vbox'}->show;

  #
  # Construct a GtkHBox 'dvd_device_hbox'
  $widgets->{'dvd_device_hbox'} = new Gtk2::HBox( 0, 0 );
  $widgets->{'dvd_tree_vbox'}->add( $widgets->{'dvd_device_hbox'} );
  $widgets->{'dvd_device_hbox'}->show;

  #
  # Construct a GtkLabel 'dvd_device'
  $widgets->{'dvd_device_label'} = new Gtk2::Label(msg('Path'));
  $widgets->{'dvd_device_hbox'}->add( $widgets->{'dvd_device_label'} );
  $widgets->{'dvd_device_label'}->show;
  $widgets->{'dvd_device_label'}->set_alignment( 0.5, 0.5 );
  $widgets->{'dvd_device_label'}->set_padding( 2, 2 );
  $widgets->{'dvd_device_hbox'}->set_child_packing( $widgets->{'dvd_device_label'}, 0, 0, 0, 'start' );

  #
  # Construct a GtkEntry 'dvd_device_entry'
  $widgets->{'dvd_device_entry'} = new Gtk2::Entry;
  $widgets->{'dvd_device_hbox'}->add( $widgets->{'dvd_device_entry'} );
  $widgets->{'dvd_device_entry'}->show;
  $widgets->{'dvd_device_entry'}->set_size_request( 100, -1 );
  $widgets->{'dvd_device_hbox'}->set_child_packing( $widgets->{'dvd_device_entry'}, 1, 1, 0, 'start' );

  #
  # Construct a GtkButton 'read_dvd_button'
  $widgets->{'read_dvd_button'} = Gtk2::Button->new_from_stock('ar_load');
  $widgets->{'dvd_device_hbox'}->add( $widgets->{'read_dvd_button'} );
  $widgets->{'read_dvd_button'}->show;
  $widgets->{'read_dvd_button'}->set_border_width(2);
  $widgets->{'dvd_device_hbox'}->set_child_packing( $widgets->{'read_dvd_button'}, 1, 1, 0, 'start' );
  $widgets->{'dvd_tree_vbox'}->set_child_packing( $widgets->{'dvd_device_hbox'},   0, 0, 0, 'start' );

  #
  # Construct a GtkScrolledWindow 'tree_scroll_window'
  $widgets->{'tree_scroll_window'} = new Gtk2::ScrolledWindow( undef, undef );
  $widgets->{'tree_scroll_window'}->set_policy( 'automatic', 'always' );
  $widgets->{'tree_scroll_window'}->set_border_width(2);
  $widgets->{'tree_scroll_window'}->set_shadow_type('in');
  $widgets->{'dvd_tree_vbox'}->add( $widgets->{'tree_scroll_window'} );
  $widgets->{'tree_scroll_window'}->show;

  #
  # Construct a GtkTree 'dvd_tree'
  $widgets->{'dvd_tree'} = new Gtk2::TreeView;
  $widgets->{'dvd_tree'}->set_headers_visible(0);
  $widgets->{'tree_scroll_window'}->add( $widgets->{'dvd_tree'} );
  $widgets->{'dvd_tree'}->show;
  $widgets->{'dvd_tree'}->set_size_request( 200, 0 );
  $widgets->{'dvd_tree_vbox'}->set_child_packing( $widgets->{'tree_scroll_window'}, 1, 1, 0, 'start' );
  $widgets->{'right_vbox'}->set_child_packing( $widgets->{'dvd_tree_frame'},        1, 1, 0, 'start' );

  $widgets->{'selected_track_label'} = new Gtk2::Label(msg("No track selected"));
  $widgets->{'dvd_tree_vbox'}->pack_end( $widgets->{'selected_track_label'}, 0, 1, 2 );
  $widgets->{'selected_track_label'}->show;
  $widgets->{'selected_track_label'}->set_alignment( 0, 0 );

### CACHE VBOX

  $widgets->{'cache_menc_vbox'} = new Gtk2::VBox();
  $widgets->{'right_vbox'}->pack_start( $widgets->{'cache_menc_vbox'}, 0, 0, 0 );
  $widgets->{'cache_menc_vbox'}->show;

### CACHE FRAME

  # Construct a GtkFrame 'cache_frame'
  $widgets->{'cache_frame'} = new Gtk2::Frame(msg('Cache status'));
  $widgets->{'cache_menc_vbox'}->pack_start( $widgets->{'cache_frame'}, 0, 0, 2 );
  $widgets->{'cache_frame'}->show;
  $widgets->{'cache_frame'}->set_border_width(2);

  #
  # Construct a GtkTable 'mencoder_table'
  $widgets->{'cache_table'} = new Gtk2::Table( 1, 4, 1 );
  $widgets->{'cache_frame'}->add( $widgets->{'cache_table'} );
  $widgets->{'cache_table'}->show;

  $widgets->{'cache_chapter_label'} = new Gtk2::Label(msg('Chapter:'));
  $widgets->{'cache_chapter_label'}->show;
  $widgets->{'cache_chapter_label'}->set_alignment( 0, 0.5 );
  $widgets->{'cache_table'}->attach( $widgets->{'cache_chapter_label'}, 0, 1, 0, 1, ['fill'], [], 2, 2 );

  $widgets->{'cache_chapter'} = new Gtk2::Label("0 (0/0)");
  $widgets->{'cache_chapter'}->show;
  $widgets->{'cache_table'}->attach( $widgets->{'cache_chapter'}, 1, 2, 0, 1, [ 'fill', 'expand' ], [], 2, 2 );

  $widgets->{'cache_size_label'} = new Gtk2::Label(msg("Size:"));
  $widgets->{'cache_size_label'}->show;
  $widgets->{'cache_size_label'}->set_alignment( 0, 0.5 );
  $widgets->{'cache_table'}->attach( $widgets->{'cache_size_label'}, 2, 3, 0, 1, [ 'fill', 'expand' ], [], 2, 2 );

  $widgets->{'cache_size'} = new Gtk2::Label("0mb");
  $widgets->{'cache_size'}->show;
  $widgets->{'cache_table'}->attach( $widgets->{'cache_size'}, 3, 4, 0, 1, [ 'fill', 'expand' ], [], 2, 2 );

### MENCODER FRAME

  # Construct a GtkFrame 'menc_frame'
  $widgets->{'menc_frame'} = new Gtk2::Frame(msg('Encoding status'));
  $widgets->{'cache_menc_vbox'}->add( $widgets->{'menc_frame'} );

  #$widgets->{'main_table'}->attach($widgets->{'menc_frame'}, 1, 2, 4, 6, ['fill'], ['fill'], 2, 2);
  $widgets->{'menc_frame'}->show;
  $widgets->{'menc_frame'}->set_border_width(2);

  #
  # Construct a GtkTable 'mencoder_table'
  $widgets->{'mencoder_table'} = new Gtk2::Table( 6, 2, 0 );
  $widgets->{'menc_frame'}->add( $widgets->{'mencoder_table'} );
  $widgets->{'mencoder_table'}->show;

  #
  # Construct a GtkLabel 'menc_fps_label'
  $widgets->{'menc_fps_label'} = new Gtk2::Label(msg('Encoding speed:'));
  $widgets->{'mencoder_table'}->attach( $widgets->{'menc_fps_label'}, 0, 1, 1, 2, ['fill'], [], 2, 1 );
  $widgets->{'menc_fps_label'}->show;
  $widgets->{'menc_fps_label'}->set_alignment( 0, 0.5 );

  #
  # Construct a GtkLabel 'menc_time_label'
  $widgets->{'menc_time_label'} = new Gtk2::Label(msg('Real time left:'));
  $widgets->{'mencoder_table'}->attach( $widgets->{'menc_time_label'}, 0, 1, 0, 1, ['fill'], [], 2, 1 );
  $widgets->{'menc_time_label'}->show;
  $widgets->{'menc_time_label'}->set_alignment( 0, 0.5 );

  #
  # Construct a GtkLabel 'menc_filesize_label'
  $widgets->{'menc_filesize_label'} = new Gtk2::Label(msg('Estimated filesize:'));
  $widgets->{'mencoder_table'}->attach( $widgets->{'menc_filesize_label'}, 0, 1, 2, 3, ['fill'], [], 2, 1 );
  $widgets->{'menc_filesize_label'}->show;
  $widgets->{'menc_filesize_label'}->set_alignment( 0, 0.5 );

  #
  # Construct a GtkLabel 'menc_progress_label'
  $widgets->{'menc_progress_label'} = new Gtk2::Label(msg('Time encoded:'));
  $widgets->{'mencoder_table'}->attach( $widgets->{'menc_progress_label'}, 0, 1, 3, 4, ['fill'], [], 2, 1 );
  $widgets->{'menc_progress_label'}->show;
  $widgets->{'menc_progress_label'}->set_alignment( 0, 0.5 );

  #
  # Construct a GtkLabel 'progress_value'
  $widgets->{'menc_seconds'} = new Gtk2::Label('0:00:00');
  $widgets->{'mencoder_table'}->attach( $widgets->{'menc_seconds'}, 1, 2, 3, 4, [ 'expand', 'fill' ], [], 2, 1 );
  $widgets->{'menc_seconds'}->show;
  $widgets->{'menc_seconds'}->set_alignment( 0.5, 0.5 );

  #
  # Construct a GtkLabel 'menc_progress_label'
  $widgets->{'menc_bitrate_label'} = new Gtk2::Label(msg('Average bitrates:'));
  $widgets->{'mencoder_table'}->attach( $widgets->{'menc_bitrate_label'}, 0, 1, 4, 5, ['fill'], [], 2, 1 );
  $widgets->{'menc_bitrate_label'}->show;
  $widgets->{'menc_bitrate_label'}->set_alignment( 0, 0.5 );

  $widgets->{'menc_bitrate'} = new Gtk2::Label('0:0');
  $widgets->{'mencoder_table'}->attach( $widgets->{'menc_bitrate'}, 1, 2, 4, 5, [ 'expand', 'fill' ], [], 2, 1 );
  $widgets->{'menc_bitrate'}->show;
  $widgets->{'menc_bitrate'}->set_alignment( 0.5, 0.5 );

  #
  # Construct a GtkLabel 'filesize'
  $widgets->{'menc_filesize'} = new Gtk2::Label('0mb');
  $widgets->{'mencoder_table'}->attach( $widgets->{'menc_filesize'}, 1, 2, 2, 3, [ 'expand', 'fill' ], [], 2, 1 );
  $widgets->{'menc_filesize'}->show;
  $widgets->{'menc_filesize'}->set_alignment( 0.5, 0.5 );

  #
  # Construct a GtkLabel 'fps'
  $widgets->{'menc_fps'} = new Gtk2::Label('0fps');
  $widgets->{'mencoder_table'}->attach( $widgets->{'menc_fps'}, 1, 2, 1, 2, [ 'expand', 'fill' ], [], 2, 1 );
  $widgets->{'menc_fps'}->show;
  $widgets->{'menc_fps'}->set_alignment( 0.5, 0.5 );

  #
  # Construct a GtkLabel 'time'
  $widgets->{'menc_time'} = new Gtk2::Label('0min');
  $widgets->{'mencoder_table'}->attach( $widgets->{'menc_time'}, 1, 2, 0, 1, [ 'expand', 'fill' ], [], 2, 1 );
  $widgets->{'menc_time'}->show;
  $widgets->{'menc_time'}->set_alignment( 0.5, 0.5 );

  #
  # Construct a GtkProgressBar 'progress'
  $widgets->{'menc_progress'} = new Gtk2::ProgressBar;
  $widgets->{'menc_progress'}->set_orientation('left_to_right');
  $widgets->{'mencoder_table'}->attach( $widgets->{'menc_progress'}, 0, 2, 5, 6, ['fill'], [], 2, 2 );
  $widgets->{'menc_progress'}->show;
  $widgets->{'right_vbox'}->set_child_packing( $widgets->{'menc_frame'}, 0, 1, 0, 'start' );

  $widgets->{'control_table'} = new Gtk2::Table( 2, 2, 1 );
  $widgets->{'control_table'}->show;

  $widgets->{'right_vbox'}->pack_end( $widgets->{'control_table'}, 0, 1, 0 );
  $widgets->{'right_vbox'}->set_child_packing( $widgets->{'control_table'}, 0, 1, 0, 'start' );

### BUTTONS

  # Construct a GtkHBox 'settings_hbox'
  $widgets->{'buttons_table'} = new Gtk2::Table( 2, 2, 1 );
  $widgets->{'buttons_frame'} = new Gtk2::Frame;
  $widgets->{'buttons_frame'}->set_border_width(2);
  $widgets->{'buttons_frame'}->add( $widgets->{'buttons_table'} );
  $widgets->{'left_vbox'}->add( $widgets->{'buttons_frame'} );
  $widgets->{'buttons_frame'}->show_all;

  #
  # Construct a GtkButton 'quit_button'
  $widgets->{'quit_button'} = Gtk2::Button->new_from_stock('ar_quit');
  $widgets->{'buttons_table'}->attach( $widgets->{'quit_button'}, 1, 2, 1, 2, [ 'expand', 'fill' ], [], 2, 2 );
  $widgets->{'quit_button'}->show;

  #
  # Construct a GtkButton 'progress_dialog_show_button'
  $widgets->{'progress_dialog_show_button'} = Gtk2::Button->new_from_stock('ar_compact');
  $widgets->{'buttons_table'}->attach( $widgets->{'progress_dialog_show_button'}, 0, 1, 1, 2, [ 'expand', 'fill' ], [], 2, 2 );
  $widgets->{'progress_dialog_show_button'}->show;
  $widgets->{'progress_dialog_show_button'}->set_sensitive(0);

  #
  # Construct a GtkButton 'start_button'
  $widgets->{'start_button'} = Gtk2::Button->new_from_stock('ar_start');
  $widgets->{'buttons_table'}->attach( $widgets->{'start_button'}, 1, 2, 0, 1, [ 'expand', 'fill' ], [], 2, 2 );
  $widgets->{'start_button'}->show;
  $widgets->{'start_button'}->set_sensitive(0);

  #
  # Construct a GtkButton 'stop_button'
  $widgets->{'stop_button'} = Gtk2::Button->new_from_stock('ar_stop');
  $widgets->{'buttons_table'}->attach( $widgets->{'stop_button'}, 1, 2, 0, 1, [ 'expand', 'fill' ], [], 2, 2 );

  #
  # Construct a GtkButton 'view_button'
  $widgets->{'view_button'} = Gtk2::Button->new_from_stock('ar_view');

  #$widgets->{'buttons_table'}->attach($widgets->{'view_button'}, 0, 1, 0, 1, ['expand', 'fill'], [], 2, 2);
  #$widgets->{'view_button'}->show;
  $widgets->{'view_button'}->set_sensitive(0);

  #$widgets->{'main_hbox'}->set_child_packing($widgets->{'right_vbox'}, 1, 1, 0, 'end');
  #
  # Construct a GtkButton 'queue_button'
  $widgets->{'queue_button'} = Gtk2::Button->new_from_stock('ar_queue');
  $widgets->{'buttons_table'}->attach( $widgets->{'queue_button'}, 0, 1, 0, 1, [ 'expand', 'fill' ], [], 2, 2 );
  $widgets->{'queue_button'}->show;
  $widgets->{'queue_button'}->set_sensitive(0);
  $widgets->{'main_hbox'}->set_child_packing( $widgets->{'right_vbox'}, 1, 1, 0, 'end' );

### PREVIEW TAB

  $widgets->{'preview_frame'} = new Gtk2::Frame(msg("Preview"));
  $widgets->{'preview_frame'}->set_border_width(2);
  $widgets->{'preview_table'} = new Gtk2::Table( 2, 6, 0 );
  $widgets->{'preview_table'}->set_row_spacings($row_height);
  $widgets->{'preview_frame'}->add( $widgets->{'preview_table'} );
  $widgets->{'notebook'}->append_page( $widgets->{'preview_frame'}, new Gtk2::Label(msg("Preview")));
  $widgets->{'preview_socket'}       = new Gtk2::Socket;
  $widgets->{'preview_socket_frame'} = new Gtk2::Frame;
  $widgets->{'preview_socket_frame'}->set_shadow_type(GTK_SHADOW_IN);
  $widgets->{'preview_socket_frame'}->add( $widgets->{'preview_socket'} );
  $widgets->{'preview_table'}->attach( $widgets->{'preview_socket_frame'}, 0, 2, 0, 1, [ 'expand', 'fill' ], ['expand'], 2, 2 );
  $widgets->{'preview_socket'}->realize;
  $widgets->{'preview_table'}->attach( new Gtk2::VBox, 0, 2, 1, 2, [ 'expand', 'fill' ], [ 'expand', 'fill' ], 2, 2 );
  $widgets->{'preview_table'}->attach( new Gtk2::HSeparator, 0, 2, 2, 3, [ 'expand', 'fill' ], [], 2, 2 );

  my $dirname = dirname( $INC{"AcidRip/interface.pm"} );
  if ( -e $dirname . "/logo.png" ) {
    $widgets->{'preview_logo'} = new_from_file Gtk2::Image( $dirname . "/logo.png" );
    $widgets->{'preview_table'}->attach( $widgets->{'preview_logo'}, 0, 2, 0, 1, [ 'expand', 'fill' ], ['expand'], 2, 2 );
  }

  # Construct a GtkButton 'preview_button'
  $widgets->{'preview_button'} = Gtk2::Button->new_from_stock('ar_preview');
  $widgets->{'preview_button'}->set_sensitive(0);
  $widgets->{'preview_table'}->attach( $widgets->{'preview_button'}, 0, 1, 4, 5, [ 'expand', 'fill' ], [], 2, 2 );

  #
  # Construct a GtkButton 'stop_preview_button'
  $widgets->{'stop_preview_button'} = Gtk2::Button->new_from_stock('ar_stop');
  $widgets->{'preview_table'}->attach( $widgets->{'stop_preview_button'}, 0, 1, 4, 5, [ 'expand', 'fill' ], [], 2, 2 );

  #
  # Construct a GtkCHECK 'flickbook_preview_check'
  $widgets->{'flickbook_preview_check'} = new Gtk2::CheckButton(msg("Flickbook"));
  $widgets->{'preview_table'}->attach( $widgets->{'flickbook_preview_check'}, 1, 2, 3, 4, ['fill'], [], 2, 2 );

  #
  $widgets->{'embed_preview_check'} = new Gtk2::CheckButton(msg("Embed"));
  $widgets->{'preview_table'}->attach( $widgets->{'embed_preview_check'}, 0, 1, 3, 4, ['fill'], [], 2, 2 );
  $widgets->{'preview_table'}->attach( $widgets->{'view_button'}, 1, 2, 4, 5, [ 'expand', 'fill' ], [], 2, 2 );
  $widgets->{'view_button'}->show;

  $widgets->{'preview_frame'}->show_all;
  $widgets->{'preview_socket_frame'}->hide;

### QUEUE TAB

  $widgets->{'queue_frame'} = new Gtk2::Frame(msg("Queue"));
  $widgets->{'queue_frame'}->set_border_width(2);
  $widgets->{'queue_table'} = new Gtk2::Table( 2, 1, 0 );
  $widgets->{'queue_table'}->set_row_spacings($row_height);
  $widgets->{'queue_frame'}->add( $widgets->{'queue_table'} );
  $widgets->{'notebook'}->append_page( $widgets->{'queue_frame'}, new Gtk2::Label(msg("Queue")) );

  $widgets->{'queue_text'} = new Gtk2::TextView;
  $widgets->{'queue_text'}->set_editable(0);
  $widgets->{'queue_scroll'} = new Gtk2::ScrolledWindow( undef, undef );
  $widgets->{'queue_scroll'}->set_policy( 'automatic', 'automatic' );
  $widgets->{'queue_scroll'}->set_size_request( -1, 150 );
  $widgets->{'queue_scroll'}->add( $widgets->{'queue_text'} );
  $widgets->{'queue_text_frame'} = new Gtk2::Frame;
  $widgets->{'queue_text_frame'}->add( $widgets->{'queue_scroll'} );
  $widgets->{'queue_text_frame'}->set_shadow_type(GTK_SHADOW_IN);
  $widgets->{'queue_table'}->attach( $widgets->{'queue_text_frame'}, 0, 2, 0, 1, [ 'expand', 'fill' ], [ 'expand', 'fill' ], 2, 2 );

  # Construct a GtkButton 'clear_queue_button'
  $widgets->{'queue_clear_button'} = Gtk2::Button->new_from_stock('ar_clear');
  $widgets->{'queue_clear_button'}->set_sensitive(0);
  $widgets->{'queue_table'}->attach( $widgets->{'queue_clear_button'}, 0, 1, 1, 2, [ 'expand', 'fill' ], [], 2, 2 );

  # Construct a GtkButton 'export_queue_button'
  $widgets->{'queue_export_button'} = Gtk2::Button->new_from_stock('ar_export');
  $widgets->{'queue_export_button'}->set_sensitive(0);
  $widgets->{'queue_table'}->attach( $widgets->{'queue_export_button'}, 1, 2, 1, 2, [ 'expand', 'fill' ], [], 2, 2 );

  $widgets->{'queue_frame'}->show_all;

### ADDITIONAL SETTINGS

  # Construct a GtkDialog 'additional_settings_dialog'
  $widgets->{'additional_settings_frame'} = new Gtk2::Frame(msg("Settings"));
  $widgets->{'additional_settings_frame'}->show;
  $widgets->{'additional_settings_frame'}->set_border_width(2);
  $widgets->{'notebook'}->append_page( $widgets->{'additional_settings_frame'}, new Gtk2::Label(msg("Settings")));

  #
  # Construct a GtkVBox 'additional_settings_vbox'
  $widgets->{'additional_settings_vbox'} = new Gtk2::VBox;    #$widgets->{'additional_settings_dialog'}->vbox;
  $widgets->{'additional_settings_frame'}->add( $widgets->{'additional_settings_vbox'} );
  $widgets->{'additional_settings_vbox'}->show;

  #
  # Construct a GtkTable 'additional_settings_table'
  $widgets->{'additional_settings_table'} = new Gtk2::Table( 11, 4, 0 );
  $widgets->{'additional_settings_vbox'}->add( $widgets->{'additional_settings_table'} );
  $widgets->{'additional_settings_table'}->show;
  $widgets->{'additional_settings_table'}->set_row_spacings($row_height);

  #
  # Construst a GtkCheckButton 'autoload_check'
  $widgets->{'tooltips_check'} = new Gtk2::CheckButton(msg('Use tooltips'));

  #$widgets->{'additional_settings_table'}->attach($widgets->{'tooltips_check'}, 2, 4, 6, 7, ['fill'], ['expand'], 2, 0);
  #$widgets->{'tooltips_check'}->show;
  $widgets->{'shutdown_check'} = new Gtk2::CheckButton(msg('Shutdown'));
  $widgets->{'additional_settings_table'}->attach( $widgets->{'shutdown_check'}, 2, 4, 6, 7, ['fill'], ['expand'], 2, 0 );
  $widgets->{'shutdown_check'}->show;

  #
  # Construst a GtkCheckButton 'autoload_check'
  $widgets->{'autoload_check'} = new Gtk2::CheckButton(msg('Autoload media'));
  $widgets->{'additional_settings_table'}->attach( $widgets->{'autoload_check'}, 0, 2, 5, 6, ['fill'], ['expand'], 2, 0 );
  $widgets->{'autoload_check'}->show;

  #
  # Construst a GtkCheckButton 'precache_check'
  $widgets->{'precache_check'} = new Gtk2::CheckButton(msg('Pre-cache video'));
  $widgets->{'additional_settings_table'}->attach( $widgets->{'precache_check'}, 2, 4, 5, 6, ['fill'], ['expand'], 2, 0 );
  $widgets->{'precache_check'}->show;

  #
  # Construst a GtkCheckButton 'autoload_check'
  $widgets->{'del_cache_check'} = new Gtk2::CheckButton(msg('Delete cache'));
  $widgets->{'additional_settings_table'}->attach( $widgets->{'del_cache_check'}, 2, 4, 4, 5, ['fill'], ['expand'], 2, 0 );
  $widgets->{'del_cache_check'}->show;

  #
  # Construst a GtkCheckButton 'autoload_check'
  $widgets->{'overwrite_check'} = new Gtk2::CheckButton(msg('Overwrite files'));
  $widgets->{'additional_settings_table'}->attach( $widgets->{'overwrite_check'}, 0, 2, 6, 7, ['fill'], ['expand'], 2, 0 );
  $widgets->{'overwrite_check'}->show;

  #
  # Construct a GtkLabel 'mencoder_label'
  $widgets->{'mencoder_label'} = new Gtk2::Label('MEncoder:');
  $widgets->{'additional_settings_table'}->attach( $widgets->{'mencoder_label'}, 0, 2, 0, 1, ['fill'], ['expand'], 2, 2 );
  $widgets->{'mencoder_label'}->show;
  $widgets->{'mencoder_label'}->set_alignment( 0, 0.5 );

  #
  # Construct a GtkEntry 'mencoder_entry'
  $widgets->{'mencoder_entry'} = new Gtk2::Entry;
  $widgets->{'mencoder_entry'}->set_size_request( 40, -1 );
  $widgets->{'additional_settings_table'}->attach( $widgets->{'mencoder_entry'}, 2, 4, 0, 1, [ 'expand', 'fill' ], ['expand'], 2, 2 );
  $widgets->{'mencoder_entry'}->show;

  #
  # Construct a GtkLabel 'mplayer_label'
  $widgets->{'mplayer_label'} = new Gtk2::Label('MPlayer:');
  $widgets->{'additional_settings_table'}->attach( $widgets->{'mplayer_label'}, 0, 2, 1, 2, ['fill'], ['expand'], 2, 2 );
  $widgets->{'mplayer_label'}->show;
  $widgets->{'mplayer_label'}->set_alignment( 0, 0.5 );

  #
  # Construct a GtkEntry 'mplayer_entry'
  $widgets->{'mplayer_entry'} = new Gtk2::Entry;
  $widgets->{'mplayer_entry'}->set_size_request( 40, -1 );
  $widgets->{'additional_settings_table'}->attach( $widgets->{'mplayer_entry'}, 2, 4, 1, 2, [ 'expand', 'fill' ], ['expand'], 2, 2 );
  $widgets->{'mplayer_entry'}->show;

  #
  # Construct a GtkLabel 'lsdvd_label'
  $widgets->{'lsdvd_label'} = new Gtk2::Label('lsdvd:');
  $widgets->{'additional_settings_table'}->attach( $widgets->{'lsdvd_label'}, 0, 2, 2, 3, ['fill'], ['expand'], 2, 2 );
  $widgets->{'lsdvd_label'}->show;
  $widgets->{'lsdvd_label'}->set_alignment( 0, 0.5 );

  #
  # Construct a GtkEntry 'lsdvd_entry'
  $widgets->{'lsdvd_entry'} = new Gtk2::Entry;
  $widgets->{'lsdvd_entry'}->set_size_request( 40, -1 );
  $widgets->{'additional_settings_table'}->attach( $widgets->{'lsdvd_entry'}, 2, 4, 2, 3, [ 'expand', 'fill' ], ['expand'], 2, 2 );
  $widgets->{'lsdvd_entry'}->show;

  #
  # Construct a GtkCHECK 'cache_check'
  $widgets->{'cache_check'} = new Gtk2::CheckButton(msg("Cache DVD"));
  $widgets->{'additional_settings_table'}->attach( $widgets->{'cache_check'}, 0, 2, 4, 5, ['fill'], ['expand'], 2, 2 );
  $widgets->{'cache_check'}->show;

  #
  # Construct a GtkLabel 'lsdvd_label'
  $widgets->{'cache_label'} = new Gtk2::Label(msg('Cache:'));
  $widgets->{'additional_settings_table'}->attach( $widgets->{'cache_label'}, 0, 2, 3, 4, ['fill'], ['expand'], 2, 2 );
  $widgets->{'cache_label'}->show;
  $widgets->{'cache_label'}->set_alignment( 0, 0.5 );

  #
  # Construct a GtkEntry for cache location'expand'
  $widgets->{'cache_directory_entry'} = new Gtk2::Entry;
  $widgets->{'cache_directory_entry'}->set_size_request( 40, -1 );
  $widgets->{'additional_settings_table'}->attach( $widgets->{'cache_directory_entry'}, 2, 4, 3, 4, ['fill'], ['expand'], 2, 2 );
  $widgets->{'cache_directory_entry'}->show;

  #
  # Construct a GtkLabel for default language
  $widgets->{'language_label'} = new Gtk2::Label(msg("Language:"));
  $widgets->{'additional_settings_table'}->attach( $widgets->{'language_label'}, 0, 2, 9, 10, ['fill'], ['expand'], 2, 2 );
  $widgets->{'language_label'}->set_alignment( 0, 0.5 );
  $widgets->{'language_label'}->set_size_request( 1, -1 );
  $widgets->{'language_label'}->show;

  #
  # Construct a GtkEntry for default language
  $widgets->{'language_entry'} = new Gtk2::Entry;
  $widgets->{'additional_settings_table'}->attach( $widgets->{'language_entry'}, 2, 4, 9, 10, ['fill'], ['expand'], 2, 2 );
  $widgets->{'language_entry'}->set_size_request( 10, -1 );
  $widgets->{'language_entry'}->show;

  #
  # Construct a GtkCHECK 'compact_check'
  $widgets->{'compact_check'} = new Gtk2::CheckButton(msg("Compact box"));
  $widgets->{'additional_settings_table'}->attach( $widgets->{'compact_check'}, 0, 2, 7, 8, ['fill'], ['expand'], 2, 2 );
  $widgets->{'compact_check'}->show;

  #
  # Construct a GtkCHECK 'enforce_size_check'
  $widgets->{'enforce_space_check'} = new Gtk2::CheckButton(msg("Enforce size"));
  $widgets->{'additional_settings_table'}->attach( $widgets->{'enforce_space_check'}, 2, 4, 7, 8, ['fill'], ['expand'], 2, 2 );
  $widgets->{'enforce_space_check'}->show;

  #
  # Construct a GtkCHECK 'ppc_bug_check'
  $widgets->{'ppc_bug_check'} = new Gtk2::CheckButton(msg("PPC cropping"));
  $widgets->{'additional_settings_table'}->attach( $widgets->{'ppc_bug_check'}, 0, 2, 8, 9, ['fill'], ['expand'], 2, 2 );
  $widgets->{'ppc_bug_check'}->show;

  #
  # Construct a GtkCHECK 'eject_check'
  $widgets->{'eject_check'} = new Gtk2::CheckButton(msg("Eject DVD"));
  $widgets->{'additional_settings_table'}->attach( $widgets->{'eject_check'}, 2, 4, 8, 9, ['fill'], ['expand'], 2, 2 );
  $widgets->{'eject_check'}->show;

  #
  $widgets->{'vcd_type_label'} = new Gtk2::Label("VCD");

  #$widgets->{'vcd_type_label'}->show;
  $widgets->{'additional_settings_table'}->attach( $widgets->{'vcd_type_label'}, 0, 1, 9, 10, [ 'expand', 'fill' ], ['expand'], 2, 2 );

  $widgets->{'vcd_type_option'} = new Gtk2::OptionMenu;
  $widgets->{'vcd_type_menu'}   = new Gtk2::Menu;
  $widgets->{'vcd_type_option'}->set_menu( $widgets->{'vcd_type_menu'} );
  $widgets->{'vcd_type_menu'}->append( new Gtk2::MenuItem("VCD") );
  $widgets->{'vcd_type_menu'}->append( new Gtk2::MenuItem("SVCD") );
  $widgets->{'vcd_type_menu'}->append( new Gtk2::MenuItem("XVCD") );
  $widgets->{'vcd_type_menu'}->append( new Gtk2::MenuItem("KVCD") );

  #$widgets->{'vcd_type_option'}->show_all;
  $widgets->{'additional_settings_table'}->attach( $widgets->{'vcd_type_option'}, 1, 2, 9, 10, [ 'expand', 'fill' ], ['expand'], 2, 2 );

  $widgets->{'vcd_format_label'} = new Gtk2::Label("");

  #$widgets->{'vcd_format_label'}->show;
  $widgets->{'additional_settings_table'}->attach( $widgets->{'vcd_format_label'}, 2, 3, 9, 10, [ 'expand', 'fill' ], ['expand'], 2, 2 );

  $widgets->{'vcd_format_option'} = new Gtk2::OptionMenu;
  $widgets->{'vcd_format_menu'}   = new Gtk2::Menu;
  $widgets->{'vcd_format_option'}->set_menu( $widgets->{'vcd_format_menu'} );
  $widgets->{'vcd_format_menu'}->append( new Gtk2::MenuItem("PAL") );
  $widgets->{'vcd_format_menu'}->append( new Gtk2::MenuItem("NTSC") );

  #$widgets->{'vcd_format_option'}->show_all;
  $widgets->{'additional_settings_table'}->attach( $widgets->{'vcd_format_option'}, 3, 4, 9, 10, [ 'expand', 'fill' ], ['expand'], 2, 2 );

  #
  # Construct a GtkButton 'save_button'
  $widgets->{'save_button'} = Gtk2::Button->new_from_stock('gtk-save');
  $widgets->{'additional_settings_table'}->attach( $widgets->{'save_button'}, 0, 2, 10, 11, [ 'expand', 'fill' ], [], 2, 2 );
  $widgets->{'save_button'}->show;

  # Construct a GtkButton 'restore_button'
  $widgets->{'restore_button'} = Gtk2::Button->new_from_stock('gtk-revert-to-saved');
  $widgets->{'additional_settings_table'}->attach( $widgets->{'restore_button'}, 2, 4, 10, 11, [ 'expand', 'fill' ], [], 2, 2 );
  $widgets->{'restore_button'}->show;

  $widgets->{'main_hbox'}->set_child_packing( $widgets->{'left_vbox'}, 1, 1, 0, 'start' );

### DEBUG WINDOW

  # Construct a mencoder output frame
  $widgets->{'mencoder_output_frame'} = new Gtk2::Frame(msg("Output log"));
  $widgets->{'mencoder_output_frame'}->set_border_width(2);
  $widgets->{'status_vbox'}->add( $widgets->{'mencoder_output_frame'} );

  $widgets->{'output_vbox'} = new Gtk2::VBox;
  $widgets->{'output_vbox'}->show;

  #
  # Construct a mencoder output table
  $widgets->{'mencoder_output_table'} = new Gtk2::Table( 4, 1, 0 );
  $widgets->{'mencoder_output_frame'}->add( $widgets->{'output_vbox'} );
  $widgets->{'output_vbox'}->pack_start( $widgets->{'mencoder_output_table'}, 0, 0, 2 );

  #
  # construct a save button for mencoder output
  $widgets->{'mencoder_output_save_button'} = Gtk2::Button->new_from_stock('ar_log_save');
  $widgets->{'mencoder_output_table'}->attach( $widgets->{'mencoder_output_save_button'}, 0, 1, 0, 1, [ 'fill', 'expand' ], [], 2, 2 );

  $widgets->{'mencoder_output_clear_button'} = Gtk2::Button->new_from_stock('ar_clear');
  $widgets->{'mencoder_output_table'}->attach( $widgets->{'mencoder_output_clear_button'}, 2, 3, 0, 1, [ 'fill', 'expand' ], [], 2, 2 );

  $widgets->{'mencoder_output_hide_button'} = Gtk2::Button->new_from_stock('ar_log_hide');
  $widgets->{'mencoder_output_table'}->attach( $widgets->{'mencoder_output_hide_button'}, 3, 4, 0, 1, [ 'fill', 'expand' ], [], 2, 2 );

  # Construct an mencoder output text
  $widgets->{'mencoder_output_text'} = new Gtk2::TextView;
  $widgets->{'mencoder_output_text'}->set_wrap_mode('word');
  $widgets->{'mencoder_output_text'}->set_editable(0);
  $widgets->{'mencoder_output_scroll'} = new Gtk2::ScrolledWindow( undef, undef );

  $widgets->{'mencoder_output_scroll'}->set_policy( 'automatic', 'always' );
  $widgets->{'mencoder_output_scroll'}->set_size_request( -1, 150 );
  $widgets->{'mencoder_output_scroll'}->add( $widgets->{'mencoder_output_text'} );

  $widgets->{'mencoder_output_scroll'}->set_shadow_type(GTK_SHADOW_IN);
  $widgets->{'output_vbox'}->pack_start( $widgets->{'mencoder_output_scroll'}, 1, 1, 2 );
  $widgets->{'mencoder_output_scroll'}->show_all;

  $widgets->{'mencoder_output_text'}->get_buffer->create_tag( "error", 'foreground' => "red" );
  $widgets->{'mencoder_output_text'}->get_buffer->create_tag( "lsdvd", 'foreground' => 'white', 'size-points' => "0" );
  $widgets->{'mencoder_output_text'}->get_buffer->create_tag( "mplayer", 'foreground' => "darkgrey", 'wrap_mode' => "none" );

### STATUS BAR

  # Construct a GtkStatusbar
  $widgets->{'status_hbox'} = new Gtk2::HBox;
  $widgets->{'status_hbox'}->show;
  $widgets->{'status_vbox'}->add( $widgets->{'status_hbox'} );
  $widgets->{'status_bar'} = new Gtk2::Statusbar;
  $widgets->{'status_hbox'}->pack_start( $widgets->{'status_bar'}, 1, 1, 2 );
  $widgets->{'status_bar'}->show;

  # Construct hide/show mencoder output button
  $widgets->{'mencoder_output_show_button'} = Gtk2::Button->new(msg("Debug"));
  $widgets->{'mencoder_output_show_button'}->show;
  $widgets->{'status_hbox'}->pack_end( $widgets->{'mencoder_output_show_button'}, 0, 1, 2 );

### COMPACT DIALOG

  $widgets->{'progress_dialog'} = new Gtk2::Dialog;
  $widgets->{'progress_dialog'}->set_title(msg('acidrip'));
  $widgets->{'progress_dialog'}->set_resizable(0);
  $widgets->{'progress_dialog'}->set_modal(1);
  $widgets->{'progress_dialog'}->realize;

  # Construct a GtkVBox 'additional_settings_vbox'
  $widgets->{'progress_vbox'} = $widgets->{'progress_dialog'}->vbox;
  $widgets->{'progress_vbox'}->show;

  # Construct a GtkHBox 'additional_settings_action_area'
  $widgets->{'progress_action_area'} = $widgets->{'progress_dialog'}->action_area;
  $widgets->{'progress_action_area'}->show;
  $widgets->{'progress_action_area'}->set_border_width(10);

  $widgets->{'progress_dialog_hide_button'} = new Gtk2::Button(msg("Full view"));
  $widgets->{'progress_dialog_hide_button'}->show;
  $widgets->{'progress_action_area'}->pack_end( $widgets->{'progress_dialog_hide_button'}, 0, 1, 0 );

### TOOLTIPS

  $widgets->{'tooltips'} = new Gtk2::Tooltips();
  $widgets->{'tooltips'}->set_tip( $widgets->{'scale_width_spin'},     				msg('scale_width_spin'));
  $widgets->{'tooltips'}->set_tip( $widgets->{'scale_height_spin'},    				msg('scale_height_spin'));
  $widgets->{'tooltips'}->set_tip( $widgets->{'crop_width_spin'},      				msg('crop_width_spin'));
  $widgets->{'tooltips'}->set_tip( $widgets->{'crop_height_spin'},     				msg('crop_height_spin'));
  $widgets->{'tooltips'}->set_tip( $widgets->{'crop_vertical_spin'},   				msg('crop_vertical_spin'));
  $widgets->{'tooltips'}->set_tip( $widgets->{'crop_horizontal_spin'}, 				msg('crop_horizontal_spin'));
  $widgets->{'tooltips'}->set_tip( $widgets->{'crop_enable_check'},    				msg('crop_enable_check'));
  $widgets->{'tooltips'}->set_tip( $widgets->{'scale_enable_check'},   				msg('scale_enable_check'));
  $widgets->{'tooltips'}->set_tip( $widgets->{'crop_detect_button'},   				msg('crop_detect_button'));
  $widgets->{'tooltips'}->set_tip( $widgets->{'video_codec_option'},   				msg('video_codec_option') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'video_options_entry'},  				msg('video_options_entry') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'video_bitrate_entry'},  				msg('video_bitrate_entry') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'subp_option'},          				msg('subp_option') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'read_dvd_button'},      				msg('read_dvd_button') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'video_passes_spin'},    				msg('video_passes_spin') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'dvd_device_entry'},     				msg('dvd_device_entry') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'autoload_check'},       				msg('autoload_check') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'overwrite_check'},     	 			msg('overwrite_check') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'audio_codec_option'},   				msg('audio_codec_option') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'audio_options_entry'},  				msg('audio_options_entry') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'audio_track_option'},   				msg('audio_track_option') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'filename_entry'},			 				msg('filename_entry') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'filesize_spin'},				 				msg('filesize_spin') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'save_button'},          				msg('save_button') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'restore_button'},      				msg('restore_button') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'start_button'},         				msg('start_button') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'stop_button'},          				msg('stop_button') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'view_button'},          				msg('view_button') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'dvd_tree'},             				msg('dvd_tree') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'mencoder_output_show_button'}, msg('mencoder_output_show_button') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'mencoder_output_hide_button'}, msg('mencoder_output_hide_button') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'mencoder_output_save_button'}, msg('mencoder_output_save_button') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'video_bitrate_lock_check'},    msg('video_bitrate_lock_check') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'scale_lock_check'},            msg('scale_lock_check') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'mencoder_output_clear_button'},msg('mencoder_output_clear_button') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'video_bpp_entry'},             msg('video_bpp_entry') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'more_options_entry'},          msg('more_options_entry') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'total_blocks_spin'},           msg('total_blocks_spin') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'mencoder_entry'}, 							msg('mencoder_entry') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'language_entry'}, 							msg('language_entry') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'cache_directory_entry'}, 			msg('cache_directory_entry') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'cache_check'}, 								msg('cache_check') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'precache_check'},      				msg('precache_check') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'compact_check'},       				msg('compact_check') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'enforce_space_check'}, 				msg('enforce_space_check') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'vf_pre_enable_check'}, 				msg('vf_pre_enable_check') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'vf_post_enable_check'},    		msg('vf_post_enable_check') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'info_field_option'},       		msg('info_field_option') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'ppc_bug_check'},           		msg('ppc_bug_check') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'flickbook_preview_check'}, 		msg('flickbook_preview_check') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'vobsubout_check'},         		msg('vobsubout_check') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'embed_preview_check'},     		msg('embed_preview_check') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'eject_check'},             		msg('eject_check') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'queue_button'},            		msg('queue_button') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'vcd_type_option'},         		msg('vcd_type_option') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'vcd_format_option'},       		msg('vcd_format_option') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'audio_gain_spin'},         		msg('audio_gain_spin') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'quit_button'},             		msg('quit_button') );
  $widgets->{'tooltips'}->set_tip( $widgets->{'shutdown_check'},          		msg('shutdown_check') );

  $widgets->{'queue_export_button'}->signal_connect( 'clicked', \&on_queue_export_button_clicked );
  $widgets->{'queue_clear_button'}->signal_connect( 'clicked',  \&on_queue_clear_button_clicked );
  $widgets->{'preview_button'}->signal_connect( 'clicked',      \&on_crop_preview_button_clicked );
  $widgets->{'crop_detect_button'}->signal_connect( 'clicked',  \&on_crop_detect_button_clicked );
  $widgets->{'save_button'}->signal_connect( 'clicked',         \&on_save_settings_button_clicked );
  $widgets->{'restore_button'}->signal_connect( 'clicked',      \&on_restore_defaults_button_clicked );
  $widgets->{'start_button'}->signal_connect( 'clicked',        \&on_start_button_clicked );
  $widgets->{'stop_button'}->signal_connect( 'clicked',         \&on_stop_button_clicked );
  $widgets->{'queue_button'}->signal_connect( 'clicked',        \&on_queue_button_clicked );
  $widgets->{'stop_preview_button'}->signal_connect( 'clicked', \&on_stop_preview_button_clicked );
  $widgets->{'view_button'}->signal_connect( 'clicked',         \&on_view_button_clicked );
  $widgets->{'scale_lock_check'}->signal_connect( 'toggled',    \&on_scale_lock_check_clicked );
  $widgets->{'mpegfile_option'}->signal_connect( 'changed',     \&on_mpegfile_option_changed );
  $widgets->{'video_bitrate_spin'}->signal_connect( 'value_changed',     \&on_setting_changed);

  $widgets->{'mencoder_output_save_button'}->signal_connect( 'clicked',  \&on_mencoder_output_save_button_clicked );
  $widgets->{'mencoder_output_clear_button'}->signal_connect( 'clicked', \&on_mencoder_output_clear_button_clicked );
  $widgets->{'mencoder_output_show_button'}->signal_connect( 'clicked',  \&on_mencoder_output_show_button_clicked );
  $widgets->{'mencoder_output_hide_button'}->signal_connect( 'clicked',  \&on_mencoder_output_hide_button_clicked );

  bless( $widgets, $class );

  $widgets->connect_signals(
    'toggled',                  \&on_setting_finished, 'tooltips_check',      'cache_check',         'autoload_check',       'crop_enable_check',
    'precache_check',           'scale_enable_check',  'overwrite_check',     'vf_pre_enable_check', 'vf_post_enable_check', 'del_cache_check',
    'video_bitrate_lock_check', 'shutdown_check',      'enforce_space_check', 'compact_check',       'ppc_bug_check',        'flickbook_preview_check',
    'vobsubout_check',          'embed_preview_check', 'eject_check'
  );
  $widgets->connect_signals( 'changed', \&on_setting_finished, 'video_passes_spin', 'total_blocks_spin', 'vf_pre_entry', 'vf_post_entry' );
  $widgets->connect_signals(
    'focus_out_event',    \&on_setting_finished,   'mplayer_entry',       'lsdvd_entry',        'mencoder_entry',      'video_bitrate_entry',
    'video_bitrate_spin', 'crop_height_spin',      'more_options_entry',  'crop_width_spin',    'crop_vertical_spin',  'crop_horizontal_spin',
    'dvd_device_entry',   'language_entry',        'video_options_entry', 'filename_entry',     'audio_options_entry', 'scale_width_spin',
    'scale_height_spin',  'info_name_entry',       'info_artist_entry',   'info_subject_entry', 'info_genre_entry',    'info_copyright_entry',
    'info_comment_entry', 'cache_directory_entry', 'filesize_spin',       'title_entry',        'audio_gain_spin'
  );
  $widgets->connect_signals( 'activate', \&on_setting_finished, 'dvd_device_entry' );
  $widgets->connect_signals(
    'changed',         \&on_setting_changed, 'filesize_spin',        'crop_height_spin', 'scale_width_spin', 'scale_height_spin',
    'crop_width_spin', 'crop_vertical_spin', 'crop_horizontal_spin', 'filename_entry',   'video_bitrate_spin'
  );

  $widgets->{'dvd_device_entry'}->signal_connect( 'activate', \&on_read_dvd_button_clicked );
  $widgets->{'video_bpp_entry'}->signal_connect( 'changed',   \&on_bpp_changed );
  $widgets->{'filesize_spin'}->signal_connect( 'changed',     \&on_filesize_changed );

  $widgets->{'read_dvd_button'}->signal_connect( 'clicked', \&on_read_dvd_button_clicked, $widgets );

  $widgets->{'acidrip'}->signal_connect( 'delete_event',                \&quit_acidrip );
  $widgets->{'quit_button'}->signal_connect( 'clicked',                 \&quit_acidrip );
  $widgets->{'progress_dialog_hide_button'}->signal_connect( 'clicked', \&progress_dialog_hide );
  $widgets->{'progress_dialog_show_button'}->signal_connect( 'clicked', \&progress_dialog_show );

  ##################################################
  # NB subp and audio combo connects in signals.pm #
  ##################################################

  Glib::Idle->add(
    sub {
      while ( Gtk2->events_pending() ) { Gtk2->main_iteration() }
    }
  );

  return $widgets;
}

1;
