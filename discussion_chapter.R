% =====================================================================
%  Discussion chapter
%  Sampling bias in Norwegian biodiversity occurrence data
%
%  Self-contained \chapter to be \input{} into the main thesis.
%  Assumes the thesis preamble already loads, at minimum:
%     \usepackage{amsmath}    % math environments
%     \usepackage{hyperref}   % optional
%
%  NOTE ON LABELS
%  --------------
%  This chapter uses \label{ch:discussion} (the target the Results
%  chapter already points at) and \label{sec:disc-*} for its sections.
%  Cross-references reach into the Results chapter
%  (\ref{chap:Results} and \ref{sec:results-*}), the Methods chapter
%  (\ref{ch:methods}, \ref{sec:hotspot}, \ref{sec:fielddiag},
%  \ref{sec:block}, \ref{sec:permutation}, \ref{sec:ano}) and the
%  Theory chapter (\ref{chap:Theory}); the Conclusion is reached as
%  \ref{chap:Conclusion}. Change these if you keep different labels.
%
%  Code is not reproduced here; scripts are named inline where relevant,
%  matching the earlier chapters.
% =====================================================================

\chapter{Discussion}
\label{ch:discussion}

The results of Chapter~\ref{chap:Results} are read here against the
question that opened the thesis: can a shared observer-bias field,
estimated jointly across the species within a taxonomic group, separate
the ecological signal from the recording artefact well enough to be
trusted? The discussion proceeds in four movements. The first returns to
that question and states what the diagnostics, taken together, can and
cannot answer (Section~\ref{sec:disc-question}). The second interprets the
central null result --- that regional bias structure looks the same under
a random composition of groups --- and confronts the obvious objection
that the integrated model may have built that result in by construction
(Section~\ref{sec:disc-geography}). The third turns to the spatial-field
diagnostic, which qualifies the null by showing how far the shared-bias
assumption actually holds for each group (Section~\ref{sec:disc-degree}).
The fourth reads the results forward, asking what the geography of the
leftover uncertainty implies for where recording effort should go next
(Section~\ref{sec:disc-practice}), before the limitations are set out
honestly (Section~\ref{sec:disc-limits}).


% =====================================================================
\section{Revisiting the shared-bias question}
\label{sec:disc-question}
% =====================================================================

The problem statement framed a single methodological question: whether a
shared observer-bias field can carry the weight the integrated model
places on it. The thesis approaches that question not by refitting the
occurrence model but by interrogating the bias surfaces it produces
(Section~\ref{sec:hotspot}), and the answer that emerges is layered rather
than a flat yes or no.

At the level of internal structure, the assumption is in good standing.
The estimated sampling intensity is dominated by a single, smooth
south--north gradient that is common to all three taxonomic groups
(Section~\ref{sec:results-pattern}), the permutation test cannot
distinguish the observed regional variance from a random draw of groups
(Section~\ref{sec:results-permutation}), and exchanging one region's data
between groups barely moves the regional structure
(Section~\ref{sec:results-randomization}). Each of these is what one would
expect to see if the bias really is shared across the species of a group,
which is the precondition the joint correction needs. To that extent the
shared-bias assumption is not merely assumed but corroborated by data the
correction did not get to choose.

What the same diagnostics cannot do is certify that the corrected
\emph{predictions} are right. They establish the consistency of the bias
field with the shared-bias hypothesis; they do not confront the
bias-corrected occupancy surfaces with independent ground truth. That
final step --- the structured-survey validation against ANO
(Section~\ref{sec:ano}) --- is the one component still outstanding
(Section~\ref{sec:results-future}), so the thesis answers the question at
the level of internal coherence and identifiability, and leaves the
out-of-sample predictive verdict for the validation to deliver. This is a
real boundary on what can presently be claimed, and it is drawn explicitly
rather than papered over.


% =====================================================================
\section{Geography over taxonomy, and a caveat by construction}
\label{sec:disc-geography}
% =====================================================================

The clearest empirical pattern in the results is that location, not taxon,
governs sampling bias in Norwegian GBIF data. The baseline variances
differ by group --- birds ($0.2405$) about half as variable as fungi
($0.4653$) and vascular plants ($0.4807$), in line with birds being
recorded more extensively and more evenly across the country
(Section~\ref{sec:results-baseline}) --- yet every one of those baselines
sits almost exactly at the centre of its permutation null, with empirical
$p$-values of $0.477$, $0.478$ and $0.479$
(Section~\ref{sec:results-permutation}). The near-identity of three
$p$-values drawn from datasets that differ in size, composition and
recording community (Section~\ref{sec:results-consistency}) is harder to
dismiss as coincidence than any single test would be: it points to a
common cause, a recording-effort gradient that the whole community of
observers shares regardless of what they record. Sampling bias here is
strongly geographic and only weakly taxon-specific.

This reading must be tempered by an honest caveat. The diagnostics operate
on the modelled bias field, not on the raw occurrence records, and the
upstream model places a single smooth spatial field beneath the species of
each group (Chapter~\ref{chap:Theory}). A shared spatial field will, by
its very construction, tend to produce regional structure that is shared
across the species drawing on it, so a permutation null that centres on
the baseline is partly what the model architecture predisposes the data to
show. The test is therefore better understood as a consistency check ---
it confirms that the fitted field behaves as a shared-bias field should,
and it would have flagged a gross violation --- than as an independent
confirmation that biology contributes no group-specific bias. The block
sampling test sharpens rather than escapes this point: it localises the
small amount of structure that \emph{is} group-sensitive to a few
peripheral, sparsely recorded regions (Section~\ref{sec:results-randomization}),
which is exactly where a smooth shared field is least able to impose
agreement and where genuine taxon-specific behaviour, if present, would
surface first.


