module KitchenSink exposing (main)

import Animation
import Array
import Browser
import Http
import Json.Decode as D
import Main exposing (Model, subscriptions, update, view)
import Msg exposing (Msg(..))
import Papers.Backend as Backend exposing (paperDecoder)


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
    , freePathwayPapers =
        Array.fromList []
    , otherPathwayPapers = []
    , openAccessPapers = []
    , buggyPapers = []
    , numFailedDOIRequests = 0
    , authorName = "Dummy Author"
    , authorProfileURL = "https://freeyourscience.org"
    , serverURL = ""
    , style = Animation.style []
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
    [ """{
        "doi": "10.1007/978-3-319-45450-4_37",
        "title": "Actuator Design for Stabilizing Single Tendon Platforms",
        "journal": "Mechanisms and Machine Science",
        "authors": "D. Haarhoff et al.",
        "year": 2016,
        "issn": "2211-0984",
        "is_open_access": false,
        "oa_pathway": "not_found",
        "oa_pathway_uri": null,
        "oa_pathway_details": null,
        "oa_location_url": null
    }"""
    , """{
        "doi": "10.1371/journal.pcbi.1006283",
        "title": "Unsupervised clustering of temporal patterns in high-dimensional neuronal ensembles using a novel dissimilarity measure",
        "journal": "PLOS Computational Biology",
        "authors": "Lukas Grossberger et al.",
        "year": 2018,
        "issn": "1553-734X",
        "is_open_access": true,
        "oa_pathway": "already_oa",
        "oa_pathway_uri": null,
        "oa_pathway_details": null,
        "oa_location_url": null
    }"""
    , """{
      "doi": "10.1021/acsnano.8b01396",
      "title": "Nanometer-Resolved Mapping of Cell-Substrate Distances of Contracting Cardiomyocytes Using Surface Plasmon Resonance Microscopy",
      "journal": "ACS Nano",
      "authors": "Eva Kreysing et al.",
      "year": 2018,
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
    , """{
    "doi": "10.1364/ol.44.001359",
    "title": "Noninvasive measurement of the refractive index of cell organelles using surface plasmon resonance microscopy",
    "journal": "Optics Letters",
    "authors": "Hossein Hassani et al.",
    "year": 2019,
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
    ]
