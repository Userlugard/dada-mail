#!/usr/bin/perl
use strict;

use FindBin;
use lib "$FindBin::Bin/../";
use lib "$FindBin::Bin/../DADA/perllib";
BEGIN { 
	my $b__dir = ( getpwuid($>) )[7].'/perl';
    push @INC,$b__dir.'5/lib/perl5',$b__dir.'5/lib/perl5/x86_64-linux-thread-multi',$b__dir.'lib',map { $b__dir . $_ } @INC;
}

use CGI::Carp qw(fatalsToBrowser);

# use some of those Modules
use DADA::Config qw(!:DEFAULT);
use DADA::Template::HTML;
use DADA::App::Guts;
use DADA::MailingList::Settings;

# we need this for cookies things
use CGI;
my $q = new CGI;
   $q->charset($DADA::Config::HTML_CHARSET);
   $q = decode_cgi_obj($q);

# This will take care of all our security woes
my ( $admin_list, $root_login, $checksout, $error_msg ) = check_list_security(
    -cgi_obj  => $q,
    -Function => 'view_list_settings'
);

my $list = $admin_list;

# get the list information
my $ls = DADA::MailingList::Settings->new( { -list => $list } );
my $li = $ls->get;

my $tmpl = template();

require DADA::Template::Widgets;
my $scrn = DADA::Template::Widgets::wrap_screen(
    {
        -data                     => \$tmpl,
		-with           => 'admin', 
		-wrapper_params => { 
			-Root_Login => $root_login,
			-List       => $list,  
		},
        -list_settings_vars_param => { -list => $list, -in_order => 1, i_know_what_im_doing => 1 },
    }
);
e_print($scrn); 

sub template {

    return q{ 
    
	<!-- tmpl_set name="title" value="Plugins &#187; View List Settings" -->
    <!-- tmpl_loop list_settings --> 
    
        <p> 
         <strong> 
          <!-- tmpl_var name --> 
         </strong> 
        </p> 
        
        <pre><!-- tmpl_var value escape="HTML" --></pre> 
        
        <hr /> 
    <!-- /tmpl_loop --> 
    
    };

}
__END__

=pod

=head1 View List Settings 

This plugin allows you to view what ALL your list settings are set to

=head2  $ADMIN_MENU ENTRY

	 {-Title      => 'View List Settings', 
	  -Title_URL  => "plugins/view_list_settings.cgi",
	  -Function   => 'view_list_settings',
	  -Activated  => 1, 
	  },

=cut


=pod

=head1 COPYRIGHT 

Copyright (c) 1999 - 2015 Justin Simoni All rights reserved. 

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, 
Boston, MA  02111-1307, USA.

=cut 


