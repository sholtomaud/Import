
package Import::Mergify;
use Moose;
use JSON;
use DBI;
use Env;
use FindBin qw($Bin);
use File::Basename;
use Text::CSV_XS;
use Try::Tiny;

use local::lib "$Bin";
use Data::Dumper;
use Time::Local;
use Hydstra;
use Import::fs;

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Merge data from Many systems into a temporary SQLite.db and then export as HYCPLIPIN (or some other format) for import into a system.
Could use a HYDB.pm import routine, or the SQL rubbish which Damian has used, or HYDBUTIL.
     
=cut

 my $counter = 0;
 my $default_source_dir = $Bin.'/dbf_source/';
 my $default_base_dir = $Bin.'/dbf_base/';
 my $defaultdb_dir = $Bin.'\\db';
 
 has 'source_dir' => ( is => 'ro', isa => 'Str', required => 1, default => $default_source_dir); 
 has 'base_dir' => ( is => 'ro', isa => 'Str', required => 1, default => $default_base_dir); 
 
 has 'tempdb_dir' => ( is => 'rw', isa => 'Str', required => 1, default => $defaultdb_dir); 
 has 'base_db_file' => ( is => 'rw', isa => 'Str', required => 1, default => 'mergify.db'); 
 has 'import_dir' => ( is => 'rw', isa => 'Str'); 
  
  
=head1 EXPORTS

  * merge()

=head1 SUBROUTINES/METHODS

=head2 SUCCESS
  
  Constant used for logging the success status of the module at any step

=cut

 use constant SUCCESS => 1;
 
=head2 FAIL
  
  Constant used for logging the fail status of the module at any step

=cut

 use constant FAIL    => 0;


=head2 merge_hydbutil_export_formatted_csv()

Merge two systems
  merge_hydbutil_export_formatted_csv() 
  
  Example:
  
  my $merge = Import::Mergify->new({'base_db_file'=>$junk_db});
  $merge->merge_hydbutil_export_formatted_csv({'source_files'=>\@src_files,'variable_mappings'=>$var_mappings->{mappings}});
  
=cut



