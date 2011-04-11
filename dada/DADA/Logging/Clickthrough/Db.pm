package DADA::Logging::Clickthrough::Db;

use lib qw(../../../ ../../../DADA/perllib);

use base "DADA::App::GenericDBFile";

use strict;

use AnyDBM_File;
use Fcntl qw(
  O_WRONLY
  O_TRUNC
  O_CREAT
  O_RDWR
  O_RDONLY
  LOCK_EX
  LOCK_SH
  LOCK_NB);
use Carp qw(croak carp);

use DADA::Config qw(!:DEFAULT);
use DADA::App::Guts;    # For now, my dear.

sub new {

    my $class = shift;

    my ($args) = @_;

    my $self = SUPER::new $class ( function => 'clickthrough', );

    $self->{new_list} = $args->{ -new_list };
    $self->_init($args);

    return $self;
}

sub add {

    my $self = shift;
    my $mid  = shift;
    die 'no mid! ' if !defined $mid;
    my $url = shift;
    my $key = $self->random_key();

    require Text::CSV;
    my $csv = Text::CSV->new($DADA::Config::TEXT_CSV_PARAMS);

    my $value = $self->encode_value( $mid, $url );

    if ($value) {
        $self->_open_db;
        $self->{DB_HASH}->{$key} = $value;
        $self->_close_db;
    }
    return $key;

}


sub encode_value {

    my $self = shift;
    my $mid  = shift;
    die 'no mid! ' if !defined $mid;
    my $url   = shift;
    my $value = undef;

    require Text::CSV;
    my $csv = Text::CSV->new($DADA::Config::TEXT_CSV_PARAMS);

    if ( $csv->combine( $mid, $url ) ) {
        $value = $csv->string;
    }
    else {

        croak "combine() failed on argument: ", $csv->error_input, "\n";

    }

    return $value;

}

sub decode_value {

    my $self  = shift;
    my $value = shift;

    die "no saved information! " if !defined $value;

    require Text::CSV;
    my $csv = Text::CSV->new($DADA::Config::TEXT_CSV_PARAMS);

    if ( $csv->parse($value) ) {
        my @fields = $csv->fields;
        return ( $fields[0], $fields[1] );

    }
    else {
        croak $DADA::Config::PROGRAM_NAME
          . " Error: CSV parsing error: parse() failed on argument: "
          . $csv->error_input() . ' '
          . $csv->error_diag();
        return ( undef, undef );
    }
}


sub reuse_key {

    my $self = shift;
    my $mid  = shift;
    die 'no mid! ' if !defined $mid;
    my $url = shift;

    my $value = $self->encode_value( $mid, $url );

    $self->_open_db;

    while ( my ( $k, $v ) = each( %{ $self->{DB_HASH} } ) ) {
        if ( $v eq $value ) {
            $self->_close_db;
            return $k;
        }
    }

    $self->_close_db;
    return undef;

}

sub fetch {

    my $self = shift;
    my $key  = shift;
    die "no key! " if !defined $key;

    my $mid;
    my $url;
    my $saved_info;

    $self->_open_db;
    if ( exists( $self->{DB_HASH}->{$key} ) ) {
        $saved_info = $self->{DB_HASH}->{$key};
        $self->_close_db;
    }
    else {
        $self->_close_db;
        warn "No saved information for: $key";
        return ( undef, undef );

        # ...
    }

    my ( $r_mid, $r_url ) = $self->decode_value($saved_info);

    return ( $r_mid, $r_url );
}


sub key_exists { 
		
	my $self = shift; 
	my ($args) = @_; 
	my $key = $args->{ -key }; 
	
	$self->_open_db;
    if(exists($self->{DB_HASH}->{$key})){ 
		$self->_close_db;
		return 1; 
	}
	else { 
		$self->_close_db;
		return 0; 
	}

}

sub _raw_db_hash {
    my $self = shift;
    $self->_lock_db;
    $self->_open_db;
    my %RAW_DB_HASH = %{ $self->{DB_HASH} };
    $self->{RAW_DB_HASH} = {%RAW_DB_HASH};
    $self->_close_db;
    $self->_unlock_db;
}



sub r_log { 
	my ($self, $mid, $url) = @_;
	if($self->{is_redirect_on} == 1){ 
	    chmod($DADA::Config::FILE_CHMOD , $self->clickthrough_log_location)
	    	if -e $self->clickthrough_log_location; 
		open(LOG, '>>:encoding(' . $DADA::Config::HTML_CHARSET . ')', $self->clickthrough_log_location) 
			or warn "Couldn't open file: '" . $self->clickthrough_log_location . '\'because: ' .  $!;
		flock(LOG, LOCK_SH);
		print LOG scalar(localtime()) . "\t" . $mid . "\t" . $url . "\n"  or warn "Couldn't write to file: " . $self->clickthrough_log_location . 'because: ' .  $!; 
		close (LOG)  or warn "Couldn't close file: " . $self->clickthrough_log_location . 'because: ' .  $!;
		return 1; 
	}else{ 
		return 0;
	}
}




