<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:fo="http://www.w3.org/1999/XSL/Format"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                exclude-result-prefixes="xs">

    <xsl:output method="xml" indent="yes"/>

    <!-- Root template -->
    <xsl:template match="/site">
        <fo:root xmlns:fo="http://www.w3.org/1999/XSL/Format">
            <fo:layout-master-set>
                <fo:simple-page-master master-name="A4-portrait"
                                       page-height="29.7cm"
                                       page-width="21cm"
                                       margin="2cm">
                    <fo:region-body margin-top="1.5cm" margin-bottom="1.5cm"/>
                    <fo:region-before extent="1cm"/>
                    <fo:region-after extent="1cm"/>
                </fo:simple-page-master>
            </fo:layout-master-set>

            <fo:page-sequence master-reference="A4-portrait">
                <!-- Page Headers/Footers -->
                <fo:static-content flow-name="xsl-region-before">
                    <fo:block text-align="center" font-size="9pt">
                        <xsl:value-of select="/site/title"/>
                    </fo:block>
                </fo:static-content>
                <fo:static-content flow-name="xsl-region-after">
                    <fo:block text-align="center" font-size="9pt">
                        Page <fo:page-number/>
                    </fo:block>
                </fo:static-content>

                <!-- Main Content Flow -->
                <fo:flow flow-name="xsl-region-body">
                    <!-- Title Page -->
                    <fo:block font-size="28pt" font-weight="bold" text-align="center" space-after="1cm">
                        <xsl:value-of select="title"/>
                    </fo:block>
                    <fo:block font-size="14pt" text-align="center" space-after="2cm">
                        Generated on <xsl:value-of select="format-dateTime(buildDate, '[D] [MNn] [Y]')"/>
                    </fo:block>

                    <!-- Process top-level sections -->
                    <xsl:apply-templates select="content/section"/>
                </fo:flow>
            </fo:page-sequence>
        </fo:root>
    </xsl:template>

    <!-- Template for sections (chapters) -->
    <xsl:template match="section">
        <xsl:variable name="level" select="count(ancestor-or-self::section)"/>
        <fo:block break-before="page"
                  font-weight="bold"
                  space-after="1cm">
            <xsl:attribute name="font-size">
                <xsl:value-of select="22 - ($level * 2)"/>
                <xsl:text>pt</xsl:text>
            </xsl:attribute>
            <xsl:value-of select="title"/>
        </fo:block>

        <!-- Process pages within this section -->
        <xsl:apply-templates select="pages/page"/>

        <!-- Recurse for sub-sections -->
        <xsl:apply-templates select="section"/>
    </xsl:template>

    <!-- Template for a single page -->
    <xsl:template match="page">
        <fo:block break-before="page">
            <fo:block font-size="16pt" font-weight="bold" space-after="8mm">
                <xsl:value-of select="title"/>
            </fo:block>
            <fo:block font-size="10pt" color="gray" space-after="1cm">
                Published on: <xsl:value-of select="format-dateTime(date, '[D] [MNn] [Y]')"/>
            </fo:block>

            <!-- Process HTML content using a recursive helper template -->
            <xsl:variable name="html-content" select="content"/>
            <xsl:call-template name="process-html-content">
                <xsl:with-param name="html" select="$html-content"/>
            </xsl:call-template>
        </fo:block>
    </xsl:template>

    <!-- Helper template to recursively process HTML content -->
    <xsl:template name="process-html-content">
        <xsl:param name="html"/>
        <!-- Regex explanation:
             Pass 1: Match paired tags like <tag>...</tag>
             &lt;([a-z0-9]+)      - Matches opening '<' followed by tag name (group 1)
             ((?:\s+[a-z]+="[^"]*")*)\s* - Captures attributes like attr="value" (group 2)
             &gt;                   - Matches closing '>' of the opening tag
             (.*?)                  - Captures content between tags (non-greedy) (group 3)
             &lt;/\1&gt;              - Matches closing tag '</' followed by the same tag name from group 1
             flags="is"             - 'i' for case-insensitive, 's' for dot-all
        -->
        <xsl:analyze-string select="$html" regex='&lt;([a-z0-9]+)((?:\s+[a-z]+="[^"]*")*)\s*&gt;(.*?)&lt;/\1&gt;' flags="is">
                <xsl:matching-substring>
                    <xsl:variable name="tag-name" select="lower-case(regex-group(1))"/>
                    <xsl:variable name="attributes-str" select="regex-group(2)"/>
                    <xsl:variable name="tag-content" select="regex-group(3)"/>

                    <!-- This is a simplified mapping. More tags can be added. -->
                    <xsl:choose>
                        <!-- Block-level elements -->
                        <xsl:when test="$tag-name = 'p'">
                            <fo:block space-after="5mm">
                                <xsl:call-template name="process-html-content">
                                    <xsl:with-param name="html" select="$tag-content"/>
                                </xsl:call-template>
                            </fo:block>
                        </xsl:when>
                        <xsl:when test="matches($tag-name, 'h[1-6]')">
                            <xsl:variable name="level" select="substring($tag-name, 2, 1)"/>
                            <fo:block font-weight="bold" space-before="8mm" space-after="4mm">
                                <xsl:attribute name="font-size">
                                    <xsl:value-of select="18 - ($level * 2)"/> <!-- Adjust font size based on heading level -->
                                    <xsl:text>pt</xsl:text>
                                </xsl:attribute>
                                <xsl:call-template name="process-html-content">
                                    <xsl:with-param name="html" select="$tag-content"/>
                                </xsl:call-template>
                            </fo:block>
                        </xsl:when>
                        <xsl:when test="$tag-name = 'ul'">
                            <fo:list-block provisional-distance-between-starts="0.5in" provisional-label-separation="0.1in" space-after="5mm">
                                <xsl:call-template name="process-html-content">
                                    <xsl:with-param name="html" select="$tag-content"/>
                                </xsl:call-template>
                            </fo:list-block>
                        </xsl:when>
                        <xsl:when test="$tag-name = 'ol'">
                            <fo:list-block provisional-distance-between-starts="0.5in" provisional-label-separation="0.1in" space-after="5mm">
                                <!-- Note: Distinguishing between ordered (ol) and unordered (ul) list item labels
                                     is difficult with the current regex-based parsing approach, as parent context
                                     is not easily available. All list items will currently use a bullet. -->
                                <xsl:call-template name="process-html-content">
                                    <xsl:with-param name="html" select="$tag-content"/>
                                </xsl:call-template>
                            </fo:list-block>
                        </xsl:when>
                        <xsl:when test="$tag-name = 'li'">
                            <fo:list-item>
                                <fo:list-item-label end-indent="label-end()">
                                    <fo:block>&#x2022;</fo:block> <!-- Bullet point for list items -->
                                </fo:list-item-label>
                                <fo:list-item-body start-indent="body-start()">
                                    <fo:block>
                                        <xsl:call-template name="process-html-content">
                                            <xsl:with-param name="html" select="$tag-content"/>
                                        </xsl:call-template>
                                    </fo:block>
                                </fo:list-item-body>
                            </fo:list-item>
                        </xsl:when>
                        <xsl:when test="$tag-name = 'blockquote'">
                            <fo:block margin-left="1cm" margin-right="1cm" font-style="italic" space-before="5mm" space-after="5mm">
                                <xsl:call-template name="process-html-content">
                                    <xsl:with-param name="html" select="$tag-content"/>
                                </xsl:call-template>
                            </fo:block>
                        </xsl:when>
                        <xsl:when test="$tag-name = 'pre'">
                            <fo:block font-family="monospace" white-space-treatment="preserve" linefeed-treatment="preserve" background-color="#f0f0f0" padding="3mm" space-before="5mm" space-after="5mm">
                                <!-- Inside <pre>, we often don't want to process more HTML, just the code inside -->
                                <xsl:call-template name="process-html-content">
                                    <xsl:with-param name="html" select="$tag-content"/>
                                </xsl:call-template>
                            </fo:block>
                        </xsl:when>
                        <!-- Inline elements -->
                        <xsl:when test="$tag-name = 'a'">
                            <xsl:variable name="href" select="replace($attributes-str, '.*href=&quot;([^&quot;]*)&quot;.*', '$1')"/>
                            <fo:basic-link>
                                <xsl:if test="string($href)">
                                    <xsl:attribute name="external-destination">
                                        <xsl:value-of select="$href"/>
                                    </xsl:attribute>
                                </xsl:if>
                                <xsl:call-template name="process-html-content">
                                    <xsl:with-param name="html" select="$tag-content"/>
                                </xsl:call-template>
                            </fo:basic-link>
                        </xsl:when>
                        <xsl:when test="$tag-name = 'strong' or $tag-name = 'b'">
                            <fo:inline font-weight="bold">
                                <xsl:call-template name="process-html-content">
                                    <xsl:with-param name="html" select="$tag-content"/>
                                </xsl:call-template>
                            </fo:inline>
                        </xsl:when>
                        <xsl:when test="$tag-name = 'em' or $tag-name = 'i'">
                            <fo:inline font-style="italic">
                                <xsl:call-template name="process-html-content">
                                    <xsl:with-param name="html" select="$tag-content"/>
                                </xsl:call-template>
                            </fo:inline>
                        </xsl:when>
                        <xsl:when test="$tag-name = 'del'">
                            <fo:inline text-decoration="line-through">
                                <xsl:call-template name="process-html-content">
                                    <xsl:with-param name="html" select="$tag-content"/>
                                </xsl:call-template>
                            </fo:inline>
                        </xsl:when>
                        <xsl:when test="$tag-name = 'code'">
                            <fo:inline font-family="monospace" background-color="#f0f0f0"><xsl:value-of select="$tag-content"/></fo:inline>
                        </xsl:when>
                        <xsl:when test="$tag-name = 'img'">
                            <xsl:variable name="src" select="replace($attributes-str, '.*src=&quot;([^&quot;]*)&quot;.*', '$1')"/>
                            <xsl:variable name="alt" select="replace($attributes-str, '.*alt=&quot;([^&quot;]*)&quot;.*', '$1')"/>
                            <xsl:if test="string($src)">
                                <fo:block text-align="center" space-before="5mm" space-after="5mm">
                                    <fo:external-graphic src="url('{$src}')">
                                        <xsl:if test="string($alt)">
                                            <xsl:attribute name="alt"><xsl:value-of select="$alt"/></xsl:attribute>
                                        </xsl:if>
                                    </fo:external-graphic>
                                </fo:block>
                            </xsl:if>
                            <!-- img tags are typically self-closing and do not have content to process recursively.
                                 Note: This regex-based parsing only handles <img> if it appears as a paired tag (e.g., <img></img>).
                                 Standard self-closing HTML <img> tags (e.g., <img src="foo.jpg"> or <img src="foo.jpg"/>)
                                 will not be matched by this regex and will be treated as plain text. -->
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- Fallback for unmatched tags, recursively process their content -->
                            <fo:block>
                                <xsl:call-template name="process-html-content">
                                    <xsl:with-param name="html" select="$tag-content"/>
                                </xsl:call-template>
                            </fo:block>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <!-- Pass 2: Handle self-closing tags like <br> and <hr> in the remaining text -->
                    <xsl:analyze-string select="." regex="&lt;(br|hr)\s*/?&gt;" flags="i">
                        <xsl:matching-substring>
                            <xsl:variable name="tag-name" select="lower-case(regex-group(1))"/>
                            <xsl:choose>
                                <xsl:when test="$tag-name = 'br'">
                                    <fo:block/> <!-- Creates a line break -->
                                </xsl:when>
                                <xsl:when test="$tag-name = 'hr'">
                                    <fo:leader leader-pattern="rule" leader-length="100%" rule-thickness="1pt" space-before="3mm" space-after="3mm"/>
                                </xsl:when>
                            </xsl:choose>
                        </xsl:matching-substring>
                        <xsl:non-matching-substring>
                            <xsl:value-of select="."/> <!-- Output plain text -->
                        </xsl:non-matching-substring>
                    </xsl:analyze-string>
                </xsl:non-matching-substring>
            </xsl:analyze-string>
    </xsl:template>

    <!-- Ignore text nodes that are just whitespace -->
    <xsl:template match="text()[normalize-space(.) = '']"/>

</xsl:stylesheet>
