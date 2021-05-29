module KitchenSink exposing (main)

import Animation
import Array
import Author exposing (Model, subscriptions, update, view)
import Browser
import Date
import Http
import Json.Decode as D
import Msg exposing (Msg(..))
import Papers.Backend as Backend exposing (paperDecoder)
import Time exposing (Month(..))


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> initialUpdate initialModel jsonPapers
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


initialModel : Model
initialModel =
    { initialDOIs = []
    , freePathwayPapers = Array.fromList []
    , otherPathwayPapers = []
    , openAccessPapers = []
    , buggyPapers = []
    , numFailedDOIRequests = 0
    , authorProfileURL = "https://freeyourscience.org"
    , authorProfileProvider = "semantic_scholar"
    , searchQuery = "Dummy Author"
    , serverURL = ""
    , style = Animation.style []
    , today = Date.fromCalendarDate 1970 Jan 1
    }


initialUpdate : Model -> List String -> ( Model, Cmd Msg )
initialUpdate model papers =
    case List.head papers of
        Nothing ->
            ( model, Cmd.none )

        Just paper ->
            initialUpdate
                (update (decodePaperMessage paper) model |> Tuple.first)
                (List.drop 1 papers)


decodePaperMessage : String -> Msg
decodePaperMessage jsonPaper =
    case decodeJsonPaper jsonPaper of
        Ok paper ->
            paper
                |> Ok
                |> GotPaper

        Err _ ->
            jsonPaper
                |> Http.BadBody
                |> Err
                |> GotPaper


decodeJsonPaper : String -> Result D.Error Backend.Paper
decodeJsonPaper paperJson =
    paperJson
        |> D.decodeString paperDecoder



-- DUMMY DATA --


