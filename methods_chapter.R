% =====================================================================
%  Methods chapter
%  Sampling bias in Norwegian biodiversity occurrence data
%
%  Self-contained \chapter to be \input{} into the main thesis.
%  Assumes the thesis preamble already loads, at minimum:
%     \usepackage{booktabs}   % nice tables
%     \usepackage{amsmath}    % math environments
%     \usepackage{amssymb}    % \checkmark
%     \usepackage{graphicx}   % figures
%     \usepackage{hyperref}   % optional
%
%  Code is not reproduced here. Each place that refers to a specific
%  script names it inline as "github code <filename>"; those scripts
%  are published in the accompanying repository (tagged release /
%  commit recorded in the repository README).
% =====================================================================

\chapter{Methods}
\label{ch:methods}

This chapter has two parts. The first describes the upstream
\emph{hotspot integration model} that this thesis takes as given: how the
occurrence data were assembled, modelled, and corrected for sampling
bias (Section~\ref{sec:hotspot}). The second describes the contribution
of the thesis itself --- a set of diagnostics that interrogate whether
the shared sampling-bias assumption underlying that correction actually
holds, and an independent validation of the bias-corrected predictions
for vascular plants (Sections~\ref{sec:overview}--\ref{sec:software}).
The thesis does not refit the occurrence model; it works downstream of
it, on the posterior surfaces the model produces.


% =====================================================================
\section{The hotspot integration model}
\label{sec:hotspot}
% =====================================================================

\subsection{Data and processing}
\label{sec:hotspot-data}

The hotspot project \citep{perrin2026addressing, herfindal2025modellering}
brings together two kinds of species data, and bringing them together is
the whole point. One kind is occurrence-only data: opportunistic
sightings, mostly pulled from GBIF. These give huge coverage across taxa
and across the country, but say nothing about how hard anyone looked for
the species. The other kind is presence--absence data from structured
monitoring schemes, which is far more useful for bias correction because
it records where people looked and found \emph{nothing}, not only where
someone happened to spot something.

The problem is that structured data barely exists in open form for most
species groups. To get around this, \citet{perrin2026addressing} relied
on three national datasets: the Norwegian Breeding Bird Monitoring Scheme
for birds, the ANO program (run by the Norwegian Environment Agency) for
plants, and the National Insect Monitoring program for arthropods. For
fungi and lichens, absences had to be inferred from field-note datasets,
which only worked after consulting the people who originally collected
them. In the end the analysis rests on about 35~million occurrence
records from 352 datasets, covering roughly 8455 species: vascular
plants, vertebrates, lichens, fungi and terrestrial arthropods. The set
of environmental covariates is kept deliberately small and open-source
(climate, land cover, terrain).

All of this is fed into integrated species distribution models (iSDMs):
hierarchical state-space models in which one latent species distribution
sits underneath a separate observation sub-model for each dataset. That
setup lets the models share information across datasets while still
handling the quirks of each one --- and the quirks matter, because GBIF
data clusters around roads, cities and anywhere people can easily walk
to. Records are filtered first: coordinate uncertainty over 100~m is
dropped, anything not identified to species is removed, and species with
fewer than 50 records are excluded. The remaining data is reprojected to
a $500 \times 500$~m grid in UTM zone~33N, and the models are run in R
with PointedSDMs \citep{mostert2023pointedsdms} and intSDM
\citep{mostert2025intsdm}, using Bayesian methods on the
high-performance computing facilities provided by Sigma2, Norway's
national system for advanced computing and data storage. For each
segment, 20 CPUs and 178~GB of memory were allocated to fit the model or
to produce estimates of species intensity and spatial sampling bias. On
average a single vascular-plant segment required around 190 CPU hours, a
reasonable cost given the model's complexity and the number of species
analysed within each segment.

For every species the model produces an intensity map, an uncertainty
layer and a group-level sampling-bias map. These are summed later on to
build the hotspot maps and the other derived products.

\subsection{Covariate selection}
\label{sec:hotspot-cov}

Covariates were picked in two rounds. \citet{perrin2026addressing}
started with a small initial set meant to capture the broad drivers of
species distributions across all groups, and kept the number low on
purpose, because fewer covariates make the groups easier to compare and
cut the compute, which matters once models are fitted for thousands of
species on shared HPC time. That starting set was then refined group by
group in consultation with domain experts, who said which variables
really mattered for their taxa. Those expert recommendations decided the
final list for each group, so the covariate list is not identical across
taxa; limestone content, for instance, was only brought in where it made
ecological sense.

Before any modelling, all covariates were put on the same footing. They
were projected onto UTM zone~33N at $500 \times 500$~m resolution to line
up with the national SSB grid. Continuous variables were interpolated
bilinearly and then mean-centred and scaled; categorical variables took
the modal value within each grid cell. The land-cover variable was the
worst offender, so it was collapsed from 45 CORINE categories down to 12
representative classes, mostly to keep the parameter count from blowing
up.

\begin{table}[ht]
\centering
\caption{Covariates used per species group, as shown in Figures 3--5 of
the report. A check mark indicates the covariate appears for that group
in the figures; a dash indicates it does not. Full group-by-covariate
detail is given in the report's supplementary tables (S1a--S1c), which
were not available here.}
\label{tab:covariates}
\begin{tabular}{l c c c}
\toprule
Covariate & Vascular plants & Fungi & Birds \\
\midrule
Summer temperature              & \checkmark & \checkmark & \checkmark \\
Summer temperature (squared)    & \checkmark & \checkmark & \checkmark \\
Summer precipitation            & \checkmark & \checkmark & \checkmark \\
Summer precipitation (squared)  & \checkmark & \checkmark & \checkmark \\
Net primary productivity        & \checkmark & \checkmark & \checkmark \\
Human density                   & \checkmark & \checkmark & \checkmark \\
Habitat heterogeneity           & \checkmark & \checkmark & \checkmark \\
Aspect                          & \checkmark & --         & \checkmark \\
Slope                           & \checkmark & --         & -- \\
Land cover (12 CORINE classes)  & \checkmark & \checkmark & \checkmark \\
Limestone content               & \checkmark & \checkmark & -- \\
\bottomrule
\end{tabular}
\end{table}

