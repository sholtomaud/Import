#!/usr/bin/perl -w
use Test::More tests=>43;
use Logger;
use FindBin qw($Bin);
use Time::Local;
use Import;
use Import::Config;
use DBI;
use Text::CSV_XS;

use constant DB_DIR => $Bin.'/db'; 
use constant SQL_DIR => $Bin.'/tmp/'; 
use constant SQL_DB => 'gwdb.db'; 
use constant HY_DB => 'hydb.db'; 

  mkdir SQL_DIR  if (! -d SQL_DIR );
  
  
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
  my $localtime = sprintf("%04d%02d%02d%02d%02d%02d", $year+1900,$mon+1,$mday,$hour,$min, $sec);
  my $foreign_db = SQL_DIR.SQL_DB;
  
  unlink ($foreign_db);
  
  my $dbh = DBI->connect(          
      "dbi:SQLite:dbname=$foreign_db", 
      "",                          
      "",                          
      { RaiseError => 1, AutoCommit => 0},         
  ) or die $DBI::errstr;


  ok(defined $dbh, 'DBI->connect() returned something' );
   
  my $dbdir = DB_DIR;
  my @files = <$dbdir/*.txt>;
  
  #if there is a fundamental error then only do a partial import (don't import to Hydstra)
  #if $partial_import = 1 it will be a partial import
  my $partial_import = 0;
  
  my $tests_per_file = 6;
  my $number_of_tests_run = 2;
  
  foreach my $GWDB_file (@files) {
    my @filename = split ('/',$GWDB_file);
    my ($filename,$fileext) = split (/\./,$filename[$#filename]);
    print "Files [$GWDB_file] name [$filename]\n";
    
    my $import = Import::Config->new(
        'config_dir'=>$Bin.'/config/',
        'db_file_name'=>uc($filename)
    );
    
    ok(defined $import, 'Import::Config->new() returned something' );
    
    my $config; 
    
    ok( $import->config, "JSON config file ok for [$filename]" );
    
=skip
    
    if (! $import->config ){
      #log those files that do not have any json configuration
      #$logger->"partial import because [$table] doesn't have json config file"; #log that it is a partial import and why
      $partial_import = 1;
      next;
    }
    else{ 
      $config = $import->config;
    }
    
    $dbh->do($config->{foreign_table_sqlcreate});
    my $sth = $dbh->prepare($config->{foreign_table_sqlprepare});

    #test plan
    
    #1. test headers meet those expected in the configuration file.
    #2. type test against the configuration file
    my $imh = Import->new(
      
    );
    
    ok($imh->testHeaders,"headers for [$filename] ok");
    ok($imh->testTypes,"column types for [$filename] ok");
        
    #Leave the actual import heavy lifting for the importer    
        
    #Setup Text::CSV_XS 
    my $csv = Text::CSV_XS->new ({ 
        sep_char => '|', 
        escape_char => '', 
        quote_char =>'', 
        allow_loose_quotes =>1 , 
        always_quote =>1 
    });
    
    ok( (open my $io, "<:encoding(utf8)", $GWDB_file), "opened [$filename] ok" );
    my $count = 0;
    while (my $row = $csv->getline ($io)) {
      $count++;
      #actually these might be to indicate that the record is contained in multiple lines.
      map(s{["'\\]}{}g, @{$row});
      
      ($count == 1) ? next :  $sth->execute(@{$row}) or die $sth->errstr;

    }
    
    close $io;
    $number_of_tests_run += $tests_per_file;
=skip
=cut  
  }    
  $dbh->commit;
  
  
  
  
  my $site    = 'testsite';
  my $comment = 'imported somethink';
  my $status  = 'ok';
  my $keyword = 'IMPTEST';
  my $errmsg  = 'Error message test';
  my $logpath = $Bin.'\\db';
  my $logdb = 'Log.db';
    
  mkdir $logpath if (! -d $logpath ) ;
  
  my $logger = Logger->new( 
    logpath => $logpath,
    logdb => $logdb,
    station => $site,
    comment => $comment,
    status  => $status,
    keyword => $keyword,
    script  => $0,
    errmsg  => $errmsg,
    user    => 'USER'
  );

  my $file = $logpath.'\\'.$logdb;
  
#ok(defined $logger, 'Logger->new() returned something' );
#ok($logger->log  , 'log()');
#ok($logger->log_hash  , 'dev_log()');
#ok(unlink $file,'unlinking file [$file]');
#ok(rmdir $logpath,'rmdir temp [$logpath]');

#done_testing( $number_of_tests_run );