jsonPapers : List String
jsonPapers =
    [ -- no policy for ISSN
      """{
        "doi": "10.1007/978-3-319-45450-4_37",
        "title": "Actuator Design for Stabilizing Single Tendon Platforms",
        "journal": "Mechanisms and Machine Science",
        "authors": "D. Haarhoff et al.",
        "year": 2016,
        "published_date": "2016-01-01",
        "issn": "2211-0984",
        "is_open_access": false,
        "oa_pathway": "not_found",
        "oa_pathway_uri": null,
        "oa_pathway_details": null,
        "oa_location_url": null
    }"""

    -- no ISSN for publication
    , """{
        "doi": "10.1007/978-3-642-123-8",
        "title": "Geotechnik Hydrogeologie",
        "journal": null,
        "authors": "Holger Schreiner et al.",
        "year": 1997,
        "published_date": "1997-01-01",
        "issn": null,
        "is_open_access": false,
        "oa_location_url": null,
        "oa_pathway": null,
        "oa_pathway_uri": null,
        "oa_pathway_details": null
    }"""

    -- OA publication, no journal
    , """{
        "doi": "10.1371/journal.pcbi.1006283",
        "title": "Unsupervised clustering of temporal patterns in high-dimensional neuronal ensembles using a novel dissimilarity measure",
        "journal": null,
        "authors": "Lukas Grossberger et al.",
        "year": 2018,
        "published_date": "2018-01-01",
        "issn": "1553-734X",
        "is_open_access": true,
        "oa_pathway": "already_oa",
        "oa_pathway_uri": null,
        "oa_pathway_details": null,
        "oa_location_url": "https://oa-location.url"
    }"""

    -- OA publication, with journal
    , """{
        "doi": "10.1371/journal.pcbi.1006283",
        "title": "Unsupervised clustering of temporal patterns in high-dimensional neuronal ensembles using a novel dissimilarity measure",
        "journal": "PLOS Computational Biology",
        "authors": "Lukas Grossberger et al.",
        "year": 2018,
        "published_date": "2018-01-01",
        "issn": "1553-734X",
        "is_open_access": true,
        "oa_pathway": "already_oa",
        "oa_pathway_uri": null,
        "oa_pathway_details": null,
        "oa_location_url": "https://oa-location.url"
    }"""

    -- free pathway, accepted version, embargo
    , """{
      "doi": "10.1021/acsnano.8b01396",
      "title": "Nanometer-Resolved Mapping of Cell-Substrate Distances of Contracting Cardiomyocytes Using Surface Plasmon Resonance Microscopy",
      "journal": "ACS Nano",
      "authors": "Eva Kreysing et al.",
      "year": 2018,
      "published_date": "2018-01-01",
      "issn": "1936-0851",
      "is_open_access": false,
      "oa_location_url": null,
      "oa_pathway": "nocost",
      "oa_pathway_uri": "https://v2.sherpa.ac.uk/id/publication/7765",
      "oa_pathway_details": [
          {
              "uri": "https://v2.sherpa.ac.uk/id/publisher_policy/4",
              "notes": "General policy note. Make sure to read this closely!",
              "urls": [
                  {
                      "description": "Copyright & Permissions",
                      "url": "http://pubs.acs.org/page/copyright/index.html"
                  },
                  {
                      "description": "ACS Journal Publishing Agreement",
                      "url": "http://pubs.acs.org/page/4authors/jpa/index.html"
                  },
                  {
                      "description": "Funder Specific Options - U.S. National Institutes of Health",
                      "url": "http://pubs.acs.org/page/policy/nih/index.html"
                  },
                  {
                      "url": "http://pubs.acs.org/userimages/ContentEditor/1285231362937/jpa_user_guide.pdf",
                      "description": "ACS Journal Publishing Agreement User's Guide"
                  },
                  {
                      "url": "https://pubs.acs.org/page/4authors/authorchoice/options.html",
                      "description": "ACS AuthorChoice: License and Pricing Options"
                  },
                  {
                      "url": "https://pubs.acs.org/page/policy/authorchoice/index.html",
                      "description": "About ACS Author Choice"
                  },
                  {
                      "description": "Example Prior Publication Policy",
                      "url": "https://publish.acs.org/publish/author_guidelines?coden=langd5#prior_publication_policy"
                  }
              ],
              "open_access_prohibited_phrases": [
                  {
                      "language": "en",
                      "value": "no",
                      "phrase": "No"
                  }
              ],
              "internal_moniker": "Default Policy",
              "id": 4,
              "permitted_oa": [
                  {
                      "conditions": [
                          "Must not violate ACS ethical Guidelines",
                          "Must note use if preprint server in cover letter and provide link to deposit",
                          "Upon publication add a link to published article with DOI"
                      ],
                      "additional_oa_fee_phrases": [
                          {
                              "language": "en",
                              "value": "no",
                              "phrase": "No"
                          }
                      ],
                      "additional_oa_fee": "no",
                      "location": {
                          "location": [
                              "named_repository",
                              "preprint_repository",
                              "subject_repository"
                          ],
                          "location_phrases": [
                              {
                                  "value": "named_repository",
                                  "phrase": "Named Repository",
                                  "language": "en"
                              },
                              {
                                  "value": "preprint_repository",
                                  "phrase": "Preprint Repository",
                                  "language": "en"
                              },
                              {
                                  "language": "en",
                                  "phrase": "Subject Repository",
                                  "value": "subject_repository"
                              }
                          ],
                          "named_repository": [
                              "ChemRxiv",
                              "bioRxiv",
                              "arXiv"
                          ]
                      },
                      "article_version_phrases": [
                          {
                              "language": "en",
                              "value": "submitted",
                              "phrase": "Submitted"
                          }
                      ],
                      "article_version": [
                          "submitted"
                      ]
                  },
                  {
                      "embargo": {
                          "units_phrases": [
                              {
                                  "language": "en",
                                  "value": "months",
                                  "phrase": "Months"
                              }
                          ],
                          "amount": 12,
                          "units": "months"
                      },
                      "article_version": [
                          "accepted"
                      ],
                      "public_notes": [
                          "If mandated to deposit before 12 months, the author must obtain a waiver from their Institution/Funding agency or use AuthorChoice"
                      ],
                      "additional_oa_fee": "no",
                      "conditions": [
                          "Must be accompanied by set statement (see policy)",
                          "Must link to publisher version"
                      ],
                      "additional_oa_fee_phrases": [
                          {
                              "value": "no",
                              "phrase": "No",
                              "language": "en"
                          }
                      ],
                      "location": {
                          "location_phrases": [
                              {
                                  "language": "en",
                                  "value": "authors_homepage",
                                  "phrase": "Author's Homepage"
                              },
                              {
                                  "language": "en",
                                  "phrase": "Institutional Website",
                                  "value": "institutional_website"
                              },
                              {
                                  "language": "en",
                                  "phrase": "Non-Commercial Institutional Repository",
                                  "value": "non_commercial_institutional_repository"
                              },
                              {
                                  "phrase": "Non-Commercial Subject Repository",
                                  "value": "non_commercial_subject_repository",
                                  "language": "en"
                              },
                              {
                                  "language": "en",
                                  "value": "preprint_repository",
                                  "phrase": "Preprint Repository"
                              }
                          ],
                          "location": [
                              "authors_homepage",
                              "institutional_website",
                              "non_commercial_institutional_repository",
                              "non_commercial_subject_repository",
                              "preprint_repository"
                          ]
                      },
                      "prerequisites": {
                          "prerequisites_phrases": [
                              {
                                  "phrase": "If Required by Funder",
                                  "value": "when_required_by_funder",
                                  "language": "en"
                              },
                              {
                                  "value": "when_required_by_institution",
                                  "phrase": "If Required by Institution",
                                  "language": "en"
                              }
                          ],
                          "prerequisites": [
                              "when_required_by_funder",
                              "when_required_by_institution"
                          ]
                      },
                      "article_version_phrases": [
                          {
                              "phrase": "Accepted",
                              "value": "accepted",
                              "language": "en"
                          }
                      ]
                  },
                  {
                      "article_version_phrases": [
                          {
                              "value": "published",
                              "phrase": "Published",
                              "language": "en"
                          }
                      ],
                      "location": {
                          "location_phrases": [
                              {
                                  "language": "en",
                                  "value": "funder_designated_location",
                                  "phrase": "Funder Designated Location"
                              },
                              {
                                  "value": "named_repository",
                                  "phrase": "Named Repository",
                                  "language": "en"
                              },
                              {
                                  "value": "this_journal",
                                  "phrase": "Journal Website",
                                  "language": "en"
                              }
                          ],
                          "location": [
                              "funder_designated_location",
                              "named_repository",
                              "this_journal"
                          ],
                          "named_repository": [
                              "PubMed Central"
                          ]
                      },
                      "copyright_owner": "publishers",
                      "additional_oa_fee_phrases": [
                          {
                              "language": "en",
                              "phrase": "Yes",
                              "value": "yes"
                          }
                      ],
                      "copyright_owner_phrases": [
                          {
                              "language": "en",
                              "value": "publishers",
                              "phrase": "Publishers"
                          }
                      ],
                      "additional_oa_fee": "yes",
                      "article_version": [
                          "published"
                      ],
                      "license": [
                          {
                              "version": "4.0",
                              "license": "cc_by",
                              "license_phrases": [
                                  {
                                      "phrase": "CC BY",
                                      "value": "cc_by",
                                      "language": "en"
                                  }
                              ]
                          },
                          {
                              "license_phrases": [
                                  {
                                      "language": "en",
                                      "value": "cc_by_nc_nd",
                                      "phrase": "CC BY-NC-ND"
                                  }
                              ],
                              "license": "cc_by_nc_nd",
                              "version": "4.0"
                          },
                          {
                              "license_phrases": [
                                  {
                                      "value": "bespoke_license",
                                      "phrase": "Publisher's Bespoke License",
                                      "language": "en"
                                  }
                              ],
                              "license": "bespoke_license",
                              "version": ""
                          }
                      ],
                      "publisher_deposit": [
                          {
                              "system_metadata": {
                                  "uri": "https://v2.sherpa.ac.uk/id/repository/267",
                                  "id": 267
                              },
                              "repository_metadata": {
                                  "type_phrases": [
                                      {
                                          "language": "en",
                                          "phrase": "Disciplinary",
                                          "value": "disciplinary"
                                      }
                                  ],
                                  "url": "http://www.ncbi.nlm.nih.gov/pmc/",
                                  "type": "disciplinary",
                                  "name": [
                                      {
                                          "preferred": "name",
                                          "language_phrases": [
                                              {
                                                  "value": "en",
                                                  "phrase": "English",
                                                  "language": "en"
                                              }
                                          ],
                                          "language": "en",
                                          "preferred_phrases": [
                                              {
                                                  "language": "en",
                                                  "phrase": "Name",
                                                  "value": "name"
                                              }
                                          ],
                                          "name": "PubMed Central"
                                      }
                                  ],
                                  "description": "Repository Description"
                              }
                          }
                      ]
                  },
                  {
                      "embargo": {
                          "units_phrases": [
                              {
                                  "value": "months",
                                  "phrase": "Months",
                                  "language": "en"
                              }
                          ],
                          "units": "months",
                          "amount": 12
                      },
                      "license": [
                          {
                              "license": "cc_by",
                              "license_phrases": [
                                  {
                                      "language": "en",
                                      "phrase": "CC BY",
                                      "value": "cc_by"
                                  }
                              ],
                              "version": "4.0"
                          },
                          {
                              "version": "4.0",
                              "license": "cc_by_nc_nd",
                              "license_phrases": [
                                  {
                                      "phrase": "CC BY-NC-ND",
                                      "value": "cc_by_nc_nd",
                                      "language": "en"
                                  }
                              ]
                          },
                          {
                              "version": "",
                              "license": "bespoke_license",
                              "license_phrases": [
                                  {
                                      "value": "bespoke_license",
                                      "phrase": "Publisher's Bespoke License",
                                      "language": "en"
                                  }
                              ]
                          }
                      ],
                      "article_version": [
                          "published"
                      ],
                      "public_notes": [
                          "The fee for this pathway is lower than that for immediate open access"
                      ],
                      "additional_oa_fee": "yes",
                      "copyright_owner_phrases": [
                          {
                              "value": "publishers",
                              "phrase": "Publishers",
                              "language": "en"
                          }
                      ],
                      "additional_oa_fee_phrases": [
                          {
                              "language": "en",
                              "value": "yes",
                              "phrase": "Yes"
                          }
                      ],
                      "copyright_owner": "publishers",
                      "location": {
                          "named_repository": [
                              "PubMed Central"
                          ],
                          "location": [
                              "authors_homepage",
                              "institutional_repository",
                              "named_repository",
                              "this_journal"
                          ],
                          "location_phrases": [
                              {
                                  "language": "en",
                                  "value": "authors_homepage",
                                  "phrase": "Author's Homepage"
                              },
                              {
                                  "value": "institutional_repository",
                                  "phrase": "Institutional Repository",
                                  "language": "en"
                              },
                              {
                                  "value": "named_repository",
                                  "phrase": "Named Repository",
                                  "language": "en"
                              },
                              {
                                  "language": "en",
                                  "phrase": "Journal Website",
                                  "value": "this_journal"
                              }
                          ]
                      },
                      "article_version_phrases": [
                          {
                              "value": "published",
                              "phrase": "Published",
                              "language": "en"
                          }
                      ]
                  }
              ],
              "open_access_prohibited": "no",
              "publication_count": 62
          }
      ]
    }"""

    -- free pathway, duplicate?
    , """{
      "doi": "10.1021/acsnano.8b01396",
      "title": "Only Notes Nanometer-Resolved Mapping of Cell-Substrate Distances",
      "journal": "ACS Nano",
      "authors": "Eva Kreysing et al.",
      "year": 2018,
      "published_date": "2018-01-01",
      "issn": "1936-0851",
      "is_open_access": false,
      "oa_location_url": null,
      "oa_pathway": "nocost",
      "oa_pathway_uri": "https://v2.sherpa.ac.uk/id/publication/7765",
      "oa_pathway_details": [
          {
              "uri": "https://v2.sherpa.ac.uk/id/publisher_policy/4",
              "notes": "General policy note. Make sure to read this closely!",
              "urls": [
                  {
                      "description": "Copyright & Permissions",
                      "url": "http://pubs.acs.org/page/copyright/index.html"
                  },
                  {
                      "description": "ACS Journal Publishing Agreement",
                      "url": "http://pubs.acs.org/page/4authors/jpa/index.html"
                  },
                  {
                      "description": "Funder Specific Options - U.S. National Institutes of Health",
                      "url": "http://pubs.acs.org/page/policy/nih/index.html"
                  },
                  {
                      "url": "http://pubs.acs.org/userimages/ContentEditor/1285231362937/jpa_user_guide.pdf",
                      "description": "ACS Journal Publishing Agreement User's Guide"
                  },
                  {
                      "url": "https://pubs.acs.org/page/4authors/authorchoice/options.html",
                      "description": "ACS AuthorChoice: License and Pricing Options"
                  },
                  {
                      "url": "https://pubs.acs.org/page/policy/authorchoice/index.html",
                      "description": "About ACS Author Choice"
                  },
                  {
                      "description": "Example Prior Publication Policy",
                      "url": "https://publish.acs.org/publish/author_guidelines?coden=langd5#prior_publication_policy"
                  }
              ],
              "open_access_prohibited_phrases": [
                  {
                      "language": "en",
                      "value": "no",
                      "phrase": "No"
                  }
              ],
              "internal_moniker": "Default Policy",
              "id": 4,
              "permitted_oa": [
                  {
                      "conditions": [
                          "Must not violate ACS ethical Guidelines",
                          "Must note use if preprint server in cover letter and provide link to deposit",
                          "Upon publication add a link to published article with DOI"
                      ],
                      "additional_oa_fee_phrases": [
                          {
                              "language": "en",
                              "value": "no",
                              "phrase": "No"
                          }
                      ],
                      "additional_oa_fee": "no",
                      "location": {
                          "location": [
                              "named_repository",
                              "preprint_repository",
                              "subject_repository"
                          ],
                          "location_phrases": [
                              {
                                  "value": "named_repository",
                                  "phrase": "Named Repository",
                                  "language": "en"
                              },
                              {
                                  "value": "preprint_repository",
                                  "phrase": "Preprint Repository",
                                  "language": "en"
                              },
                              {
                                  "language": "en",
                                  "phrase": "Subject Repository",
                                  "value": "subject_repository"
                              }
                          ],
                          "named_repository": [
                              "ChemRxiv",
                              "bioRxiv",
                              "arXiv"
                          ]
                      },
                      "article_version_phrases": [
                          {
                              "language": "en",
                              "value": "submitted",
                              "phrase": "Submitted"
                          }
                      ],
                      "article_version": [
                          "submitted"
                      ]
                  },
                  {
                      "embargo": {
                          "units_phrases": [
                              {
                                  "language": "en",
                                  "value": "months",
                                  "phrase": "Months"
                              }
                          ],
                          "amount": 12,
                          "units": "months"
                      },
                      "article_version": [
                          "accepted"
                      ],
                      "public_notes": [
                          "If mandated to deposit before 12 months, the author must obtain a waiver from their Institution/Funding agency or use AuthorChoice"
                      ],
                      "additional_oa_fee": "no",
                      "conditions": [
                          "Must be accompanied by set statement (see policy)",
                          "Must link to publisher version"
                      ],
                      "additional_oa_fee_phrases": [
                          {
                              "value": "no",
                              "phrase": "No",
                              "language": "en"
                          }
                      ],
                      "location": {
                          "location_phrases": [
                              {
                                  "language": "en",
                                  "value": "authors_homepage",
                                  "phrase": "Author's Homepage"
                              },
                              {
                                  "language": "en",
                                  "phrase": "Institutional Website",
                                  "value": "institutional_website"
                              },
                              {
                                  "language": "en",
                                  "phrase": "Non-Commercial Institutional Repository",
                                  "value": "non_commercial_institutional_repository"
                              },
                              {
                                  "phrase": "Non-Commercial Subject Repository",
                                  "value": "non_commercial_subject_repository",
                                  "language": "en"
                              },
                              {
                                  "language": "en",
                                  "value": "preprint_repository",
                                  "phrase": "Preprint Repository"
                              }
                          ],
                          "location": [
                              "authors_homepage",
                              "institutional_website",
                              "non_commercial_institutional_repository",
                              "non_commercial_subject_repository",
                              "preprint_repository"
                          ]
                      },
                      "article_version_phrases": [
                          {
                              "phrase": "Accepted",
                              "value": "accepted",
                              "language": "en"
                          }
                      ]
                  },
                  {
                      "article_version_phrases": [
                          {
                              "value": "published",
                              "phrase": "Published",
                              "language": "en"
                          }
                      ],
                      "location": {
                          "location_phrases": [
                              {
                                  "language": "en",
                                  "value": "funder_designated_location",
                                  "phrase": "Funder Designated Location"
                              },
                              {
                                  "value": "named_repository",
                                  "phrase": "Named Repository",
                                  "language": "en"
                              },
                              {
                                  "value": "this_journal",
                                  "phrase": "Journal Website",
                                  "language": "en"
                              }
                          ],
                          "location": [
                              "funder_designated_location",
                              "named_repository",
                              "this_journal"
                          ],
                          "named_repository": [
                              "PubMed Central"
                          ]
                      },
                      "copyright_owner": "publishers",
                      "additional_oa_fee_phrases": [
                          {
                              "language": "en",
                              "phrase": "Yes",
                              "value": "yes"
                          }
                      ],
                      "copyright_owner_phrases": [
                          {
                              "language": "en",
                              "value": "publishers",
                              "phrase": "Publishers"
                          }
                      ],
                      "additional_oa_fee": "yes",
                      "article_version": [
                          "published"
                      ],
                      "license": [
                          {
                              "version": "4.0",
                              "license": "cc_by",
                              "license_phrases": [
                                  {
                                      "phrase": "CC BY",
                                      "value": "cc_by",
                                      "language": "en"
                                  }
                              ]
                          },
                          {
                              "license_phrases": [
                                  {
                                      "language": "en",
                                      "value": "cc_by_nc_nd",
                                      "phrase": "CC BY-NC-ND"
                                  }
                              ],
                              "license": "cc_by_nc_nd",
                              "version": "4.0"
                          },
                          {
                              "license_phrases": [
                                  {
                                      "value": "bespoke_license",
                                      "phrase": "Publisher's Bespoke License",
                                      "language": "en"
                                  }
                              ],
                              "license": "bespoke_license",
                              "version": ""
                          }
                      ],
                      "publisher_deposit": [
                          {
                              "system_metadata": {
                                  "uri": "https://v2.sherpa.ac.uk/id/repository/267",
                                  "id": 267
                              },
                              "repository_metadata": {
                                  "type_phrases": [
                                      {
                                          "language": "en",
                                          "phrase": "Disciplinary",
                                          "value": "disciplinary"
                                      }
                                  ],
                                  "url": "http://www.ncbi.nlm.nih.gov/pmc/",
                                  "type": "disciplinary",
                                  "name": [
                                      {
                                          "preferred": "name",
                                          "language_phrases": [
                                              {
                                                  "value": "en",
                                                  "phrase": "English",
                                                  "language": "en"
                                              }
                                          ],
                                          "language": "en",
                                          "preferred_phrases": [
                                              {
                                                  "language": "en",
                                                  "phrase": "Name",
                                                  "value": "name"
                                              }
                                          ],
                                          "name": "PubMed Central"
                                      }
                                  ],
                                  "description": "Repository Description"
                              }
                          }
                      ]
                  },
                  {
                      "embargo": {
                          "units_phrases": [
                              {
                                  "value": "months",
                                  "phrase": "Months",
                                  "language": "en"
                              }
                          ],
                          "units": "months",
                          "amount": 12
                      },
                      "license": [
                          {
                              "license": "cc_by",
                              "license_phrases": [
                                  {
                                      "language": "en",
                                      "phrase": "CC BY",
                                      "value": "cc_by"
                                  }
                              ],
                              "version": "4.0"
                          },
                          {
                              "version": "4.0",
                              "license": "cc_by_nc_nd",
                              "license_phrases": [
                                  {
                                      "phrase": "CC BY-NC-ND",
                                      "value": "cc_by_nc_nd",
                                      "language": "en"
                                  }
                              ]
                          },
                          {
                              "version": "",
                              "license": "bespoke_license",
                              "license_phrases": [
                                  {
                                      "value": "bespoke_license",
                                      "phrase": "Publisher's Bespoke License",
                                      "language": "en"
                                  }
                              ]
                          }
                      ],
                      "article_version": [
                          "published"
                      ],
                      "public_notes": [
                          "The fee for this pathway is lower than that for immediate open access"
                      ],
                      "additional_oa_fee": "yes",
                      "copyright_owner_phrases": [
                          {
                              "value": "publishers",
                              "phrase": "Publishers",
                              "language": "en"
                          }
                      ],
                      "additional_oa_fee_phrases": [
                          {
                              "language": "en",
                              "value": "yes",
                              "phrase": "Yes"
                          }
                      ],
                      "copyright_owner": "publishers",
                      "location": {
                          "named_repository": [
                              "PubMed Central"
                          ],
                          "location": [
                              "authors_homepage",
                              "institutional_repository",
                              "named_repository",
                              "this_journal"
                          ],
                          "location_phrases": [
                              {
                                  "language": "en",
                                  "value": "authors_homepage",
                                  "phrase": "Author's Homepage"
                              },
                              {
                                  "value": "institutional_repository",
                                  "phrase": "Institutional Repository",
                                  "language": "en"
                              },
                              {
                                  "value": "named_repository",
                                  "phrase": "Named Repository",
                                  "language": "en"
                              },
                              {
                                  "language": "en",
                                  "phrase": "Journal Website",
                                  "value": "this_journal"
                              }
                          ]
                      },
                      "article_version_phrases": [
                          {
                              "value": "published",
                              "phrase": "Published",
                              "language": "en"
                          }
                      ]
                  }
              ],
              "open_access_prohibited": "no",
              "publication_count": 62
          }
      ]
    }"""

    -- free pathway, not sure what set it apart
    , """{
      "doi": "10.1021/acsnano.8b01396",
      "title": "Nanometer-Enhanced Mapping of Cell-Substrate Distances With Just Prerequisites",
      "journal": "ACS Nano",
      "authors": "Eva Kreysing et al.",
      "year": 2018,
      "published_date": "2018-01-01",
      "issn": "1936-0851",
      "is_open_access": false,
      "oa_location_url": null,
      "oa_pathway": "nocost",
      "oa_pathway_uri": "https://v2.sherpa.ac.uk/id/publication/7765",
      "oa_pathway_details": [
          {
              "uri": "https://v2.sherpa.ac.uk/id/publisher_policy/4",
              "notes": "General policy note. Make sure to read this closely!",
              "urls": [
                  {
                      "description": "Copyright & Permissions",
                      "url": "http://pubs.acs.org/page/copyright/index.html"
                  },
                  {
                      "description": "ACS Journal Publishing Agreement",
                      "url": "http://pubs.acs.org/page/4authors/jpa/index.html"
                  },
                  {
                      "description": "Funder Specific Options - U.S. National Institutes of Health",
                      "url": "http://pubs.acs.org/page/policy/nih/index.html"
                  },
                  {
                      "url": "http://pubs.acs.org/userimages/ContentEditor/1285231362937/jpa_user_guide.pdf",
                      "description": "ACS Journal Publishing Agreement User's Guide"
                  },
                  {
                      "url": "https://pubs.acs.org/page/4authors/authorchoice/options.html",
                      "description": "ACS AuthorChoice: License and Pricing Options"
                  },
                  {
                      "url": "https://pubs.acs.org/page/policy/authorchoice/index.html",
                      "description": "About ACS Author Choice"
                  },
                  {
                      "description": "Example Prior Publication Policy",
                      "url": "https://publish.acs.org/publish/author_guidelines?coden=langd5#prior_publication_policy"
                  }
              ],
              "open_access_prohibited_phrases": [
                  {
                      "language": "en",
                      "value": "no",
                      "phrase": "No"
                  }
              ],
              "internal_moniker": "Default Policy",
              "id": 4,
              "permitted_oa": [
                  {
                      "conditions": [
                          "Must not violate ACS ethical Guidelines",
                          "Must note use if preprint server in cover letter and provide link to deposit",
                          "Upon publication add a link to published article with DOI"
                      ],
                      "additional_oa_fee_phrases": [
                          {
                              "language": "en",
                              "value": "no",
                              "phrase": "No"
                          }
                      ],
                      "additional_oa_fee": "no",
                      "location": {
                          "location": [
                              "named_repository",
                              "preprint_repository",
                              "subject_repository"
                          ],
                          "location_phrases": [
                              {
                                  "value": "named_repository",
                                  "phrase": "Named Repository",
                                  "language": "en"
                              },
                              {
                                  "value": "preprint_repository",
                                  "phrase": "Preprint Repository",
                                  "language": "en"
                              },
                              {
                                  "language": "en",
                                  "phrase": "Subject Repository",
                                  "value": "subject_repository"
                              }
                          ],
                          "named_repository": [
                              "ChemRxiv",
                              "bioRxiv",
                              "arXiv"
                          ]
                      },
                      "article_version_phrases": [
                          {
                              "language": "en",
                              "value": "submitted",
                              "phrase": "Submitted"
                          }
                      ],
                      "article_version": [
                          "submitted"
                      ]
                  },
                  {
                      "embargo": {
                          "units_phrases": [
                              {
                                  "language": "en",
                                  "value": "months",
                                  "phrase": "Months"
                              }
                          ],
                          "amount": 12,
                          "units": "months"
                      },
                      "article_version": [
                          "accepted"
                      ],
                      "additional_oa_fee": "no",
                      "conditions": [
                          "Must be accompanied by set statement (see policy)",
                          "Must link to publisher version"
                      ],
                      "additional_oa_fee_phrases": [
                          {
                              "value": "no",
                              "phrase": "No",
                              "language": "en"
                          }
                      ],
                      "location": {
                          "location_phrases": [
                              {
                                  "language": "en",
                                  "value": "authors_homepage",
                                  "phrase": "Author's Homepage"
                              },
                              {
                                  "language": "en",
                                  "phrase": "Institutional Website",
                                  "value": "institutional_website"
                              },
                              {
                                  "language": "en",
                                  "phrase": "Non-Commercial Institutional Repository",
                                  "value": "non_commercial_institutional_repository"
                              },
                              {
                                  "phrase": "Non-Commercial Subject Repository",
                                  "value": "non_commercial_subject_repository",
                                  "language": "en"
                              },
                              {
                                  "language": "en",
                                  "value": "preprint_repository",
                                  "phrase": "Preprint Repository"
                              }
                          ],
                          "location": [
                              "authors_homepage",
                              "institutional_website",
                              "non_commercial_institutional_repository",
                              "non_commercial_subject_repository",
                              "preprint_repository"
                          ]
                      },
                      "prerequisites": {
                          "prerequisites_phrases": [
                              {
                                  "phrase": "If Required by Funder",
                                  "value": "when_required_by_funder",
                                  "language": "en"
                              },
                              {
                                  "value": "when_required_by_institution",
                                  "phrase": "If Required by Institution",
                                  "language": "en"
                              }
                          ],
                          "prerequisites": [
                              "when_required_by_funder",
                              "when_required_by_institution"
                          ]
                      },
                      "article_version_phrases": [
                          {
                              "phrase": "Accepted",
                              "value": "accepted",
                              "language": "en"
                          }
                      ]
                  },
                  {
                      "article_version_phrases": [
                          {
                              "value": "published",
                              "phrase": "Published",
                              "language": "en"
                          }
                      ],
                      "location": {
                          "location_phrases": [
                              {
                                  "language": "en",
                                  "value": "funder_designated_location",
                                  "phrase": "Funder Designated Location"
                              },
                              {
                                  "value": "named_repository",
                                  "phrase": "Named Repository",
                                  "language": "en"
                              },
                              {
                                  "value": "this_journal",
                                  "phrase": "Journal Website",
                                  "language": "en"
                              }
                          ],
                          "location": [
                              "funder_designated_location",
                              "named_repository",
                              "this_journal"
                          ],
                          "named_repository": [
                              "PubMed Central"
                          ]
                      },
                      "copyright_owner": "publishers",
                      "additional_oa_fee_phrases": [
                          {
                              "language": "en",
                              "phrase": "Yes",
                              "value": "yes"
                          }
                      ],
                      "copyright_owner_phrases": [
                          {
                              "language": "en",
                              "value": "publishers",
                              "phrase": "Publishers"
                          }
                      ],
                      "additional_oa_fee": "yes",
                      "article_version": [
                          "published"
                      ],
                      "license": [
                          {
                              "version": "4.0",
                              "license": "cc_by",
                              "license_phrases": [
                                  {
                                      "phrase": "CC BY",
                                      "value": "cc_by",
                                      "language": "en"
                                  }
                              ]
                          },
                          {
                              "license_phrases": [
                                  {
                                      "language": "en",
                                      "value": "cc_by_nc_nd",
                                      "phrase": "CC BY-NC-ND"
                                  }
                              ],
                              "license": "cc_by_nc_nd",
                              "version": "4.0"
                          },
                          {
                              "license_phrases": [
                                  {
                                      "value": "bespoke_license",
                                      "phrase": "Publisher's Bespoke License",
                                      "language": "en"
                                  }
                              ],
                              "license": "bespoke_license",
                              "version": ""
                          }
                      ],
                      "publisher_deposit": [
                          {
                              "system_metadata": {
                                  "uri": "https://v2.sherpa.ac.uk/id/repository/267",
                                  "id": 267
                              },
                              "repository_metadata": {
                                  "type_phrases": [
                                      {
                                          "language": "en",
                                          "phrase": "Disciplinary",
                                          "value": "disciplinary"
                                      }
                                  ],
                                  "url": "http://www.ncbi.nlm.nih.gov/pmc/",
                                  "type": "disciplinary",
                                  "name": [
                                      {
                                          "preferred": "name",
                                          "language_phrases": [
                                              {
                                                  "value": "en",
                                                  "phrase": "English",
                                                  "language": "en"
                                              }
                                          ],
                                          "language": "en",
                                          "preferred_phrases": [
                                              {
                                                  "language": "en",
                                                  "phrase": "Name",
                                                  "value": "name"
                                              }
                                          ],
                                          "name": "PubMed Central"
                                      }
                                  ],
                                  "description": "Repository Description"
                              }
                          }
                      ]
                  },
                  {
                      "embargo": {
                          "units_phrases": [
                              {
                                  "value": "months",
                                  "phrase": "Months",
                                  "language": "en"
                              }
                          ],
                          "units": "months",
                          "amount": 12
                      },
                      "license": [
                          {
                              "license": "cc_by",
                              "license_phrases": [
                                  {
                                      "language": "en",
                                      "phrase": "CC BY",
                                      "value": "cc_by"
                                  }
                              ],
                              "version": "4.0"
                          },
                          {
                              "version": "4.0",
                              "license": "cc_by_nc_nd",
                              "license_phrases": [
                                  {
                                      "phrase": "CC BY-NC-ND",
                                      "value": "cc_by_nc_nd",
                                      "language": "en"
                                  }
                              ]
                          },
                          {
                              "version": "",
                              "license": "bespoke_license",
                              "license_phrases": [
                                  {
                                      "value": "bespoke_license",
                                      "phrase": "Publisher's Bespoke License",
                                      "language": "en"
                                  }
                              ]
                          }
                      ],
                      "article_version": [
                          "published"
                      ],
                      "public_notes": [
                          "The fee for this pathway is lower than that for immediate open access"
                      ],
                      "additional_oa_fee": "yes",
                      "copyright_owner_phrases": [
                          {
                              "value": "publishers",
                              "phrase": "Publishers",
                              "language": "en"
                          }
                      ],
                      "additional_oa_fee_phrases": [
                          {
                              "language": "en",
                              "value": "yes",
                              "phrase": "Yes"
                          }
                      ],
                      "copyright_owner": "publishers",
                      "location": {
                          "named_repository": [
                              "PubMed Central"
                          ],
                          "location": [
                              "authors_homepage",
                              "institutional_repository",
                              "named_repository",
                              "this_journal"
                          ],
                          "location_phrases": [
                              {
                                  "language": "en",
                                  "value": "authors_homepage",
                                  "phrase": "Author's Homepage"
                              },
                              {
                                  "value": "institutional_repository",
                                  "phrase": "Institutional Repository",
                                  "language": "en"
                              },
                              {
                                  "value": "named_repository",
                                  "phrase": "Named Repository",
                                  "language": "en"
                              },
                              {
                                  "language": "en",
                                  "phrase": "Journal Website",
                                  "value": "this_journal"
                              }
                          ]
                      },
                      "article_version_phrases": [
                          {
                              "value": "published",
                              "phrase": "Published",
                              "language": "en"
                          }
                      ]
                  }
              ],
              "open_access_prohibited": "no",
              "publication_count": 62
          }
      ]
    }"""

    -- free pathway, no embargo
    , """{
    "doi": "10.1364/ol.44.001359",
    "title": "Noninvasive measurement of the refractive index of cell organelles using surface plasmon resonance microscopy",
    "journal": "Optics Letters",
    "authors": "Hossein Hassani et al.",
    "year": 2019,
    "published_date": "2019-01-01",
    "issn": "0146-9592",
    "is_open_access": false,
    "oa_pathway": "nocost",
    "oa_location_url": "#oa-location",
    "oa_pathway_uri": "https://v2.sherpa.ac.uk/id/publication/13362",
    "oa_pathway_details": [
        {
            "publication_count": 13,
            "permitted_oa": [
                {
                    "location": {
                        "location_phrases": [
                            {
                                "value": "named_repository",
                                "phrase": "Named Repository",
                                "language": "en"
                            },
                            {
                                "language": "en",
                                "value": "preprint_repository",
                                "phrase": "Preprint Repository"
                            }
                        ],
                        "location": [
                            "named_repository",
                            "preprint_repository"
                        ],
                        "named_repository": [
                            "arXiv"
                        ]
                    },
                    "article_version_phrases": [
                        {
                            "value": "submitted",
                            "phrase": "Submitted",
                            "language": "en"
                        },
                        {
                            "phrase": "Accepted",
                            "value": "accepted",
                            "language": "en"
                        }
                    ],
                    "article_version": [
                        "submitted",
                        "accepted"
                    ],
                    "conditions": [
                        "Publisher automatically deposited in PubMed Central for selected titles",
                        "Must link to publisher version",
                        "Publisher copyright and source must be acknowledged with set statement (see policy)"
                    ],
                    "additional_oa_fee_phrases": [
                        {
                            "language": "en",
                            "value": "no",
                            "phrase": "No"
                        }
                    ],
                    "additional_oa_fee": "no"
                },
                {
                    "article_version": [
                        "submitted",
                        "accepted"
                    ],
                    "location": {
                        "location_phrases": [
                            {
                                "phrase": "Funder Designated Location",
                                "value": "funder_designated_location",
                                "language": "en"
                            },
                            {
                                "language": "en",
                                "value": "institutional_repository",
                                "phrase": "Institutional Repository"
                            }
                        ],
                        "location": [
                            "funder_designated_location",
                            "institutional_repository"
                        ]
                    },
                    "article_version_phrases": [
                        {
                            "phrase": "Submitted",
                            "value": "submitted",
                            "language": "en"
                        },
                        {
                            "language": "en",
                            "phrase": "Accepted",
                            "value": "accepted"
                        }
                    ],
                    "embargo": {
                        "units_phrases": [
                            {
                                "language": "en",
                                "phrase": "Months",
                                "value": "months"
                            }
                        ],
                        "amount": 12,
                        "units": "months"
                    },
                    "additional_oa_fee": "no",
                    "conditions": [
                        "Publisher copyright and source must be acknowledged with set statement (see policy)",
                        "Publisher automatically deposited in PubMed Central for selected titles",
                        "Must link to publisher version"
                    ],
                    "additional_oa_fee_phrases": [
                        {
                            "value": "no",
                            "phrase": "No",
                            "language": "en"
                        }
                    ]
                }
            ],
            "open_access_prohibited": "no",
            "id": 108,
            "open_access_prohibited_phrases": [
                {
                    "value": "no",
                    "phrase": "No",
                    "language": "en"
                }
            ],
            "internal_moniker": "Default policy",
            "uri": "https://v2.sherpa.ac.uk/id/publisher_policy/108",
            "urls": [
                {
                    "description": "Posting Policy",
                    "url": "https://www.osapublishing.org/submit/review/copyright_permissions.cfm#posting"
                },
                {
                    "url": "https://www.osapublishing.org/submit/forms/copyxfer.pdf",
                    "description": "Copyright Transfer Agreement"
                }
            ]
        }
    ]
    }"""

    -- free pathway, prerequisite funders
    , """{
    "doi": "10.1016/s0001-4079(19)34586-8",
    "title": "Nouveaux progrès et nouveaux outils d’étude de la génétique moléculaire des dyslipoprotéinémies",
    "journal": "Bulletin de l'Académie Nationale de Médecine",
    "authors": "Pascale Benlian et al.",
    "year": 2001,
    "published_date": "2001-01-01",
    "issn": "0001-4079",
    "is_open_access": false,
    "oa_location_url": null,
    "oa_pathway": "nocost",
    "oa_pathway_uri": "https://v2.sherpa.ac.uk/id/publication/10419",
    "oa_pathway_details": [
        {
        "uri": "https://v2.sherpa.ac.uk/id/publisher_policy/3329",
        "internal_moniker": "UK Funder 12 months",
        "open_access_prohibited": "no",
        "open_access_prohibited_phrases": [
            { "phrase": "No", "value": "no", "language": "en" }
        ],
        "permitted_oa": [
            {
            "conditions": ["Must link to publisher version with DOI"],
            "article_version": ["accepted"],
            "prerequisites": {
                "prerequisite_funders": [
                {
                    "funder_metadata": {
                    "identifiers": [
                        {
                        "identifier": "http://dx.doi.org/10.13039/100004440",
                        "type_phrases": [
                            {
                            "phrase": "FundRef DOI",
                            "value": "fundref",
                            "language": "en"
                            }
                        ],
                        "type": "fundref"
                        },
                        {
                        "identifier": "https://ror.org/029chgv08",
                        "type": "ror",
                        "type_phrases": [
                            { "phrase": "ROR ID", "value": "ror", "language": "en" }
                        ]
                        }
                    ],
                    "name": [
                        {
                        "preferred_phrases": [
                            { "language": "en", "phrase": "Name", "value": "name" }
                        ],
                        "preferred": "name",
                        "language_phrases": [
                            { "value": "en", "phrase": "English", "language": "en" }
                        ],
                        "name": "Wellcome Trust",
                        "language": "en"
                        }
                    ],
                    "groups": [
                        {
                        "type": "funder_group",
                        "id": 1059,
                        "name": "Europe PMC Funders' Group",
                        "uri": "https://v2.sherpa.ac.uk/id/funder_group/1059"
                        },
                        {
                        "id": 1063,
                        "name": "Plan S Funders",
                        "uri": "https://v2.sherpa.ac.uk/id/funder_group/1063",
                        "type": "funder_group"
                        }
                    ],
                    "url": [
                        {
                        "url": "http://www.wellcome.ac.uk/",
                        "language_phrases": [
                            { "phrase": "English", "value": "en", "language": "en" }
                        ],
                        "language": "en"
                        }
                    ],
                    "id": 695,
                    "country": "gb",
                    "country_phrases": [
                        {
                        "phrase": "United Kingdom",
                        "value": "gb",
                        "language": "en"
                        }
                    ]
                    },
                    "system_metadata": {
                    "uri": "https://v2.sherpa.ac.uk/id/funder/695",
                    "id": 695
                    }
                },
                {
                    "system_metadata": {
                    "id": 698,
                    "uri": "https://v2.sherpa.ac.uk/id/funder/698"
                    },
                    "funder_metadata": {
                    "id": 698,
                    "country": "gb",
                    "country_phrases": [
                        {
                        "phrase": "United Kingdom",
                        "value": "gb",
                        "language": "en"
                        }
                    ],
                    "groups": [
                        {
                        "type": "funder_group",
                        "id": 1061,
                        "name": "UK Research and Innovation",
                        "uri": "https://v2.sherpa.ac.uk/id/funder_group/1061"
                        },
                        {
                        "type": "funder_group",
                        "uri": "https://v2.sherpa.ac.uk/id/funder_group/1063",
                        "name": "Plan S Funders",
                        "id": 1063
                        }
                    ],
                    "identifiers": [
                        {
                        "identifier": "http://dx.doi.org/10.13039/501100000267",
                        "type_phrases": [
                            {
                            "phrase": "FundRef DOI",
                            "value": "fundref",
                            "language": "en"
                            }
                        ],
                        "type": "fundref"
                        },
                        {
                        "type": "ror",
                        "type_phrases": [
                            { "value": "ror", "phrase": "ROR ID", "language": "en" }
                        ],
                        "identifier": "https://ror.org/0505m1554"
                        }
                    ],
                    "name": [
                        {
                        "acronym": "AHRC",
                        "preferred_phrases": [
                            { "language": "en", "phrase": "Name", "value": "name" }
                        ],
                        "preferred": "name",
                        "name": "Arts and Humanities Research Council",
                        "language_phrases": [
                            { "language": "en", "value": "en", "phrase": "English" }
                        ],
                        "language": "en"
                        }
                    ],
                    "url": [
                        {
                        "url": "http://www.ahrc.ac.uk/Pages/Home.aspx",
                        "language_phrases": [
                            { "phrase": "English", "value": "en", "language": "en" }
                        ],
                        "language": "en"
                        }
                    ]
                    }
                },
                {
                    "system_metadata": {
                    "id": 709,
                    "uri": "https://v2.sherpa.ac.uk/id/funder/709"
                    },
                    "funder_metadata": {
                    "url": [
                        {
                        "language_phrases": [
                            { "language": "en", "phrase": "English", "value": "en" }
                        ],
                        "url": "http://www.bbsrc.ac.uk/home/home.aspx",
                        "language": "en"
                        }
                    ],
                    "identifiers": [
                        {
                        "identifier": "http://dx.doi.org/10.13039/501100000268",
                        "type": "fundref",
                        "type_phrases": [
                            {
                            "language": "en",
                            "phrase": "FundRef DOI",
                            "value": "fundref"
                            }
                        ]
                        },
                        {
                        "identifier": "https://ror.org/00cwqg982",
                        "type": "ror",
                        "type_phrases": [
                            { "value": "ror", "phrase": "ROR ID", "language": "en" }
                        ]
                        }
                    ],
                    "groups": [
                        {
                        "type": "funder_group",
                        "name": "UK Research and Innovation",
                        "uri": "https://v2.sherpa.ac.uk/id/funder_group/1061",
                        "id": 1061
                        },
                        {
                        "id": 1059,
                        "name": "Europe PMC Funders' Group",
                        "uri": "https://v2.sherpa.ac.uk/id/funder_group/1059",
                        "type": "funder_group"
                        },
                        {
                        "type": "funder_group",
                        "uri": "https://v2.sherpa.ac.uk/id/funder_group/1063",
                        "name": "Plan S Funders",
                        "id": 1063
                        }
                    ],
                    "name": [
                        {
                        "preferred_phrases": [
                            { "value": "name", "phrase": "Name", "language": "en" }
                        ],
                        "preferred": "name",
                        "acronym": "BBSRC",
                        "name": "Biotechnology and Biological Sciences Research Council",
                        "language_phrases": [
                            { "language": "en", "value": "en", "phrase": "English" }
                        ],
                        "language": "en"
                        }
                    ],
                    "country_phrases": [
                        {
                        "language": "en",
                        "phrase": "United Kingdom",
                        "value": "gb"
                        }
                    ],
                    "country": "gb",
                    "id": 709
                    }
                },
                {
                    "funder_metadata": {
                    "url": [
                        {
                        "language_phrases": [
                            { "value": "en", "phrase": "English", "language": "en" }
                        ],
                        "url": "http://www.esrc.ac.uk/",
                        "language": "en"
                        }
                    ],
                    "identifiers": [
                        {
                        "identifier": "http://dx.doi.org/10.13039/501100000269",
                        "type_phrases": [
                            {
                            "language": "en",
                            "phrase": "FundRef DOI",
                            "value": "fundref"
                            }
                        ],
                        "type": "fundref"
                        },
                        {
                        "identifier": "https://ror.org/03n0ht308",
                        "type": "ror",
                        "type_phrases": [
                            { "language": "en", "phrase": "ROR ID", "value": "ror" }
                        ]
                        }
                    ],
                    "groups": [
                        {
                        "name": "UK Research and Innovation",
                        "uri": "https://v2.sherpa.ac.uk/id/funder_group/1061",
                        "id": 1061,
                        "type": "funder_group"
                        },
                        {
                        "type": "funder_group",
                        "uri": "https://v2.sherpa.ac.uk/id/funder_group/1063",
                        "name": "Plan S Funders",
                        "id": 1063
                        }
                    ],
                    "name": [
                        {
                        "language_phrases": [
                            { "phrase": "English", "value": "en", "language": "en" }
                        ],
                        "name": "Economic and Social Research Council",
                        "acronym": "ESRC",
                        "preferred": "name",
                        "preferred_phrases": [
                            { "value": "name", "phrase": "Name", "language": "en" }
                        ],
                        "language": "en"
                        }
                    ],
                    "country_phrases": [
                        {
                        "language": "en",
                        "phrase": "United Kingdom",
                        "value": "gb"
                        }
                    ],
                    "country": "gb",
                    "id": 717
                    },
                    "system_metadata": {
                    "uri": "https://v2.sherpa.ac.uk/id/funder/717",
                    "id": 717
                    }
                },
                {
                    "funder_metadata": {
                    "country_phrases": [
                        {
                        "phrase": "United Kingdom",
                        "value": "gb",
                        "language": "en"
                        }
                    ],
                    "country": "gb",
                    "id": 726,
                    "url": [
                        {
                        "language_phrases": [
                            { "phrase": "English", "value": "en", "language": "en" }
                        ],
                        "url": "https://nerc.ukri.org/",
                        "language": "en"
                        }
                    ],
                    "groups": [
                        {
                        "uri": "https://v2.sherpa.ac.uk/id/funder_group/1061",
                        "name": "UK Research and Innovation",
                        "id": 1061,
                        "type": "funder_group"
                        },
                        {
                        "type": "funder_group",
                        "id": 1063,
                        "name": "Plan S Funders",
                        "uri": "https://v2.sherpa.ac.uk/id/funder_group/1063"
                        }
                    ],
                    "identifiers": [
                        {
                        "type_phrases": [
                            {
                            "language": "en",
                            "value": "fundref",
                            "phrase": "FundRef DOI"
                            }
                        ],
                        "type": "fundref",
                        "identifier": "http://dx.doi.org/10.13039/501100000270"
                        },
                        {
                        "identifier": "https://ror.org/02b5d8509",
                        "type": "ror",
                        "type_phrases": [
                            { "value": "ror", "phrase": "ROR ID", "language": "en" }
                        ]
                        }
                    ],
                    "name": [
                        {
                        "language": "en",
                        "preferred_phrases": [
                            { "value": "name", "phrase": "Name", "language": "en" }
                        ],
                        "preferred": "name",
                        "acronym": "NERC",
                        "language_phrases": [
                            { "language": "en", "phrase": "English", "value": "en" }
                        ],
                        "name": "Natural Environment Research Council"
                        }
                    ]
                    },
                    "system_metadata": {
                    "uri": "https://v2.sherpa.ac.uk/id/funder/726",
                    "id": 726
                    }
                },
                {
                    "funder_metadata": {
                    "country_phrases": [
                        {
                        "language": "en",
                        "value": "gb",
                        "phrase": "United Kingdom"
                        }
                    ],
                    "country": "gb",
                    "id": 722,
                    "url": [
                        {
                        "language_phrases": [
                            { "language": "en", "value": "en", "phrase": "English" }
                        ],
                        "url": "http://www.epsrc.ac.uk/Pages/default.aspx",
                        "language": "en"
                        }
                    ],
                    "groups": [
                        {
                        "id": 1061,
                        "uri": "https://v2.sherpa.ac.uk/id/funder_group/1061",
                        "name": "UK Research and Innovation",
                        "type": "funder_group"
                        },
                        {
                        "type": "funder_group",
                        "uri": "https://v2.sherpa.ac.uk/id/funder_group/1063",
                        "name": "Plan S Funders",
                        "id": 1063
                        }
                    ],
                    "name": [
                        {
                        "language": "en",
                        "name": "Engineering and Physical Sciences Research Council",
                        "language_phrases": [
                            { "phrase": "English", "value": "en", "language": "en" }
                        ],
                        "preferred": "name",
                        "preferred_phrases": [
                            { "phrase": "Name", "value": "name", "language": "en" }
                        ],
                        "acronym": "EPSRC"
                        }
                    ],
                    "identifiers": [
                        {
                        "type": "fundref",
                        "type_phrases": [
                            {
                            "phrase": "FundRef DOI",
                            "value": "fundref",
                            "language": "en"
                            }
                        ],
                        "identifier": "http://dx.doi.org/10.13039/501100000266"
                        },
                        {
                        "identifier": "https://ror.org/0439y7842",
                        "type": "ror",
                        "type_phrases": [
                            { "language": "en", "value": "ror", "phrase": "ROR ID" }
                        ]
                        }
                    ]
                    },
                    "system_metadata": {
                    "uri": "https://v2.sherpa.ac.uk/id/funder/722",
                    "id": 722
                    }
                },
                {
                    "system_metadata": {
                    "uri": "https://v2.sherpa.ac.uk/id/funder/716",
                    "id": 716
                    },
                    "funder_metadata": {
                    "name": [
                        {
                        "language": "en",
                        "language_phrases": [
                            { "language": "en", "value": "en", "phrase": "English" }
                        ],
                        "name": "Science and Technology Facilities Council",
                        "acronym": "STFC",
                        "preferred_phrases": [
                            { "language": "en", "value": "name", "phrase": "Name" }
                        ],
                        "preferred": "name"
                        }
                    ],
                    "groups": [
                        {
                        "type": "funder_group",
                        "name": "UK Research and Innovation",
                        "uri": "https://v2.sherpa.ac.uk/id/funder_group/1061",
                        "id": 1061
                        },
                        {
                        "name": "Plan S Funders",
                        "uri": "https://v2.sherpa.ac.uk/id/funder_group/1063",
                        "id": 1063,
                        "type": "funder_group"
                        }
                    ],
                    "identifiers": [
                        {
                        "type": "fundref",
                        "type_phrases": [
                            {
                            "value": "fundref",
                            "phrase": "FundRef DOI",
                            "language": "en"
                            }
                        ],
                        "identifier": "http://dx.doi.org/10.13039/501100000271"
                        },
                        {
                        "identifier": "https://ror.org/057g20z61",
                        "type_phrases": [
                            { "value": "ror", "phrase": "ROR ID", "language": "en" }
                        ],
                        "type": "ror"
                        }
                    ],
                    "url": [
                        {
                        "language": "en",
                        "url": "http://www.stfc.ac.uk/",
                        "language_phrases": [
                            { "phrase": "English", "value": "en", "language": "en" }
                        ]
                        }
                    ],
                    "country": "gb",
                    "id": 716,
                    "country_phrases": [
                        {
                        "language": "en",
                        "phrase": "United Kingdom",
                        "value": "gb"
                        }
                    ]
                    }
                },
                {
                    "system_metadata": {
                    "id": 705,
                    "uri": "https://v2.sherpa.ac.uk/id/funder/705"
                    },
                    "funder_metadata": {
                    "identifiers": [
                        {
                        "type": "fundref",
                        "type_phrases": [
                            {
                            "language": "en",
                            "value": "fundref",
                            "phrase": "FundRef DOI"
                            }
                        ],
                        "identifier": "http://dx.doi.org/10.13039/501100000265"
                        },
                        {
                        "type_phrases": [
                            { "language": "en", "phrase": "ROR ID", "value": "ror" }
                        ],
                        "type": "ror",
                        "identifier": "https://ror.org/03x94j517"
                        }
                    ],
                    "name": [
                        {
                        "language": "en",
                        "acronym": "MRC",
                        "preferred": "name",
                        "preferred_phrases": [
                            { "language": "en", "phrase": "Name", "value": "name" }
                        ],
                        "name": "Medical Research Council",
                        "language_phrases": [
                            { "value": "en", "phrase": "English", "language": "en" }
                        ]
                        }
                    ],
                    "groups": [
                        {
                        "id": 1061,
                        "uri": "https://v2.sherpa.ac.uk/id/funder_group/1061",
                        "name": "UK Research and Innovation",
                        "type": "funder_group"
                        },
                        {
                        "type": "funder_group",
                        "id": 1059,
                        "uri": "https://v2.sherpa.ac.uk/id/funder_group/1059",
                        "name": "Europe PMC Funders' Group"
                        },
                        {
                        "type": "funder_group",
                        "uri": "https://v2.sherpa.ac.uk/id/funder_group/1063",
                        "name": "Plan S Funders",
                        "id": 1063
                        }
                    ],
                    "url": [
                        {
                        "url": "http://www.mrc.ac.uk/index.htm",
                        "language_phrases": [
                            { "value": "en", "phrase": "English", "language": "en" }
                        ],
                        "language": "en"
                        }
                    ],
                    "id": 705,
                    "country": "gb",
                    "country_phrases": [
                        {
                        "phrase": "United Kingdom",
                        "value": "gb",
                        "language": "en"
                        }
                    ]
                    }
                },
                {
                    "system_metadata": {
                    "uri": "https://v2.sherpa.ac.uk/id/funder/877",
                    "id": 877
                    },
                    "funder_metadata": {
                    "country_phrases": [
                        {
                        "value": "gb",
                        "phrase": "United Kingdom",
                        "language": "en"
                        }
                    ],
                    "country": "gb",
                    "id": 877,
                    "url": [
                        {
                        "language": "en",
                        "url": "http://www.hefce.ac.uk/",
                        "language_phrases": [
                            { "value": "en", "phrase": "English", "language": "en" }
                        ]
                        }
                    ],
                    "identifiers": [
                        {
                        "identifier": "http://dx.doi.org/10.13039/501100000384",
                        "type_phrases": [
                            {
                            "language": "en",
                            "phrase": "FundRef DOI",
                            "value": "fundref"
                            }
                        ],
                        "type": "fundref"
                        },
                        {
                        "identifier": "https://ror.org/02wxr8x18",
                        "type_phrases": [
                            { "value": "ror", "phrase": "ROR ID", "language": "en" }
                        ],
                        "type": "ror"
                        }
                    ],
                    "groups": [
                        {
                        "type": "funder_group",
                        "id": 1060,
                        "name": "REF",
                        "uri": "https://v2.sherpa.ac.uk/id/funder_group/1060"
                        }
                    ],
                    "name": [
                        {
                        "language": "en",
                        "language_phrases": [
                            { "value": "en", "phrase": "English", "language": "en" }
                        ],
                        "name": "Higher Education Funding Council for England",
                        "acronym": "HEFCE",
                        "preferred": "acronym",
                        "preferred_phrases": [
                            {
                            "language": "en",
                            "value": "acronym",
                            "phrase": "Acronym"
                            }
                        ]
                        }
                    ]
                    }
                },
                {
                    "system_metadata": {
                    "id": 881,
                    "uri": "https://v2.sherpa.ac.uk/id/funder/881"
                    },
                    "funder_metadata": {
                    "groups": [
                        {
                        "type": "funder_group",
                        "uri": "https://v2.sherpa.ac.uk/id/funder_group/1060",
                        "name": "REF",
                        "id": 1060
                        }
                    ],
                    "identifiers": [
                        {
                        "identifier": "http://dx.doi.org/10.13039/501100000383",
                        "type_phrases": [
                            {
                            "phrase": "FundRef DOI",
                            "value": "fundref",
                            "language": "en"
                            }
                        ],
                        "type": "fundref"
                        },
                        {
                        "type_phrases": [
                            { "language": "en", "phrase": "ROR ID", "value": "ror" }
                        ],
                        "type": "ror",
                        "identifier": "https://ror.org/056y81r79"
                        }
                    ],
                    "name": [
                        {
                        "language_phrases": [
                            { "value": "en", "phrase": "English", "language": "en" }
                        ],
                        "name": "Higher Education Funding Council for Wales",
                        "acronym": "HEFCW",
                        "preferred": "acronym",
                        "preferred_phrases": [
                            {
                            "phrase": "Acronym",
                            "value": "acronym",
                            "language": "en"
                            }
                        ],
                        "language": "en"
                        },
                        {
                        "acronym": "CCAUC",
                        "preferred": "acronym",
                        "preferred_phrases": [
                            {
                            "value": "acronym",
                            "phrase": "Acronym",
                            "language": "en"
                            }
                        ],
                        "name": "Cyngor Cyllido Addysg Uwch Cymru",
                        "language_phrases": [
                            { "language": "en", "phrase": "Welsh", "value": "cy" }
                        ],
                        "language": "cy"
                        }
                    ],
                    "url": [
                        {
                        "language": "en",
                        "url": "http://www.hefcw.ac.uk/home/home.aspx",
                        "language_phrases": [
                            { "language": "en", "phrase": "English", "value": "en" }
                        ]
                        },
                        {
                        "language": "cy",
                        "url": "http://www.hefcw.ac.uk/home/home_cy.aspx",
                        "language_phrases": [
                            { "value": "cy", "phrase": "Welsh", "language": "en" }
                        ]
                        }
                    ],
                    "id": 881,
                    "country": "gb",
                    "country_phrases": [
                        {
                        "language": "en",
                        "phrase": "United Kingdom",
                        "value": "gb"
                        }
                    ]
                    }
                },
                {
                    "funder_metadata": {
                    "id": 887,
                    "country": "gb",
                    "country_phrases": [
                        {
                        "language": "en",
                        "phrase": "United Kingdom",
                        "value": "gb"
                        }
                    ],
                    "name": [
                        {
                        "language": "en",
                        "language_phrases": [
                            { "phrase": "English", "value": "en", "language": "en" }
                        ],
                        "name": "Scottish Funding Council",
                        "preferred_phrases": [
                            { "value": "name", "phrase": "Name", "language": "en" }
                        ],
                        "preferred": "name",
                        "acronym": "SFC"
                        }
                    ],
                    "identifiers": [
                        {
                        "type_phrases": [
                            {
                            "value": "fundref",
                            "phrase": "FundRef DOI",
                            "language": "en"
                            }
                        ],
                        "type": "fundref",
                        "identifier": "http://dx.doi.org/10.13039/501100000360"
                        },
                        {
                        "type_phrases": [
                            { "phrase": "ROR ID", "value": "ror", "language": "en" }
                        ],
                        "type": "ror",
                        "identifier": "https://ror.org/056bwcz71"
                        }
                    ],
                    "groups": [
                        {
                        "type": "funder_group",
                        "id": 1060,
                        "uri": "https://v2.sherpa.ac.uk/id/funder_group/1060",
                        "name": "REF"
                        }
                    ],
                    "url": [
                        {
                        "language_phrases": [
                            { "language": "en", "value": "en", "phrase": "English" }
                        ],
                        "url": "http://www.sfc.ac.uk/",
                        "language": "en"
                        }
                    ]
                    },
                    "system_metadata": {
                    "id": 887,
                    "uri": "https://v2.sherpa.ac.uk/id/funder/887"
                    }
                },
                {
                    "system_metadata": {
                    "uri": "https://v2.sherpa.ac.uk/id/funder/884",
                    "id": 884
                    },
                    "funder_metadata": {
                    "url": [
                        {
                        "language_phrases": [
                            { "language": "en", "value": "en", "phrase": "English" }
                        ],
                        "url": "https://www.economy-ni.gov.uk/",
                        "language": "en"
                        }
                    ],
                    "identifiers": [
                        {
                        "type": "fundref",
                        "type_phrases": [
                            {
                            "value": "fundref",
                            "phrase": "FundRef DOI",
                            "language": "en"
                            }
                        ],
                        "identifier": "http://dx.doi.org/10.13039/100008303"
                        },
                        {
                        "identifier": "https://ror.org/05w9mt194",
                        "type_phrases": [
                            { "value": "ror", "phrase": "ROR ID", "language": "en" }
                        ],
                        "type": "ror"
                        }
                    ],
                    "groups": [
                        {
                        "name": "REF",
                        "uri": "https://v2.sherpa.ac.uk/id/funder_group/1060",
                        "id": 1060,
                        "type": "funder_group"
                        }
                    ],
                    "name": [
                        {
                        "name": "Department for the Economy, Northern Ireland",
                        "language_phrases": [
                            { "phrase": "English", "value": "en", "language": "en" }
                        ],
                        "preferred": "name",
                        "preferred_phrases": [
                            { "value": "name", "phrase": "Name", "language": "en" }
                        ],
                        "language": "en"
                        }
                    ],
                    "country_phrases": [
                        {
                        "language": "en",
                        "value": "gb",
                        "phrase": "United Kingdom"
                        }
                    ],
                    "id": 884,
                    "country": "gb"
                    }
                }
                ]
            },
            "additional_oa_fee": "no",
            "location": {
                "location": ["institutional_repository", "subject_repository"],
                "location_phrases": [
                {
                    "phrase": "Institutional Repository",
                    "value": "institutional_repository",
                    "language": "en"
                },
                {
                    "language": "en",
                    "phrase": "Subject Repository",
                    "value": "subject_repository"
                }
                ]
            },
            "article_version_phrases": [
                { "language": "en", "phrase": "Accepted", "value": "accepted" }
            ],
            "license": [
                {
                "license_phrases": [
                    {
                    "language": "en",
                    "value": "cc_by_nc_nd",
                    "phrase": "CC BY-NC-ND"
                    }
                ],
                "license": "cc_by_nc_nd"
                }
            ],
            "additional_oa_fee_phrases": [
                { "language": "en", "phrase": "No", "value": "no" }
            ],
            "embargo": {
                "amount": 12,
                "units_phrases": [
                { "language": "en", "phrase": "Months", "value": "months" }
                ],
                "units": "months"
            }
            }
        ],
        "id": 3329,
        "urls": [
            {
            "url": "https://www.elsevier.com/__data/assets/pdf_file/0011/78473/UK-Embargo-Periods.pdf",
            "description": "Journal Embargo List for UK Authors"
            },
            {
            "description": "Article Sharing",
            "url": "https://www.elsevier.com/about/policies/sharing"
            }
        ],
        "publication_count": 783
        }
    ]
    }"""

    -- non-free publisher policy
    , """{
    "doi": "10.1016/j.neuroimage.2016.09.039",
    "title": "Age-related changes in sleep EEG are attenuated in highly intelligent individuals",
    "journal": "NeuroImage",
    "authors": "Adrián Pótári et al.",
    "year": 2017,
    "published_date": "2017-02-01",
    "issn": "1053-8119",
    "is_open_access": false,
    "oa_location_url": null,
    "oa_pathway": "nocost",
    "oa_pathway_uri": "https://v2.sherpa.ac.uk/id/publication/11398",
    "oa_pathway_details": [
        {
        "id": 2252,
        "uri": "https://v2.sherpa.ac.uk/id/publisher_policy/2252",
        "open_access_prohibited_phrases": [
            { "value": "no", "phrase": "No", "language": "en" }
        ],
        "permitted_oa": [
            {
            "license": [
                {
                "license_phrases": [
                    { "language": "en", "phrase": "CC BY", "value": "cc_by" }
                ],
                "license": "cc_by"
                }
            ],
            "additional_oa_fee_phrases": [
                { "value": "no", "phrase": "No", "language": "en" }
            ],
            "additional_oa_fee": "no",
            "article_version_phrases": [
                { "phrase": "Submitted", "value": "submitted", "language": "en" },
                { "value": "accepted", "phrase": "Accepted", "language": "en" },
                { "value": "published", "phrase": "Published", "language": "en" }
            ],
            "conditions": [
                "Published source must be acknowledged",
                "Must link to publisher version with DOI"
            ],
            "article_version": ["submitted", "accepted", "published"],
            "location": {
                "location": ["any_repository", "named_repository", "this_journal"],
                "named_repository": ["PubMed Central"],
                "location_phrases": [
                {
                    "phrase": "Any Repository",
                    "value": "any_repository",
                    "language": "en"
                },
                {
                    "language": "en",
                    "phrase": "Named Repository",
                    "value": "named_repository"
                },
                {
                    "value": "this_journal",
                    "phrase": "Journal Website",
                    "language": "en"
                }
                ]
            },
            "publisher_deposit": [
                {
                "system_metadata": {
                    "uri": "https://v2.sherpa.ac.uk/id/repository/267",
                    "id": 267
                },
                "repository_metadata": {
                    "name": [
                    {
                        "preferred": "name",
                        "language_phrases": [
                        { "phrase": "English", "value": "en", "language": "en" }
                        ],
                        "name": "PubMed Central",
                        "language": "en",
                        "preferred_phrases": [
                        { "language": "en", "phrase": "Name", "value": "name" }
                        ]
                    }
                    ],
                    "type": "disciplinary",
                    "description": "A subject-based repository of biomedical and life sciences journal literature developed and managed by the National Center for Biotechnology Information (NCBI) at the US National Library of Medicine (NLM). Content includes articles deposited by participating journals that have applied to and been selected for the archive by NLM, as well as individual author manuscripts that have been submitted in compliance with the NIH Public Access Policy and similar policies of other research funding agencies. More than 2000 journals currently use PMC as a repository. Digitization projects have also added content from the 18th, 19th, and 20th centuries to the archive.",
                    "url": "http://www.ncbi.nlm.nih.gov/pmc/",
                    "type_phrases": [
                    {
                        "language": "en",
                        "value": "disciplinary",
                        "phrase": "Disciplinary"
                    }
                    ]
                }
                }
            ]
            },
            {
            "article_version_phrases": [
                { "phrase": "Submitted", "value": "submitted", "language": "en" },
                { "language": "en", "value": "accepted", "phrase": "Accepted" },
                { "phrase": "Published", "value": "published", "language": "en" }
            ],
            "license": [
                {
                "license_phrases": [
                    {
                    "language": "en",
                    "value": "cc_by_nc_nd",
                    "phrase": "CC BY-NC-ND"
                    }
                ],
                "license": "cc_by_nc_nd"
                }
            ],
            "additional_oa_fee_phrases": [
                { "value": "no", "phrase": "No", "language": "en" }
            ],
            "additional_oa_fee": "no",
            "publisher_deposit": [
                {
                "system_metadata": {
                    "id": 267,
                    "uri": "https://v2.sherpa.ac.uk/id/repository/267"
                },
                "repository_metadata": {
                    "url": "http://www.ncbi.nlm.nih.gov/pmc/",
                    "description": "A subject-based repository of biomedical and life sciences journal literature developed and managed by the National Center for Biotechnology Information (NCBI) at the US National Library of Medicine (NLM). Content includes articles deposited by participating journals that have applied to and been selected for the archive by NLM, as well as individual author manuscripts that have been submitted in compliance with the NIH Public Access Policy and similar policies of other research funding agencies. More than 2000 journals currently use PMC as a repository. Digitization projects have also added content from the 18th, 19th, and 20th centuries to the archive.",
                    "type": "disciplinary",
                    "name": [
                    {
                        "preferred": "name",
                        "language_phrases": [
                        { "language": "en", "phrase": "English", "value": "en" }
                        ],
                        "name": "PubMed Central",
                        "preferred_phrases": [
                        { "language": "en", "value": "name", "phrase": "Name" }
                        ],
                        "language": "en"
                    }
                    ],
                    "type_phrases": [
                    {
                        "language": "en",
                        "phrase": "Disciplinary",
                        "value": "disciplinary"
                    }
                    ]
                }
                }
            ],
            "conditions": [
                "Published source must be acknowledged",
                "Must link to publisher version with DOI"
            ],
            "article_version": ["submitted", "accepted", "published"],
            "location": {
                "location": [
                "named_repository",
                "non_commercial_repository",
                "this_journal"
                ],
                "named_repository": ["PubMed Central"],
                "location_phrases": [
                {
                    "phrase": "Named Repository",
                    "value": "named_repository",
                    "language": "en"
                },
                {
                    "language": "en",
                    "value": "non_commercial_repository",
                    "phrase": "Non-Commercial Repository"
                },
                {
                    "language": "en",
                    "value": "this_journal",
                    "phrase": "Journal Website"
                }
                ]
            }
            },
            {
            "additional_oa_fee": "no",
            "location": {
                "location": ["this_journal"],
                "location_phrases": [
                {
                    "language": "en",
                    "value": "this_journal",
                    "phrase": "Journal Website"
                }
                ]
            },
            "additional_oa_fee_phrases": [
                { "value": "no", "phrase": "No", "language": "en" }
            ],
            "article_version": ["published"],
            "license": [
                {
                "license": "cc_by",
                "license_phrases": [
                    { "language": "en", "phrase": "CC BY", "value": "cc_by" }
                ]
                },
                {
                "license": "cc_by_nc_nd",
                "license_phrases": [
                    {
                    "phrase": "CC BY-NC-ND",
                    "value": "cc_by_nc_nd",
                    "language": "en"
                    }
                ]
                }
            ],
            "article_version_phrases": [
                { "phrase": "Published", "value": "published", "language": "en" }
            ]
            }
        ],
        "urls": [
            {
            "description": "Copyright",
            "url": "https://www.elsevier.com/about/policies/copyright"
            },
            {
            "description": "Open Access",
            "url": "https://www.elsevier.com/about/open-science/open-access"
            }
        ],
        "publication_count": 57,
        "open_access_prohibited": "no",
        "internal_moniker": "Creative Commons Licenses"
        }
    ]
    }
    """
    ]