\subsection{Accounting for bias in the iSDM}
\label{sec:hotspot-bias}

\subsubsection{Taxonomic and within-group structure}

Species were sorted into taxonomic groups using the same scheme the
Norwegian Biodiversity Information Centre uses for its red list
(Artsdatabanken 2021). That grouping does a lot of work in the project:
it sets how the end products are presented, how covariates were chosen,
and how the GBIF download was split up. From this base
\citet{perrin2026addressing} adjusted some groups after consulting domain
experts, and the adjustments came out of ecology, life history and
sampling method, not taxonomy on its own.

Of the three groups considered in this thesis, birds are the only one
where the report describes an explicit grouping decision: ground-nesting
birds, wading birds and woodpeckers were pulled out from the rest of the
birds, on grounds of cultural significance in the region rather than
anything statistical. For the main text those bird subgroups are merged
back together, so the bird results shown are for birds as a whole.
Vascular plants and fungi were left more or less as the red-list scheme
defined them; the report describes no special splitting or merging for
either, unlike the deliberate restructuring done for insects, mammals or
lichens. What the report does say, for every group, is that hotspots are
never pooled across very different taxa: the hotspot definition is
threshold-based, so combining a species-rich group with a species-poor
one would dilute the species-poor group's own concentrations wherever
the habitat needs do not line up. Defining hotspots separately per group
avoids that.

Operationally, this taxonomic scheme is what defines the model
\emph{groups} (also called segments) that the rest of this thesis works
with. Within each broad taxon the species are partitioned into these
sub-models, and it is at the group level --- not the individual-species
level --- that the sampling-bias field and the covariate effects are
estimated and shared (Section~\ref{sec:hotspot-sampling}). In the runs
analysed here this gives on the order of twenty groups per dataset, a
number detected directly from the model output on disk rather than fixed
in advance (Section~\ref{sec:overview}). Each species therefore enters
the downstream diagnostics through exactly one group, and every cell of
that group's bias surface is one observation in the analyses that follow.

For every group the same three levels of management concern were then
applied: (a) all species, (b) threatened species (categories CR, EN and
VU on the Norwegian Red List), and (c) species of national
responsibility. Conservation status below the species level was not used,
since subspecies distinctions caused problems for the richness metrics,
and species on the Alien Species List were dropped from the analysis
altogether. The output is one hotspot map per group per level of concern,
so for these three taxa one obtains separate outputs for all species,
threatened species and national-responsibility species of vascular
plants, fungi and birds.

One caveat is about data availability rather than grouping. Vascular
plants and birds are both well covered, with opportunistic occurrence
data and structured presence--absence data that lets sampling effort
actually be teased apart. Fungi are in a weaker position: their
presence--absence information had to be inferred from field-note datasets
after consulting the original authors, so the bias correction for fungi
rests on a shakier footing than it does for the other two.

\subsubsection{Sampling bias}
\label{sec:hotspot-sampling}

Sampling bias is the thing the whole workflow exists to deal with. GBIF
occurrence data does not really show where the species are; it shows
where people happened to be looking. Records pile up around cities, along
roads and near anywhere with parking, and they also bunch along
administrative borders where different countries or counties share (or
do not share) their data in different ways. So before anything sensible
can be said about real biodiversity, two very different things have to be
told apart: a species not being there, and nobody bothering to check.
That is what the bias correction is meant to do.

The correction works by pulling the two data types into the same model.
Occurrence-only data has reach but no information about effort.
Structured presence--absence data does carry effort information, because
a recorded absence means somebody was there, looked, and saw nothing.
Combining them lets the structured data inform an estimate of how
sampling effort is spread across space, and that estimate is then used to
take the bias out of the occurrence-only signal. Where no
presence--absence data was available at all (bats, the other mammals,
amphibians, reptiles) the correction could not be done, and the report
withholds those hotspot products and warns users to be very careful with
what remains.

The important structural choice is that the sampling bias is estimated
\emph{per group, not per species}. Inside a group, the bias field and the
covariate effects are shared. Every species in the group sits on top of
that shared layer as its own realisation of the latent distribution
process, but the effort surface and the environmental relationships
underneath are estimated once, for the whole group. That is what makes
the whole thing run: fitting an independent bias model for every one of
thousands of species would not be feasible. Pooling the information means
one shared bias field and one shared set of covariate effects do the work
for everyone in the group at once, and it lets a data-poor species borrow
strength from its better-sampled neighbours --- the only reason it can be
included at all. This pooling falls directly out of the integrated,
hierarchical state-space setup: shared latent parameters across the
datasets in a group, plus dataset-specific parameters layered on top to
soak up the quirks and biases of each particular dataset. Estimation is
Bayesian, done with PointedSDMs (which wraps R-INLA and inlabru) and
orchestrated through intSDM.

The bias is not thrown away once the model is fitted; it is carried
forward. For every group the workflow outputs a sampling-bias map
alongside the intensity and uncertainty layers, and the sampling-effort
field feeds straight into the uncertainty of the hotspot maps. So a
poorly sampled area shows up as high uncertainty, rather than being
quietly labelled low-biodiversity --- which would be the dangerous
failure mode. The report uses this deliberately: it found a clear
geographic pattern in sampling intensity itself, much heavier in the
populous south-east and central regions and much thinner in northern
Norway and at altitude, and the uncertainty maps make those data gaps
visible rather than hiding them.


