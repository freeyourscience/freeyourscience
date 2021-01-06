module ApiTest exposing (..)

import Api exposing (paperDecoder)
import Expect exposing (Expectation)
import Json.Decode as D exposing (Decoder)
import Test exposing (..)
import Types exposing (..)
import Api exposing (recommendedPathway)


fullPaperJson : String
fullPaperJson =
    """
{"doi":"10.1002/STAB.201710469","title":"Zukunft Robotik - Automatisierungspotentiale im Stahl- und Metallleichtbau","journal":"Stahlbau","authors":"Sigrid Brell-Cokcan et al.","year":2017,"issn":"0038-9145","is_open_access":false,"oa_pathway":"nocost","oa_pathway_uri":"https://v2.sherpa.ac.uk/id/publication/1908","oa_pathway_details":[{"open_access_prohibited":"no","urls":[{"description":"Vereinbarung zur Rechteűbertragung","url":"https://www.ernst-und-sohn.de/sites/default/files/uploads/service/autoren/EuS_CTA_DE_2016-02.pdf"}],"permitted_oa":[{"additional_oa_fee":"no","location":{"location_phrases":[{"phrase":"Academic Social Network","language":"en","value":"academic_social_network"},{"phrase":"Author's Homepage","language":"en","value":"authors_homepage"},{"language":"en","value":"non_commercial_repository","phrase":"Non-Commercial Repository"}],"location":["academic_social_network","authors_homepage","non_commercial_repository"]},"article_version":["submitted"],"article_version_phrases":[{"language":"en","value":"submitted","phrase":"Submitted"}],"additional_oa_fee_phrases":[{"language":"en","value":"no","phrase":"No"}],"conditions":["Published source must be acknowledged","Must link to publisher version with DOI"]},{"additional_oa_fee_phrases":[{"phrase":"No","value":"no","language":"en"}],"conditions":["Published source must be acknowledged","Must link to publisher version with DOI"],"article_version_phrases":[{"language":"en","value":"accepted","phrase":"Accepted"}],"location":{"named_repository":["PubMed Central"],"location_phrases":[{"phrase":"Author's Homepage","language":"en","value":"authors_homepage"},{"phrase":"Institutional Website","value":"institutional_website","language":"en"},{"phrase":"Named Repository","language":"en","value":"named_repository"},{"phrase":"Subject Repository","language":"en","value":"subject_repository"}],"location":["authors_homepage","institutional_website","named_repository","subject_repository"]},"additional_oa_fee":"no","embargo":{"units":"months","amount":12,"units_phrases":[{"phrase":"Months","value":"months","language":"en"}]},"article_version":["accepted"]}],"open_access_prohibited_phrases":[{"language":"en","value":"no","phrase":"No"}],"internal_moniker":"Ernst und Sohn","publication_count":12,"uri":"https://v2.sherpa.ac.uk/id/publisher_policy/1390","id":1390}]}
"""


oaPathwayNull : String
oaPathwayNull =
    """
{"doi":"10.1002/STAB.201710469","title":"Zukunft Robotik - Automatisierungspotentiale im Stahl- und Metallleichtbau","journal":"Stahlbau","authors":"Sigrid Brell-Cokcan et al.","year":2017,"issn":"0038-9145","is_open_access":false,"oa_pathway":"nocost","oa_pathway_uri":"https://v2.sherpa.ac.uk/id/publication/1908","oa_pathway_details":null}
"""


dummyPathway : Pathway
dummyPathway =
    { articleVersion = "accepted"
    , locations = [ "Academic Social Network", "Author's Homepage" ]
    , prerequisites = [ "If Required by Institution", "12 months have passed since publication" ]
    , conditions = [ "Must be accompanied by set statement (see policy)", "Must link to publisher version" ]
    , notes = [ "If mandated to deposit before 12 months, the author must obtain a  waiver from their Institution/Funding agency or use  AuthorChoice" ]
    , urls = [ { name = "Best Page Ever", url = "https://freeyourscience.org" } ]
    , policyUrl = "https://freeyourscience.org"
    }


suite : Test
suite =
    describe "Testing the paperDecoder"
        [ test "Parse the oa_pathway_details into a recommended pathway" <|
            let
                decodedPaper =
                    D.decodeString paperDecoder fullPaperJson

                recommendedPathway =
                    \result ->
                        case result of
                            Ok paper ->
                                paper.recommendedPathway

                            _ ->
                                Nothing
            in
            Expect.all
                [ \_ -> Expect.ok decodedPaper
                , \_ -> Expect.equal (Just dummyPathway) (recommendedPathway decodedPaper)
                ]
        , test "Handle null for oa_pathway_details" <|
            let
                decodedPaper =
                    D.decodeString paperDecoder oaPathwayNull

                recommendedPathway =
                    \result ->
                        case result of
                            Ok paper ->
                                paper.recommendedPathway

                            _ ->
                                Nothing
            in
            \_ ->
                Expect.equal (Nothing) (recommendedPathway decodedPaper)
        ]
