package solrbook;

import org.apache.commons.io.filefilter.FileFilterUtils;
import org.apache.http.HttpException;
import org.apache.http.HttpResponse;
import org.apache.http.entity.InputStreamEntity;
import org.apache.http.impl.conn.DefaultHttpResponseParserFactory;
import org.apache.http.impl.io.HttpTransportMetricsImpl;
import org.apache.http.impl.io.SessionInputBufferImpl;
import org.apache.http.io.HttpMessageParser;
import org.apache.http.protocol.HTTP;
import org.apache.http.util.EntityUtils;
import org.apache.solr.client.solrj.SolrQuery;
import org.apache.solr.client.solrj.SolrServer;
import org.apache.solr.client.solrj.SolrServerException;
import org.apache.solr.client.solrj.StreamingResponseCallback;
import org.apache.solr.client.solrj.embedded.EmbeddedSolrServer;
import org.apache.solr.client.solrj.impl.BinaryRequestWriter;
import org.apache.solr.client.solrj.impl.BinaryResponseParser;
import org.apache.solr.client.solrj.impl.ConcurrentUpdateSolrServer;
import org.apache.solr.client.solrj.impl.HttpSolrServer;
import org.apache.solr.client.solrj.impl.XMLResponseParser;
import org.apache.solr.client.solrj.request.RequestWriter;
import org.apache.solr.client.solrj.response.FacetField;
import org.apache.solr.client.solrj.response.QueryResponse;
import org.apache.solr.common.SolrDocument;
import org.apache.solr.common.SolrInputDocument;
import org.apache.solr.core.ConfigSolr;
import org.apache.solr.core.CoreContainer;
import org.apache.solr.core.CoreDescriptor;
import org.apache.solr.core.SolrCore;
import org.apache.solr.core.SolrResourceLoader;
import org.archive.io.ArchiveReader;
import org.archive.io.ArchiveReaderFactory;
import org.archive.io.ArchiveRecord;
import org.archive.io.ArchiveRecordHeader;
import org.archive.io.arc.ARCRecord;

import java.io.File;
import java.io.FilenameFilter;
import java.io.IOException;
import java.net.URL;
import java.util.List;
import java.util.Properties;

/**
 * Simple command line application that allows you to index ARC records into Solr via either the
 * remote HTTP interface or via the pure Java based Embedded Solr Server
 */
public class BrainzSolrClient {

  /**
   * Three parameters are required for the main method.
   */
  public static void main(String[] args) throws Exception {

    String pathToArcs;
    String remoteOrLocal;
    String connectionParameter;

    if (args.length == 3) {
      pathToArcs = args[0];
      remoteOrLocal = args[1];
      connectionParameter = args[2];
    } else {
      throw new Exception(
              "We expect three parameters, " +
                      "the first is the relative path to the arcs, " +
                      "the second is REMOTE or EMBEDDED, " +
                      "the third is either URL for REMOTE like " +
                      "http://localhost:8983/solr/crawler or the PATH for EMBEDDED like " +
                      "../../../cores");
    }

    File arcDir = new File(pathToArcs).getAbsoluteFile();
    if (!arcDir.exists() || !arcDir.isDirectory()) {
      throw new Exception("ARC dir:" + arcDir + " doesn't exist or not a dir");
    }

    SolrServer solrServer = createSolr(remoteOrLocal, connectionParameter);
    try {
      solrServer.deleteByQuery("*:*"); // delete everything and commit!
      solrServer.commit();

      BrainzSolrClient myClient = new BrainzSolrClient(solrServer);
      int addedDocs = myClient.index(arcDir);
      System.out.println("Added " + addedDocs + " docs");
      solrServer.commit();
      solrServer.optimize();//optional; somewhat atypical

      // do a search that returns results as beans and displays count of hits.
      myClient.searchForBeans("*:*");//prints hit count
      myClient.searchStreamDocs("*:*");//prints the URLs

      // searches for facets (only) and prints them
      myClient.searchFacets("*:*");//prints facets

      //note: we could have done the 3 searches above in one go but didn't merely to
      // showcase features separately

    } finally {
      solrServer.shutdown();
    }
  }