% =====================================================================
\section{Overview and analytical strategy}
\label{sec:overview}
% =====================================================================

The whole bias correction rests on one assumption, worth stating plainly
because everything downstream depends on it. The model treats sampling
effort as a single surface shared across every species in a group,
estimated once from the structured data and then reused to debias the
occurrence-only records. That only works if the structured data and the
opportunistic data are biased in the same way, or close enough that one
can stand in for the other. If the people running the structured surveys
went to systematically different places than the casual recorders did,
then the effort surface learned from the structured data is the wrong
surface to subtract, and the correction quietly pushes the estimates in
the wrong direction instead of fixing them. Crucially, a model can fit
well, produce clean intensity maps and sensible uncertainty layers, and
still lean on an assumption that does not hold, because nothing in the
fitted likelihood tells you the shared-bias assumption was reasonable ---
the model was built around it from the start. It therefore has to be
checked from the outside.

This thesis does that checking. It takes as input the posterior
\emph{sampling-intensity} surfaces (the ``bias field'') produced by the
model of Section~\ref{sec:hotspot}, and interrogates them with a sequence
of steps that hand off from one to the next:

\begin{enumerate}
  \item a \textbf{spatial-field diagnostic} that compares the covariate
        effects estimated with and without a spatial field in the bias
        sub-model, group by group (Section~\ref{sec:fielddiag});
  \item a \textbf{stratified block sampling test} that localises which
        region drives the spatial spread of the bias field
        (Section~\ref{sec:block});
  \item a \textbf{permutation test} that asks whether the taxonomic
        groups are spatially exchangeable
        (Section~\ref{sec:permutation});
  \item a \textbf{two-way ANOVA} that decomposes the variance of the bias
        field into region, group and interaction components
        (Section~\ref{sec:anova}); and
  \item a \textbf{structured-survey validation} that checks the
        bias-corrected vascular-plant predictions against independent
        field data from the ANO programme (Section~\ref{sec:ano}).
\end{enumerate}

\noindent
The first four describe the internal structure of the modelled bias and
how far the shared-bias assumption can be trusted for each group; the
fifth asks whether the correction built on that bias is trustworthy
against ground truth the model never saw. All steps are implemented in
\textsf{R} using \textsf{terra} and \textsf{sf} for the geospatial
operations. The mapping, extraction and block-sampling steps are
organised as a small numbered pipeline driven by a single configuration
file and a shared helper file (github code \texttt{Workflow/00\_config.R},
github code \texttt{Workflow/01\_setup.R}), so that switching to a new
dataset requires editing only the configuration; the modules can be run
end-to-end through driver scripts in 6-region and 12-region variants
(github code \texttt{Workflow/run\_all.R},
github code \texttt{Workflow/run\_all\_12.R}).

\paragraph{Datasets and the bias field.}
Throughout, the analysis works with four datasets --- \emph{birds},
\emph{fungi}, \emph{vascular plants}, and a re-run bird dataset
(\emph{new birds}). Each dataset is a collection of model \emph{groups}
(the taxonomic sub-models of Section~\ref{sec:hotspot-bias}), supplied as
one posterior raster stack per group on disk under the convention
\path{<root>/<subfolder>/<prefix><N>/Bias/Bias.rds}. The number of groups
is detected from disk rather than hard-coded (github code
\texttt{detect\_groups()} in \texttt{two\_way\_anova\_all\_datasets.R} /
\texttt{permutation\_all\_datasets.R}), giving on the order of twenty
groups per dataset in the runs reported here. Each stack is read,
unpacked from its packed \textsf{terra} form, reduced to its
posterior-\emph{mean} layer (the ``bias mean''), and cropped and masked
to the Norwegian mainland so that only on-land cells contribute (github
code \texttt{make\_bias\_country()} in \texttt{Workflow/01\_setup.R}). The
national outline used for cropping is taken from \textsf{Natural Earth} at
the large (1:10\,m) scale via \textsf{rnaturalearth} /
\textsf{rnaturalearthhires} (github code \texttt{load\_country\_outline()}
in \texttt{Workflow/01\_setup.R}). The bias mean is interpreted as a
relative sampling-intensity surface: higher values mark areas the
upstream model infers to be more intensively surveyed.

\paragraph{Coordinate reference and resolution.}
All modelled rasters carry the projection EPSG:25833 (ETRS89 / UTM
zone~33N), but one technical property of the saved surfaces matters for
every spatial operation below and is therefore stated explicitly: their
coordinates are stored in \emph{kilometres} rather than metres (extent
$\approx[-90,\,1124]\times[6443,\,7944]$\,km), the embedded CRS label is
``unknown'', and their effective resolution is $\approx 1$\,km --- not the
finer grid on which the underlying model was fitted. Consequently the
regional analyses operate at the $1$\,km saved-prediction resolution:
region squares are defined in this kilometre space, and the point data
introduced for the validation (Section~\ref{sec:ano}) are first
reprojected to EPSG:25833 in metres and then divided by $1000$ before
extraction, so that points and rasters share one coordinate space.


% =====================================================================
\section{Spatial-field diagnostic of the shared-bias assumption}
\label{sec:fielddiag}
% =====================================================================

The first diagnostic asks, group by group, how much the bias estimate
leans on the shared-bias assumption. A deviation from that assumption does
not announce itself in a summary table; it shows up as spatial structure
left over in the wrong place. The test exposes it by refitting the bias
sub-model with and without a spatial field and watching how far the
covariate effects move. If the assumption is clean, adding a spatial
field to the bias model should mostly soak up residual noise and leave the
covariate effects roughly where they were; if effort and environment are
confounded, the covariates aligned with the same spatial gradient as the
sampling effort will shift sharply once the field is in, because without
the field the model hands that spatial structure to the covariates and
reads it as ecology. The size of the shift is therefore a direct measure
of how much the group's bias estimate was relying on the assumption that
the structured and opportunistic data sample the same space.

