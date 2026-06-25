% =====================================================================
%  Results chapter
%  Sampling bias in Norwegian biodiversity occurrence data
%
%  Self-contained \chapter to be \input{} into the main thesis.
%  Assumes the thesis preamble already loads, at minimum:
%     \usepackage{booktabs}     % nice tables
%     \usepackage{amsmath}      % math environments
%     \usepackage{graphicx}     % figures
%     \usepackage{subcaption}   % subfigures
%     \usepackage{float}        % the [H] float specifier
%     \usepackage{hyperref}     % optional
%
%  NOTE ON LABELS
%  --------------
%  This chapter uses \label{chap:Results} for the chapter and
%  \label{sec:results-*} for its sections, to avoid clashing with the
%  methods file (methods_chapter.R, \label{ch:methods}) and the theory
%  file (theory_chapter.R, \label{chap:Theory}). Cross-references into
%  the Methods chapter point at \ref{sec:regions}, \ref{sec:extract},
%  \ref{sec:block}, \ref{sec:permutation} and \ref{sec:ano}; the forward
%  reference to the discussion points at \ref{ch:discussion} and the
%  back-reference to the background at \ref{chap:Background}. Change these
%  if you keep different labels there.
%
%  Code is not reproduced here. Each place that refers to a specific
%  script names it inline as "github code <filename>", matching the
%  Methods chapter; those scripts are published in the accompanying
%  repository.
% =====================================================================

\chapter{Results}
\label{chap:Results}

This chapter reports what the diagnostics of Chapter~\ref{ch:methods}
recover when applied to the modelled sampling-bias field for Norway, in
three movements. The first
(Sections~\ref{sec:results-occurrences}--\ref{sec:results-regions})
is descriptive: it shows the raw occurrence data that motivate the bias
modelling, then the estimated sampling-intensity surfaces themselves,
first as full-country maps and then resolved over the fixed study
regions. The second
(Sections~\ref{sec:results-setup}--\ref{sec:results-consistency}) is
inferential: it states the analytical setup, reports the observed
baseline variances, and tests whether the regional structure of bias
departs from a random composition of taxonomic groups by means of the
permutation test. The third
(Sections~\ref{sec:results-randomization}--\ref{sec:results-summary})
localises that result with the stratified block sampling test, draws the
findings together, and notes the analysis still outstanding. Throughout,
the question is the same: how is sampling bias distributed in space, and
how much of that structure is shared across taxonomic groups rather than
particular to any one of them.


% =====================================================================
\section{Distribution of occurrences for the taxonomic groups}
\label{sec:results-occurrences}
% =====================================================================

\subsection{Occurrence data for the control species}
Before any of the fitted models, it is worth looking at the raw
occurrence data. The three control species standing in for the groups are
the bracket fungus \textit{Fomitopsis pinicola} for the fungi, the herb
\textit{Lysimachia europaea} for the vascular plants, and the fieldfare
\textit{Turdus pilaris} for the birds. All three are common in Norway and
heavily recorded, so their occurrence maps give a first impression of how
observation effort spreads across the country. The fieldfare is almost a
best case for birds, abundant and reported just about everywhere, so
Figure~\ref{fig:control-occurrences} also includes a weaker bird, the
peregrine falcon \textit{Falco peregrinus}, to show what the group looks
like when the control species is more localised and leans on specialist
observers. All four maps draw GBIF records straight from a citable
download on the same national outline (github code
\texttt{gbif\_norway\_maps.R}).

\begin{figure}[htbp]
\centering
\begin{subfigure}[b]{0.48\textwidth}
\includegraphics[width=\textwidth]{Figures/occ_fomitopsis_pinicola.png}
\caption{\textit{Fomitopsis pinicola} (fungi), $n = 9{,}585$.}
\label{fig:occ-fungi}
\end{subfigure}
\hfill
\begin{subfigure}[b]{0.48\textwidth}
\includegraphics[width=\textwidth]{Figures/occ_lysimachia_europaea.png}
\caption{\textit{Lysimachia europaea} (vascular plants), $n = 29{,}605$.}
\label{fig:occ-plants}
\end{subfigure}
\caption{GBIF occurrence records in Norway for the fungal and vascular plant control species. Source: GBIF.org, \texttt{10.15468/dl.3ru6rq}.}
\label{fig:occ-fungi-plants}
\end{figure}

The four maps differ markedly in how many records they hold and how those
records are spread, and the differences track the observer behaviour
discussed in Chapter~\ref{chap:Background}. The fieldfare in
Figure~\ref{fig:occ-birds} has the most records by a wide margin and the
most complete coverage, reaching well into the north and the inland
regions. This reflects the large, widely distributed community of
birdwatchers appearing in the data. \textit{Lysimachia europaea} in
Figure~\ref{fig:occ-plants} is recorded over the whole country too, but
the records clearly thin out in the interior and the far north, which is
what botanical effort clustered on accessible, species-rich sites
produces. \textit{Fomitopsis pinicola} in Figure~\ref{fig:occ-fungi} has
the fewest records and the patchiest coverage of all: dense clumps in the
south-east and along the populated coast, and large gaps elsewhere.