sub merge_hydbutil_export_formatted_csv {
  my $self = shift;
  my $base_db = $self->base_db_file;
  my @source_files = @{$_[0]->{source_files}};
  my %mappings = %{$_[0]->{variable_mappings}};
  my %tables = %{$_[0]->{tables}};

  
  #my @source_files = $_[1];
  
  print "source_files \n".Dumper(@source_files);
  
  my $hydbh = DBI->connect(          
      "dbi:SQLite:dbname=$base_db", 
      "",                          
      "",                          
      { RaiseError => 1, AutoCommit => 0},         
  ) or die $DBI::errstr;
  
  my $fs = Import::fs->new();
  my $exec_rep_file = "C:\\temp\\exec_report.txt";
  my $commit_file = "C:\\temp\\report.txt";
  unlink ($commit_file);
  unlink ($exec_rep_file);
  open my $rep, ">>", $commit_file;
  open my $exec_rep, ">>", $exec_rep_file;
  print $rep Dumper($_).'\n';
  
  foreach ( @source_files ){
    my $table = $fs->TableName($_);
    my $module = ucfirst(lc($table));
    my $hytable = "Hydstra::$module";
    
    my %transform_config = %{$tables{lc($table)}};

    print "module [$module]\n";
    my $hyt = $hytable->new();
    
    my $varsetup;
    
    eval{
      $varsetup = $hytable->variable;
    };
    if ($@) {
      warn $@; # print the error
      print "No variable setup for [$module] [".Dumper($@)."]\n";
    }

    my $create = $hytable->create;
    my $prepare = $hytable->prepare;
    #$prepare =~ s{IGNORE}{ABORT}ig;
    my $sth = $hydbh->prepare($prepare);
        
    my $csv = Text::CSV_XS->new ({ 
      sep_char => ',', 
      escape_char => '', 
      quote_char =>'', 
      allow_loose_quotes =>1 , 
      always_quote =>1 
    });
  
    open my $io, "<:encoding(utf8)", $_;
    my $count = 0;
    #print $rep "Hello World";
    while (my $row = $csv->getline ($io)) {
      $count++;
      my @row_array = @{$row}; 
      
      #my $cleansed_row = check_scientific_notation($row);
      
      #check for scientific notation
      foreach my $col ( 0 .. $#row_array ){
        if ( $row_array[$col] =~ m{(e+|e-)}){
          $row_array[$col] = sprintf("%.8g", $row_array[$col]);
        }
      }

      if ( $varsetup->{variables} ){
        foreach my $table_variable_field ( keys %{$varsetup} ){
          if ( $table_variable_field->{combined} ){
            my $varcol = $table_variable_field->{column};
            my ($var,$subvar) = split('\.',$row_array[$varcol]);
            if ( defined $mappings{$var} ){
              $row_array[$varcol] = $mappings{$var}.'.'.$subvar;
            }
            
          }
          else{
            my $varcol = $table_variable_field->{column};
            my $var = $row_array[$varcol];
            if ( defined $mappings{$var} ){
              $row_array[$varcol] = $mappings{$var};
            }
          }
        }

=skip
        if ( $varsetup->{combined_variable} ){
          my $varcol = $varsetup->{variable_column};
          my ($var,$subvar) = split('\.',$row_array[$varcol]);
          
          if ( defined $mappings{$var} ){
            $row_array[$varcol] = $mappings{$var}.'.'.$subvar;
          }
          
        }
        elsif( defined ( $varsetup->{varfrom_column} ) ){
          my $varfrom_col = $varsetup->{varfrom_column};
          my $varto_col = $varsetup->{varto_column};
          
          my $varfrom = $row_array[$varfrom_col];
          my $varto = $row_array[$varto_col];
          
          if ( defined $mappings{$varfrom} ){
            $row_array[$varfrom_col] = $mappings{$varfrom};
          }
          
          if ( defined $mappings{$varto} ){
            $row_array[$varto_col] = $mappings{$varto};
          }
          
        }
        else{
          my $varcol = $varsetup->{variable_column};
          my $var = $row_array[$varcol];
          
          if ( defined $mappings{$var} ){
            $row_array[$varcol] = $mappings{$var};
          }
        }
=cut        
      }
      
      eval{
        $sth->execute(@row_array); # or die $sth->errstr;
      };
      if ($@) {
        warn $@; # print the error
        print $exec_rep "Execute Error: File [$_], Row [$count], Row Values [".Dumper(@{$row})."]\ndollar@ [".Dumper($@)."]\n";
      }
      
    } 
    
      eval{
        $hydbh->commit;
      };
      if ($@) {
        #warn $@; # print the error
        print $rep "Commit Error: File [$@]\n";
   
        #table check (each table has a different rule associated with it)
        #need to test the value and precision is appropriate
        
=skip        
        my @keys = $hytable->keys;
        
        #assemble the SQL statement 
        my $sql_stement = "SELECT * FROM $table where ";
        my @row_array = @{$row};
        #assemble the where statement 
        foreach my $key_col ( 0 .. $#keys ){
          $sql_stement .= qq{$keys[$key_col] = '$row_array[$key_col]' and};
        }
        $sql_stement =~ s{and$}{}i;
        print $rep "$sql_stement\n";
=cut        
        #my $st = $sth->prepare($sql_stement);
        #$st->execute();

        #if ( ! a_full_duplicate() ){
          #create_a_new_record();
        #}
        #else{
        #  next;
        #}
        
        
        
        #select * where the approrpriate record from the SQLite.db 
        #foreach $column (keys $table_config{$table}){
        # get the column name for the colo  SELECT Name, Price FROM Cars;
        # check the ${$row}[$column] 
        # select 
        #}
     
      }
      print "Importing table [$table] row [$count]    \r";
    
    
    

    close($io);
    close($rep);
  }
  return 1;
}

