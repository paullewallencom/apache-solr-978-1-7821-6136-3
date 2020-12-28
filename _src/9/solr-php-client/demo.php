<?php
  require_once( 'Apache/Solr/Service.php' );
  
  // 
  // 
  // Try to connect to the named server, port, and url
  // 
  $solr = new Apache_Solr_Service( 'localhost', '8983', '/solr/mbartists' );
  
  if ( ! $solr->ping() ) {
    echo 'Solr service not responding.';
    exit;
  }
  
  //
  //
  // Create a documents to represent the new artist Susan Boyle who has just been discovered
  // on "Britain's Got Talent" show.
  // http://en.wikipedia.org/wiki/Susan_Boyle
  // In practice, documents would likely be assembled from a 
  //   database query. 
  //
  $artists = array(
    'suan_boyle' => array(
      'id' => 'Artist:-1',
      'type' => 'Artist',
      'a_name' => 'Susan Boyle',
      'a_type' => 'person',
      'a_member_name' => array('Susan Boyle')
    )
  );
    
  $documents = array();
  
  foreach ( $artists as $item => $fields ) {
    $artist = new Apache_Solr_Document();
    
    foreach ( $fields as $key => $value ) {
      if ( is_array( $value ) ) {
        foreach ( $value as $datum ) {
          $artist->setMultiValue( $key, $datum );
        }
      }
      else {
        $artist->$key = $value;
      }
    }
    
    $documents[] = $artist;
  }
    
  //
  //
  // Load the documents into the index
  // 
  try {
    $solr->addDocuments( $documents );
    $solr->commit();
    $solr->optimize();
  }
  catch ( Exception $e ) {
    echo $e->getMessage();
  }
  
  //
  // 
  // Run some queries. Provide the raw path, a starting offset
  //   for result documents, and the maximum number of result
  //   documents to return. You can also use a fourth parameter
  //   to control how results are sorted and highlighted, 
  //   among other options.
  //
  $offset = 0;
  $limit = 40;
  
  $queries = array(
    'id:"Artist:-1"',
    'a_name: Susan Boyle',
    'a_name: boyle',
    'a_member_name: Susan Boyle'
  );
  echo "<head><title>Solr PHP Demo</title></head>";

  foreach ( $queries as $query ) {
    $response = $solr->search( $query, $offset, $limit );
    
    if ( $response->getHttpStatus() == 200 ) { 
      // print_r( $response->getRawResponse() );
      
      if ( $response->response->numFound > 0 ) {
        echo "<b>$query </b><br />";

        foreach ( $response->response->docs as $doc ) { 
          
          $output = "$doc->a_name ($doc->id) <br />";
          
          // highlight Susan Boyle if we find her.
          if ($doc->id == 'Artist:-1') {
            $output = "<em><font color=blue>" . $output . "</font></em>";
          }
          
          echo $output;
        }
        
        echo '<br />';
      }
    }
    else {
      echo $response->getHttpStatusMessage();
    }
  }
?>