\begin{figure}[htbp]
\centering
\begin{subfigure}[b]{0.48\textwidth}
\includegraphics[width=\textwidth]{Figures/occ_turdus_pilaris.png}
\caption{\textit{Turdus pilaris} (fieldfare, birds), $n = 484{,}709$.}
\label{fig:occ-birds}
\end{subfigure}
\hfill
\begin{subfigure}[b]{0.48\textwidth}
\includegraphics[width=\textwidth]{Figures/occ_falco_peregrinus.png}
\caption{\textit{Falco peregrinus} (peregrine falcon, weaker bird control), $n = 79{,}445$.}
\label{fig:occ-falco}
\end{subfigure}
\caption{GBIF occurrence records in Norway for the two bird control species: the abundant fieldfare and the more localised peregrine falcon. The number of records differs by more than an order of magnitude between the two. Source: GBIF.org, \texttt{10.15468/dl.3ru6rq}.}
\label{fig:control-occurrences}
\end{figure}

The peregrine falcon in Figure~\ref{fig:occ-falco} is the reason for the
second bird map. It is still a well-known species that is reported often,
but it is much rarer than the fieldfare, more localised, and it leans more
on specialist observers, so its map should carry a stronger imprint of
where people actually go. And it does. The peregrine has roughly ten times
fewer records than the fieldfare ($79{,}445$ against $484{,}709$), and its
distribution is visibly patchier, concentrated where dedicated raptor
watchers are active rather than spread evenly over its real range.

Two features appear in all four maps. The records pile into southern and
coastal Norway, where most people live, and they thin across the
mountainous interior and the far north-east. Even the best-sampled species
clumps rather than covering the ground evenly. This is the observer bias
that the integrated models in the next sections are meant to separate from
the real ecological signal, and the fieldfare-versus-peregrine contrast
sets up the question the rest of the chapter works on.


% =====================================================================
\section{Estimated sampling intensity}
\label{sec:results-pattern}
% =====================================================================

\subsection{Visualising the estimated sampling intensity}
The occurrence maps above are the raw data. The integrated model does not
hand back a single sampling-effort surface, though; it gives a whole
posterior distribution over it, so the object to look at is not one map but
a stack of them. To make the estimated sampling intensity visible, the bias
term of the fitted model is evaluated on a regular grid over all of Norway
and drawn one posterior sample at a time, on the same colour scale every
time so the panels line up (github code \texttt{Workflow/06\_png\_maps.R}).
Each map shows the posterior mean of the bias on the log scale. More
negative values, the purples and dark blues, are where the model infers
relative sampling effort to be low, and values near zero, the yellows and
pale greens, mark the best-covered ground. The hotspot project supplies one
bias field per posterior sample and per group, so the maps become a way of
reading the spatial pattern of effort and the uncertainty around it
together.

\begin{figure}[htbp]
\centering
\begin{subfigure}[b]{0.48\textwidth}
\includegraphics[width=\textwidth]{bias_mean_fungiA33.png}
\caption{Posterior sample A33.}
\label{fig:bias-fungi-a33}
\end{subfigure}
\hfill
\begin{subfigure}[b]{0.48\textwidth}
\includegraphics[width=\textwidth]{bias_mean_fungiA39.png}
\caption{Posterior sample A39.}
\label{fig:bias-fungi-a39}
\end{subfigure}
\caption{Estimated sampling intensity (posterior mean of the bias term, log scale) for the fungi group, shown for the two posterior samples that differ most from one another. Both panels use the same colour scale; more negative values indicate lower relative sampling effort. Source: hotspot project.}
\label{fig:bias-fungi}
\end{figure}

Figure~\ref{fig:bias-fungi} takes the fungi group and shows the two
posterior samples that sit furthest apart, which is the clearest way to
show what these maps reveal. The two agree on the broad shape of the
problem. Southern and south-eastern Norway come out best covered, the
palest greens and yellows sitting over the populated lowlands, and effort
drops off towards the mountains and the north. Where they disagree is on how
severe that drop-off becomes. Sample A33 in
Figure~\ref{fig:bias-fungi-a33} keeps most of the country in the middling
green-to-teal band and treats the north as merely under-sampled. Sample A39
in Figure~\ref{fig:bias-fungi-a39} pushes those same northern regions down
into the dark blue and purple, and scatters low-effort patches a good deal
further south. So the well-sampled core stays put across the posterior, but
the intensity up in the thinly recorded north is anything but settled. It
is precisely where the data run out that the model is least sure how much
effort to assume.

\subsection{Sampling intensity for the vascular plant group}
The same can be done for the vascular plants, which are recorded a good
deal more heavily than the fungi and so make a useful comparison. The recipe
is unchanged: the bias term drawn one posterior sample at a time on a shared
colour scale, with the two most-different samples picked out to bracket what
the posterior allows. Plant records are both more plentiful and more evenly
spread than fungal ones, so one might expect the two maps to agree more
closely than the fungi pair did. Whether they do is what is worth checking.