\begin{figure}[htbp]
\centering
\includegraphics[width=\textwidth]{fungi_bias_field_effects.png}
\caption{Covariate effects on fungi richness with (blue) and without
(red) a spatial field in the bias estimation model. Bars show the
estimated effect of each covariate and whiskers the associated
uncertainty. Source: hotspot project.}
\label{fig:bias-field-fungi}
\end{figure}

For fungi (Figure~\ref{fig:bias-field-fungi}) the effects do not stay
put. Several shift sharply once the field is in: summer precipitation
collapses from a large positive effect to essentially nothing, and both
squared terms (summer precipitation squared and summer temperature
squared) pull noticeably toward zero. Effects tied to genuine habitat
rather than to where people record --- habitat heterogeneity and human
density --- barely move. The covariates that move are exactly those
aligned with the same broad south-to-north climate gradient as the
sampling effort, so for fungi, whose absences are inferred rather than
designed, this is the warning the diagnostic was built to surface.

\begin{figure}[htbp]
\centering
\includegraphics[width=\textwidth]{plants_bias_field_effects.png}
\caption{Covariate effects on plant richness with (blue) and without
(red) a spatial field in the bias estimation model. Bars show the
estimated effect of each covariate and whiskers the associated
uncertainty. Source: hotspot project.}
\label{fig:bias-field-plants}
\end{figure}

Vascular plants make the useful contrast
(Figure~\ref{fig:bias-field-plants}). Most effects --- aspect, distance to
water, habitat heterogeneity, net primary productivity, road environment
and slope --- sit in roughly the same place with and without the field,
which is what one hopes to see if the covariates pick up ecology rather
than standing in for where people happened to record. The one place the
plant fit behaves like the fungi fit is the climate terms: summer
precipitation again collapses to essentially zero once the field is in,
and the two squared terms pull toward zero in the same way. So the same
confounding between effort and the climate gradient is present, but for
plants it is confined to a few covariates instead of running through most
of them --- the expected result, given that plants have genuine
structured presence--absence data behind them.

Taken together, the two figures give the diagnosis this section was after.
The shared-bias assumption is not something that simply holds or fails; it
holds to a degree that tracks how good the structured data behind each
group is. For vascular plants only the climate terms react to the field
and the rest of the picture is stable, so the assumption can be trusted
for everything except the parts of the climate signal that run along the
recording-effort gradient. For fungi the reaction is far broader and the
climate effects are almost entirely rewritten, which says the bias
estimate for that group was doing work the structured data could not
support. Two practical readings follow. First, the spatial field in the
bias model is not optional housekeeping: it is what absorbs the
effort-driven spatial structure the covariates would otherwise claim, and
the gap between the red and blue bars measures how much it was needed.
Second, the size of that gap is itself the per-group health check on the
assumption, to be read generously for fungi and with more confidence for
plants when the corrected maps are interpreted in later chapters.


% =====================================================================
\section{The bias field as a spatial object}
\label{sec:fullmaps}
% =====================================================================

The remaining diagnostics treat the bias field directly as a spatial
object, so the next task is simply to see it. For each dataset, every
group's bias-mean surface is plotted as a full-country raster over the
Norwegian outline (github code \texttt{Workflow/02\_full\_maps.R}). The
key design choice is that \emph{all} groups within a dataset are drawn on
a single shared colour scale: a common \texttt{zlim} and a common set of
class breaks are computed across every group first, then reused for each
map (github code \texttt{Workflow/01\_setup.R}). Without this, each map
would auto-scale to its own range and the maps would not be comparable;
with it, a given colour means the same sampling intensity in every panel,
so differences between groups and between parts of the country can be read
directly off the colour. The full maps are written as a single multi-page
PDF (one page per group), with one-PNG-per-group versions for dropping
individual maps into figures and slides (github code
\texttt{Workflow/06\_png\_maps.R}; an auto-discovering variant is github
code \texttt{Workflow/06\_png\_maps\_multi.R}). A companion layout draws,
for each group, the full map beside a grid of per-region zoom panels on
the same shared scale (github code \texttt{Workflow/03\_region\_maps.R}).

As context for what this modelled intensity is correcting, raw
georeferenced occurrence records for four exemplar species spanning the
groups --- \emph{Fomitopsis pinicola} (fungi), \emph{Lysimachia europaea}
(vascular plant), \emph{Turdus pilaris} and \emph{Falco peregrinus}
(birds) --- are mapped straight from a citable GBIF download. The records
are retrieved through a formal \textsf{rgbif::occ\_download()} call (which
mints a DOI), with names resolved against the GBIF backbone so synonyms
(e.g.\ \emph{Trientalis europaea} $\rightarrow$ \emph{Lysimachia
europaea}) are captured, restricted to mainland Norway and to
georeferenced records without geospatial issues (github code
\texttt{gbif\_norway\_maps.R}). These show the uneven field effort that
motivates the bias modelling in the first place.

The purpose of this step is diagnostic and motivating rather than
inferential. The maps make the central pattern visible --- a strong
south--north gradient in inferred sampling intensity, dense in the
well-surveyed south-east and sparse in the far north --- and that visible
pattern is exactly what the remaining sections make quantitative. A map
cannot by itself say whether that gradient is statistically real, whether
it is shared across groups, or which areas drive it; for that, the country
must be partitioned into comparable spatial units.

\subsection{Reconstruction of the spatial mesh}
\label{sec:mesh}