=head2 combine_variable_tables()

Combine the variable tables with the base table

=cut 

sub combine_variable_tables{
  my $self = shift;
  my %source_files = %{$_[0]->{source_files}};
  my %tables = %{$_[0]->{tables}};
  my %system_var_mapping =();
  my %return_hash = ();
  #print "source files\n[";
  #print Dumper($_[0]);
  #print "] source files\n";
  #print $source_files{base};
  #print "Done \n";
  my %return;

  if ( !defined $tables{variable} ){
    my $msg = "Variable table not defined in INI file.";
    my $script_action = "Script stopped.";
    my $user_action = "Please make sure the variable table is defined in your INI file.";
    $return_hash{error}{msg} = $msg;
    $return_hash{error}{script_action} = $script_action;
    $return_hash{error}{user_action} = $user_action;
    #errorLog(\%return_hash);
    return \%return_hash;
  }

  foreach ( keys %source_files){
    print " source [$_] file $source_files{$_}\n";
  }
  
  my $hytable = "Hydstra::Variable";
  my @keys = $hytable->keys;
  my $cols = $hytable->ordered_fields;
  #print "cols [".Dumper($cols)."]\n";
  
  my $csv = Text::CSV_XS->new ({ 
      sep_char => ',', 
      escape_char => '', 
      quote_char =>'', 
      allow_loose_quotes =>1 , 
      always_quote =>1 
    });

    #print $rep "Hello World";
  
  my %variables;
  
  my $base_system_file = $source_files{base};
  open my $io, "<:encoding(utf8)", $base_system_file;
  my $count = 0;
  
  
  while (my $row = $csv->getline ($io)) {
    my @row_array = @{$row};
    my $variable = $row_array[0];
    #print "variables \n";
    #print "$row_array[0]\n";
    #my %rower = ();
    
    #foreach my $col ( 0 .. $#{$cols}){
    #  $rower{$$cols[$col]} = $row_array[$col];
    #}
    $variables{$variable} = $row;
    #print "row [".Dumper(\%row)."]\n";
  }
  
  #print Dumper(\%variables);
  print "variables \n";
  
  foreach ( %variables){
    #print "variable [$_] values [".Dumper(\%{$variables{$_}})."]\n";
  }
  
  #1. Add any non-existing variables to the variable hash
  #2. Now go and check whether the existing variable numbers have the same variable name - if not report to file.
  
  #variable  =   { "keys": [{ "field":"varnum", "action":"increment", "value":1, "combined_var":"prefix","subordinates":[{"table":"wqvar","field":"variable"},{"table":"varsub","field":"variable"},{"table":"varcon"},{"table":"results"},{"table":"hydmeas","field":"variable"},{"table":"gwtrace","field":"variable"}] }] }

  
  foreach my $system ( keys %source_files ){
    next if $system eq 'base';
    
    my $system_output_file = 'C:\\temp\\'.$system.'.txt';
    unlink ($system_output_file);
    open my $sof, ">:encoding(utf8)", $system_output_file;
    
    open my $io, "<:encoding(utf8)", $source_files{$system};
    my $count = 0;
  
        print $sof "\nVARIABLE CHECK\n"; 
    while ( my $row = $csv->getline ($io) ) {
      my @row_array = @{$row};
      my $variable = $row_array[0];
      if ( !defined ( $variables{$row_array[0]} )){
        $variables{$variable} = $row;
      }
      else{
        #check the var name 
        my @col_check = (2,3,5,6,7,8);
        
        my $clash = 0;
            
        foreach my $colum_to_check ( @col_check ){
          if ( $variables{$row_array[0]}[$colum_to_check] ne $row_array[$colum_to_check] ){
            #print $sof "variable clash [ $row_array[0] ]\nBASE [$variables{$row_array[0]}[$colum_to_check]] $system [$row_array[$colum_to_check]] \n"; 
            $clash++;
          }
        } 
        
        #get next free variable
        if ( $clash > 0 ){
          my $counter = 0;
          my $free_variable = free_variable_search(\%variables);
          #print $sof "found a class for [$variable] free variable [$free_variable]\n"; 
          $row_array[0] = $free_variable;
          $system_var_mapping{$system}{$variable} = $free_variable;
          $variables{$free_variable} = \@row_array;
        }
      }
    }
  }
  
  
  my $var_file = 'C:\\temp\\variable_file.txt';
  unlink ($var_file);
  open my $vof, ">:encoding(utf8)", $var_file;
  #print $vof "Variables ".Dumper(\%variables);
  close ($vof);
  
  
  
  $return_hash{data} = \%variables;
  $return_hash{mappings} = \%system_var_mapping;
  #print "return hash\n";
  #print Dumper(%return_hash);
  #print "end return hash";
  
  #return \%system_var_mapping;  
  return \%return_hash;  
}

 
=head2 free_variable_search()