\begin{figure}[htbp]
\centering
\begin{subfigure}[b]{0.48\textwidth}
\includegraphics[width=\textwidth]{bias_mean_vascularPlantsA19.png}
\caption{Posterior sample A19.}
\label{fig:bias-plants-a19}
\end{subfigure}
\hfill
\begin{subfigure}[b]{0.48\textwidth}
\includegraphics[width=\textwidth]{bias_mean_vascularPlantsA20.png}
\caption{Posterior sample A20.}
\label{fig:bias-plants-a20}
\end{subfigure}
\caption{Estimated sampling intensity (posterior mean of the bias term, log scale) for the vascular plant group, shown for the two posterior samples that differ most from one another. Both panels use the same colour scale; more negative values indicate lower relative sampling effort. Source: hotspot project.}
\label{fig:bias-plants}
\end{figure}

Figure~\ref{fig:bias-plants} shows the outcome, and the two samples disagree
more than the additional recording would lead one to expect. Both still put
the best coverage in the populated south, the palest greens and yellows
gathering around the lowlands and Oslo. The disagreement is over the north
and the central mountain spine. Sample A19 in
Figure~\ref{fig:bias-plants-a19} drives those regions deep into the dark
blue and purple, the worst of it forming a continuous belt up the interior
with an isolated very-low-effort patch in the far north-east, so this sample
reads the plant data as strongly biased away from the mountains and the
Arctic. Sample A20 in Figure~\ref{fig:bias-plants-a20} says almost the
opposite about the same ground. The deep purple is gone, the north relaxes
into the moderate green-to-teal band, and pale well-sampled patches appear
even at high latitude. The takeaway is the same as for the fungi, with one
extra warning attached. That stable, well-sampled southern core shows up in
both plant maps, so the model knows where effort is high. What it cannot pin
down is how far that effort reaches into the thinly recorded north, and
there the posterior runs across almost the whole colour scale. That the
disagreement is this wide even for a fairly well-recorded group is the
warning: an abundance of data alone does not guarantee a stable bias
estimate. Where records stay thin, as they do across the interior and the
far north, the maps expose a large share of leftover uncertainty that a
single summary map would obscure. Set beside Figure~\ref{fig:bias-fungi},
the plant maps say the same thing, the north is the part of the country the
model is least certain about, regardless of which group is examined.

\subsection{Sampling intensity for the bird group}
The birds round out the comparison. They are the most heavily recorded of
the three by a wide margin, so this should be the case where the posterior
samples agree the most. The setup is the same as the others: the bias term
drawn one posterior sample at a time on a shared colour scale, with the two
most-different samples pulled out so the width of the disagreement can be
measured against the fungi and the plants.

\begin{figure}[htbp]
\centering
\begin{subfigure}[b]{0.48\textwidth}
\includegraphics[width=\textwidth]{bias_mean_birds18.png}
\caption{Posterior sample 18.}
\label{fig:bias-birds-18}
\end{subfigure}
\hfill
\begin{subfigure}[b]{0.48\textwidth}
\includegraphics[width=\textwidth]{bias_mean_birds20.png}
\caption{Posterior sample 20.}
\label{fig:bias-birds-20}
\end{subfigure}
\caption{Estimated sampling intensity (posterior mean of the bias term, log scale) for the bird group, shown for the two posterior samples that differ most from one another. Both panels use the same colour scale; more negative values indicate lower relative sampling effort. Source: hotspot project.}
\label{fig:bias-birds}
\end{figure}

Figure~\ref{fig:bias-birds} bears that out, and the contrast with the
earlier groups is clear. Sample 18 in Figure~\ref{fig:bias-birds-18} is
close to uniformly green from the far south up to the Arctic coast. The dark
blue and purple that ran through the harsher fungi and plant samples is
essentially gone, and even the northern interior, the area that troubled
every other group, sits comfortably in the moderate range. Sample 20 in
Figure~\ref{fig:bias-birds-20} is the most pessimistic sample the bird
posterior offers, and even so its low-effort areas come down to a few
compact dark-blue patches and a small purple core in the far north-east,
nothing like the continuous belts seen elsewhere. So the two maps differ far
less than any other pair. They differ only over how deep a handful of
northern pockets go, and agree on green, well-sampled coverage nearly
everywhere else. Lined up with Figures~\ref{fig:bias-fungi}
and~\ref{fig:bias-plants}, the bird maps complete a clear ordering across
the three groups. The gap between the two most-different samples narrows as
the data accumulate: widest for the sparsely recorded fungi, smaller but
still real for the vascular plants, and tightest for the abundant birds. And
in every group the disagreement settles in the same place, the sparsely
sampled interior and the far north, which says again that this is where the
model's read on sampling effort is most starved of data. The birds are the
favourable end of that same pattern. When records are dense and spread
across the whole country, the maps collapse to a stable, near-flat surface
and the leftover uncertainty that swamps the fungi all but vanishes.

