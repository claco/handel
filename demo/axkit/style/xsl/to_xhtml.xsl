<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id$ -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" cdata-section-elements="CDATA" version="1.0">
	<xsl:output
		method="xml"
		indent="no"
		omit-xml-declaration="yes"
		doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN"
		doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
		encoding="UTF-8"
		media-type="text/html"
	/>
	<xsl:template match="/page">
		<xsl:element name="html">
			<xsl:attribute name="xml:lang">en</xsl:attribute>
			<xsl:attribute name="lang">en</xsl:attribute>
			<head>
				<title>Handel Demo: <xsl:value-of select="title"/></title>
				<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
				<link rel="stylesheet" type="text/css" href="style/css/basic.css" media="screen"/>
			</head>
			<xsl:copy-of select="body"/>
		</xsl:element>
	</xsl:template>
</xsl:stylesheet>