  public static SolrServer createSolr(String connectionType, String connectionParameter) throws Exception {
    switch (connectionType.toUpperCase()) {
      case "REMOTE":
        return createRemoteSolr(connectionParameter);
      case "STREAMING":
        return createStreamingSolr(connectionParameter);
      case "EMBEDDED":
        return createEmbeddedSolr(connectionParameter);
      default:
        throw new IllegalArgumentException("Unknown conn type: " + connectionType);
    }
  }

  /**
   * Starts a connection to a remote Solr using HTTP as the transport mechanism.
   */
  public static SolrServer createRemoteSolr(String url) {
    return new HttpSolrServer(url);
  }

  /**
   * Starts a connection to a remote Solr server that streams documents.
   */
  public static SolrServer createStreamingSolr(String url) {
    final int QUEUE_SIZE = 10;//for big docs we use a small queue; otherwise much more
    final int THREAD_COUNT = 2;//be careful with this number; read the book
    final ConcurrentUpdateSolrServer solrServer = new ConcurrentUpdateSolrServer(url, QUEUE_SIZE, THREAD_COUNT);
    //note: these methods are on all SolrServer subclasses except EmbeddedSolrServer. see SOLR-6456
    if (useXml) {
      solrServer.setRequestWriter(new RequestWriter());
      solrServer.setParser(new XMLResponseParser());
    } else {//javabin
      solrServer.setRequestWriter(new BinaryRequestWriter());
      solrServer.setParser(new BinaryResponseParser());
    }
    return solrServer;
  }

  /**
   * Starts a connection to a local embedded Solr that connects directly, without using HTTP as a
   * transport layer.
   */
  public static SolrServer createEmbeddedSolr(final String instanceDir) throws Exception {
    final String coreName = new File(instanceDir).getName();
    //dataDir can be omitted to use the default in solrconfig.xml
    final String dataDir = instanceDir + "/../../cores_data/" + coreName;
    // note: this is more complex than it should be. See SOLR-4502
    SolrResourceLoader resourceLoader = new SolrResourceLoader(instanceDir);
    CoreContainer container = new CoreContainer(resourceLoader,
            ConfigSolr.fromString(resourceLoader, "<solr />"));
    container.load();
    Properties coreProps = new Properties();
    coreProps.setProperty(CoreDescriptor.CORE_DATADIR, dataDir);//"dataDir"
    CoreDescriptor descriptor = new CoreDescriptor(container, coreName, instanceDir, coreProps);
    SolrCore core = container.create(descriptor);
    container.register(core, false);//not needed in Solr 4.9+
    return new EmbeddedSolrServer(container, core.getName());
  }

  private final SolrServer solrServer;

  boolean printOutUrls = true; // Print to System.out each URL being indexed
  boolean indexIntoSolr = true; // Actually perform indexing?
  boolean indexAsSolrDocument = true; // true to index as a SolrDocument or false to index as POJO
  static boolean useXml = false;//vs javabin. We only do on CUSS.

  public BrainzSolrClient(SolrServer solrServer) {
    this.solrServer = solrServer;
  }

  public int index(File arcDir) throws Exception {
    File[] arcFiles = arcDir.listFiles((FilenameFilter) FileFilterUtils.suffixFileFilter(".arc"));
    int hits = 0;
    for (File arcFile : arcFiles) {
      System.out.println("Reading " + arcFile.getName());
      try (ArchiveReader archiveReader = ArchiveReaderFactory.get(arcFile)) {
        archiveReader.setDigest(true);

        for (ArchiveRecord rec : archiveReader) {
          if (index(rec))
            hits++;
        }
      }
    }
    return hits;
  }

  private boolean index(ArchiveRecord rec) throws Exception {
    if (((ARCRecord) rec).getStatusCode() != 200)
      return false;
    ArchiveRecordHeader meta = rec.getHeader();
    if (!meta.getMimetype().trim().startsWith("text/html"))
      return false;
    if (printOutUrls) {
      System.out.println(meta.getUrl());
    }
    String htmlString;
    try {
      htmlString = parseHttpBody(rec);
    } catch (Exception e) {
      e.printStackTrace();//normally don't do this but ok in sample code
      return false;
    }
    if (htmlString == null)
      return false;
    if (indexIntoSolr) {
      if (indexAsSolrDocument) {
        indexAsSolrDocument(meta, htmlString);
      } else {
        indexAsBean(meta, htmlString);
      }
    }
    return true;
  }