\subsection{Sampling intensity for the alternate bird group}
The fieldfare is about as good as a control species gets, so it cannot, on
its own, show what happens when birds are represented by something patchier.
That is the point of repeating the exercise here with a weaker, less common
bird. If swapping the control species barely moves the maps, then what was
seen for the fieldfare was not simply the luck of a very well recorded
species, and the bird group is genuinely on firmer ground than the fungi or
the plants. If the disagreement returns, the stability was largely a product
of record volume. The setup is the same as before: one posterior sample of
the bias term per map, a shared colour scale, and the two samples that sit
furthest apart.

\begin{figure}[htbp]
\centering
\begin{subfigure}[b]{0.48\textwidth}
\includegraphics[width=\textwidth]{bias_mean_birds17.png}
\caption{Posterior sample 17.}
\label{fig:bias-altbirds-17}
\end{subfigure}
\hfill
\begin{subfigure}[b]{0.48\textwidth}
\includegraphics[width=\textwidth]{bias_mean_birds16.png}
\caption{Posterior sample 16.}
\label{fig:bias-altbirds-16}
\end{subfigure}
\caption{Estimated sampling intensity (posterior mean of the bias term, log scale) for the alternate bird group, based on a weaker common species, shown for the two posterior samples that differ most from one another. Both panels use the same colour scale; more negative values indicate lower relative sampling effort. Source: hotspot project.}
\label{fig:bias-altbirds}
\end{figure}

Figure~\ref{fig:bias-altbirds} settles the question, and the bird group
holds up. The two maps look a lot like the fieldfare pair in
Figure~\ref{fig:bias-birds}. Sample 17 in Figure~\ref{fig:bias-altbirds-17}
is mostly that same broad green wash over the south and the coast, with only
a mild blue cooling inland and up north, so even a less-recorded bird still
carries most of the dense, country-wide effort that birds get. Sample 16 in
Figure~\ref{fig:bias-altbirds-16} is the darker of the two: the interior
valleys and the northern interior sink into darker blue and a couple of
small purple cores appear in the far north-east. But the two maps still
agree over the well-sampled south and the coast, and they diverge only in
the same data-thin interior and the same northern margins seen for every
group.

The honest comparison is the one between the fieldfare and this weaker bird,
since both stand in for the same group. Set the two side by side and the
alternate bird does disagree a little more than the fieldfare did. That is
what one would expect from a species that is recorded less, and it would be
wrong to claim they are identical. The gap is small, though, and it sits in
exactly the places where every group struggles, the sparse interior and the
far north. It never extends into the well-covered south, as the fungi gap
does in Figure~\ref{fig:bias-fungi}. So the choice of bird matters at the
edges, but it does not change the verdict: what determines how well the
sampling intensity can be pinned down is the number of records and how
widely they are spread, not which particular bird is used as the control.
The bird group stays the stable one whichever control species is chosen.

The national maps establish the descriptive pattern, but they flatten out
everything that happens at the scale a planner actually works at. To recover
that, the same fixed regions are cut out of every map and examined on their
own (Section~\ref{sec:results-regions}); the analytical setup that underlies
those regions and the tests that follow is stated first
(Section~\ref{sec:results-setup}).


% =====================================================================
\section{Overview of the analytical setup}
\label{sec:results-setup}
% =====================================================================

This chapter reports the spatial structure of sampling bias in GBIF
occurrence data for Norway and tests whether that structure differs from
what would be expected under a random composition of taxonomic groups. The
machinery behind the tests is described in full in Chapter~\ref{ch:methods};
this section recalls only what is needed to read the results. The analysis
was applied identically to three datasets (birds, fungi, and vascular
plants) comprising $21$, $20$, and $19$ taxonomic groups, respectively. For
each group, a per-cell sampling-bias surface (the modelled mean bias) was
extracted on a common grid covering mainland Norway
(Section~\ref{sec:extract}).

Spatial variation was summarised over twelve focal regions, each defined as
a $10 \times 10$~km square centred on a fixed location and resolving to a
full set of $121$ non-\texttt{NA} bias cells (Section~\ref{sec:regions}).
The region centres are listed in Table~\ref{tab:regions}; the centres for
Svolv{\ae}r and Kirkenes were adjusted slightly ($3$~km west and $1$~km
south, respectively) so that every region's square fell entirely within the
modelled land area and returned the complete $121$-cell complement for
analysis.

\begin{table}[ht]
  \centering
  \caption{The twelve focal regions and their projected centre coordinates
    (km). Each region is a $10 \times 10$~km square resolving to $121$
    non-missing bias cells.}
  \label{tab:regions}
  \begin{tabular}{llrr}
    \toprule
    Region & & $x$ & $y$ \\
    \midrule
    Setesdal     & & $100$  & $6600$ \\
    Oslo         & & $255$  & $6655$ \\
    Valdres      & & $200$  & $6780$ \\
    Trondheim    & & $280$  & $7030$ \\
    Troms{\o}    & & $650$  & $7680$ \\
    Lakselv      & & $900$  & $7800$ \\
    Bergen       & & $-28$  & $6734$ \\
    Kristiansand & & $84$   & $6472$ \\
    Skorovatn    & & $420$  & $7161$ \\
    Bod{\o}      & & $486$  & $7467$ \\
    Svolv{\ae}r  & & $477$  & $7572$ \\
    Kirkenes     & & $1075$ & $7801$ \\
    \bottomrule
  \end{tabular}
