# Hugo XML Exporter

This is a specialized Hugo "theme" designed not for rendering a website, but for exporting your entire Hugo site's content, metadata, and associated resources into a single, structured XML file. This can be incredibly useful for:

- **Data Migration**: Moving content to another platform or CMS.
- **Content Analysis**: Easily parsing your site's data for insights.
- **Archiving**: Creating a comprehensive, self-contained backup of your site's content.
- **Headless CMS Integration**: Providing a structured data feed for other applications.

## Features

- **Complete Content Export**: Includes all regular pages and sections.
- **Hierarchical Structure**: Preserves the nested structure of your sections and sub-sections.
- **Rich Metadata**: Exports all front matter parameters, including `tags`, `categories`, and any custom fields.
- **Content & Summary**: Page content and summaries are embedded as CDATA blocks, ensuring well-formed XML even with HTML content.
- **Resource Details**: Lists all page resources (images, documents, etc.) with their names, permalinks, types, and for images, their `width` and `height`.
- **Single File Output**: Generates one `site-export.xml` file for easy handling.

## Installation

1.  **Add as a Theme Component (Recommended)**:

    If you have an existing theme, you can add this as a component. First, add it as a Git submodule:
    ```bash
    git submodule add https://github.com/your-username/hugo-xml-exporter.git themes/hugo-xml
    ```
    Then, in your `hugo.toml` (or `config.toml`), add `hugo-xml` to your `theme` list:
    ```toml
    # hugo.toml
    theme = ["your-main-theme", "hugo-xml"]
    ```
    **Note**: For this exporter to work, you might need to temporarily make `hugo-xml` the *only* theme or ensure its `layouts` directory is prioritized. A simpler approach is to copy the `layouts` directory directly into your project's root `layouts` folder.

2.  **Direct Copy**:

    Copy the `layouts` directory from this repository directly into the `layouts` directory at the root of your Hugo project.

## Configuration (`hugo.toml`)

To enable the XML export, you need to configure a custom output format in your `hugo.toml` (or `config.toml`):

```toml
# hugo.toml

# 1. Define a new custom output format called 'SITE_XML'
[outputFormats.SITE_XML]
  mediaType = "application/xml"
  baseName = "site-export"  # This will be the name of the output file (site-export.xml)
  isPlainText = true
  notAlternative = true # Ensures it doesn't get added to <link rel="alternate">

# 2. Instruct the "home" page kind to generate ONLY this XML file.
#    This stops Hugo from generating the usual index.html for the homepage.
[outputs]
  home = ["SITE_XML"]
```

## Usage

After configuring `hugo.toml` and placing the `layouts` files correctly, simply run Hugo:

```bash
hugo
```

A file named `site-export.xml` will be generated in your `public/` directory, containing the full XML representation of your site.