  /**
   * Demonstrate the typical use case of reading from a record, store as a SolrDocument.
   */
  private void indexAsSolrDocument(ArchiveRecordHeader meta, String htmlStr) throws Exception {
    SolrInputDocument doc = new SolrInputDocument();

    doc.setField("url", meta.getUrl(), 1.0f);
    doc.setField("mimeType", meta.getMimetype(), 1.0f);
    doc.setField("docText",htmlStr);
    URL url = new URL(meta.getUrl());
    doc.setField("host", url.getHost());
    doc.setField("path", url.getPath());
    solrServer.add(doc); // or could batch in a collection
  }

  /**
   * Demonstrate the use case of storing a POJO (JavaBean) into Solr, using a record as the data
   * source to facilitate this example.
   */
  private void indexAsBean(ArchiveRecordHeader meta,
                           String htmlStr) throws Exception {
    RecordItem item = new RecordItem();

    item.setId(meta.getUrl());
    item.setMimeType(meta.getMimetype());
    item.setHtml(htmlStr);
    URL url = new URL(meta.getUrl());
    item.setHost(url.getHost());
    item.setPath(url.getPath());
    solrServer.addBean(item); // or could batch in a collection
  }

  public List<RecordItem> searchForBeans(String queryStr) throws SolrServerException {
    SolrQuery solrQuery = new SolrQuery(queryStr);
    solrQuery.setRequestHandler("/select");//you should make this configurable; and note '/'
    QueryResponse response = solrServer.query(solrQuery);
    System.out.println("Perform Search for '" + queryStr + "': found " + response.getResults().getNumFound());
    //bean style:
    return response.getBeans(RecordItem.class);
    //SolrDocument style:
    //return response.getResults(); // returns a SolrDocumentList which is a List<SolrDocument>
  }

  public void searchStreamDocs(String queryStr) throws IOException, SolrServerException {
    SolrQuery solrQuery = new SolrQuery(queryStr);
    QueryResponse response = solrServer.queryAndStreamResponse(solrQuery, new StreamingResponseCallback() {
      @Override
      public void streamDocListInfo(long numFound, long start, Float maxScore) {
        //DO SOMETHING
      }

      @Override
      public void streamSolrDocument(SolrDocument doc) {
        //DO SOMETHING, probably not simply adding the doc on some list, which misses the
        // point of streaming.
        System.out.println(doc.getFieldValue("url"));
      }
    });
  }

  public void searchFacets(String queryStr) throws SolrServerException {
    SolrQuery solrQuery = new SolrQuery(queryStr);
    solrQuery.setRows(0);//just facets this time
    solrQuery.addFacetField("host", "path");//2 fields to facet on
    solrQuery.setFacetLimit(10);
    solrQuery.setFacetMinCount(2);
    QueryResponse response = solrServer.query(solrQuery);
    for (FacetField facetField : response.getFacetFields()) {
      System.out.println("Facet: "+facetField.getName());
      for (FacetField.Count count : facetField.getValues()) {
        System.out.println(" " + count.getName()+":"+count.getCount());
      }
    }
  }

  public String parseHttpBody(ArchiveRecord rec) throws IOException, HttpException {
    //Use Apache HttpComponents. First read headers, then the body "entity"
    SessionInputBufferImpl sessionInputBuffer = new SessionInputBufferImpl(
            new HttpTransportMetricsImpl(), 1024);//buf size (double buf unfortunately)
    sessionInputBuffer.bind(rec);//ArchiveRecord *is* an InputStream!  weird
    HttpMessageParser<HttpResponse> httpMessageParser =
            DefaultHttpResponseParserFactory.INSTANCE.create(sessionInputBuffer, null);
    HttpResponse httpResponse = httpMessageParser.parse();
    //(the InputStream is now positioned at the body entity)
    InputStreamEntity entity = new InputStreamEntity(rec);
    entity.setContentType(httpResponse.getFirstHeader(HTTP.CONTENT_TYPE));
    entity.setContentEncoding(httpResponse.getFirstHeader(HTTP.CONTENT_ENCODING));
    entity.setChunked(false);//Arc takes care of this as well as transfer-encoding?
    return EntityUtils.toString(entity);
  }

}
