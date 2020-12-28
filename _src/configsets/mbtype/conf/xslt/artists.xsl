<?xml version="1.0"?>
<!-- Author: David Smiley -->
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:common="http://exslt.org/common"
                xml:space="default">
  <xsl:output indent="yes" method="xml" />

  <xsl:template match="text()"/>

  <xsl:strip-space elements="*"/>

  <!-- #### common stuff -->

  <xsl:template match="table">
    <add>
      <xsl:apply-templates/>
    </add>
  </xsl:template>
  
  <xsl:template match="tr">
    <doc>
      <field name="type">Artist</field>
      <xsl:apply-templates/>
    </doc>
  </xsl:template>

  <xsl:template match="td" >
    <xsl:variable name="names"><id/><a_name /><a_name_sort /><a_begin_date d=""/><a_end_date d=""/><a_type />
      <a_alias m=""/><a_member_name m=""/><a_member_id m=""/><a_release_date_latest d=""/></xsl:variable>
    <xsl:variable name="p" select="position()"/>
    <xsl:variable name="nameNode" select="common:node-set($names)/*[$p]"/>
    <xsl:variable name="field" select="local-name($nameNode)"/>
    <xsl:variable name="multi" select="$nameNode/@m"/>
    <xsl:variable name="date" select="$nameNode/@d"/>
    <xsl:choose>
      <xsl:when test="$multi">
        <xsl:call-template name="output-tokens">
          <xsl:with-param name="list" select="."/>
          <xsl:with-param name="field" select="$field"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$field = 'id'">
        <field name="{$field}">Artist:<xsl:value-of select="."/></field>
      </xsl:when>
      <xsl:when test="$field = 'a_type' and . = '1' ">
        <field name="{$field}">person</field>
      </xsl:when>
      <xsl:when test="$field = 'a_type' and . = '2' ">
        <field name="{$field}">group</field>
      </xsl:when>
      <xsl:when test="$date">
        <field name="{$field}"><xsl:value-of select="."/>T00:00:00Z</field>
      </xsl:when>
      <xsl:otherwise>
        <field name="{$field}"><xsl:value-of select="."/></field>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <xsl:template name="output-tokens">
    <xsl:param name="list"/>
    <xsl:param name="field"/>
    <xsl:if test="$list">
      <xsl:variable name="first" select="substring-before(concat($list,'|'), '|')"/>
      <xsl:variable name="remaining" select="substring-after($list, '|')"/>
      <field name="{$field}">
        <xsl:value-of select="$first"/>
      </field>
      <xsl:if test="$remaining">
        <xsl:call-template name="output-tokens">
          <xsl:with-param name="list" select="$remaining"/>
          <xsl:with-param name="field" select="$field" />
        </xsl:call-template>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <xsl:template match="td[string-length(.)=0]" />
  
</xsl:stylesheet>