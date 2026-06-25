% =====================================================================
%  Conclusion chapter
%  Sampling bias in Norwegian biodiversity occurrence data
%
%  Self-contained \chapter to be \input{} into the main thesis.
%  Assumes the thesis preamble already loads, at minimum:
%     \usepackage{hyperref}   % optional
%
%  NOTE ON LABELS
%  --------------
%  This chapter uses \label{chap:Conclusion} (the target the Discussion
%  chapter points at) and \label{sec:concl-*} for its sections, matching
%  the section titles in the table of contents (Summary of Findings,
%  Contributions to Knowledge, Future work). Cross-references reach the
%  Results chapter (\ref{chap:Results}, \ref{sec:results-*}), the Methods
%  chapter (\ref{ch:methods}, \ref{sec:fielddiag}, \ref{sec:block},
%  \ref{sec:permutation}, \ref{sec:ano}) and the Discussion
%  (\ref{ch:discussion}). Change these if you keep different labels.
% =====================================================================

\chapter{Conclusion}
\label{chap:Conclusion}

This thesis set out to test a single assumption on which the integrated
correction of Norwegian biodiversity data rests: that the species within a
taxonomic group share a common observer-bias structure, captured by one
spatial bias field. Rather than refit the occurrence model, it took the
posterior bias surfaces produced by the Hotspot project and interrogated
them with a sequence of spatial diagnostics. This closing chapter
summarises what those diagnostics found
(Section~\ref{sec:concl-summary}), states what the work contributes
(Section~\ref{sec:concl-contrib}), and sets out the analysis that remains
(Section~\ref{sec:concl-future}).


% =====================================================================
\section{Summary of Findings}
\label{sec:concl-summary}
% =====================================================================

The headline result is that sampling bias in Norwegian GBIF data is
governed by geography far more than by taxonomy. For birds, fungi and
vascular plants alike, the estimated sampling intensity is dominated by a
smooth south--north gradient, dense in the well-surveyed south-east and
thin across the interior and the far north
(Section~\ref{sec:results-pattern}). The magnitude of that bias differs by
group --- birds are about half as variable as fungi and vascular plants,
consistent with bird recording being the most spatially extensive activity
(Section~\ref{sec:results-baseline}) --- but the regional \emph{structure}
is statistically indistinguishable from a random composition of groups, with
permutation $p$-values of $0.477$, $0.478$ and $0.479$ that agree to within a
fraction of a permutation standard deviation
(Sections~\ref{sec:results-permutation} and~\ref{sec:results-consistency}).
The stratified block sampling test confirms and localises this: exchanging
a region's data between groups changes the structure only slightly, the
leverage is concentrated in a few peripheral, sparsely recorded regions
whose identity depends on the taxon, and the densely sampled regions ---
Oslo above all --- are nearly interchangeable
(Section~\ref{sec:results-randomization}).

The spatial-field diagnostic qualifies this otherwise uniform picture
(Section~\ref{sec:fielddiag}). The shared-bias assumption does not simply
hold or fail; it holds to a degree that tracks the quality of the
structured data behind each group. For vascular plants, anchored by the
ANO survey, only the climate covariates react when the spatial field is
added, so the assumption can be trusted across most of the picture. For
fungi, which lack an exhaustive survey, the covariate effects are almost
entirely rewritten by the field, so the correction for that group rests on
softer ground and must be read more cautiously. Taken together, the
findings say that the bias correction is well-founded where independent
structured data exist to anchor it, and that the spatial field is the
component carrying the effort-driven structure the covariates would
otherwise misread as ecology.


% =====================================================================
\section{Contributions to Knowledge}
\label{sec:concl-contrib}
% =====================================================================

The thesis makes three contributions. The first is methodological: it
treats the fitted bias field itself as data and brings a coherent toolkit
to bear on it --- a spatial-field confounding diagnostic, a variance
decomposition, a permutation test of group exchangeability, and a
stratified block sampling test of regional leverage --- assembled into a
modular, reproducible pipeline that switches between datasets by editing a
single configuration (Chapter~\ref{ch:methods}). This gives a transferable
way to ask whether the shared-bias assumption underlying an integrated
species distribution model actually holds, a question usually assumed away
rather than tested.

The second is empirical. For the three Norwegian groups studied, the work
establishes that observer bias is dominated by a shared geographic
gradient that is common across taxa and only weakly taxon-specific, that
the residual taxon-specific structure lives in a handful of peripheral,
data-poor regions, and that the degree to which the shared-bias correction
can be trusted is set by the structured data available for each group
rather than by the volume of opportunistic records alone. The
fieldfare-versus-peregrine comparison makes the same point within a single
group: stability comes from record density and spread, not from the
particular species chosen to represent the group.

The third is practical. Because the diagnostics identify exactly where the
bias estimate is least constrained --- the sparse interior and the far
north --- they convert a descriptive map of uncertainty into guidance on
where additional structured sampling would do the most good. In a setting
where conservation decisions are only as reliable as the distribution maps
behind them, knowing where those maps are weakest, and why, is itself a
usable result.


% =====================================================================
\section{Future work}
\label{sec:concl-future}
% =====================================================================

The most immediate task is to complete the independent validation of the
bias-corrected vascular-plant predictions against the held-out ANO survey
(Sections~\ref{sec:ano} and~\ref{sec:results-future}). The data preparation
is in place; carrying the per-species AUC, the per-region skill and the
bias-versus-error Spearman diagnostic through to results would close the one
loop this thesis leaves open, turning the internal consistency established
here into a statement about out-of-sample predictive accuracy, and testing
in particular whether the correction pays off evenly across the south--north
gradient rather than only where records were already abundant.

Beyond that, several extensions follow naturally. The genuine-absence
validation could be widened to other groups as suitable structured surveys
become available, though birds and fungi will remain harder cases than
plants. The regional analysis could be refitted at a finer resolution than
the $1$\,km saved-prediction grid and with regions chosen objectively rather
than by hand, and the full posterior could be propagated through the
regional statistics instead of being summarised by the mean bias, giving a
formal account of the large northern uncertainty the maps reveal. The same
pipeline could be applied to the remaining Hotspot groups, such as lichens
and terrestrial arthropods, to test whether the geography-over-taxonomy
finding generalises beyond the three groups treated here. Finally, the
region-sensitivity ranking invites a targeted design study: using the
identified high-leverage regions to plan where new structured monitoring
would most improve the bias correction, and so most improve the biodiversity
maps that conservation planning depends on. The broader implications of the
result are taken up in the Discussion (Chapter~\ref{ch:discussion}); the
work above is what would carry it from a well-supported internal finding to
a fully validated one.
