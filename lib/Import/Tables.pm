
package Import::Tables;
use Moose;
use JSON::XS;
use Env;
use File::Basename;
use Try::Tiny;
use Data::Dumper;
use Time::Local;
use FindBin qw($Bin);

use local::lib "$Bin";

=head1 VERSION

Version 1.01

=cut

our $VERSION = '1.01';

=head1 SYNOPSIS

Munge INI

=cut

# has 'source_dir' => ( is => 'ro', isa => 'Str', required => 1, default => $default_source_dir); 
# has 'base_dir' => ( is => 'ro', isa => 'Str', required => 1, default => $default_base_dir); 
 
# has 'tempdb_dir' => ( is => 'rw', isa => 'Str', required => 1, default => $defaultdb_dir); 
# has 'base_db_file' => ( is => 'rw', isa => 'Str', required => 1, default => 'mergify.db'); 
# has 'import_dir' => ( is => 'rw', isa => 'Str'); 
  
  
=head1 EXPORTS

  * get_tables_hash()

=head1 SUBROUTINES/METHODS

=head2 SUCCESS
  
  Constant used for logging the success status of the module at any step

=cut

 use constant SUCCESS => 1;
 
=head2 FAIL
  
  Constant used for logging the fail status of the module at any step

=cut

 use constant FAIL    => 0;


=head2 get_tables_hash()

Get the tables from INI file.
  Example:
  
  my $im = Import::Tables->new();
  $im->get_tables_hash({'merge_tables'=>$ini{'merge_tables'}});
  
=cut


sub get_tables_hash {
  my $self = shift;
  #my $merge_tables = $self->merge_tables;
  my $mt = $_[0]->{merge_tables};
  my %merge_tables = %{$mt};
  my %tables;

  foreach my $table ( keys %merge_tables ){
    my $config =  $merge_tables{$table};
    my $decoded;
    
    if ( $config == 1 || $config eq 'default' ){
      $tables{$table}++;
    }
    else{
      try {
          $decoded = JSON::XS::decode_json($config);
          $tables{$table} = $decoded;     
      }
      catch {
          warn "Caught JSON::XS decode error: $_";
          print "trouble with decoding INI file for [$table]";
      };

    
      foreach my $key ( @{$tables{$table}->{keys} } ){
        
        next if !defined $key->{subordinates};

        foreach my $sub ( @{ $key->{subordinates} } ){

          my %keyfield = ();
          my $subtable = $sub->{table};               
          $keyfield{field} = $sub->{field}//$key->{field};    #Default to parent table field if not explicitly stated
          $keyfield{action} = $key->{action};
          $keyfield{value} = $key->{value};
          (defined  $key->{combined_var} )? $keyfield{combined_var} = $key->{combined_var} : print "no combined var \n" ;
          
          my @keys = ( defined $tables{$subtable}{keys} )? @{$tables{$subtable}{keys}} : ();
          push(@keys,\%keyfield);
          $tables{$subtable}{keys} = \@keys;
        
        }
      }
    }  
  }
  return %tables;
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

1; # End of Import