sub o_log { 
	my ($self, $mid) = @_;
	if($self->{is_log_openings_on} == 1){ 
	    chmod($DADA::Config::FILE_CHMOD , $self->clickthrough_log_location)
	    	if -e $self->clickthrough_log_location; 
		open(LOG, '>>:encoding(' . $DADA::Config::HTML_CHARSET . ')' ,  $self->clickthrough_log_location)
			or warn "Couldn't open file: '" . $self->clickthrough_log_location . '\'because: ' .  $!;
		flock(LOG, LOCK_SH);
		print LOG scalar(localtime()) . "\t" . $mid . "\t" . 'open' . "\n";
		close (LOG);
		return 1; 
	}else{ 
		return 0;
	}
}




sub sc_log { 
	my ($self, $mid, $sc) = @_;
	if($self->{enable_subscriber_count_logging} == 1){ 
	    chmod($DADA::Config::FILE_CHMOD , $self->clickthrough_log_location)
	    	if -e $self->clickthrough_log_location; 
		open(LOG, '>>:encoding(' . $DADA::Config::HTML_CHARSET . ')',  $self->clickthrough_log_location)
			or warn "Couldn't open file: '" . $self->clickthrough_log_location . '\'because: ' .  $!;
		flock(LOG, LOCK_SH);
		print LOG scalar(localtime()) . "\t" . $mid . "\t" . 'num_subscribers' . "\t" . $sc . "\n";
		close (LOG);
		return 1; 
	}else{ 
		return 0;
	}
}




sub bounce_log { 
	my ($self, $type, $mid, $email) = @_;
	if($self->{is_log_bounces_on} == 1){ 
	    chmod($DADA::Config::FILE_CHMOD , $self->clickthrough_log_location)
	    	if -e $self->clickthrough_log_location; 
		open(LOG, '>>:encoding(' . $DADA::Config::HTML_CHARSET . ')',  $self->clickthrough_log_location)
			or warn "Couldn't open file: '" . $self->clickthrough_log_location . '\'because: ' .  $!;
		flock(LOG, LOCK_SH);
		
		if($type eq 'hard'){ 
			print LOG scalar(localtime()) . "\t" . $mid . "\t" . 'hard_bounce' . "\t" . $email . "\n";
		}
		else { 
			print LOG scalar(localtime()) . "\t" . $mid . "\t" . 'soft_bounce' . "\t" . $email . "\n";
		}
	
		close (LOG);
		return 1; 
	}else{ 
		return 0;
	}
}




sub report_by_message_index {
    my $self          = shift;
    my $sorted_report = [];
    my $report        = {};
    my $l;

# DEV: I would sor to of like to make some validation that the info
# we're using to count is actually correct - like if it's a message_id - it's all numerical, etc
# I'd also like to make some sort of pagination scheme, so that we only have a few message_id's
# we're interested in. That shouldn't be too difficult.

    if ( -e $self->clickthrough_log_location ) {
        open( LOG,
            '<:encoding(' . $DADA::Config::HTML_CHARSET . ')',
            $self->clickthrough_log_location
          )
          or croak "Couldn't open file: '"
          . $self->clickthrough_log_location
          . '\'because: '
          . $!;
        while ( defined( $l = <LOG> ) ) {
            chomp($l);
    		
			my ( $t, $mid, $url, $extra ) = split( "\t", $l, 4 );

            $t     = strip($t);
            $mid   = strip($mid);
            $url   = strip($url);
            $extra = strip($extra);
			
			next if ! $mid;  
			next unless($self->verified_mid($mid)); 
			

			
            if (   $url ne 'open'
                && $url ne 'num_subscribers'
                && $url ne 'bounce'
                && $url ne 'hard_bounce'
                && $url ne 'soft_bounce'
                && $url ne undef )
            {
                $report->{$mid}->{count}++;
            }
            elsif ( $url eq 'open' ) {
                $report->{$mid}->{open}++;
            }
            elsif ( $url eq 'soft_bounce' ) {
                $report->{$mid}->{soft_bounce}++;
            }
            elsif ( $url eq 'hard_bounce' || $url eq 'bounce') {

                $report->{$mid}->{hard_bounce}++;

            }
            elsif ( $url eq 'num_subscribers' ) {				
                $report->{$mid}->{num_subscribers} = $extra;
            }
			else { 
				# warn "What? url:'$url', extra:$extra";
			}

            #$report->{$mid}->{date} =
            #DADA::App::Guts::date_this(
            #    -Packed_Date => $mid,
            #);

            #$unsorted_report->{$mid} = $i_report;

        }
        close(LOG);

        require DADA::MailingList::Archives;
        my $mja =
          DADA::MailingList::Archives->new( { -list => $self->{name} } );

        # Now, sorted:
        for ( sort { $b <=> $a } keys %$report ) {
            $report->{$_}->{mid} = $_;
            $report->{$_}->{date} = DADA::App::Guts::date_this( -Packed_Date => $_, );
            

              if ( $mja->check_if_entry_exists($_) ) {
                $report->{$_}->{message_subject} = $mja->get_archive_subject($_)
                  || $_;
            }
            else {
            }


            push( @$sorted_report, $report->{$_} );
        }

        return $sorted_report;
    }
}


