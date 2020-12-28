
<!-- 
  Simple transform of Solr query results to HTML
 -->
<xsl:stylesheet version='1.0'
    xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
>
  <xsl:output media-type="application/json" encoding="UTF-8" omit-xml-declaration="yes"/> 
  
  <xsl:template match='/'>
    <xsl:variable name="searchTerms" select="response/lst[@name='responseHeader']/lst[@name='params']/str[@name='terms.prefix']" />
    
    ["<xsl:value-of select="$searchTerms" />",
     [
      <xsl:for-each select="response/lst[@name='terms']/lst[@name='a_spell']/int">
        "<xsl:value-of select="./@name" />",
       </xsl:for-each>     
     ],
     [
     <xsl:for-each select="response/lst[@name='terms']/lst[@name='a_spell']/int">
       "<xsl:value-of select="."/> results",
      </xsl:for-each>
      ],
     [
     <xsl:for-each select="response/lst[@name='terms']/lst[@name='a_spell']/int">
       "browse?q=<xsl:value-of select="./@name" />",
      </xsl:for-each>
      ]
     ]
  </xsl:template>
  
</xsl:stylesheet>