\end{table}

The test statistic for the permutation test is the \emph{total variance} of
the pooled bias cells across all twelve regions. The observed (baseline)
value was computed using each present group exactly once. A null
distribution was then generated by $1000$ permutations: within each region,
$n_{\text{groups}}$ groups were drawn with replacement, the corresponding
$121$ cells were taken from each draw, all twelve regions were pooled, and
the total variance was recomputed. The proportion of permuted variances
greater than or equal to the baseline served as the empirical $p$-value, and
a fixed random seed makes the result exactly reproducible
(Section~\ref{sec:permutation}). The sections that follow present, in turn,
the regional view of the descriptive bias pattern
(Section~\ref{sec:results-regions}), the observed baseline variances
(Section~\ref{sec:results-baseline}), and the outcome of the permutation
test (Section~\ref{sec:results-permutation}).


% =====================================================================
\section{Regions}
\label{sec:results-regions}
% =====================================================================

The national maps are good for the broad picture, but they flatten out
everything that happens at the scale a planner actually works at. To get at
that, the same set of regions is cut out of every map and looked at on its
own (github code \texttt{Workflow/03\_region\_maps.R}). The regions are
identical across all the taxonomic groups, so there is no point repeating
them group by group. One example carries the idea, and the rest follow the
same template.

The regions were chosen by hand. The maps were inspected for areas that
stood out, places where the bias was clearly high or clearly low, with a
deliberate effort to spread them across the whole country rather than letting
them pile up in one part of it. Sampling only the south teaches you about the
south, and the same goes for the north, so the aim was a combination: a few
regions in the south, a few through the middle, and a few in the north. Six
came out of that: Setesdal and Oslo in the south, Valdres and Trondheim
through the middle, and Troms\o{} and Lakselv in the north. The spread is
what matters here, since it sets low-effort spots against well-covered ones
while still reaching from one end of Norway to the other.

Figure~\ref{fig:regions-fungi} shows the example, taken from the fungi
group, sample A1. The national map on the left marks the six regions, and
the six panels on the right zoom into each one and show the bias values
inside it on the same colour scale. The contrast is the point. Oslo and
Trondheim sit in the pale green-to-yellow band, the best-sampled end, while
Setesdal, Troms\o{} and Lakselv sink into the darker blues, and Valdres
falls somewhere between the two. So even a single posterior sample, read at
the regional scale, already separates the places the model trusts from the
ones it does not.

\begin{figure}[htbp]
\centering
\includegraphics[width=\textwidth]{regions_fungiA1.png}
\caption{The six regions used throughout the analysis, shown here on the fungi group, posterior sample A1. The national map on the left marks each region, and the panels on the right zoom into them and show the estimated sampling intensity (posterior mean of the bias term, log scale) inside each region on a shared colour scale. The regions are the same for every taxonomic group. Source: hotspot project.}
\label{fig:regions-fungi}
\end{figure}

The number of regions did not stay at six. Later in the work it was doubled,
mostly because six points spread across a country this long leave large
gaps, and a handful of extra regions gives a steadier read on how the bias
behaves between the obvious hotspots. The regions were still picked by hand
and still spread the same way, south to north, and the rest of the setup is
unchanged: the same shared colour scale, the same regions reused across every
group. Figure~\ref{fig:regions-fungi-12} shows the result, again on the
fungi group, sample A1. The six original regions are still there, Setesdal,
Oslo, Valdres and Trondheim in the south and through the middle, and
Troms\o{} and Lakselv in the north, and six more have been slotted in around
them: Bergen and Kristiansand fill out the south and the west coast,
Skorovatn and Bod\o{} cover the gap through Tr\o{}ndelag and Nordland, and
Svolv\ae r and Kirkenes push right up to the northern edge. The read does not
change; it just gets finer. Oslo still sits alone at the bright,
well-sampled end, with Bergen, Kristiansand and Trondheim a step behind it in
the greens, while the interior and the far north settle into the same dark
blues as before and Skorovatn drops the lowest of the lot. The extra regions
mostly land where the national map would lead you to expect, but they confirm
it region by region rather than leaving it to the eye, and they make the
south-to-north gradient in sampling effort harder to dismiss as an artefact
of where the original six happened to fall.

\begin{figure}
    \centering
    \includegraphics[width=1\linewidth]{fungiA1_12_reg.png}
    \caption{The twelve regions used in the later analysis, shown here on the fungi group, posterior sample A1. The six original regions are kept and six more added, still chosen by hand and still spread from south to north. The national map on the left marks each region, and the panels on the right zoom into them and show the estimated sampling intensity (posterior mean of the bias term, log scale) inside each region on a shared colour scale. The regions are the same for every taxonomic group. Source: hotspot project.}
    \label{fig:regions-fungi-12}
\end{figure}

The regional view confirms by eye what the tests now make quantitative,
beginning with the observed spread of bias across regions.


