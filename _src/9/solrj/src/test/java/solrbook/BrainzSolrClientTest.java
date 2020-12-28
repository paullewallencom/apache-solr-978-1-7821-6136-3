package solrbook;

import org.junit.Ignore;
import org.junit.Test;

/**
 * Unit test for simple BrainzSolrClient.
 */
public class BrainzSolrClientTest {

  final String arcpath = "../heritrix-2.0.2/jobs/completed-musicbrainz-only-artists-20090707185058/arcs/";

  @Test
  public void testHeritrixRemote() throws Exception {
    System.out.println("WARNING: Will fail if Solr isn't running.");
    String connType = "REMOTE";
    String connString = "http://localhost:8983/solr/crawler";
    BrainzSolrClient.main(new String[]{arcpath, connType, connString});
  }

  @Test
  public void testHeritrixRemoteStreaming() throws Exception {
    System.out.println("WARNING: Will fail if Solr isn't running.");
    String connType = "STREAMING";
    String connString = "http://localhost:8983/solr/crawler";
    BrainzSolrClient.main(new String[]{arcpath, connType, connString});
  }

  @Test
  public void testHeritrixEmbedded() throws Exception {
    String connType = "EMBEDDED";
    String connString = "../../cores/crawler";
    BrainzSolrClient.main(new String[]{arcpath, connType, connString});
  }


  @Test @Ignore
  public void testHeritrix3() throws Exception {
    System.out.println("WARNING: Will fail if Solr isn't running.");
    String arcpath = "../heritrix-3.0.0/jobs/test2/warcs";
    String connType = "REMOTE";
    String connString = "http://localhost:8983/solr/crawler";
    BrainzSolrClient.main(new String[]{arcpath, connType, connString});
  }
}
