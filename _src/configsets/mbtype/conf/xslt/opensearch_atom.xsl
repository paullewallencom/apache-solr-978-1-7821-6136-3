<?xml version="1.0" encoding="UTF-8"?>
<!--
    OpenSearch Atom search results representation. Based on patch SOLR-2143.
-->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="xml" encoding="utf-8" indent="yes" media-type="application/atom+xml;charset=UTF-8" />
    <xsl:template match="/">
        <xsl:variable name="searchTerms" select="response/lst[@name='responseHeader']/lst[@name='params']/str[@name='q']" />
        <xsl:variable name="totalHits" select="response/result/@numFound" />
        <xsl:variable name="searchTimeSecs" select="number(response/lst[@name='responseHeader']/int[@name='QTime']) div 1000.0" />
        <xsl:variable name="start">
            <xsl:choose>
                <xsl:when test="response/lst[@name='responseHeader']/lst[@name='params']/str[@name='start'] != ''">
                    <xsl:value-of select="response/lst[@name='responseHeader']/lst[@name='params']/str[@name='start']" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="0" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="rows">
            <xsl:choose>
                <xsl:when test="response/lst[@name='responseHeader']/lst[@name='params']/str[@name='rows'] != ''">
                    <xsl:value-of select="response/lst[@name='responseHeader']/lst[@name='params']/str[@name='rows']" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="20" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="totalPages" select="ceiling(number($totalHits) div number($rows))" />
        <xsl:variable name="currentPage" select="ceiling(number($start) div number($rows))" />
        <feed xmlns="http://www.w3.org/2005/Atom" xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/">
            <title>MBArtists search results for: <xsl:value-of select="$searchTerms" /></title>
            <subtitle><xsl:value-of select="$totalHits" /> results found in <xsl:value-of select="$searchTimeSecs" /> seconds.</subtitle>
            <logo>http://localhost:8983/solr/mbartists/admin/solr_small.png</logo>
            <updated><xsl:value-of select="response/result/doc[position()=1]/date[@name='timestamp']" /></updated>
            <author><name>Solr/Lucene</name></author>
            <id>tag:localhost:<xsl:value-of select="$searchTerms" /></id>
            <opensearch:totalResults><xsl:value-of select="$totalHits" /></opensearch:totalResults>
            <opensearch:startIndex><xsl:value-of select="$start" /></opensearch:startIndex>
            <opensearch:itemsPerPage><xsl:value-of select="$rows" /></opensearch:itemsPerPage>
            <opensearch:Query role="request" searchTerms="{$searchTerms}" startPage="1" />
            <!-- You might want to add another stylesheet to emit HTML... 
            <link rel="alternate" type="text/html" 
                href="select?q={$searchTerms}&amp;wt=xslt&amp;tr=as_html.xsl&amp;start=TODO&amp;rows=TODO" />
            -->
            <!-- 
                You should use XPath 2.0 functions to "escape-uri" these link href state transitions.
                See http://wiki.apache.org/solr/XsltResponseWriter for help on switching to XPath 2.0 
            -->
            <link rel="self" type="application/atom+xml" 
                href="select?q={$searchTerms}&amp;wt=xslt&amp;tr=opensearch_atom.xsl&amp;start={$start}&amp;rows={$rows}" />
            <link rel="first" type="application/atom+xml"
                href="select?q={$searchTerms}&amp;wt=xslt&amp;tr=opensearch_atom.xsl&amp;start=0&amp;rows={$rows}" />
            <xsl:choose>
                <xsl:when test="number($start) &gt; number($rows)">
                    <xsl:variable name="previous" select="(number($currentPage) - 1) * number($rows)" />
                    <link rel="previous" type="application/atom+xml"
                        href="select?q={$searchTerms}&amp;wt=xslt&amp;tr=opensearch_atom.xsl&amp;start={$previous}&amp;rows={$rows}" />
                </xsl:when>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="number($totalHits) &gt; number($rows) and (number($totalHits) - number($start)) &gt; number($rows)">
                    <xsl:variable name="next" select="(number($currentPage) + 1) * number($rows)" />
                    <link rel="next" type="application/atom+xml"
                        href="select?q={$searchTerms}&amp;wt=xslt&amp;tr=opensearch_atom.xsl&amp;start={$next}&amp;rows={$rows}" />                    
                </xsl:when>
            </xsl:choose>
            <link rel="last" type="application/atom+xml"
                href="select?q={$searchTerms}&amp;wt=xslt&amp;tr=opensearch_atom.xsl&amp;start={number($totalHits) - 1}&amp;rows={$rows}" />
            <!-- autodiscovery tag -->
            <link rel="search" type="application/opensearchdescription+xml"
                href="opensearch_description.xml" />
            <xsl:for-each select="response/result/doc">
                <xsl:variable name="id" select="str[@name='id']" />
                <entry>
                    <title>
                        <xsl:value-of select="str[@name='a_name']" />
                    </title>
                    <link href='select?q=id:"{$id}"' />
                    <id>tag:localhost:<xsl:value-of select="$id" /></id>
                    <summary>
                        <xsl:value-of select="arr[@name='a_name']" />
                    </summary>
                    <updated>
                        <xsl:value-of select="date[@name='indexedAt']" />
                    </updated>
                </entry>
            </xsl:for-each>            
        </feed>
    </xsl:template>
</xsl:stylesheet>