The upstream model places its spatial random field on a constrained
Delaunay triangulation (an \textsf{INLA} / \textsf{fmesher} 2-D mesh) over
mainland Norway, and estimates the field at the mesh \emph{nodes}. To
document the spatial discretisation actually used, the mesh is rebuilt with
the original parameters from the region geometry
(\texttt{regionGeometry.RDS}) using \textsf{fmesher} (github code
\texttt{buildMesh()} in \texttt{meshNodes.R}). The mesh parameters (in
metres, as the region geometry is EPSG:25833 in metres) are: a
\textbf{cutoff} of $3$\,km (minimum edge length; closer nodes are merged);
\textbf{max.edge} of $(50,\,300)$\,km (maximum triangle edge inside the
study region and in the outer buffer); and \textbf{offset} of
$(20,\,100)$\,km (the reach of the inner and outer extension hulls). Two
extension hulls are built so the field is not distorted at the coastline,
and nodes are classified as inside the study region or in the extension
buffer by intersection with the region geometry (github code
\texttt{meshNodes.R}).

Because the same mesh underlies every group, a separate check verifies how
it relates to the small study regions defined below
(Section~\ref{sec:regions}): for each $10$\,km region square the number of
mesh nodes inside the square and the distance to the nearest node are
tabulated, and a zoom panel is drawn per region showing the local
triangulation, the square and the enclosed nodes (github code
\texttt{meshRegionPanels.R}). This makes explicit that regional values are
read off a field whose nodes are sparse at the $10$\,km scale --- relevant
context for how much weight to place on any single region.


% =====================================================================
\section{Study regions}
\label{sec:regions}
% =====================================================================

To compare the bias field across space, Norway is summarised over a set of
fixed $10\times10$\,km square blocks. Each region is defined by a centre
coordinate in the rasters' UTM-33 kilometre space and a side length of
$10$\,km (half-side $5$\,km); square polygons are constructed directly from
those centres in the raster CRS (github code
\texttt{build\_region\_polygons()} in \texttt{Workflow/01\_setup.R}). Using
fixed-size squares rather than administrative units keeps the spatial
``sample size'' (the block of cells) comparable from region to region,
which the later variance comparisons require.

Two nested region sets are used:

\begin{itemize}
  \item a \textbf{6-region} set --- Setesdal, Oslo, Valdres, Trondheim,
        Troms\o{} and Lakselv (github code \texttt{Workflow/00\_config.R});
        and
  \item a \textbf{12-region} set --- the original six plus Bergen,
        Kristiansand, Skorovatn, Bod\o{}, Svolv\ae r and Kirkenes (github
        code \texttt{00\_config\_12\_updated.R}; the unadjusted variant is
        github code \texttt{Workflow/00\_config\_12.R}).
\end{itemize}

\noindent
The two sets are intentionally nested: the six regions are exactly the
first six of the twelve, so a single extraction serves both and any result
on six regions can be compared against the same result on twelve without
re-reading the rasters (used directly in Section~\ref{sec:anova}). The
6-region set is the original coarse coverage; the 12-region set roughly
doubles spatial coverage and resolution.

\paragraph{Distribution across Norway.}
The centres are chosen to span the country's full survey-effort gradient
rather than to tile it uniformly. They run from the data-rich south-east
(Oslo, Kristiansand) and south (Setesdal, Valdres, Bergen) through the
central transition (Trondheim, Skorovatn), up the northern coast (Bod\o{},
Svolv\ae r, Troms\o{}) to the data-sparse far north and Finnmark (Lakselv,
Kirkenes). Spreading the regions along this south--north axis is what lets
the later tests probe whether the bias field's structure tracks the
gradient seen in the maps.

\paragraph{Tuning the northern squares.}
Two of the northernmost squares originally straddled the coastline, so part
of each fell on ocean cells with no bias value, leaving those regions with
fewer usable cells than the others and unbalancing the design. The centres
of Svolv\ae r and Kirkenes were therefore nudged by a few kilometres
(Svolv\ae r $3$\,km west, Kirkenes $1$\,km south) until each square
overlapped a full, dense block of $121$ non-missing bias cells ($11\times
11$ at $\approx 1$\,km resolution) for every group. The replacement
centres were found by a small search over candidate centres on the raster
grid and verified to give $121$ valid cells for all groups (github code
\texttt{fix\_region\_centers.R}, github code \texttt{verify\_centers.R};
the adopted values are recorded in github code
\texttt{00\_config\_12\_updated.R}). This balancing is what makes the
variance and ANOVA comparisons fair across regions.

The regions define \emph{where} the field is measured; the next step turns
those polygons into numbers.


% =====================================================================
\section{Extracting the values}
\label{sec:extract}
% =====================================================================

All the regional tests share one data layout: \emph{one observation per
raster cell, per group, within a region}. For each group, the bias-mean
surface (already cropped and masked to Norway) is intersected with the
region polygons, and every raster cell that \emph{touches} a region square
is extracted together with its cell index, coordinates and bias value
(github code \texttt{extract\_bias\_cells\_touching()} in
\texttt{Workflow/04\_extract\_values.R}). ``Touching'' cells are used
rather than only cells whose centroid falls inside, so that a square of
fixed geographic size yields a consistent block of cells regardless of how
it aligns with the grid.

A subtlety matters for the comparisons that follow: every group must be
read on \emph{exactly the same} cells, or apparent differences between
groups could be artefacts of slightly different cell sets. The test scripts
therefore first derive a set of \emph{canonical} cell indices per region
from the reference (Norway-masked) grid, then align each group's values to
those indices, dropping any cell with a missing value (this canonical-cell
construction lives inside github code \texttt{permutation\_all\_datasets.R}
and github code \texttt{two\_way\_anova\_all\_datasets.R}). The result is a
balanced long-format table (group $\times$ region $\times$ cell
$\rightarrow$ bias mean), written to a multi-sheet Excel workbook for
re-use and cell-count checking (github code
\texttt{Workflow/04\_extract\_values.R}). With the balanced $121$-cell
blocks and roughly twenty groups across twelve regions, each dataset
contributes on the order of $25\,000$--$30\,000$ cell observations.