sub report_by_message {
	 
	my $self      = shift; 
	my $match_mid = shift; 
	
	my $report = {}; 
	my $l;
	open(LOG, '<:encoding(' . $DADA::Config::HTML_CHARSET . ')', $self->clickthrough_log_location)
		or croak "Couldn't open file: '" . $self->clickthrough_log_location . '\'because: ' .  $!;
	while(defined($l = <LOG>)){ 
		chomp($l); 
		
		my ($t, $mid, $url, $extra) = split("\t", $l, 4); 
			
		$t     = strip($t); 
		$mid   = strip($mid); 
		$url   = strip($url); 
		$extra = strip($extra); 
					
		if($match_mid eq $mid){ 
		
			if($url ne 'open' && 
			   $url ne 'num_subscribers' && 
			   $url ne 'bounce' && 
			   $url ne 'soft_bounce' && 
			   $url ne 'hard_bounce' && 
			   $url ne undef){
				$report->{$url}->{count}++; #?!
			}elsif($url eq 'open'){ 	
			
				$report->{'open'}++;
				
			}elsif($url eq 'num_subscribers'){ 
			
				$report->{'num_subscribers'} = $extra;	
				
			}elsif($url eq 'soft_bounce'){ 	
			
				push(@{$report->{'soft_bounce_report'}}, {email => $extra, timestamp => $t});

			}elsif($url eq 'hard_bounce'){ 	

					push(@{$report->{'hard_bounce_report'}}, {email => $extra, timestamp => $t});

			}	
		}		
	}
	close(LOG); 
	
	my $url_report = [];

    for ( sort keys %$report ) {

        next
          if ( $_ eq 'open'
            || $_ eq 'num_subscribers'
            || $_ eq 'bounce'
			|| $_ eq 'soft_bounce'
            || $_ eq 'hard_bounce'
            || $_ eq undef );

        push( @$url_report, { url => $_, count => $report->{$_}->{count} } );
    }
	$report->{url_report} = $url_report; 
	
    my $num_bounces = 0;
    if ( $report->{bounce} ) {
        $num_bounces = $#{ $report->{bounce} } + 1;
    }
	$report->{num_bounces} = $num_bounces; 

	return $report; 
}


sub export_logs { 

	my $self = shift; 
	my $type = shift; 
	my $fh   = shift || \*STDOUT; 
	
	my $l; 
	
	unless(-e $self->clickthrough_log_location){ 
		print '';
		return; 
	}
	
	require   Text::CSV; 
	my $csv = Text::CSV->new($DADA::Config::TEXT_CSV_PARAMS);
	open(LOG, '<:encoding(' . $DADA::Config::HTML_CHARSET . ')', $self->clickthrough_log_location)
		or croak "Couldn't open file: '" . $self->clickthrough_log_location . '\'because: ' .  $!;
	while(defined($l = <LOG>)){ 
		chomp($l);
		my @fields = split(/\t/, $l);
		my $url = $fields[2]; 
		
		my $log_line_type = 'activity'; 
		
		if (   $url ne 'open'
            && $url ne 'num_subscribers'
            && $url ne 'bounce'
            && $url ne 'hard_bounce'
            && $url ne 'soft_bounce'
            && $url ne undef ){
		
				$log_line_type = 'clickthrough'; 
		
		}
		
		if($type eq 'clickthrough' && $log_line_type eq 'clickthrough'){ 
			my $status = $csv->print ($fh, [@fields]);
			print $fh "\n";
		}
		elsif($type eq 'activity' && $log_line_type eq 'activity' ) { 
			my $status = $csv->print ($fh, [@fields]);
			print $fh "\n";
		}
	}
}

1;

=pod

=head1 NAME

DADA::MailingList::Clickthrough::Db

=head1 VERSION

Fill me in!
 
=head1 SYNOPSIS

Fill me in!

=head1 DESCRIPTION

Fill me in !
 
=head1 SUBROUTINES/METHODS 

Fill me in!

=head1 DIAGNOSTICS

Fill me in!

=head1 CONFIGURATION AND ENVIRONMENT

Fill me in!

=head1 DEPENDENCIES


Fill me in!


=head1 INCOMPATIBILITIES

Fill me in!

=head1 BUGS AND LIMITATIONS

Fill me in!

=head1 AUTHOR

Fill me in!

=head1 LICENCE AND COPYRIGHT

Fill me in!

=cut

