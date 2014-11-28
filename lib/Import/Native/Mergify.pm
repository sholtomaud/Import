
package Import;
use Moose;
use DBI;
use JSON;
use DateTime;
use Env;
use FindBin qw($Bin);
use File::Copy;
#use Logger;
use Try::Tiny;


=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Merge data from Many systems
     
=cut

 my $default_source_dir = $Bin.'/dbf_source/';
 my $default_base_dir = $Bin.'/dbf_base/';
 my $defaultdb_dir = $Bin.'\\db';
 
 has 'source_dir' => ( is => 'ro', isa => 'Str', required => 1, default => $default_source_dir); 
 has 'base_dir' => ( is => 'ro', isa => 'Str', required => 1, default => $default_base_dir); 
 
 has 'tempdb_dir' => ( is => 'rw', isa => 'Str', required => 1, default => $defaultdb_dir); 
 has 'tempdb' => ( is => 'rw', isa => 'Str', required => 1, default => 'GWDB.db'); 
 has 'import_dir' => ( is => 'rw', isa => 'Str'); 
  
  
=head1 EXPORTS

  * tables()
  * FileList()

=head1 SUBROUTINES/METHODS

=head2 SUCCESS
  
  Constant used for logging the success status of the module at any step

=cut

 use constant SUCCESS => 1;
 
=head2 FAIL
  
  Constant used for logging the fail status of the module at any step

=cut

 use constant FAIL    => 0;

 
 
=head2 CheckHeaders()

Check the Headers of foreign db.txt files are as expected
  
=cut


sub file_list {
  
  my $self = shift;
  my $d = $self->import_dir;
  opendir(D, "$d") || die "Can't open directory $d: $!\n";
  my @list = readdir(D);
  closedir(D);
  
  #return 0 if (! );
  
  return 1;
}
 

=head2 tables()
  
Return hashref of all the Hydstra tables in the configuration files

=cut 

 sub tables{
    my $self = shift;
    my $config_dir = $self->config_dir;
    #my $config_dir = $self->config_dir;
    #my $db_file_name = $self->db_file_name;
    
    print "config_dir  [$config_dir]\n";
    my @files = <$config_dir/*.json>;
    
    my %tables;
    my %hytables;
    my @hytables;
    $tables{config_dir} = $config_dir;
    foreach my $file (@files) {
      print "file name [$file]\n";
      my @filename = split ('/',$file);
      my ($filename,$fileext) = split (/\./,$filename[$#filename]);
    
    #opendir(DIR, $config_dir) or die $!;

    #while (my $file = readdir(DIR)) {
      
      my $import = Import::Config->new(
        'config_dir'=>$self->config_dir,
        'db_file_name'=>uc($filename)
      );
      
      my $config = $import->config;
      #$tables{$filename} = $config;
      
      #$tables{$_->{foreign_field}}++ for @{$config->{elements}};
      #$tables{$_->{foreign_field}}++ for @{$config->{elements}};
      
      foreach my $element ( @{$config->{elements}} ){
        my $mappings = $element->{hydstra_mappings};
        #$hytables{$filename}{foreign_field}{$element->{foreign_field}}++; 
        #$hytables{$filename}{mappings}= $mappings; 
        foreach my $mapping ( @{$mappings} ){
          #$hytables{tables}{$mapping->{table}}{$mapping->{field}}++;
          $hytables{$mapping->{table}}++;
        }
      }
      
      
      
      
=skip      
      
      my %foreign_fields;
      
      print "Fields [".$_->{foreign_field}."]\n" for @{$config->{elements}};
=cut      
    }
    push (@hytables,$_) for keys \%hytables;
    #return \%tables; #\%foreign_fields;
    return \@hytables; #\%foreign_fields;
}

=head2 FileList()

Return an array of files
  
=cut

sub FileList{
  my $self = shift;
  my $d = $self->import_dir;
  opendir(D, "$d") || die "Can't open directory $d: $!\n";
  my @list = readdir(D);
  closedir(D);
  return @list;
}

=head2 CheckHeaders()

Check the Headers of foreign db.txt files are as expected
  
=cut

sub checkHeaders{
  
  my $self = shift;
  my $d = $self->import_dir;
  opendir(D, "$d") || die "Can't open directory $d: $!\n";
  my @list = readdir(D);
  closedir(D);
  
  #return 0 if (! );
  
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

1; # End of Import
