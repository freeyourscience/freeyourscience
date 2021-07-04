def assemble_author_name(author: dict) -> str:
    # Even though the Unpaywall schema (https://unpaywall.org/data-format#doi-object)
    # says z_authors is exclusively a Crossref Contributor schema
    # https://github.com/CrossRef/rest-api-doc/blob/master/api_format.md#contributor
    # however, for DOI 10.1007/s00350-021-5862-6 the author schema contains no "given"
    # or "family" key but a "name" key instead.
    if "name" in author:
        return author["name"]

    name_components = []
    if "given" in author:
        name_components.append(author["given"])

    if "family" in author:
        name_components.append(author["family"])

    if not name_components:
        name_components.append("unknown authors")

    return " ".join(name_components)
