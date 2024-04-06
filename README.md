# Explainer for a future browsing context group dependency hint

This proposal is an early design sketch by the Chrome Portals team to describe the problem below and solicit
feedback on the proposed solution. It has not been approved to ship in Chrome.

## Proponents

- Chrome Portals team

## Participate
- https://github.com/explainers-by-googlers/future-browsing-context-group-dependency-hint/issues

## Table of Contents

<!-- Update this table of contents by running `npx doctoc README.md` -->
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Introduction](#introduction)
- [Background](#background)
- [Goals](#goals)
- [Non-goals](#non-goals)
- [Proposed solution](#proposed-solution)
- [Considerations](#considerations)
  - [Security](#security)
  - [Privacy](#privacy)
  - [Specification changes](#specification-changes)
  - [Interoperability](#interoperability)
  - [Compatibility](#compatibility)
- [Considered alternatives](#considered-alternatives)
  - [Do nothing](#do-nothing)
  - [Do not perform proactive browsing context group changes](#do-not-perform-proactive-browsing-context-group-changes)
  - [Base the change on whether an auxiliary browsing context has ever existed](#base-the-change-on-whether-an-auxiliary-browsing-context-has-ever-existed)
  - [Introduce an HTTP header as an opt-out](#introduce-an-http-header-as-an-opt-out)
  - [Change behaviour based on the browser's settings](#change-behaviour-based-on-the-browsers-settings)
  - [Introducing a new rel type instead of opener](#introducing-a-new-rel-type-instead-of-opener)
  - [Add an options parameter to location.assign](#add-an-options-parameter-to-locationassign)
- [Stakeholder Feedback / Opposition](#stakeholder-feedback--opposition)
- [References & acknowledgements](#references--acknowledgements)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Introduction

Some browsers perform a browsing context group (BCG) swap on navigations for performance reasons. In certain scenarios, this can cause web-facing breakage of named window reuse. This proposal introduces an opt-out mechanism that web content can use to indicate to the browser that it relies on a browsing context group not happening. The proposed mechanism is to use the ["opener"](https://html.spec.whatwg.org/multipage/links.html#link-type-opener) rel type. An author would annotate anchor elements for which a BCG swap on navigation would cause breakage.

## Background

When calling [window.open()](https://developer.mozilla.org/en-US/docs/Web/API/Window/open) with a target name of an existing browsing context, the user agent decides whether the reuse is permitted. The requesting and target contexts being in the same browsing context group (BCG) is key to this decision. For example, if a page isolates itself using [COOP](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cross-Origin-Opener-Policy), pages in other browsing context groups cannot access it. The Firefox, Chrome, and WebKit implementations of named window lookup (see [here](https://searchfox.org/mozilla-central/source/dom/ipc/WindowGlobalChild.cpp#825), [here](https://source.chromium.org/chromium/chromium/src/+/main:third_party/blink/renderer/core/page/frame_tree.cc;drc=3fcc7f102b29bf17c462fd438e418dcc7e27f3a3;l=238), [here](https://github.com/WebKit/WebKit/blob/dc7bb79ca72bfc056244eb5d31e0d5844f8faa61/Source/WebCore/page/FrameTree.cpp#L267)) are consistent about lookups being scoped to BCGs.

A user agent could change browsing context groups on navigation for a number of other reasons. These include implementation specific security requirements like isolating privileged pages like "about" pages or extension pages, or performance improvements in cases where preserving scripting relationships is considered not important/desirable like cross-site browser triggered navigations.

Furthermore, Firefox and Chrome both swap browsing context groups for performance reasons for most top level navigations when there are no existing opener relationships (see [here](https://searchfox.org/mozilla-central/source/dom/docs/navigation/nav_replace.rst#76), [here](https://source.chromium.org/chromium/chromium/src/+/main:content/browser/renderer_host/render_frame_host_manager.cc;l=2466;drc=f4a00cc248dd2dc8ec8759fb51620d47b5114090;bpv=1;bpt=1)). The motivation is to make more pages eligible for back-forward cache (bfcache). WebKit only appears to do BCG swaps related to COOP (see [here](https://github.com/WebKit/WebKit/blob/801286aa3dcb9720da3f98e6d25ce5e1ab5b79bb/Source/WebKit/NetworkProcess/NetworkResourceLoader.cpp#L998)).

However, some existing web content relies on being in the same BCG across navigations. Consider this bug [report](https://issues.chromium.org/issues/40281878) which describes a case where this proactive BCG change broke some window reuse, due to the opener relationship not being established until after a navigation, where the destination page creates a popup, then after navigating back in session history, another page tries to reuse the popup. The user would keep getting new windows, making their workflow tedious. Consider this example:

```html
a.html:
Step 1: Navigate to b.html.
<a href="b.html">B</a>
Step 4: Attempt to navigate existing popup.
<a href="a_popup.html" target="my_popup">Navigate existing popup</a>

b.html:
Step 2: Open popup.
<a href="b_popup.html" target="my_popup">Create popup</a>
Step 3: Back to a.html.
```

Step 4 will open a new window unless it's ineligible for bfcache. This applies to both Firefox and Chrome. Intentionally making a site bfcache-ineligible currently serves as an implicit opt-out for the proactive BCG swap.

Note that the [spec](https://html.spec.whatwg.org/multipage/document-sequences.html#the-rules-for-choosing-a-navigable) for named window lookups partially defers to implementation defined logic, so either behaviour would be allowed by the spec.

While bfcache is currently the primary motivation for these swaps, other features in development, such as [prerendering](https://github.com/WICG/nav-speculation), will benefit from continuing to be able to perform these swaps.

## Goals

- Prevent site breakage: Allow authors of affected web pages to prevent breakage for their users.
- Performance: Provide an option which does not encourage more drastic workarounds, such as intentional bfcache-ineligibility.
- Performance: Continue to provide sufficient flexibility to user agents to make performance optimizations for unaffected web pages.

## Non-goals

Note that we do not want to introduce a general bfcache opt-out mechanism. The opt-out should be scoped to the specifics of the breakage. There is broad [agreement](https://github.com/fergald/explainer-bfcache-ccns/blob/main/api.md#api-non-goals) that we should not introduce unconditional bfcache opt-out mechanisms.

## Proposed solution

We propose making use of the existing ["opener"](https://html.spec.whatwg.org/multipage/links.html#link-type-opener) rel type to signal to the user agent that there will be a future opener relationship that the referring page wants to preserve from the destination page. If the annotation is present, the user agent should not perform a browsing context group change when navigating via the link, unless needed for security.

In the example above, the link would be annotated as follows:
```html
<a href="b.html" rel="opener">B</a>
```

Using rel="opener" on navigations targeting the current window currently isn't meaningful and is a no-op. This proposal introduces semantics for it. While the destination isn't what would be the opener relative to the referrer, the use of "opener" seems appropriately related to the page author's intent, and seems close to rel opener's [original](https://github.com/whatwg/html/issues/4078) motivation.

For programmatic navigations, such as assigning to location.href, it would be nice to have a mechanism which doesn't involve dynamically creating an invisible anchor element and programmatically clicking it. We propose adding an "opener" feature in window.open()'s features list. This is the opposite of "noopener" just like the "opener" and "noopener" rel types. Then a programmatic navigation could be done as follows:
```js
// Before
location.href = getNextPageUrl();
// After
window.open(getNextPageUrl(), '_self', 'opener');
```

## Considerations

### Security

No concerns expected. This is not introducing a new capability. It's a more targeted opt-out mechanism for behaviour that can already be achieved. Also note that the page can only use this to avoid optional BCG changes that aren't needed for security. Notably, it can't be used to avoid COOP enforcement.

### Privacy

No concerns expected.

### Specification changes

Regardless of this proposal, we should update some parts of the spec related to browsing context groups to reflect actual implementations of the major engines. The [rules for choosing a navigable](https://html.spec.whatwg.org/multipage/document-sequences.html#the-rules-for-choosing-a-navigable) should explicitly mention that a browsing context from a different BCG can't be used. In [obtain a browsing context to use for a navigation response](https://html.spec.whatwg.org/multipage/browsers.html#obtain-browsing-context-navigation), we should set limits of when a user agent can choose to swap BCGs across same-origin, page [initiated](https://html.spec.whatwg.org/multipage/browsing-the-web.html#user-navigation-involvement) navigations (notably, not when there are auxiliary browsing contexts), but otherwise allow implementation defined swaps such as for a user agent's security requirements.

For the proposal itself, we'd pass whether an explicit opener rel is on the link from [follow the hyperlink](https://html.spec.whatwg.org/multipage/links.html#following-hyperlinks-2) to [obtain a browsing context to use for a navigation response](https://html.spec.whatwg.org/multipage/browsers.html#obtain-browsing-context-navigation). We'd do the same with the opener feature from [window open steps](https://html.spec.whatwg.org/multipage/nav-history-apis.html#window-open-steps). At the BCG switch logic, we'd handle the case where we have an explicit opener rel as a limitation of when the user agent can choose to swap. Since the window lookup steps would still have implementation defined logic, perhaps preventing swaps with an explicit opener rel should only be optional/recommended behaviour. We'd also describe this case at the [definition](https://html.spec.whatwg.org/multipage/links.html#link-type-opener) of the keyword.

### Interoperability

WebKit wouldn't have to make any changes. They already have the intended behaviour of reusing the existing window, without the use of the proposed annotation, and would be aligned with the spec changes.

If Firefox wishes to adopt this behaviour, I wouldn't expect architectural difficulties in doing so. It's a matter of passing a bool through to their isolation logic. Alternatively, it would be fine from a spec perspective if they wish to keep the existing behaviour.

### Compatibility

The use of an opener rel on a link that targets the same window currently has no effect. There are a small number of pages that do this anyway (see [use counter](https://chromestatus.com/metrics/feature/timeline/popularity/4742)). The only negative effect such pages would experience is a potential unintentional loss of bfcache eligibility. Compared to the lack of clarity from creating a new rel type, this seems worth it.

For user agents that don't recognize an "opener" window feature, this could change the window selection to a popup instead of a tab. This wouldn't matter for _self navigations. But in any case, a page could explicitly use the feature "popup=0" to avoid this.

## Considered alternatives

### Do nothing

Pages which rely on bfcache ineligibility hacks will lose these mechanisms over time. It's better to have a targeted opt-out. Without other options, we may be encouraging user-unfriendly site behaviour like opening popups for no reason that's apparent to the user.

### Do not perform proactive browsing context group changes

This would cause a substantial loss of performance across the web, due to the reduction in bfcache eligibility, for user agents with bfcache implementations which require a browsing context group boundary for cached pages.

### Base the change on whether an auxiliary browsing context has ever existed

This is not much better than doing nothing as it still encourages unexplained popups.

### Introduce an HTTP header as an opt-out

This seems more complex than is warranted for this issue. Some developers are not able to easily set headers. It'd be ideal for the solution to stay within HTML.

See also [Non-goals](#non-goals) regarding not introducing an unconditional opt-out.

### Change behaviour based on the browser's settings

For example, we could use whether a user has enabled pop-ups on the site as part of the logic for the proactive BCG swap. However, this would be a vague heuristic that isn't discoverable, and would make far more sites bfcache ineligible than necessary.

### Introducing a new rel type instead of opener

As noted in the compatibility considerations, very few sites would be impacted by loss of bfcache eligibility if "opener" usage is no longer a no-op. The ease of understanding the use of "opener" seems worth it.

But if there's a preference to use a new rel type, that'd be fine. The rest of this proposal would still apply.

### Add an options parameter to location.assign

For programmatic navigations, instead of the window feature approach with _self window.open() navigations, we could add an options parameter to location.assign like so:
```js
// Before
location.href = getNextPageUrl();
// After
location.assign(getNextPageUrl(), {opener: true});
```
The window feature approach is used in the main proposal as it's the smaller change and promotes consistency with more window features that are common with link types. Though this options approach might be better if in the future we want to make more navigation options available programmatically (e.g. letting assign specify a referrer policy).

## Stakeholder Feedback / Opposition

TODO: Request standards positions.
- Firefox: No signal.
- Safari: No signal.
- Web Developers: Positive. The reporter of the motivating [bug](https://issues.chromium.org/issues/40281878) has indicated that this proposal would enable their use case without bfcache-ineligibility hacks.

## References & acknowledgements

Many thanks for valuable feedback and advice from:

- Charlie Reis
- Domenic Denicola
- Jeremy Roman
- Rakina Zata Amni