% =====================================================================
\section{How far the assumption holds: the spatial-field diagnostic}
\label{sec:disc-degree}
% =====================================================================

The spatial-field diagnostic (Section~\ref{sec:fielddiag}) is what keeps
the conclusion from collapsing into a uniform endorsement of the
correction. By refitting the bias sub-model with and without a spatial
field and watching the covariate effects move, it measures, group by
group, how much of the estimated bias was leaning on smooth spatial
confounding rather than on genuine covariate information
(Chapter~\ref{chap:Theory}). The two groups behave very differently. For
vascular plants, most covariate effects barely shift when the field is
added, and only the climate terms --- summer precipitation and its squared
companions --- react, so the confounding between recording effort and the
broad climate gradient is confined to a handful of covariates. For fungi
the reaction is far broader: summer precipitation collapses from a large
positive effect to essentially nothing, the squared climate terms are
pulled sharply toward zero, and only the covariates tied to genuine
habitat, such as habitat heterogeneity and human density, stay put.

The interpretation is that the shared-bias assumption holds to a degree
that tracks the quality of the structured data standing behind each group.
Vascular plants are anchored by the area-representative ANO scheme, which
supplies genuine presence--absence information and genuine absences; their
bias estimate is consequently stable, and the field is needed only to
absorb the climate-aligned part of the effort gradient. Fungi have no
comparable exhaustive survey, their absences are inferred rather than
designed, and their covariate effects are almost entirely rewritten once
the field is present --- a sign that for that group the bias estimate was
doing work the structured data could not support. The practical reading
follows directly: the spatial field in the bias model is not optional
housekeeping but the component that absorbs the effort-driven spatial
structure the covariates would otherwise misread as ecology, and the size
of the covariate shift is a per-group health check on the correction, to
be read with confidence for plants and generously for fungi. This is the
nuance that the internal null results, on their own, would hide: the
correction rests on firmer ground exactly where independent survey data
exist to anchor it, and on softer ground where they do not.


% =====================================================================
\section{Where the uncertainty lives, and what it implies for sampling}
\label{sec:disc-practice}
% =====================================================================

Across every group the disagreement among posterior samples, the spread of
the block-swap influence, and the thinning of the raw records all settle
in the same place: the sparsely recorded interior and the far north
(Sections~\ref{sec:results-pattern} and~\ref{sec:results-randomization}).
The well-sampled south is stable across the posterior and nearly
interchangeable between groups --- Oslo is the least influential region in
all three datasets --- while the regions that carry the structure are
peripheral and effort-poor, and which one matters most is taxon-specific:
the northern Skorovatn and Kirkenes for birds, the southern-coastal
Kristiansand for fungi, Setesdal and Lakselv for vascular plants
(Section~\ref{sec:results-randomization}). The model is most certain where
it has the most data and least certain where it has the least, which is
unsurprising in itself but useful when made quantitative.

The actionable consequence is that the value of additional recording
effort is not spread evenly across the country. Adding records to the
already dense south would change the bias estimate very little; the leverage
lies in the peripheral, data-thin regions where the posterior runs across
almost the whole colour scale and where a single region's data can still
move the regional structure. A diagnostic that identifies those regions is
therefore not only descriptive but prescriptive: it points to where new
structured sampling --- the kind that supplies genuine absences and so
anchors the bias estimate, as ANO does for plants --- would most reduce the
uncertainty that the maps expose. The clean ordering of the three groups,
with the disagreement widest for the sparsely recorded fungi and tightest
for the abundant birds, reinforces the same message from the other
direction: volume and spread of records, not the choice of taxon, are what
buy a stable bias surface, and the fieldfare-versus-peregrine comparison
shows that even within a group it is record density rather than the
particular species that decides the matter.


% =====================================================================
\section{Limitations}
\label{sec:disc-limits}
% =====================================================================

Several limitations bound these conclusions and are stated plainly. First,
and most importantly, the predictive validation is incomplete: the internal
diagnostics show the bias field to be self-consistent with the shared-bias
hypothesis, but the out-of-sample test of the corrected predictions against
ANO (Section~\ref{sec:ano}) has not yet been carried through, so no claim is
made here about predictive accuracy. Second, the diagnostics interrogate the
model's output rather than the raw data, and as noted in
Section~\ref{sec:disc-geography} a shared spatial field partly predisposes
the permutation null toward its centred outcome; the tests should be read as
consistency checks, not as independent proof that bias is taxon-neutral.

Third, the spatial resolution is set by the saved prediction surfaces at
roughly $1$\,km, and the upstream spatial mesh is sparse at the $10$\,km
scale of the study regions (Section~\ref{sec:hotspot}), so each region's
values are read off relatively few independent field nodes and no single
region should be over-interpreted. Fourth, the twelve regions were chosen by
hand to span the survey-effort gradient rather than sampled objectively;
this serves the descriptive aim well but introduces a subjective element,
and the results are necessarily conditioned on that choice, even if the
move from six to twelve regions left the read unchanged. Fifth, the maps
summarise each posterior by its mean bias and display only the two most
divergent samples per group; this is an honest way to bracket the
uncertainty but stops short of propagating the full posterior through the
regional statistics. Finally, the genuine-absence validation is available
only for vascular plants, because birds are imperfectly detected and fungi
lack an exhaustive Norwegian structured survey (Section~\ref{sec:ano}); the
exclusion is itself a symptom of the data gaps the thesis documents, but it
means the firmest part of the analysis covers only one of the three groups.

None of these undoes the central finding --- that Norwegian sampling bias is
governed by a shared geographic gradient that the correction can exploit ---
but each marks the edge of what the present evidence supports, and together
they map the work that would tighten it. Those threads are drawn together,
and the contributions and remaining work set out, in
Chapter~\ref{chap:Conclusion}.