% =====================================================================
\section{Baseline regional variance}
\label{sec:results-baseline}
% =====================================================================

The observed test statistic for each dataset is the total variance of the
pooled bias cells, computed with every taxonomic group represented exactly
once (github code \texttt{total\_variance.R},
\texttt{new\_total\_variance.R}). These baseline values are reported in
Table~\ref{tab:baseline}. The pooled sample is large in every case, between
$27{,}588$ and $30{,}492$ cells, so the baseline variance is estimated with
high precision.

\begin{table}[ht]
  \centering
  \caption{Baseline total variance of pooled bias cells for each dataset,
    with the number of taxonomic groups and the total number of non-missing
    cells contributing to the estimate.}
  \label{tab:baseline}
  \begin{tabular}{lrrr}
    \toprule
    Dataset & Groups & Cells & Baseline variance \\
    \midrule
    Birds           & $21$ & $30{,}492$ & $0.2405$ \\
    Fungi           & $20$ & $29{,}040$ & $0.4653$ \\
    Vascular plants & $19$ & $27{,}588$ & $0.4807$ \\
    \bottomrule
  \end{tabular}
\end{table}

The three datasets differ markedly in the magnitude of their baseline
variance. Birds show the lowest value ($0.2405$), whereas fungi ($0.4653$)
and vascular plants ($0.4807$) are roughly twice as variable. This difference
does not stem from the number of groups or the sample size, which are similar
across datasets; it reflects a genuine contrast in how unevenly recording
effort is distributed among regions for each taxon.

The lower variance for birds fits with bird recording being the most
spatially extensive and evenly distributed of the three activities.
Birdwatching is a widespread, year-round pursuit that generates occurrence
records even in sparsely populated regions, which compresses the
between-region contrast in bias. Fungi and vascular plants are recorded more
opportunistically and are tied more strongly to accessible, well-vegetated
southern localities, producing a sharper gradient between high- and
low-effort regions and a larger total variance. These baseline values are the
observed quantities against which the permutation null distributions in
Section~\ref{sec:results-permutation} are compared.


% =====================================================================
\section{Permutation test of total variance}
\label{sec:results-permutation}
% =====================================================================

For each dataset, the observed baseline variance was compared against a null
distribution of $1000$ permuted total variances, generated by resampling
taxonomic groups with replacement within each region (see
Section~\ref{sec:results-setup}, and Section~\ref{sec:permutation} for the
full procedure; github code \texttt{permutation\_all\_datasets.R}). The
empirical $p$-value is the proportion of permuted variances that equal or
exceed the baseline. Results are summarised in Table~\ref{tab:permutation}
and the null distributions are shown in Figure~\ref{fig:histograms}.

\begin{table}[ht]
  \centering
  \caption{Permutation test of total variance for each dataset. The
    observed baseline is compared to the mean, standard deviation, and the
    proportion of $1000$ permuted variances that are greater than or equal
    to it ($p$).}
  \label{tab:permutation}
  \begin{tabular}{lrrrr}
    \toprule
    Dataset & Baseline & Perm.\ mean & Perm.\ SD & $p\,(\geq)$ \\
    \midrule
    Birds           & $0.2405$ & $0.2402$ & $0.0060$ & $0.477$ \\
    Fungi           & $0.4653$ & $0.4652$ & $0.0106$ & $0.478$ \\
    Vascular plants & $0.4807$ & $0.4796$ & $0.0147$ & $0.479$ \\
    \bottomrule
  \end{tabular}
\end{table}

In every dataset the observed baseline variance lies almost exactly at the
centre of its null distribution. The baseline and the permutation mean differ
only in the third or fourth decimal place. For birds it is $0.2405$ against
$0.2402$, a separation far smaller than one permutation standard deviation.
The empirical $p$-values follow suit: $0.477$ (birds), $0.478$ (fungi), and
$0.479$ (vascular plants). In each case roughly half of the permuted
variances exceed the observed value, and half fall below it.

None of the three tests gives any evidence that the real composition of
taxonomic groups produces more (or less) regional structure in sampling bias
than a random draw of groups would. The observed total variance is, to a very
close approximation, the variance expected by chance under the permutation
scheme. This null outcome is examined further, and its implications
discussed, in Section~\ref{sec:results-consistency} and in
Chapter~\ref{ch:discussion}.

\begin{figure}[H]
\centering
\includegraphics[width=0.6\textwidth]{birds_permutation_histogram.png}\\[0.6em]
\includegraphics[width=0.6\textwidth]{fungi_permutation_histogram.png}\\[0.6em]
\includegraphics[width=0.6\textwidth]{vascularPlants_permutation_histogram.png}
\caption{Null distributions of total variance from $1000$ permutations for
birds (top), fungi (middle), and vascular plants (bottom). In each panel
the red line marks the observed baseline variance. The baseline falls
near the centre of the distribution in all three datasets.}
\label{fig:histograms}
\end{figure}


% =====================================================================
\section{Consistency across taxa}
\label{sec:results-consistency}
% =====================================================================

