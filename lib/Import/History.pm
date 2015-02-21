
package Import::History;

use Moose;
use DBI;
use JSON;
use DateTime;
use Env;
use FindBin qw($Bin);
use File::Copy;
#use Logger;
#use Import::Config;
use Try::Tiny;

use HyDB;


=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Generic import of data to History table
     
=cut
  
=head1 EXPORTS

  * import()

=head1 SUBROUTINES/METHODS

=head2 SUCCESS
  
  Constant used for logging the success status of the module at any step

=cut

 use constant SUCCESS => 1;
 
=head2 FAIL
  
  Constant used for logging the fail status of the module at any step

=cut

 use constant FAIL    => 0;


=head2 update()
  
Import hashref to the HISTORY table

=cut 

 sub update{
    my $self = shift;
    #my %mappings = %{$_[0]->{variable_mappings}};
    my %history   = %{$_[0]->{history}};
    my %params     = %{$_[0]->{params}};
    
    my $workarea  = '[priv.histupd]';
    
    my $rep = 'C:\\temp\\historyreport.txt';
    open my $io, '>', $rep;
    
    my $hydb = HyDB->new( 'history', $workarea, { allowdupes => 0, printdest => '-R', errordest => $io } );
    
    foreach my $site( keys %history) { 
      $hydb->sethash( \%{ $history{$site} } );
      $hydb->write();
      $hydb->clear();
    }
    $hydb->close();
    
    close ($rep);
    return 1;
  
}

=head2 base64()
  
Import base64 to the HISTORY table

=cut 

 sub base64{
    my $self = shift;
    #my %mappings = %{$_[0]->{variable_mappings}};
    my %history   = %{$_[0]->{history}};
    my %params     = %{$_[0]->{params}};
    my $workarea  = $_[0]->{workarea};
    
#my $workarea  = '[priv.histupd]';
    
    my $rep = 'C:\\temp\\historyreport.txt';
    open my $io, '>', $rep;
    
    my $hydb = HyDB->new( 'history', '['.$workarea.']', { allowdupes => 0, printdest => '-R', errordest => $io } );
      
    foreach my $site( keys %history) { 
      $hydb->sethash( \%{ $history{$site} } );
      $hydb->write();
      $hydb->clear();
    }
    $hydb->close();
    
    close ($rep);
    return 1;
  
}

    
=head1 AUTHOR

Sholto Maud, C<< <sholto.maud at gmail.com> >>

=head1 BUGS

Please report any bugs in the issues wiki.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Import

=over 4

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Sholto Maud.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of History