Search for a free variable.

=cut 

sub free_variable_search{
  my %vars = %{$_[0]};
  my $varno;
  foreach my $vacant_var_counter ( 300 .. 9999 ) {
    if ( ! defined ( $vars{$vacant_var_counter } ) ){
      $varno = $vacant_var_counter;
      last;
    }
    else{
      $varno = 0;
    }
  }
  return $varno;
}

  
=head2 create_a_new_record()

Keep a log of all the previous lookups.

=cut 

sub create_a_new_record{

} 
 
=head2 a_full_duplicate()
  
Check whether the record is a full duplicate or not.

I.e. A record can have a duplicate key (which gets picked up from the commit statement)
however the actual values of the record may be different. 

If there is a dupliate key and the values of the record are the same, then you can discard the recrod from the other system database becasue they are the same
However if there is a duplicate key, and the values of the record are different, then you want to keep the record,  

=cut 

sub a_full_duplicate{
=skip  
  my $rw;
  my $check = 0;
  while ($rw = $st->fetchrow_arrayref()) {
      #$table_check_columns{}
      #if (@$rw[0] &&  ) 
      #print "@$rw[0] @$rw[1] @$rw[2]\n";
      
      foreach $column_no ( keys %table_check_columns ){
        $check = ( $table_check_columns{$column_no} eq @$rw[$column_no] ) 1 : 0;
      }
  }
  $st->finish();  
  return $check;
=cut
}


=head2 try_import()
  
Try to import into the SQLite.db


=cut 



sub try_import{

=skip   
  eval {
    $sth->execute();
    
  };
  if ($@) {
    # $sth->err and $DBI::err will be true if error was from DBI
    warn $@; # print the error
    increment({table=>$hytable,row=>@row});
    #... # do whatever you need to deal with the error
  }
  else{
  
    print "  create [$create] prepare [$prepare]\n";
    my @rw = split(',',$prepare);
    my @row;
    push (@row,'') for @rw;
    $hydbh->do($create);
  
  }
  
  return 1;
=cut
}

 
 
 
 
=head2 track_changes()
  
Track the changes made to the current table in the form of old VARNUM=new VARNUM
This needs to be cascaded through all the variable tables, so we need to know which field we are dealing with, and the table, and whether to change it.
col_no.

=cut 

sub track_changes{
}

=head2 increment()
  
Increment the appropriate column number by 1, and redo the import until you find a number which will suit

=cut 

sub increment{
  
  $counter++;
=skip  
  foreach ( @precedence ){
    if ( $_[0]=>table eq $_=>table ){
      
    }
    else{
      next;
    } 
    
  }
  
  try{
    import();
  }
  catch{
    increment();
  }
=cut
  
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