The clearest feature of the results is not any single test but the agreement
among them. The three datasets differ in the number of taxonomic groups
($21$, $20$, and $19$), in sample size, and in the absolute magnitude of
their variance, with birds roughly half as variable as fungi and vascular
plants. Even so, they return almost identical empirical $p$-values: $0.477$,
$0.478$, and $0.479$. All three baselines sit within a fraction of a
permutation standard deviation of their respective null means.

This convergence tells us something on its own. If the null result for any
one dataset were an artefact of a particular set of groups, of sample size,
or of the specific regions chosen, there would be little reason for three
independently assembled datasets to agree so closely. Instead, the same
outcome emerges across taxa that are recorded by different communities,
through different methods, and with different spatial tendencies. So the
agreement strengthens the conclusion drawn from each test individually rather
than just repeating it.

This fits the descriptive pattern reported in
Section~\ref{sec:results-pattern}: within each dataset, the regional bias
profile is broadly shared from group to group. When a spatial pattern of
effort is common to all groups, resampling groups within a region leaves the
pooled distribution, and so its total variance, largely unchanged. The
permutation test recovers a baseline variance close to its null expectation
not by coincidence but as a direct consequence of the shared structure of
recording effort. Sampling bias in these data is strongly geographic but only
weakly taxon-specific, and that holds uniformly across birds, fungi, and
vascular plants.


% =====================================================================
\section{Stratified block sampling (region-swap) test}
\label{sec:results-randomization}
% =====================================================================

The permutation test in Section~\ref{sec:results-permutation} assessed the
overall level of regional bias variance. A second analysis localises that
result by asking \emph{which regions drive the regional structure of bias,
and how stable is that structure when a single region's data are exchanged
between taxonomic groups?} The test statistic is the \emph{variance among
regional variances}: for a given group, the bias variance is computed within
each of the twelve regions, and the variance of those twelve values measures
how unevenly internal heterogeneity is spread across regions
(Section~\ref{sec:block}; github code \texttt{Workflow/05\_randomization.R}).

For each target group the original statistic was computed from that group's
own twelve regions. A block randomization was then performed: one region at a
time was removed from the target group and replaced by the same region's
cells drawn from a different (donor) group, and the statistic was recomputed.
Carried out over every target-group $\times$ region $\times$ donor-group
combination, this yields, for each swap, a change relative to the original,
$\Delta = (\text{variance among regions})_{\text{mixed}} - (\text{variance
among regions})_{\text{original}}$. The analysis was applied separately to
all three datasets, using only those groups present in all twelve regions:
$20$ groups for birds, $20$ for fungi, and $19$ for vascular plants, giving
$4{,}560$, $4{,}560$, and $4{,}104$ swaps respectively.

\subsection{Magnitude of change under swapping}
\label{sec:rand-change}

In all three datasets the change in the statistic was small and roughly
centred on zero (Table~\ref{tab:rand-change}). Median changes were of order
$10^{-8}$ or smaller, negligible against original statistics of order
$10^{-5}$ to $10^{-4}$, and the majority of swaps fell below
$1 \times 10^{-6}$ in absolute terms ($60\%$ for birds, $87\%$ for fungi,
$73\%$ for vascular plants). Only a small minority of swaps produced larger
excursions. Exchanging any single region's data between groups therefore
rarely altered the regional structure of bias by much, in any taxon. This
mirrors the null outcome of the permutation test: because the spatial pattern
of recording effort is largely shared across groups
(Section~\ref{sec:results-pattern}), substituting one group's region for
another's leaves the overall structure essentially intact.

\begin{table}[ht]
  \centering
  \caption{Distribution of the change in variance among regional variances
    ($\Delta = $ mixed $-$ original) across all swaps, by dataset. The
    statistic is centred near zero in every case.}
  \label{tab:rand-change}
  \begin{tabular}{lrrrr}
    \toprule
    Dataset & Swaps & Median $\Delta$ & IQR & $\Pr(|\Delta|<10^{-6})$ \\
    \midrule
    Birds           & $4{,}560$ & $5.3 \times 10^{-8}$  & $[-4.3,\ 8.5]\times 10^{-7}$ & $0.60$ \\
    Fungi           & $4{,}560$ & $7.3 \times 10^{-9}$  & $[-1.5,\ 2.2]\times 10^{-7}$ & $0.87$ \\
    Vascular plants & $4{,}104$ & $-6.1 \times 10^{-10}$ & $[-4.3,\ 4.3]\times 10^{-7}$ & $0.73$ \\
    \bottomrule
  \end{tabular}
\end{table}

\subsection{Region sensitivity}
\label{sec:rand-sensitivity}

Most swaps had little effect, but influence was strongly uneven across
regions, and the most influential region differed between taxa
(Table~\ref{tab:rand-sensitivity}). For birds, two northern, sparsely
recorded regions dominated: \textbf{Skorovatn} and \textbf{Kirkenes} were an
order of magnitude more influential than any other region. For fungi, a
single southern region, \textbf{Kristiansand}, stood out by a comparable
margin. For vascular plants, the most influential regions were
\textbf{Setesdal} and \textbf{Lakselv}. In each dataset the leading region is
a peripheral, comparatively low-effort locality whose bias profile is most
atypical relative to the rest, so substituting it perturbs the among-region
variance the most.