A single scalar summary of this table --- the \emph{total variance} of all
non-missing bias values pooled across every region and group --- is also
computed, and recomputed after the northern centres were re-tuned (github
code \texttt{total\_variance.R}, github code
\texttt{new\_total\_variance.R}). Letting $x_1,\dots,x_n$ denote those
pooled values, the (sample) total variance is

\begin{equation}
  s^2 \;=\; \frac{1}{n-1}\sum_{i=1}^{n}\bigl(x_i-\bar{x}\bigr)^2 ,
  \label{eq:total-var}
\end{equation}

\noindent
reported alongside the population version $s^2(n-1)/n$, the mean and the
standard deviation. This pooled total variance is the observed statistic
the permutation test (Section~\ref{sec:permutation}) reproduces under its
null. With the extracted table in hand, the tests can now interrogate it
from different angles.


% =====================================================================
\section{Stratified block sampling test}
\label{sec:block}
% =====================================================================

The first regional test asks a localisation question: \emph{which region
carries the most leverage over the spatial spread of the bias field?} The
statistic of interest is the \emph{variance among regional variances}. For
a given group, the bias variance is computed separately within each region,
and the variance of those per-region variances measures how unevenly bias
is structured across space --- a large value means some regions are far
more internally variable than others (github code
\texttt{Workflow/05\_randomization.R}; the script names this a
``randomization'' test, but it is a stratified block sampling test, and is
referred to as such here).

The test proceeds, for each \emph{target} group in turn, as a series of
single-region block swaps:

\begin{enumerate}
  \item \textbf{Original.} Using only the target group's own cells, compute
        the per-region variances and record the variance among them.
  \item \textbf{Single-region swaps.} For each region $r$ and each other
        (\emph{donor}) group $d$, replace region $r$'s block of cells with
        the same region's block taken from donor $d$, while keeping the
        other eleven regions from the target group, and recompute the
        variance among regional variances for this ``mixed'' configuration.
  \item \textbf{Change scores.} For every swap, record the signed and
        absolute change in the statistic relative to the target group's
        original value.
\end{enumerate}

