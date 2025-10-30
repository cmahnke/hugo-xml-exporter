#!/bin/sh

# ==============================================================================
#
# setup-tools.sh
#
# This script downloads and configures Apache FOP and Saxon-HE for converting
# the site's XML export to a PDF.
#
# Usage:
#   ./setup-tools.sh [INSTALL_DIR]
#
#   [INSTALL_DIR] is optional. If not provided, tools will be installed
#   in a 'tools' subdirectory in the current location.
#
# ==============================================================================

set -e # Exit immediately if a command exits with a non-zero status.

# --- Configuration ---
FOP_VERSION="2.9"
SAXON_VERSION="12.4"

FOP_URL="https://archive.apache.org/dist/xmlgraphics/fop/binaries/fop-${FOP_VERSION}-bin.tar.gz"
SAXON_URL="https://repo1.maven.org/maven2/net/sf/saxon/Saxon-HE/${SAXON_VERSION}/Saxon-HE-${SAXON_VERSION}.jar"

FOP_ARCHIVE="fop-${FOP_VERSION}-bin.tar.gz"
SAXON_JAR="Saxon-HE-${SAXON_VERSION}.jar"

# --- Installation Directory ---
INSTALL_DIR=${1:-./tools}

echo "--- PDF Tooling Setup ---"
echo "Installation directory: ${INSTALL_DIR}"

# --- Check Dependencies ---
command -v java >/dev/null 2>&1 || { echo >&2 "Java is not installed. Please install a JDK (e.g., OpenJDK 11 or later) and try again."; exit 1; }
command -v curl >/dev/null 2>&1 || { echo >&2 "curl is not installed. Please install it and try again."; exit 1; }
command -v tar >/dev/null 2>&1 || { echo >&2 "tar is not installed. Please install it and try again."; exit 1; }

# --- Create Directories ---
mkdir -p "${INSTALL_DIR}"
cd "${INSTALL_DIR}"

# --- Download and Extract Apache FOP ---
if [ ! -d "fop-${FOP_VERSION}" ]; then
    echo "Downloading Apache FOP ${FOP_VERSION}..."
    curl -L -o "${FOP_ARCHIVE}" "${FOP_URL}"

    echo "Extracting Apache FOP..."
    tar -xzf "${FOP_ARCHIVE}"
    rm "${FOP_ARCHIVE}"
    echo "Apache FOP installed in $(pwd)/fop-${FOP_VERSION}"
else
    echo "Apache FOP ${FOP_VERSION} already found. Skipping download."
fi

# --- Download Saxon-HE ---
if [ ! -f "${SAXON_JAR}" ]; then
    echo "Downloading Saxon-HE ${SAXON_VERSION}..."
    curl -L -o "${SAXON_JAR}" "${SAXON_URL}"
    echo "Saxon-HE installed in $(pwd)/${SAXON_JAR}"
else
    echo "Saxon-HE ${SAXON_VERSION} already found. Skipping download."
fi

# --- Create Saxon Wrapper Script ---
echo "Creating 'saxon-transform' wrapper script..."
cat > saxon-transform <<EOF
#!/bin/sh
DIR=\$(cd "\$(dirname "\$0")" && pwd)
java -jar "\$DIR/${SAXON_JAR}" "\$@"
EOF
chmod +x saxon-transform

# --- Create FOP Wrapper Script ---
echo "Creating 'fop-render' wrapper script..."
cat > fop-render <<EOF
#!/bin/sh
DIR=\$(cd "\$(dirname "\$0")" && pwd)
sh "\$DIR/fop-${FOP_VERSION}/fop" "\$@"
EOF
chmod +x fop-render

echo ""
echo "--- Setup Complete ---"
echo "You can now use the wrapper scripts in the '${INSTALL_DIR}' directory."
echo ""
echo "Example Usage:"
echo "1. Transform XML to FO:"
echo "   ${INSTALL_DIR}/saxon-transform -s:public/site-export.xml -xsl:to-fo.xsl -o:public/site-export.fo"
echo ""
echo "2. Render FO to PDF:"
echo "   ${INSTALL_DIR}/fop-render -fo public/site-export.fo -pdf public/site-export.pdf"
echo ""

cd ..

exit 0
