
package Import::Config;
use Moose;
use JSON;
use Env;
use FindBin qw($Bin);
use Hydstra;
use Try::Tiny;

#extends 'Import';

=head1 Import::Config

Import configuration files 

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Use this module to import configuration files

Code snippet.

  use Import::Config;
  
  my $config = Import::Config->new( 
   
  );

  
     
=cut

=head2 SUCCESS
  
  Constant used for logging the success status of the module at any step

=cut

 use constant SUCCESS => 1;
 
=head2 FAIL
  
  Constant used for logging the fail status of the module at any step

=cut

 use constant FAIL    => 0;
 
 has 'config_dir' => ( is => 'ro', isa => 'Str'); 
 has 'db_file_name' => ( is => 'ro', isa => 'Str', required => 1); 

=head1 EXPORTS

  * config()
  
=head1 SUBROUTINES/METHODS

=head2 config()
  
 Return the config for a particular table

=cut 

 sub config{
    my $self = shift;
    
    my $config_dir = $self->config_dir;
    my $db_file_name = $self->db_file_name;
    
    my $config_file = $self->config_dir.$self->db_file_name.'.json';
    print "importing table config file [$config_file]\n";
    
    my $json;
    {
      local $/; #Enable 'slurp' mode
      my $fh;
      try{
        open $fh, "<", lc($config_file) or die print "couldn't open config file [$config_file]\n";
        $json = <$fh>;
        close $fh;
        my $data = decode_json($json);
        return $data;
      }
      catch{
        print "issue opening [$_]\n";
        return 0;
      }

    };
 }

=head2 hydstra_tables()
  
 Return the hydstra tables for a foriegn table

=cut 

 sub hydstra_tables{
    my $self = shift;
    my $config = shift;
    my (@mappings,@tables,%tables);
    push ( @mappings, $_->{hydstra_mappings} ) for @{$config->{elements}};
    foreach my $mapping( @mappings ){
      $tables{$_->{table}}++ for @{$mapping};   
    }
    push (@tables, $_) for (keys %tables);
    return \@tables;
 }
 
=head2 mapping()
  
 Takes a Hydstra field, and returns the foriegn field (assumes 
 
=cut 

 sub mapping{
    my $self = shift;
    my $config = shift;
    my $field = shift;
    #my $field = $params->{hydstra_field};
    #my $config = $params->{config};
    
    my (@mappings,%fields,%mapping);
    $fields{$_->{foreign_field}} = \@{$_->{hydstra_mappings}} for @{$config->{elements}};
    
    foreach my $foreign_field ( keys %fields ){
      foreach (@{$fields{$foreign_field}}){
        $mapping{$_->{field}} = $foreign_field;
      }
    }
    
    my $mapped_field = $mapping{$field};
    return $mapped_field;
 } 
 
=head2 table_field_mapping()
  
 Takes a foreign field, and Hydstra  table and returns the hydstra field
 E.g. table_field_mapping($config,lc($foreign_field),lc($hydstra_table) )
 
=cut 

 sub table_field_mapping{
    my $self = shift;
    my $config = shift;
    my $foreign_field = shift;
    my $hydstra_table = shift;
    
    $foreign_field =~ s{\s}{_}ig;
    
    my (@mappings,%fields);
    my %mapping =();
    
    for ( @{$config->{elements}} ){
      next if ( !defined  $_->{hydstra_mappings} );
      $fields{ $_->{foreign_field} } = \@{$_->{hydstra_mappings}};
    }
    
    #$fields{ $_->{foreign_field} } = \@{$_->{hydstra_mappings}} for @{$config->{elements}};
            
    foreach my $ff ( keys %fields ){
      foreach (@{$fields{$ff}}){
        #$mapping{}{hydstra_table} = hydstra_field;
        $mapping{lc( $ff ) }{lc( $_->{table} ) }{ lc($_->{field}) }++;
      }
    }
    
    if ( defined $mapping{lc( $foreign_field) }{lc ( $hydstra_table ) } ){
      my $mapped_fields;
      %{$mapped_fields} = %{$mapping{$foreign_field}{$hydstra_table}};
      return $mapped_fields;
    }
    else{
      return;
    }
 }  
 
=head2 value()
  
 Return a field value which has been set in the config file
 
=cut 

 sub value{
    my $self = shift;
    my $config = shift;
    my $field = shift;
    #my $field = $params->{field};
    
    my (@mappings,%fields_with_value_defined);
    push ( @mappings, $_->{hydstra_mappings} ) for @{$config->{elements}};
    
    foreach my $mapping( @mappings ){
      foreach (@{$mapping}){
        if ( defined $_->{value} ){
          $fields_with_value_defined{$_->{field}} = $_->{value};   
        }  
      }
    }
    
    if ( defined ( $fields_with_value_defined{$field} ) ){
      my $value = $fields_with_value_defined{$field};
      return $value;
    }
    else{
      return;
    }
    
 } 
 
=head2 lookup_value()
  
 Return a value from a lookup hash which has been set in the config file
 
=cut 

 sub lookup_value{
    my $self = shift;
    my $config = shift;
    my $field = shift;
    my $lookup_value = shift;
    
    my (@mappings,@tables,%value_mappings);
    
    push ( @mappings, $_->{hydstra_mappings} ) for @{$config->{elements}};
    
    foreach my $mapping( @mappings ){
      foreach (@{$mapping}){
        if ( defined $_->{value_mappings} ){
          $value_mappings{ lc($_->{field}) } = $_->{value_mappings} ;   
        }
        #else {
        #  my $return = 'not defined $_->{value_mappings}';
        #  return $mapping;
        #}
      }
    }
    #my $value = $value_mappings{lc($field)}{lc($lookup_value)}
    my $value = (defined $value_mappings{lc($field)} )? $value_mappings{lc($field)}{lc($lookup_value)}//"lookup [$lookup_value] does not exist but should!!!!": return;
#    my $value = $lookups->;
    #//'';
    #return;
    return $value;
 }
 
 
 
 
 no Moose;
 
 
=head1 AUTHOR

Sholto Maud, C<< <sholto.maud at gmail.com> >>

=head1 BUGS

Please report any bugs in the issues wiki.


=head1 SUPPORT

You can find documentation for this module on the Git repo

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

1; # End of Config

 