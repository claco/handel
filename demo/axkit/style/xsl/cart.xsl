<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id$ -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" cdata-section-elements="CDATA" version="1.0">
	<xsl:output method="xml" omit-xml-declaration="no" encoding="UTF-8"/>

	<xsl:template match="@*|node()">
	  <xsl:copy>
		<xsl:apply-templates select="@*|node()"/>
	  </xsl:copy>
	</xsl:template>

	<xsl:template match="cart">
		<xsl:choose>
			<xsl:when test="item">
				<table id="cart" border="1">
					<tr>
						<th>SKU</th>
						<th>Description</th>
						<th>Price</th>
						<th>Quantity</th>
						<th>Total</th>
						<th></th>
					</tr>
					<xsl:for-each select="item">
						<tr>
							<td>
								<xsl:element name="a">
									<xsl:attribute name="href">products.xsp#<xsl:value-of select="sku/."/></xsl:attribute>
									<xsl:attribute name="title">Read more about <xsl:value-of select="sku/."/></xsl:attribute>
									<xsl:value-of select="sku/."/>
								</xsl:element>
							</td>
							<td><xsl:value-of select="description/."/></td>
							<td><xsl:value-of select="price/."/></td>
							<td>
								<form action="cart.xsp" method="post">
									<input type="hidden" name="action" value="update"/>
									<xsl:element name="input">
										<xsl:attribute name="type">hidden</xsl:attribute>
										<xsl:attribute name="name">id</xsl:attribute>
										<xsl:attribute name="value"><xsl:value-of select="id/."/></xsl:attribute>
									</xsl:element>
									<xsl:element name="input">
										<xsl:attribute name="type">text</xsl:attribute>
										<xsl:attribute name="name">quantity</xsl:attribute>
										<xsl:attribute name="size">3</xsl:attribute>
										<xsl:attribute name="value"><xsl:value-of select="quantity/."/></xsl:attribute>
									</xsl:element>
								</form>
							</td>
							<td><xsl:value-of select="total/."/></td>
							<td>
								<form action="cart.xsp" method="post">
									<input type="hidden" name="action" value="delete"/>
									<xsl:element name="input">
										<xsl:attribute name="type">hidden</xsl:attribute>
										<xsl:attribute name="name">id</xsl:attribute>
										<xsl:attribute name="value"><xsl:value-of select="id/."/></xsl:attribute>
									</xsl:element>
									<input type="submit" value="Delete"/>
								</form>
							</td>
						</tr>
					</xsl:for-each>
					<tr>
						<td colspan="4">Subtotal</td>
						<td><xsl:value-of select="subtotal/."/></td>
						<td></td>
					</tr>
				</table>
			</xsl:when>
			<xsl:otherwise>
				<p class="warning">Your shopping cart is empty.</p>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>