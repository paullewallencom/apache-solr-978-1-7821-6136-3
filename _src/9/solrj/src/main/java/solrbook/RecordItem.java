package solrbook;

import org.apache.solr.client.solrj.beans.Field;

public class RecordItem {

	//@Field("url")  COMMENTED to show you can put the annotation on a setter
	String id;
	
	@Field
	String mimeType;
	
	@Field("docText")
	String html;
	
	@Field
	String host;
	
	@Field
	String path;

	public String getId() {
		return id;
	}

  @Field("url")
	public void setId(String id) {
		this.id = id;
	}

	public String getMimeType() {
		return mimeType;
	}

	public void setMimeType(String mimeType) {
		this.mimeType = mimeType;
	}

	public String getHtml() {
		return html;
	}

	public void setHtml(String html) {
		this.html = html;
	}

	public String getHost() {
		return host;
	}

	public void setHost(String host) {
		this.host = host;
	}

	public String getPath() {
		return path;
	}

	public void setPath(String path) {
		this.path = path;
	}
	

}