Against this taxon-specific variation, one feature was entirely consistent:
\textbf{Oslo}, the most densely and evenly sampled region, was the
\emph{least} influential region in all three datasets, changing the result
hardly at all when exchanged. Well-sampled regions resemble the dataset as a
whole closely enough to be nearly interchangeable between groups, whereas the
sparse, idiosyncratic regions carry the structure.

\begin{table}[ht]
  \centering
  \caption{Region sensitivity across datasets: mean absolute change in
    variance among regional variances when each region is swapped, in units
    of $10^{-6}$. The most influential region per dataset is shown in bold;
    Oslo is the least influential in all three. Regions are ordered by their
    bird-dataset value.}
  \label{tab:rand-sensitivity}
  \begin{tabular}{lrrr}
    \toprule
    Swapped region & Birds & Fungi & Vascular \\
    \midrule
    Skorovatn    & $\mathbf{22.12}$ & $0.28$           & $0.90$          \\
    Kirkenes     & $18.12$          & $0.36$           & $0.53$          \\
    Lakselv      & $2.97$           & $0.25$           & $2.25$          \\
    Troms\o      & $1.98$           & $0.23$           & $0.39$          \\
    Setesdal     & $0.77$           & $0.32$           & $\mathbf{5.46}$ \\
    Bod\o        & $0.75$           & $0.34$           & $0.56$          \\
    Kristiansand & $0.73$           & $\mathbf{8.97}$  & $1.18$          \\
    Bergen       & $0.70$           & $0.32$           & $0.37$          \\
    Trondheim    & $0.68$           & $0.52$           & $0.81$          \\
    Svolv\ae r   & $0.58$           & $0.12$           & $0.31$          \\
    Valdres      & $0.53$           & $0.66$           & $0.47$          \\
    Oslo         & $0.14$           & $0.07$           & $0.22$          \\
    \bottomrule
  \end{tabular}
\end{table}


% =====================================================================
\section{Summary of findings}
\label{sec:results-summary}
% =====================================================================

This chapter quantified the spatial structure of GBIF sampling bias in
Norway and tested whether that structure departs from a random composition of
taxonomic groups. The main findings come down to five points.

The bias is strongly geographic. For all three datasets, the modelled bias is
concentrated in southern and accessible coastal regions and thins towards the
northern and interior regions (Section~\ref{sec:results-pattern}), so the
dominant axis of variation is location, not taxon. The baseline variance does
differ by taxon: birds show the lowest total variance ($0.2405$), while fungi
($0.4653$) and vascular plants ($0.4807$) are roughly twice as variable,
which fits with birds being recorded more extensively and evenly across the
country (Section~\ref{sec:results-baseline}). But that observed variance turns
out to be indistinguishable from chance. In every dataset the baseline total
variance falls almost exactly at the centre of its permutation null
distribution, with empirical $p$-values of $0.477$ (birds), $0.478$ (fungi),
and $0.479$ (vascular plants), and no test gives evidence that group
composition structures regional bias beyond what random resampling produces
(Section~\ref{sec:results-permutation}).

The result is consistent across taxa. The close agreement of the three
$p$-values, across datasets that differ in size, composition, and recording
community, says this null outcome is general rather than dataset-specific
(Section~\ref{sec:results-consistency}). And no single region controls the
pattern. The block sampling test confirms and localises this: exchanging
individual regions between groups changes the regional structure of bias only
slightly and roughly symmetrically about zero, with the great majority of
swaps having negligible effect. Influence is concentrated in a few
peripheral, sparsely recorded regions, the far north for birds and the
southern coast and interior for fungi and vascular plants, while the densely
sampled regions, Oslo above all, are nearly interchangeable between groups.
Which localities matter most is taxon-specific, but none exerts a controlling
effect (Section~\ref{sec:results-randomization}).

Taken together, these results indicate that sampling bias in Norwegian GBIF
data is governed by a shared geographic gradient of recording effort that is
common to all taxonomic groups, and is only weakly taxon-specific. The
regional pattern of bias is an emergent property of where recording happens
rather than the artefact of any one locality, even though which localities
contribute most depends on the taxon. The ecological and methodological
implications of this pattern, including its consequences for bias correction
and for the design of future recording effort, are considered in
Chapter~\ref{ch:discussion}.


% =====================================================================
\section{Outstanding analysis}
\label{sec:results-future}
% =====================================================================

One component of the planned analysis is not yet reported here: the
independent validation of the bias-corrected vascular-plant predictions
against the structured ANO survey, set out in Section~\ref{sec:ano}. That
comparison confronts the corrected predictions with field data the model
never saw, and so tests whether the shared-bias correction actually pays off
against ground truth, and whether it does so evenly across the south--north
gradient rather than only where records were already abundant. The data
preparation is in place; the validation results will be added once the
hold-out scoring is complete, and their implications taken up in
Chapter~\ref{ch:discussion}.
