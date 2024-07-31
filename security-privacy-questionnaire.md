# [Self-Review Questionnaire: Security and Privacy](https://w3ctag.github.io/security-questionnaire/)

> 01.  What information does this feature expose,
>      and for what purposes?

Nothing.

> 02.  Do features in your specification expose the minimum amount of information
>      necessary to implement the intended functionality?

Yes.

> 03.  Do the features in your specification expose personal information,
>      personally-identifiable information (PII), or information derived from
>      either?

No.

> 04.  How do the features in your specification deal with sensitive information?

No sensitive information is involved.

> 05.  Does data exposed by your specification carry related but distinct
>      information that may not be obvious to users?

No.

> 06.  Do the features in your specification introduce state
>      that persists across browsing sessions?

No.

> 07.  Do the features in your specification expose information about the
>      underlying platform to origins?

No.

> 08.  Does this specification allow an origin to send data to the underlying
>      platform?

No.

> 09.  Do features in this specification enable access to device sensors?

No.

> 10.  Do features in this specification enable new script execution/loading
>      mechanisms?

No.

> 11.  Do features in this specification allow an origin to access other devices?

No.

> 12.  Do features in this specification allow an origin some measure of control over
>      a user agent's native UI?

No.

> 13.  What temporary identifiers do the features in this specification create or
>      expose to the web?

None.

> 14.  How does this specification distinguish between behavior in first-party and
>      third-party contexts?

There is no difference in behavior. A third-party could induce a loss of BFCache eligibility upon navigation (e.g. a cross-site iframe navigating `_top`, using the opt-out). If we ignored the annotation in this case, we'd have the same issue as described in the "Do nothing" section of the "Considered alternatives" where ignoring it could promote more disruptive behavior.

> 15.  How do the features in this specification work in the context of a browser’s
>      Private Browsing or Incognito mode?

There is no difference in behavior.

> 16.  Does this specification have both "Security Considerations" and "Privacy
>      Considerations" sections?

No. Note that the proposed changes are small enough that the spec changes will just be PRs for existing HTML spec sections.

> 17.  Do features in your specification enable origins to downgrade default
>      security protections?

No. In particular, note that this cannot be used to avoid browsing context group changes that are required for security, such as for Cross-Origin-Opener-Policy.

> 18.  What happens when a document that uses your feature is kept alive in BFCache
>      (instead of getting destroyed) after navigation, and potentially gets reused
>      on future navigations back to the document?

Depending on the user agent implementation, this may make the page ineligible for BFCache. For user agents that do support this case, there shouldn't be an issue, as there is no state associated with the referring page.

> 19.  What happens when a document that uses your feature gets disconnected?

Nothing. It only has an effect when a navigation is triggered.

> 20.  Does your feature allow sites to learn about the users use of assistive technology?

No.

> 21.  What should this questionnaire have asked?

No suggestions.