\noindent
Because each swap replaces an entire spatial block (a whole region's cells)
rather than individual cells, the procedure is stratified by region and
operates on coherent blocks --- hence stratified block sampling.
Aggregating the absolute changes \emph{by swapped region} (mean, median,
standard deviation and maximum across all target/donor combinations) gives
a \emph{region-sensitivity} ranking: regions whose replacement typically
moves the statistic the most are the most influential. The outputs are a
per-target summary table, the full table of regional variances, the ten
largest changes per target group, and the region-sensitivity ranking, with
diagnostic plots (a boxplot of absolute change per region, a histogram of
signed changes centred on zero, and a dot chart of mean / median / maximum
change per region). The expectation is that sparsely sampled northern
regions carry the most leverage, since their bias values are the least
constrained.

This test pinpoints \emph{where} structure lives, but it treats one region
at a time and says nothing about whether the taxonomic groups as a whole
are interchangeable. That global question is the permutation test's job.


% =====================================================================
\section{Permutation test}
\label{sec:permutation}
% =====================================================================

The permutation test asks whether the taxonomic groups within a dataset are
spatially \emph{exchangeable}: would the pooled bias field look the same if,
within each region, the contributing groups were resampled? If groups carry
idiosyncratic spatial signal, reshuffling which groups contribute should
change the pooled variance; if they do not, the observed total variance
should sit in the middle of the reshuffled distribution. The procedure is
run identically across datasets (github code
\texttt{permutation\_all\_datasets.R}; a single-dataset variant is github
code \texttt{permutation\_histogram.R}):

\begin{enumerate}
  \item For each of the $12$ regions, assemble a cells~$\times$~groups
        matrix ($121$ cells $\times$ the detected number of groups $G$) of
        bias-mean values.
  \item \textbf{Observed statistic.} Use each group exactly once, pool all
        regions, and compute the total variance (Eq.~\ref{eq:total-var}).
        This is the \emph{baseline} --- the same quantity computed in
        Section~\ref{sec:extract}.
  \item \textbf{Null distribution.} Repeat $B=1000$ times: within each
        region independently, draw $G$ groups \emph{with replacement}, take
        that region's $121$ cell values from each drawn group, pool all
        regions, and compute the total variance.
  \item \textbf{Position of the observed value.} Summarise where the
        baseline falls among the $1000$ permuted variances by the proportion
        at least as large,
        $p_{\ge}=\tfrac{1}{B}\sum_b \mathbf{1}\{v_b \ge v_{\mathrm{obs}}\}$
        (and the complementary $p_{\le}$), and plot the null distribution
        with the baseline marked.
\end{enumerate}

\noindent
Resampling \emph{with replacement within region} is the crucial design
choice: it preserves each region's spatial footprint and sample size while
breaking the identity of which group supplied each cell, so the null
isolates group exchangeability from regional structure. The random-number
generator is seeded (\texttt{set.seed(1234)}) so the permutation
distribution is exactly reproducible. A baseline sitting near the centre of
the null ($p_{\ge}\approx 0.5$) is read as evidence that groups are
approximately exchangeable, i.e.\ that the regional structure of the bias
field is largely \emph{shared} across taxonomic groups rather than
group-specific.

Where the block sampling test localises leverage to a region, the
permutation test makes a global statement about groups; together they
separate ``which region matters'' from ``do groups matter at all''.
Neither, however, quantifies \emph{how much} of the field's variation is
attributable to region versus group. That apportionment is what the ANOVA
provides.


% =====================================================================
\section{Two-way ANOVA variance decomposition}
\label{sec:anova}
% =====================================================================

The two-way ANOVA decomposes the bias field into its two design factors.
Per dataset, the bias mean of each cell is the response, with crossed fixed
factors

\begin{equation}
  y_{ijk} \;=\; \mu \;+\; \alpha_i \;+\; \beta_j \;+\;
  (\alpha\beta)_{ij} \;+\; \varepsilon_{ijk},
  \label{eq:anova}
\end{equation}

\noindent
where $\alpha_i$ is the effect of taxonomic \emph{group}
($i=1,\dots,G$), $\beta_j$ the effect of \emph{region}
($j=1,\dots,12$), $(\alpha\beta)_{ij}$ their interaction, and
$\varepsilon_{ijk}$ the cell-level residual (github code
\texttt{two\_way\_anova\_all\_datasets.R}; a fungi-only version is github
code \texttt{two\_way\_anova\_fungi.R}). Each raster cell within a region,
for a given group, is one observation --- the same long-format layout used
by the other tests (Section~\ref{sec:extract}).

Because the canonical-cell construction makes the design balanced (an equal
number of cells per group$\times$region), the sequential (Type~I) sums of
squares equal the Type~II/III sums of squares and term order is immaterial;
a Type~III check using sum-to-zero contrasts is nonetheless reported where
the \textsf{car} package is available.

\paragraph{Effect sizes, not $p$-values.}
With tens of thousands of cells every term is overwhelmingly
``significant'', so the conclusion is based on \emph{effect size}. For each
term the proportion of variance explained is reported as both $\eta^2$ and
partial $\eta^2$,

\begin{equation}
  \eta^2_{\text{term}} \;=\;
  \frac{\mathrm{SS}_{\text{term}}}{\mathrm{SS}_{\text{total}}},
  \qquad
  \eta^2_{p,\text{term}} \;=\;
  \frac{\mathrm{SS}_{\text{term}}}
       {\mathrm{SS}_{\text{term}}+\mathrm{SS}_{\text{residual}}},
  \label{eq:eta2}
\end{equation}

\noindent
and the dominant systematic source --- region, group or interaction --- is
the term with the largest $\eta^2$. Model fit is checked with the standard
residual diagnostics and a group$\times$region interaction plot of cell
means. The response is modelled on its natural scale; because the intensity
surface is right-skewed, the code also allows the ANOVA to be re-run on
$\log(\text{bias})$ via a switch (\texttt{LOG\_RESPONSE} in
\texttt{two\_way\_anova\_all\_datasets.R}), and the $\eta^2$ ranking is
robust to that choice. The per-dataset decompositions are collated into a
stacked bar chart --- region / group / interaction / residual share, one
bar per dataset --- so the governing factor is visible at a glance (github
code \texttt{anova\_effectsize\_barchart.R}).

\paragraph{Robustness to the number of regions.}
To confirm the decomposition does not depend on how finely Norway is
partitioned, the same two-way ANOVA is refitted on both the 6-region and
the 12-region set for each dataset. Because the six regions are nested in
the twelve, each raster is extracted once and both fits come from the same
cell table; the two decompositions are compared in a grouped bar chart so
any shift in the region / group / interaction / residual split is apparent
(github code \texttt{two\_way\_anova\_region\_comparison.R}).

The permutation test, block sampling test and ANOVA together describe the
\emph{internal} structure of the modelled bias --- how it is distributed
across regions and groups, and which regions move it. None of them,
however, can show that the bias-\emph{corrected} predictions built on this
field are actually right. That requires confronting the predictions with
data the model never saw.


% =====================================================================
\section{Independent validation against the ANO survey (vascular plants)}
\label{sec:ano}
% =====================================================================

The final component validates the bias-corrected vascular-plant predictions
against an independent, structured survey: the Norwegian nature-monitoring
programme ANO (\emph{Arealrepresentativ naturoverv\aa king}). The
validation is restricted to vascular plants for a substantive reason, not a
temporal one: ANO records every vascular plant rooted in each
$1\,\text{m}^2$ plot, so a modelled species \emph{not} listed for a plot is
a \emph{true} absence. Birds (mobile, imperfectly detected, coordinates
generalised off GBIF) and fungi (no exhaustive Norwegian structured survey,
hence no real absences) lack this complete-list property and cannot serve
the same role; these exclusions are themselves evidence of the data gaps
the thesis documents (github code \texttt{ano\_validation/00\_config\_ano.R}).

\paragraph{Reference predictions.}
The quantities validated are the model's per-species occupancy predictions,
stored per modelled species as \path{<species>/Richness.rds} (the
posterior-mean layer, an occupancy probability in $[0,1]$), together with
the group-level bias field (\path{Bias/Bias.rds}) used in the diagnostic
below. Model segments are located robustly as the sub-folders that actually
contain a bias field, excluding helper directories (github code
\texttt{find\_segments()} in \texttt{ano\_validation/00\_config\_ano.R}).

\paragraph{Acquiring and preparing the survey.}
ANO vascular-plant records are obtained from GBIF through a reproducible,
citable download (\textsf{rgbif::occ\_download()}, which mints a DOI),
filtered to the ANO dataset, \texttt{country = NO}, the vascular-plant
clade (phylum Tracheophyta, resolved from the GBIF backbone), georeferenced
records without geospatial issues, and coordinate uncertainty $\le 100$\,m
--- mirroring the upstream project's filter (github code
\texttt{ano\_validation/01\_download\_ano.R}). The records are cleaned to
species level, reprojected to EPSG:25833 in metres, and clipped to the
mainland by a northing ceiling (dropping Svalbard / Jan Mayen). The plot
unit is the GBIF \texttt{parentEventID} (year:site:plot), and a
plot~$\times$~species presence/absence matrix is built; because all records
carry \texttt{occurrenceStatus = PRESENT}, absences are inferred under the
complete-list assumption --- valid precisely because ANO plots are
exhaustive for vascular plants (github code
\texttt{ano\_validation/02\_prepare\_ano.R}). To obtain a genuinely
\emph{independent} test set, the most recent ANO season (\textbf{2024}) is
held out; since ANO rotates roughly one fifth of its sites each year, the
held-out plots are at new locations, under the stated assumption that the
2024 season had not yet entered the model's training snapshot (accessed
November~2024).

