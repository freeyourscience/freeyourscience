ARTICLE_VERSIONS = dict(
    published=3,
    accepted=2,
    submitted=1,
)
LOCATIONS = dict(
    any_repository=6,
    preprint_repository=5,
    subject_repository=5,
    non_commercial_repository=5,
    non_commercial_subject_repository=4,
    institutional_repository=4,
    non_commercial_institutional_repository=4,
    named_repository=4,
    any_website=3,
    institutional_website=3,
    non_commercial_website=3,
    authors_homepage=3,
    academic_social_network=2,
    non_commercial_social_network=2,
    named_academic_social_network=2,
    funder_designated_location=2,
    this_journal=1,
)
EMBARGOS = dict(
    no_embargo=2,
    expired_embargo=2,
    embargo=1,
)


def score(articleVersion, location, embargo):
    return ARTICLE_VERSIONS[articleVersion] + LOCATIONS[location] + EMBARGOS[embargo]


if __name__ == "__main__":
    policies = [
        ("published", "any_repository", "no_embargo"),
        ("submitted", "this_journal", "embargo"),
        ("accepted", "any_repository", "expired_embargo"),
        ("accepted", "preprint_repository", "no_embargo"),
        ("accepted", "authors_homepage", "no_embargo"),
        ("accepted", "institutional_repository", "no_embargo"),
        ("accepted", "institutional_repository", "embargo"),
        ("accepted", "funder_designated_location", "no_embargo"),
        ("submitted", "institutional_repository", "no_embargo"),
        ("submitted", "any_repository", "no_embargo"),
    ]

    scored_policies = [(p, score(*p)) for p in policies]
    scored_policies = sorted(scored_policies, key=lambda sp: sp[1], reverse=True)

    for p, s in scored_policies:
        print(f"{s} {p}")
