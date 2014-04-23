#!/usr/bin/perl -w
use Test::More tests=>3;
use Logger;
use FindBin qw($Bin);
use lib "$Bin/lib"; 
use Time::Local;
use Import;
use Import::Config;
use DBI;
use Data::Dumper;
use Hydstra;

use constant DB_DIR => 'C:/temp/gwdb'; 
use constant SQL_DIR => $Bin.'/tmp/'; 
use constant SQL_DB => 'gwdb.db'; 
use constant HY_DB => 'hydb.db'; 

  mkdir SQL_DIR  if (! -d SQL_DIR );
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
  my $localtime = sprintf("%04d%02d%02d%02d%02d%02d", $year+1900,$mon+1,$mday,$hour,$min, $sec);
  my $foreign_db = SQL_DIR.'test_'.SQL_DB;
  my $hy_db = SQL_DIR.HY_DB;
  
  unlink ($hy_db);

  #connect to Foreign temporary SQLite db
  my $dbh = DBI->connect(          
      "dbi:SQLite:dbname=$foreign_db", 
      "",                          
      "",                          
      { RaiseError => 1, AutoCommit => 0},         
  ) or die $DBI::errstr;

  ok(defined $dbh, "connected to foreign db ok");
  
  #connect to Hydstra temporary SQLite db
   my $hydbh = DBI->connect(          
      "dbi:SQLite:dbname=$hy_db", 
      "",                          
      "",                          
      { RaiseError => 1, AutoCommit => 0},         
  ) or die $DBI::errstr;
   
  ok(defined $hydbh, "connected to hydb.db db ok");
   
  open my $fh, ">>", 'c:/temp/log.txt';
  print $fh "Connected to both\n";