\paragraph{Scoring: discrimination, regional skill, and a bias diagnostic.}
Each modelled species' prediction raster is read once and extracted at all
hold-out plot coordinates --- after the metres-to-kilometres conversion of
Section~\ref{sec:overview} --- and reused for three summaries (github code
\texttt{ano\_validation/03\_validate\_vascular.R}):

\begin{enumerate}
  \item \textbf{Per-species discrimination.} For each species present in
        both the model and the hold-out, performance is the area under the
        ROC curve (AUC; \textsf{pROC}), a threshold-free measure of how well
        predicted occupancy separates present from absent plots. Species
        with fewer than three presences or three absences are not scored;
        overall performance is summarised by mean and median AUC and the
        fraction of species with $\mathrm{AUC}>0.7$.
  \item \textbf{Regional skill.} Each hold-out plot is assigned to the
        nearest of the twelve region centres (the same regions as the rest
        of the pipeline), and a mean AUC is computed per region (regions
        with fewer than $30$ plots are not reported), to show \emph{where}
        in Norway the corrected predictions discriminate well.
  \item \textbf{Bias diagnostic.} A successful correction should not fail
        systematically where the model itself flags high sampling bias. The
        group-level bias field is averaged across segments and sampled at
        each plot; per-plot predictive error is the mean Brier score across
        species ($\overline{(\hat p - y)^2}$, lower is better); and the
        Spearman rank correlation between per-plot bias magnitude and
        per-plot Brier score is reported. A correlation near zero indicates
        the correction holds across the bias gradient, whereas a strong
        positive correlation would signal residual failure in high-bias
        areas.
\end{enumerate}

\noindent
This closes the loop opened by the maps: the same regional gridding and
bias field that the internal tests dissect are here used to ask whether the
correction actually pays off against independent ground truth, and
specifically whether it pays off \emph{evenly} across the south--north
gradient rather than only where data were already abundant. The per-species
AUCs, per-region AUCs and per-plot bias/error values are written out for the
figures and discussion that follow. Because the saved predictions are at
$\approx 1$\,km resolution, the validation is necessarily at that
resolution; this, the species-coverage limit (only modelled species that
also occur in the ANO hold-out are testable), the low-support regions, and
the 2024-hold-out assumption are the principal caveats carried into the
Results and Discussion.


% =====================================================================
\section{Software, reproducibility and data availability}
\label{sec:software}
% =====================================================================

All analyses were carried out in \textsf{R} \citep{rcore2023}. The
principal packages are \textsf{terra} \citep{hijmans2023} and \textsf{sf}
for raster and vector geospatial operations; \textsf{fmesher} for mesh
reconstruction; \textsf{rnaturalearth} and \textsf{rnaturalearthhires} for
the national outline; \textsf{rgbif} (with \textsf{httr}) for the citable
GBIF downloads; \textsf{dplyr}, \textsf{tidyr}, \textsf{readxl} and
\textsf{writexl} for data handling; \textsf{ggplot2} and \textsf{patchwork}
for figures; and \textsf{pROC} for the validation AUCs (github code:
package lists in \texttt{Workflow/01\_setup.R} and the script headers). A
small \textsf{Python} utility (\textsf{python-pptx}) assembles the result
figures into a slide deck (github code \texttt{build\_deck.py}).

The mapping-and-randomization steps are organised as a modular, numbered
pipeline: a single configuration file holds all settings that change
between datasets (paths, group prefix and indices, regions, plotting and
output filenames), a setup file provides the shared packages and helpers,
and the numbered modules carry out, in order, the full-country maps, the
per-region maps, the within-region extraction and the block sampling test
(github code \texttt{Workflow/00\_config.R},
\texttt{Workflow/01\_setup.R} and modules \texttt{02}--\texttt{06}).
Modules \texttt{02}--\texttt{05} run end-to-end through a driver script in
6-region and 12-region variants (github code \texttt{Workflow/run\_all.R},
\texttt{Workflow/run\_all\_12.R}); switching to a new dataset with the same
on-disk structure requires editing only the configuration. An optional
override mechanism lets the 12-region configuration be layered on top of
the base configuration without duplicating it (github code
\texttt{ALT\_CONFIG} block in \texttt{Workflow/00\_config.R}).

Reproducibility is supported throughout: GBIF data are obtained by formal
downloads that each yield a citable DOI (saved to \texttt{CITATION.txt}
files), credentials are read from the user's \texttt{.Renviron} and never
committed, random seeds are fixed for the permutation tests, and the
analysis is driven from version-controlled, modular scripts. Large inputs
(the GBIF archives and the model raster outputs) and generated outputs are
not stored in the repository; they are regenerated by re-running the
download and analysis scripts. The exact code state used for this thesis is
the tagged release / commit of the repository, to which a permanent DOI can
be minted on release (e.g.\ via Zenodo); see the repository \texttt{README.md}.