=skip  
  my $row = $dbh->selectall_arrayref({ Rn=>1} );
  
  Prt($prtdest_scr,NowStr()."    - Printing out data\n");
  foreach my $rw (@$row){
    #{ $_ = '' unless defined }
    print "Station: $rw->{station}\n";
  }
  
  art of sumber [$VAR1 = [
          {
            'Top' => '22.5',
            'Rn' => 65054,
            'Condition' => 'UC'
          },
  
=cut
  
  
  my $importer = Import->new(
        'config_dir'=>$Bin.'/config/'
        #'import_dir'=>$dbdir 
  );
  
  
  
  
  
  #my $foreign_tables = $importer->FileList;
  #my $tables_query = qq { select * from sqlite_master where type='table' };
  my @tth = $dbh->tables(); #prepare($tables_query);
  #my $tables = $tth->execute();
  my %tables;
  foreach my $table (@tth){
    my ($db,$name) = split('\.',$table); #"main"."FORIEGN_AQUIFER"
    $db =~ s{"}{}g;
    $name =~ s{"}{}g;
    #print $fh "table [$table] db [$db] name [$name]\n";
    if ( lc($db) eq 'main' ){
      if ( lc($name) ne 'sqlite_master'){
        $tables{$name}++;
      }
    }
  }
  
  #print $fh "tabl_info [".Dumper(\@tth)."] end of dumper";
  
  my %data = ();
   my $rns_aquifer = 1;
  foreach my $foreign_table ( keys %tables ){
    print $fh "Preparing config for foreign_table [$foreign_table]\n";
    my $db_config_name = substr($foreign_table,8);
    my $import = Import::Config->new(
        'config_dir'=>$Bin.'/config/',
        'db_file_name'=>uc($db_config_name)
    );
    
    my $config = $import->config();
    #print $fh "config [".Dumper($config)."]\n";  
    
    #print $fh "Preparing for foreign_table [$foreign_table]\n";
    my $query = qq{select * from $foreign_table limit 10};
    my $sth = $dbh->prepare($query);
    $sth->execute();
    
    print $fh "Executed query\n";
    
    my $rows_ref = $sth->fetchall_arrayref({});
    #print $fh "foreign_table [$foreign_table] [".Dumper($rns_aquifer)."]\n";  
    my %row;
    
    #$sth->bind_columns( \( @row{ @{$sth->{NAME_lc} } } ));
    #while ($sth->fetch) {
    #    print "foo = $row{foo}, bar = $row{bar}, ni = $row{ni}\n";
    #}
    my %data = ();
    
    #we know the table arlready 
    my $hydstra_tables = $import->hydstra_tables($config);
    
    #print $fh "hydstra tables for foreign_table [$foreign_table] [".Dumper($hydstra_tables)."]\n";  
    
    next if ( $db_config_name =~ m{^(Var|Elev|Spec|Water|Mult).*}i );
    
    foreach my $hydstra_table (@$hydstra_tables){
      my $module = ucfirst($hydstra_table);
      my $hypm = "Hydstra::$module";
      my $table = $hypm->new();
      my $create = $table->create;
      my $prepare = $table->prepare;
      
      #This comes from an export from the table module
      my $ordered_hydstra_fields = $table->ordered_fields;
      print $fh "Hydstra Table [$hydstra_table]\n";
      #print $fh "Ordered fields [\n".Dumper($ordered_hydstra_fields)."]\n";
      $hydbh->do($create);
      
      #my @ordered_hyfields = $config->ordered_hytable_fields($hydstra_table);
      #$config->value('field'=>$_)
      
      
      #foreach (@{$ordered_hydstra_fields}){ 
      #  my $mapped_field = $import->mapping($config,$_)//'ignored';
      #  print $fh "hyfield [$_] mapped_field [$mapped_field]\n";
      #}
      
      foreach $row_ref ( @$rows_ref ) {
        my $hysth = $hydbh->prepare($prepare);
        
        print $fh " row_ref [".Dumper($row_ref)."]\n";
        my %mapped_data = ();
        foreach $foreign_key ( keys %{$row_ref}){
            if ( $row_ref->{$foreign_key} gt ''){
              my $mapped_fields = $import->table_field_mapping($config,lc($foreign_key),lc($hydstra_table) )//next; #"[$foreign_key] undef";
              foreach $mapped_field ( keys %{$mapped_fields} ){
                if ( defined ( $import->value($config,$mapped_field) ) ){
                  $mapped_data{lc($mapped_field)} = $import->value($config,$mapped_field);
                }
                #elsif(){}
                else{
                  $mapped_data{lc($mapped_field)} = $row_ref->{$foreign_key}//'what the?';
                }
              }  
            }
            else{
              next;
            }
        }
        
        #%{$mapped_data{$hydstra_table}} = map { $import->table_field_mapping($config,$_,$hydstra_table)  } keys %{$row_ref};
        print $fh " mapped_data [".Dumper(\%mapped_data)."]\n";
        my @row = map { $mapped_data{$_}//'' } @$ordered_hydstra_fields;
=skip        
        my @row = map { 
          if ( defined ( $import->value($config,$_) ) ){
            $import->value($config,$_);
          }
          elsif ( defined ( $import->lookup_value($config,$_,$row_ref->{ ucfirst( $import->mapping($config,$_)//'ignore' ) }))){
             if ($import->lookup_value($config,$_,$row_ref->{ ucfirst( $import->mapping($config,$_)//'ignore' ) }) ne 'undef'){
              $import->lookup_value($config,$_,$row_ref->{ ucfirst( $import->mapping($config,$_)//'ignore' ) });
             }
             else{
               "row[value mapping not defined!]\n";
             }
          }
          else{
            $row_ref->{ ucfirst( $import->mapping($config,$_)//'ignore' ) }//'';
          }
        } @$ordered_hydstra_fields;
=cut        
        print $fh "row [".Dumper(\@row)."]\n";
        
        $hysth->execute(@row);
      }
      
      
      #$sth->bind_columns(map {\$rec{$_}} @$ordered_hydstra_fields);
      
      #my $rows_ref = $sth->fetchall_arrayref({});
      
=skip    
      foreach $row_ref ( @$rows_ref ) {
        
        #my @write_row = ( map { 
          #if ( defined ( $import->value($config,$_) ) ){
          #if ( defined ( $import->value('field'=>$_) ) ){
          #  $config->value('field'=>$_);
          #  print $fh "   Value defined for [$_]\n";
          #}
          #elsif ( defined ( $config->lookup_value('field'=>$_) ) ){  
          #  $config->lookup_value( 'field'=>$_, 'value'=>$row_ref->{$_} );
          #}
          #else{
            #$row_ref->{$_}//''; 
            #print $fh "   Value for [$_]\n  row_ref [".Dumper($row_ref)."] value [$row_ref->{$_}]";
            print $fh "   row_ref [".Dumper($row_ref)."]\n";
          #}
        #} @ordered_hyfields );
        
    my %rec =();

    $sth->bind_columns(map {\$rec{$_}} @fields);

    print "$rec{emp_id}\t",
          "$rec{first_name}\t",
          "$rec{monthly_payment}\n"
        while $sth->fetchrow_arrayref;
        
        #my @write_row = ( map { $row_ref->{$_}//'' } @ordered_hyfields );
        my @write_row = ( map { $_ } @ordered_hyfields );
        print $fh "Write row [".Dumper(\@write_row)."]";
        
        #$hysth->execute(@write_row);  
        #write this row to the sqlite hydb.db
      }
=cut      
     $hydbh->commit;
    }
    

=skip    
    foreach $row ( @{$rns_aquifer} ){
      
      foreach $foreign_field ( keys %{$row}){
        foreach $mapping ( $config{'elements'}->{foreign_field}{$foreign_field}{hydstra_mappings} ){
          my $hydstra_table = $mapping->{table};
          my $hydstra_field = $mapping->{field};
          my $value;
          
          if ( defined $mapping->{value} ){
            $value = $mapping->{value};
          }
          elsif( defined $mapping->{value_mappings} ){
            $value = $mapping->{value_mappings}->{$row->{$foreign_field}}//'';
          }
          else{
            $value = $row->{$foreign_field};
          }
          $data{$hydstra_table}{$hydstra_field} = $value;
        }
      }
      
    foreach $table (keys %data){  
      my @ordered_hyfields = $config->ordered_hyfields( 'table'=>$hytable );
      push (@row, $_) if ( defined $data{$hydstra_table}{$_} ) for @ordered_hyfields;
      then slurp into hydb.db. while $sth->fetchrow_arrayref;
    }
    
    
    
    my @fields = (qw(emp_id first_name monthly_payment));

    $sth->execute;
    my %rec =();

    $sth->bind_columns(map {\$rec{$_}} @fields);

    print "$rec{emp_id}\t",
          "$rec{first_name}\t",
          "$rec{monthly_payment}\n"
        while $sth->fetchrow_arrayref;
    
    
      
      
    } 
    
{
'table' => 'gwtracer',
'field' => 'variable'
'value' => '821'
},
{
'table' => 'gwtracer',
'field' => 'value'
}
    
    
    print $fh "foreign_table [$foreign_table] [".Dumper(\%data)."]\n";  
    
    my @fields = (qw(emp_id first_name monthly_payment));
    my @fields = (qw($import_json->ordered_fields));

    
    
    
    
    my %rec =();

    table_fields
    foreach  
    $sth->bind_columns(map {\$rec{$_}} @fields);
    
    
    #Example from http://www.perlmonks.org/?node_id=284436#arcol3
     my @fields = (qw(emp_id first_name monthly_payment));

    $sth->execute;
    my %rec =();
    $sth->(RN,TOP,BOT,JIGGY,COMMENT)
    fiels = (STATION,TOP,BOT,IGNORE,COMMNT,IGNORE)
    
    
    
    foreach $hytable ( @{$config->hydstra_tables} ){
      my @fields = $config->ordered_mappings( 'table'=>$hytable );
      $sth->bind_columns(map {\$rec{$hytable}{ $_ }}  @fields);
    }
    
    my @ordered_hyfields = $config->ordered_hyfields( 'table'=>$hytable );
    my @row;
     
    push (@row, $_) if ( defined $rec{$_} ) for @ordered_hyfields;
    
    then slurp into hydb.db. while $sth->fetchrow_arrayref;
    
    
    print "$rec{emp_id}\t",
          "$rec{first_name}\t",
          "$rec{monthly_payment}\n"
        while $sth->fetchrow_arrayref;
    
    
    
    
    
    
    foreach field in $row_ref 
        my $table = $hydstra_mappings->table
        my $field = $hydstra_mappings->field
        "hydstra_mappings" : [{
					"table" : "aquifer",
					"field" : "swlvalue"
				}
			]
=cut    
    
=skip   
    my $rowref = $sth->fetchrow_arrayref({});
    
    foreach my $element ( @elements ){
    
      my $foreign_field = $element->{foreign_field};
      my @hydstra_mappings = $element->{hydstra_mappings};
      
      foreach $hydstra_mapping ( @hydstra_mappings ){
        my $table = $hydstra_mappings->{table};
        my $field = $hydstra_mappings->{field};
        %{$data{$table}} = map { $field , [ $_->{$foreign_field} ]} @$rowref;
      }
    }  
    print "$rec{emp_id}\t","$rec{first_name}\t","$rec{monthly_payment}\n" while $sth->fetchrow_arrayref;
    
    foreach $output_hydstra_table ( keys %$return ){
    ####  I need an array for the table with 
      
      ####  1. all the defaults 
              # my $hashrow = with the Hydstra::$table->new( $correct_field_names{$table} );
      ####  2. lookups filled in
      ####  2. validated
    
    foreach $foreign_field ( @elements ){ 
    
      foreach $hydstra_mapping ( @hydstra_mappings ){
          
          my $table = $hydstra_mappings->table
          my $field = $hydstra_mappings->field
          
          
          $_->{'Rn'}
          $_->{$foreign_field}
      }
    }
    
    
    
    
    
    
    
    
    foreach $field $foreign_table
    
    "foreign_field" : "swl",
			"foreign_sqlite_type" : "real",
			"foreign_table" : "aquifer",
			"foreign_key_field" : 0,
			"hydstra_mappings" : [{
					"table" : "aquifer",
					"field" : "swlvalue"
				}
			]
          
          each $field in $_->{}
    foreach $record (@$rns_aquifer){
      foreach $field (keys %record){
        
      }
    }
    foreach $foreign_field ( @elements ){ 
    
      foreach $hydstra_mapping ( @hydstra_mappings ){
          
          $hydstra_mappings->table
          $hydstra_mappings->field
          
          
          $_->{'Rn'}
          $_->{$foreign_field}
      }
    }
    #my @data = map { [ $_->{'Rn'}, $_->{'Top'} ]} @$rns_aquifer;
    
    my %data = 
    
    "table" : "aquifer",
    
    $ordered_fields = Hydstra::$table;
    
    my %hypm;
    foreach my $hydstra_table ( @$tables){
      $hypm{$hydstra_table} = Hydstra::$hydstra_table->new();
    }
    
    
    my $sql_create = $hypm->{$table}->sql_create;
    
    
    foreach my $mapped_table ( @{$hydstra_mappings{'table'}} ){
      
      my $ordered_fields = $hypm->{$table}->ordered_fields;
      
      map { $hydstra_table,[ 
      for @$ordered_fields;
            
            $_->{'Rn'}, $_->{'Top'} 
      
      ]} @$rns_aquifer;
    }
=cut      
  }
  
    
    
  $dbh->disconnect();
  $hydbh->disconnect();
  
  
=skip  














  my $module = 'Aquifer';
  my $hypm = "Hydstra::$module";
  my $table = $hypm->new();
  my $create = $table->create;
  my $prepare = $table->prepare;
  $hydbh->do($create);
   my $sth = $dbh->prepare("INSERT INTO $uctable VALUES ($vals)");
      
  $sth->execute(@{$rns_aquifer}) or die $sth->errstr;
  
  
  $hydbh->commit;
=cut  
 
  
  ok( defined $rns_aquifer, "aquifer defined ok");
  
  #print $fh "Top [$_->{'Top'}]\n" for @$rns_aquifer;
  #print $fh "Top [$_->{'Top'}]\n" for @$rns_aquifer;
  
  #print $fh "art of sumber [".Dumper($rns_aquifer)."] end of dumper";
  #print $fh "art of sumber [".Dumper(\@data)."] end of dumper";
  print $fh "art of sumber [".Dumper(\%data)."] end of dumper";

  
=sip
  Notes on how this normalisation works.

  
  #foreach ( column for which there is a hydstra mapping 
    
    for each hydstra table
      look for the key fields in foreign which make up a hydstra key, 
      then pick up the related fields which make up the record
      
    or - 
    for each foreign table
      
    
    
    pick up the 
    
    
  ){
    
  }
=cut  
  
  
=sk  
  ok(defined $hydbh, "connected to db/hydb.db ok");
    
  foreach ( @{$tablesref}){
    my $module = ucfirst($_);
    next if ($module eq 'Elevations' || $module eq 'Group' || $module eq 'Variable');
    #my $table = Hydstra::$module->new();
    #print $fh " table [$table]\n";
    my $hypm = "Hydstra::$module";
    my $table = $hypm->new();
    my $create = $table->create;
    my $prepare = $table->prepare;
    my @rw = split(',',$prepare);
    my @row;
    push (@row,'') for @rw;
    print $fh "module [$module]\n  create [$create]\n  prepare [$prepare]\n";
    my $create = $table->create;
    print $fh "  create [$create]\n";
    
    #ok(!defined $table->create, "table->create [$create] ok");
    $hydbh->do($create);
    #my $hysth = $hydbh->prepare($prepare);
    #$hysth->execute(@row);
  }  
  close ($fh);
    #$hydbh->do($table->create);

  $hydbh->commit;
=cut  
  
  
  
  
  
  
#done_testing( $number_of_tests_run );
