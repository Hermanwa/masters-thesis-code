% =====================================================================
%  Theory chapter
%  Sampling bias in Norwegian biodiversity occurrence data
%
%  Self-contained \chapter to be \input{} into the main thesis.
%  Assumes the thesis preamble already loads, at minimum:
%     \usepackage{amsmath}    % math environments
%     \usepackage{amssymb}    % symbols
%     \usepackage{bm}         % bold math (optional)
%     \usepackage{hyperref}   % optional
%
%  NOTE ON LABELS
%  --------------
%  The methods file (methods_chapter.R) uses \label{ch:methods} for the
%  Methods chapter and \label{sec:overview} for its overview section.
%  To avoid duplicate-label clashes across the document, this chapter
%  uses \label{chap:Theory} and renames its own overview to
%  \label{sec:theory_overview}. The closing cross-reference points at
%  \ref{ch:methods}; change it if you keep a different label there.
%
%  NEW BIBLIOGRAPHY KEYS introduced below (add to your .bib if missing):
%     hodges2010adding      % Hodges & Reich 2010, spatial confounding
%     reich2006effects      % Reich, Hodges & Zadnik 2006
%     fisher1925statistical % Fisher, analysis of variance
%     cohen1988statistical  % Cohen, effect sizes (eta^2)
%     good2005permutation   % Good, permutation tests
%     efron1993introduction % Efron & Tibshirani, the bootstrap
%     kunsch1989jackknife   % Kunsch, block bootstrap
%     hanley1982meaning     % Hanley & McNeil, ROC / AUC
%     brier1950verification % Brier, the Brier score
%     murphy1973new         % Murphy, Brier-score decomposition
%     spearman1904proof     % Spearman, rank correlation
%  Existing keys reused: adjei2023point, adjei_point_nodate,
%     lindgren_explicit_2011, simpson_penalising_2017, rue_approximate_2009
% =====================================================================

\chapter{Theory}
\label{chap:Theory}

This chapter develops the statistical theory the thesis rests on, in two
movements. The first (Sections~\ref{sec:theory_overview}--\ref{sec:integrated_model})
sets out the point-process framework for the integrated species
distribution model whose output this thesis analyses: how a latent
ecological intensity is defined, how heterogeneous datasets are linked to
it through their observation processes, and how the whole is fitted by
Bayesian methods. The second (Sections~\ref{sec:confounding}--\ref{sec:validation_theory})
develops the theory behind the diagnostics applied to that output ---
spatial confounding between covariates and the spatial field, the
decomposition and resampling of spatial variance, and the metrics used to
validate probabilistic predictions. Together they give the theoretical
basis for both the model being interrogated and the tools used to
interrogate it.


% =====================================================================
\section{Overview and motivation}
\label{sec:theory_overview}
% =====================================================================

\subsection{The point process framework for integrated modelling of species diversity}

In recent decades, the volume and diversity of biodiversity data have
increased substantially. Species occurrence records are now collected
through structured monitoring programs, museum collections, and
large-scale citizen science initiatives. While these data provide
unprecedented opportunities for understanding species distributions and
biodiversity patterns, they are also characterised by substantial
heterogeneity in sampling protocols, spatial resolution, and observation
quality \citep{adjei2023point}. If these differences are not explicitly
accounted for, statistical inference about species distributions and
diversity may be biased.

Species distribution models (SDMs) are widely used to describe and predict
where species occur across landscapes. However, traditional SDMs are often
fitted to multiple data sources independently, ignoring the fact that the
same underlying ecological process generates all observed data. This can
lead to inconsistent parameter estimates and missed opportunities to
borrow information across datasets.

An alternative and increasingly adopted framework treats all observations
as realisations of a spatial point process, characterised by an intensity
function $\lambda(s)$, where $s \in D$ represents a spatial location
\citep{adjei2023point}. The intensity function $\lambda(s)$ describes the
expected number of individuals per unit area at location $s$.
Ecologically, it can be interpreted as a spatially explicit measure of
species abundance or habitat suitability. Regions where $\lambda(s)$ is
large correspond to areas with higher expected density of individuals,
while low values indicate less favourable environmental conditions.


% =====================================================================
\section{The ecological process model}
\label{sec:ecological_process}
% =====================================================================

\subsection{Poisson point process formulation}

Following the framework described in \citep{adjei2023point}, the underlying
ecological distribution is commonly modelled as a Poisson point process.
Under this model, the number of individuals within any subregion
$B \subset D$, denoted $N_B$, follows a Poisson distribution with mean
\begin{equation}
    \mu_B = \int_B \lambda(s)\, ds.
\end{equation}
Thus,
\begin{equation}
    N_B \sim \text{Poisson}(\mu_B).
\end{equation}
This property holds for any measurable subregion $B \subset D$, and counts
in disjoint regions are independent. The intensity function therefore
completely characterises the spatial distribution of the point process.

\subsection{Log-Gaussian Cox process}

To capture the effects of environmental conditions and residual spatial
structure, the intensity function is typically modelled on the log scale:
\begin{equation}
    \lambda(s) = \exp\big(\eta(s)\big).
\end{equation}
The linear predictor $\eta(s)$ is specified as
\begin{equation}
    \eta(s) = X(s)^\top \beta + u(s),
    \label{eq:linpred}
\end{equation}
where $X(s)$ is a vector of environmental covariates at location $s$,
$\beta$ is a vector of regression coefficients, and $u(s)$ is a spatial
random effect \citep{adjei2023point}. Typical covariates include climatic
variables (e.g., temperature, precipitation), topographic features (e.g.,
elevation, slope), and land-cover classifications. The choice of covariates
is guided by ecological knowledge of the species and the study region.

This specification defines a \textit{log-Gaussian Cox process} (LGCP), in
which the log-intensity is modelled as a Gaussian random field
\citep{adjei2023point}. The covariate component $X(s)^\top \beta$ captures
systematic environmental effects, while the spatial random field $u(s)$
accounts for residual spatial autocorrelation not explained by observed
covariates.

The spatial random field is typically assumed to follow a Gaussian process
with a Mat\'{e}rn covariance function, allowing flexible control over
spatial range and smoothness. For two locations $s_i$ and $s_j$, the
covariance is given by
\begin{equation}
    \text{Cov}\big(u(s_i), u(s_j)\big)
    = \sigma_u^2 \, C_{\text{Mat\'{e}rn}}\big(\|s_i - s_j\|\big),
\end{equation}
where $\sigma_u^2$ denotes the marginal variance and
$C_{\text{Mat\'{e}rn}}(\cdot)$ is the Mat\'{e}rn correlation function
\citep{adjei2023point}.

\subsection[SPDE approximation and GMRFs]{SPDE approximation and Gaussian Markov random fields}
\label{subsec:spde}

Direct computation with Gaussian random fields (GRFs) is expensive, scaling
as $\mathcal{O}(n^3)$ with the number of spatial locations. Computational
efficiency is achieved through the stochastic partial differential equation
(SPDE) approach of \cite{lindgren_explicit_2011}, which establishes that a
GRF with Mat\'{e}rn covariance is the stationary solution to the SPDE
\begin{equation}
    (\kappa^2 - \Delta)^{\alpha/2} \tau\, u(s) = \mathcal{W}(s),
\end{equation}
where $\Delta$ is the Laplacian, $\mathcal{W}(s)$ is Gaussian white noise,
and the parameters $\kappa > 0$ and $\tau > 0$ determine the spatial range
and marginal variance. The smoothness parameter $\alpha = \nu + d/2$ is
linked to the Mat\'{e}rn smoothness $\nu$ and the spatial dimension $d$.

By discretising this SPDE on a constrained Delaunay triangulation (mesh) of
the domain and applying the finite element method, the GRF is approximated
by a Gaussian Markov random field (GMRF). A GMRF possesses a sparse
precision matrix, reducing the computational cost to $\mathcal{O}(n^{3/2})$
or better through sparse Cholesky factorisation. This approximation is
exact in the sense that the finite element basis representation converges
to the true GRF as the mesh is refined.

The spatial range $\rho$ and marginal standard deviation $\sigma_u$ of the
Mat\'{e}rn field are related to the SPDE parameters by
\begin{equation}
    \rho = \frac{\sqrt{8\nu}}{\kappa}, \qquad
    \sigma_u^2 = \frac{\Gamma(\nu)}
    {\Gamma(\nu + d/2)(4\pi)^{d/2} \kappa^{2\nu} \tau^2}.
\end{equation}
For the common choice $\nu = 1$ in two dimensions ($d = 2$), the smoothness
parameter becomes $\alpha = 2$.

\subsection{Interpretation in a biodiversity context}

Within a biodiversity framework, the intensity function $\lambda(s)$
represents the fundamental ecological quantity from which multiple measures
can be derived. For a single species, it describes spatial variation in
expected abundance. For multiple species, each species
$k \in \{1, \dots, K\}$ is assumed to have its own latent intensity surface
$\lambda^{(k)}(s)$, potentially sharing environmental drivers or spatial
structure.

Importantly, modelling the ecological process in continuous space avoids
the need to discretise the landscape into grid cells, thereby reducing loss
of spatial resolution and enabling integration of datasets collected at
different spatial scales \citep{adjei2023point}. Furthermore, defining a
single latent intensity surface provides a common foundation for linking
heterogeneous observation processes in integrated species distribution
models.

By separating the ecological process from observation processes, inference
about species diversity reflects biological mechanisms rather than
artefacts of data collection. The following section introduces the
observation process models that link empirical biodiversity data to the
latent intensity function.


% =====================================================================
\section{Observation process models}
\label{sec:observation_models}
% =====================================================================

Having defined the latent ecological process through the intensity function
$\lambda(s)$, we now describe how different types of biodiversity data are
linked to this underlying process. In the point process framework, each
dataset is interpreted as an attempt to observe the same latent spatial
point pattern, but through different sampling protocols and with different
sources of observation error \citep{adjei2023point}.

Let $Y = \{Y_1, \dots, Y_M\}$ denote $M$ observed datasets. For each dataset
$Y_d$, we specify an observation model of the form
\begin{equation}
    P(Y_d \mid \lambda(s), \theta_d),
\end{equation}
where $\theta_d$ represents parameters specific to the observation process
of dataset $d$. Conditional on the latent intensity function, the datasets
are assumed independent, so that the joint model factorises as
\begin{equation}
    P(Y, \lambda(s)) = P(\lambda(s)) \prod_{d=1}^{M} P(Y_d \mid \lambda(s), \theta_d).
\end{equation}
This hierarchical formulation separates the ecological process from the
observation processes and allows heterogeneous data types to inform the
same latent intensity surface \citep{adjei2023point}.

\subsection{Abundance count data}

Suppose that species abundance is recorded as counts within a spatial unit
$B \subset D$. Let $N_B$ denote the observed number of individuals in area
$B$. Under the Poisson point process assumption, the natural observation
model is
\begin{equation}
    N_B \sim \text{Poisson}(\mu_B), \qquad \mu_B = \int_B \lambda(s)\, ds.
\end{equation}
The log link connects the expected count to the linear predictor:
\begin{equation}
    \log(\mu_B) = \log\!\left(\int_B \exp\big(\eta(s)\big)\, ds\right).
\end{equation}
When the spatial resolution of the count data is coarse relative to the
variation in $\lambda(s)$, this integral is approximated numerically
\citep{adjei2023point}.

\subsection{Presence--absence data}

Let $Y_B \in \{0,1\}$ denote a binary observation of presence or absence in
area $B$. Under the Poisson point process model, the probability of
observing at least one individual in area $B$ is
\begin{equation}
    \Psi_B = \Pr(N_B > 0) = 1 - e^{-\mu_B},
\end{equation}
where $\mu_B = \int_B \lambda(s)\, ds$. We therefore model
\begin{equation}
    Y_B \sim \text{Bernoulli}(\Psi_B).
\end{equation}
Taking the complementary log-log link yields
\begin{equation}
    \log\big(-\log(1 - \Psi_B)\big) = \log(\mu_B),
\end{equation}
which links the binary observation directly to the underlying intensity
surface \citep{adjei2023point}. The cloglog is the natural link here rather
than a modelling choice: it arises directly from the Poisson generating
process, ensuring that the binary observation model is consistent with the
underlying continuous-space point process.

If multiple visits are conducted at site $B$, with $r$ detections out of
$J$ visits, the model may be extended to
\begin{equation}
    r \sim \text{Binomial}(J, \Psi_B).
\end{equation}
Unlike classical occupancy models, presence is not treated as a separate
latent state; rather, absence corresponds to a zero count arising from the
Poisson process \citep{adjei2023point}.

\subsection{Presence-only data}
\label{subsec:presence_only}

Presence-only data consist of observed locations $\{s_1, \dots, s_N\}$ where
the species has been recorded, without information about absences. These
data can be modelled naturally as a thinned Poisson point process
\citep{adjei2023point}.

If individuals are detected with spatially varying probability $q(s)$, the
observed intensity becomes
\begin{equation}
    \lambda^{*}(s) = q(s)\lambda(s).
\end{equation}
The log-likelihood of the inhomogeneous Poisson point process over the
domain $D$ is
\begin{equation}
    \ell = \sum_{i=1}^{N} \log \lambda^{*}(s_i) - \int_D \lambda^{*}(s)\, ds.
\end{equation}
Because the integral is generally intractable, it is approximated
numerically using quadrature points \citep{adjei_point_nodate}. On the log
scale, the observed intensity can be written as
\begin{equation}
    \log \lambda^{*}(s) = \eta(s) + \log q(s),
    \label{eq:bias_decomp}
\end{equation}
where $\eta(s)$ is the latent ecological linear predictor defined in
Section~\ref{sec:ecological_process}. The term $\log q(s)$ captures spatial
sampling bias. In practice, $q(s)$ is modelled as a function of
observer-related covariates such as road density, human population density,
or recorded survey effort; alternatively, an additional spatial random
field may be specified for $\log q(s)$ when the bias structure is not fully
explained by observed covariates. This decomposition --- an ecological
signal $\eta(s)$ plus a sampling-effort term $\log q(s)$ --- is the object
the thesis diagnostics interrogate, and the optional spatial field on
$\log q(s)$ is precisely the field whose effect is examined in
Section~\ref{sec:confounding}.

\subsection{Advantages of integration}

When multiple datasets are available, fitting separate models may lead to
parameter non-identifiability, particularly for detection probabilities or
sampling bias surfaces. By integrating datasets through a shared latent
intensity function, information is borrowed across data sources, improving
parameter estimation and predictive performance \citep{adjei2023point}.

In particular, structured survey data can help correct for bias in
presence-only datasets, while opportunistic data can improve spatial
coverage. The integrated likelihood framework therefore enables robust
inference on species distributions and derived biodiversity metrics by
explicitly accounting for heterogeneous observation processes.


% =====================================================================
\section{Integrated model formulation}
\label{sec:integrated_model}
% =====================================================================

The ecological process model defined in
Section~\ref{sec:ecological_process} and the observation models described
in Section~\ref{sec:observation_models} can be combined into a unified
hierarchical framework. This formulation, commonly referred to as an
Integrated Species Distribution Model (ISDM), links multiple heterogeneous
datasets through a shared latent intensity function $\lambda(s)$
\citep{adjei2023point}.

\subsection{Joint likelihood}

Let $Y = \{Y_1, \dots, Y_M\}$ denote $M$ datasets, potentially consisting of
different data types (e.g., presence-only, presence--absence, or count
data). Each dataset $Y_d$ is associated with its own observation model
parameterised by $\theta_d$, but all datasets depend on the same latent
ecological process $\lambda(s)$.

The joint probability distribution for the data and the latent intensity
surface can be written as
\begin{equation}
    P(Y, \lambda(s) \mid \theta)
    = P(\lambda(s)) \prod_{d=1}^{M} P(Y_d \mid \lambda(s), \theta_d),
\end{equation}
where $\theta = \{\theta_1, \dots, \theta_M\}$ and $P(\lambda(s))$
represents the prior or process model for the latent intensity (e.g., the
log-Gaussian Cox process defined in Section~\ref{sec:ecological_process}).

This hierarchical formulation separates:
\begin{itemize}
    \item The ecological process $P(\lambda(s))$, describing the true
          species distribution.
    \item The observation processes $P(Y_d \mid \lambda(s), \theta_d)$,
          describing how each dataset is generated.
\end{itemize}
Conditional on $\lambda(s)$, the datasets are assumed independent. They are
therefore linked only through the shared latent intensity surface
\citep{adjei_point_nodate}.

\subsection{Identifiability and information sharing}

When datasets are analysed separately, certain parameters may be
non-identifiable. For example, in presence-only data, the sampling effort
function $q(s)$ and the ecological intensity $\lambda(s)$ cannot generally
be separated without additional information. Similarly, in single-visit
presence--absence surveys, detection probability may not be identifiable.

By integrating multiple data sources, the shared intensity function
$\lambda(s)$ is informed jointly by all datasets. This allows
observation-specific parameters (such as detection probability or sampling
bias) to be estimated relative to the common ecological process
\citep{adjei_point_nodate}. In particular, if at least one dataset has a
well-characterised or unbiased observation process, it can anchor inference
on the latent intensity surface. This anchoring is exactly the assumption
the thesis tests: the structured presence--absence data is taken to anchor
the effort surface $q(s)$, and the diagnostics ask whether that anchor is
strong enough to be shared across all species in a group.

Thus, integration improves:
\begin{itemize}
    \item Parameter identifiability,
    \item Precision of regression coefficients,
    \item Predictive performance.
\end{itemize}

\subsection{Derived ecological quantities}

An important feature of the point process framework is that many ecological
state variables arise naturally as functions of the intensity surface. For
any region $B \subset D$, the expected abundance is
\begin{equation}
    \mu_B = \int_B \lambda(s)\, ds,
\end{equation}
and the probability of occupancy is
\begin{equation}
    \Psi_B = 1 - e^{-\mu_B}.
\end{equation}

For a community of $K$ species, species richness over a region $B$ is
defined as the expected number of species present, which under the point
process framework is
\begin{equation}
    S(B) = \sum_{k=1}^{K} \Psi_B^{(k)}
    = \sum_{k=1}^{K} \left(1 - e^{-\mu_B^{(k)}}\right),
\end{equation}
where $\mu_B^{(k)} = \int_B \lambda^{(k)}(s)\, ds$ is the expected abundance
of species $k$ in region $B$. This expression gives the \emph{expected}
species richness; the \emph{realised} richness is the actual number of
species present, which is a random variable whose distribution can also be
characterised within this framework.

In this way, biodiversity metrics are interpreted as derived quantities of
the underlying spatial point processes rather than as independently
modelled states.

\subsection{Bayesian inference and prior specification}

Inference is conducted within a Bayesian framework, where prior
distributions are specified for all model parameters
\citep{adjei_point_nodate}. Let $\Theta$ denote the full parameter set,
including fixed effects $\beta$, spatial hyperparameters $(\rho, \sigma_u)$,
and observation-specific parameters $\theta_d$. The posterior distribution
is proportional to
\begin{equation}
    P(\Theta, \lambda(s) \mid Y)
    \propto P(\lambda(s) \mid \Theta)
    \prod_{d=1}^{M} P(Y_d \mid \lambda(s), \theta_d)\, P(\Theta).
\end{equation}

For the spatial hyperparameters, penalised complexity (PC) priors
\citep{simpson_penalising_2017} are commonly used. PC priors are derived by
penalising the Kullback--Leibler divergence from a base model (e.g., no
spatial effect), favouring simpler models while remaining weakly
informative. Specifically, PC priors are placed on the Mat\'{e}rn range
$\rho$ and marginal standard deviation $\sigma_u$, reflecting prior beliefs
about the spatial scale of variation and the magnitude of residual spatial
structure.

Because the latent intensity function is modelled as a Gaussian random
field approximated by a GMRF (Section~\ref{subsec:spde}), computationally
efficient inference is available through the integrated nested Laplace
approximation (INLA) \citep{rue_approximate_2009}.

\subsection{Integrated nested Laplace approximation (INLA)}
\label{subsec:inla}

INLA is a deterministic Bayesian inference algorithm designed for latent
Gaussian models, of which the LGCP is a special case. Rather than sampling
from the posterior via Markov chain Monte Carlo (MCMC), INLA constructs
accurate analytical approximations to the marginal posteriors of model
parameters and latent effects.

The key idea is a nested Laplace approximation. Let $\mathbf{x}$ denote the
vector of latent Gaussian variables (the GMRF approximating the spatial
field and any other Gaussian random effects), and let $\boldsymbol{\theta}$
denote the hyperparameters. INLA approximates the marginal posterior of each
hyperparameter as
\begin{equation}
    \tilde{p}(\theta_j \mid Y)
    = \int \tilde{p}(\boldsymbol{\theta} \mid Y)\, d\boldsymbol{\theta}_{-j},
\end{equation}
where $\tilde{p}(\boldsymbol{\theta} \mid Y)$ is itself obtained via a
Laplace approximation to the marginal likelihood
$p(Y \mid \boldsymbol{\theta})$. Marginal posteriors for the latent effects
are then obtained by a second Laplace approximation conditional on
$\boldsymbol{\theta}$.

The GMRF structure of the latent field (Section~\ref{subsec:spde}) is
essential to INLA's efficiency: the sparse precision matrix of the GMRF
enables fast computation of the required log-determinants and matrix
solves, reducing the computational complexity from $\mathcal{O}(n^3)$ to
$\mathcal{O}(n^{3/2})$ or better. Together, the SPDE approximation and INLA
make inference on spatial models with tens of thousands of mesh nodes
computationally feasible.

\subsection{Implications for biodiversity modelling}

The integrated formulation provides a coherent statistical foundation for
combining structured and unstructured biodiversity data. By explicitly
modelling observation processes and linking them to a shared latent
ecological surface, the framework ensures that inference about species
diversity reflects ecological mechanisms rather than artefacts of data
collection.

This approach is particularly valuable in modern biodiversity research,
where data are heterogeneous in origin, resolution, and quality. The point
process framework therefore offers both theoretical consistency and
practical flexibility for modelling species distributions and spatial
patterns of biodiversity \citep{adjei_point_nodate}.


% =====================================================================
\section{Spatial confounding and the role of the spatial field}
\label{sec:confounding}
% =====================================================================

The integrated model rests on the decomposition of
Equation~\ref{eq:bias_decomp}, in which the observed log-intensity splits
into an ecological linear predictor $\eta(s) = X(s)^\top\beta + u(s)$ and a
sampling-effort term $\log q(s)$. A central concern of this thesis is how
cleanly that split, and the analogous split within the effort term itself,
can actually be made --- a question that is a spatial instance of the
general phenomenon of \emph{confounding} between fixed effects and a
correlated spatial random effect \citep{reich2006effects, hodges2010adding}.

\subsection{Collinearity between covariates and the spatial field}

Consider the linear predictor of Equation~\ref{eq:linpred}, written for the
$n$ locations of a fitted model in vector form as
\begin{equation}
    \boldsymbol{\eta} = \mathbf{X}\boldsymbol{\beta} + \mathbf{u},
    \qquad \mathbf{u} \sim \mathcal{N}\!\big(\mathbf{0}, \boldsymbol{\Sigma}_u\big),
\end{equation}
where $\mathbf{X}$ is the $n \times p$ covariate matrix and $\mathbf{u}$ is
the (Markov-approximated) spatial field. The fixed effects $\boldsymbol{\beta}$
are identified by the part of the response that the covariates explain and
the field does not. When a covariate is itself spatially smooth --- a
broad-scale climate gradient, for instance --- its column of $\mathbf{X}$
lies close to the space of smooth surfaces that $\mathbf{u}$ can also
represent. The covariate and the field are then collinear, and the data
cannot cleanly attribute the shared, smoothly varying component of the
response to one rather than the other. Introducing the spatial field can in
this case absorb variation that, in its absence, is loaded onto
$\boldsymbol{\beta}$, so that the estimate $\hat{\boldsymbol{\beta}}$ shifts
when the field is added \citep{hodges2010adding}. This shift is not a
numerical artefact but a statement about identifiability: the more a
covariate's effect is confounded with smooth spatial structure, the more
its estimate depends on whether that structure is modelled explicitly.

\subsection{Confounding as a diagnostic}

The same mechanism that makes confounding a nuisance for estimation makes it
useful as a diagnostic. If a covariate genuinely represents an ecological
relationship, its estimated effect should be relatively stable whether or
not a spatial field is present, because the relationship holds locally and
is not merely a reflection of a global gradient. If, on the other hand, a
covariate is acting as a proxy for an unmodelled spatial pattern --- such as
a south-to-north gradient in sampling effort --- then its effect will be
large when no field is available to carry that pattern and will collapse
once the field is added to soak it up. Comparing the estimated coefficients
$\hat{\boldsymbol{\beta}}$ from two otherwise identical fits, one with and one
without the spatial field, therefore localises which effects are
confounded with spatial structure and by how much. Applied to the effort
sub-model $\log q(s)$ of Equation~\ref{eq:bias_decomp}, the magnitude of the
coefficient shift becomes a direct, per-group measure of how far the
estimated sampling bias leans on smooth spatial confounding rather than on
genuine covariate information --- the basis of the spatial-field diagnostic
used in this thesis.


% =====================================================================
\section{Quantifying and decomposing spatial variance}
\label{sec:variance_theory}
% =====================================================================

The remaining diagnostics treat the fitted bias surface as data and ask how
its variation is distributed in space and across taxonomic groups. This
requires a small amount of theory on variance, its decomposition by an
analysis of variance, and the effect-size measures used to interpret that
decomposition.

\subsection{Variance as a measure of spatial heterogeneity}

For a set of values $x_1, \dots, x_n$ extracted from the bias surface, the
sample variance
\begin{equation}
    s^2 = \frac{1}{n-1}\sum_{i=1}^{n}\big(x_i - \bar{x}\big)^2
    \label{eq:sample_var}
\end{equation}
summarises their spread about the mean $\bar{x}$. Computed over all cells
pooled across regions and groups, it gives a single \emph{total variance};
computed within one spatial block it gives a \emph{within-region variance}
that measures how heterogeneous the estimated sampling intensity is inside
that block. A second-order summary is obtained by applying
Equation~\ref{eq:sample_var} to the collection of per-region variances
themselves, yielding the \emph{variance among regional variances}: a large
value means some regions are far more internally variable than others, so
the spatial structuring of the bias is itself unevenly distributed across
the country. These nested notions of variance --- within a block, and among
the block-level variances --- are the statistics localised and resampled in
the block sampling test.

\subsection{The two-way analysis of variance}
\label{subsec:anova_theory}

To attribute the spread of the bias surface to identifiable sources, the
analysis of variance \citep{fisher1925statistical} decomposes the total
variation into additive components associated with the design factors. With
two crossed fixed factors --- taxonomic \emph{group} ($i = 1,\dots,a$) and
\emph{region} ($j = 1,\dots,b$) --- and $K$ cell observations per
combination, the cell value $y_{ijk}$ is modelled as
\begin{equation}
    y_{ijk} = \mu + \alpha_i + \beta_j + (\alpha\beta)_{ij} + \varepsilon_{ijk},
    \qquad \varepsilon_{ijk} \sim \mathcal{N}(0, \sigma^2),
    \label{eq:anova_theory}
\end{equation}
where $\mu$ is the grand mean, $\alpha_i$ and $\beta_j$ are the main effects
of group and region, $(\alpha\beta)_{ij}$ is their interaction, and
$\varepsilon_{ijk}$ is the residual. The corresponding decomposition of the
total sum of squares is
\begin{equation}
    \mathrm{SS}_{\text{total}} = \mathrm{SS}_{A} + \mathrm{SS}_{B}
    + \mathrm{SS}_{AB} + \mathrm{SS}_{E},
    \label{eq:ss_decomp}
\end{equation}
with $A$ denoting group, $B$ region, $AB$ their interaction and $E$ the
residual. When the design is \emph{balanced} --- an equal number of
observations $K$ in every group$\times$region cell --- the factors are
orthogonal, the sums of squares are mutually independent, and the sequential
(Type~I) decomposition coincides with the marginal (Type~II/III)
decompositions, so the result does not depend on the order in which terms
enter the model. The balanced canonical-cell construction used in the thesis
is what secures this property.

\subsection{Effect sizes versus significance}
\label{subsec:effect_size}

The decomposition in Equation~\ref{eq:ss_decomp} is usually accompanied by
$F$-tests, but with tens of thousands of cell observations any non-zero
effect becomes statistically significant, so significance carries little
information. Interpretation is instead based on \emph{effect size}: the
proportion of variation each term explains \citep{cohen1988statistical}.
Two standard measures are reported,
\begin{equation}
    \eta^2_{\text{term}}
    = \frac{\mathrm{SS}_{\text{term}}}{\mathrm{SS}_{\text{total}}},
    \qquad
    \eta^2_{p,\text{term}}
    = \frac{\mathrm{SS}_{\text{term}}}
           {\mathrm{SS}_{\text{term}} + \mathrm{SS}_{\text{residual}}},
    \label{eq:eta2_theory}
\end{equation}
where $\eta^2$ expresses a term's share of the total variation and partial
$\eta^2$ its share relative only to itself plus the residual. The term with
the largest $\eta^2$ identifies the dominant systematic source of structure
in the bias surface --- whether it is driven mainly by where one looks
(region), by which taxon one models (group), or by their interaction.
Because $\eta^2$ is a ratio of sums of squares, the \emph{ranking} of the
terms is invariant to monotone rescalings of the response that preserve the
decomposition's structure, which is why the conclusion is robust to fitting
the model on the natural or the log scale of the right-skewed intensity.


% =====================================================================
\section{Resampling-based inference}
\label{sec:resampling_theory}
% =====================================================================

The permutation and block sampling tests draw their validity not from a
parametric sampling distribution but from resampling the data under an
explicit null. This section states the two ideas they rest on:
exchangeability and the (block) bootstrap.

\subsection{Exchangeability and permutation tests}
\label{subsec:permutation_theory}

A collection of random variables is \emph{exchangeable} if their joint
distribution is invariant under any permutation of their labels. A
permutation test \citep{good2005permutation} converts a hypothesis of
exchangeability into a test: if some grouping label is irrelevant under the
null, then reshuffling that label should leave the distribution of any test
statistic unchanged. Concretely, let $T_{\mathrm{obs}}$ be the statistic
computed on the data as observed, and let $T_1, \dots, T_B$ be its values
recomputed on $B$ reshuffled (or resampled) datasets drawn under the null.
The position of the observed value within this reference distribution,
\begin{equation}
    p_{\ge} = \frac{1}{B}\sum_{b=1}^{B}
    \mathbf{1}\{\,T_b \ge T_{\mathrm{obs}}\,\},
    \label{eq:perm_p}
\end{equation}
measures how extreme the data are relative to the null; a value of
$p_{\ge}$ near $0.5$ places the observed statistic in the centre of the null
distribution and is read as consistency with exchangeability. In the thesis
the labels reshuffled are the taxonomic groups contributing each cell, so
the test asks whether the groups are spatially exchangeable --- whether the
regional structure of the bias field is shared across groups rather than
group-specific. Fixing the random-number seed makes the reference
distribution, and hence $p_{\ge}$, exactly reproducible.

\subsection{The bootstrap and block resampling}
\label{subsec:bootstrap_theory}

The reference distributions above are generated by resampling. The bootstrap
\citep{efron1993introduction} approximates the sampling distribution of a
statistic by repeatedly recomputing it on datasets drawn \emph{with
replacement} from the observed data. Drawing with replacement is what
preserves each resampled dataset's size while letting the composition vary,
so that the variability of the statistic across resamples estimates its true
sampling variability.

Plain (cell-by-cell) resampling assumes the resampled units are
exchangeable, which spatially autocorrelated data are not: nearby cells
carry redundant information, and breaking them apart would destroy the very
structure under study and understate dependence. The remedy is to resample
\emph{blocks} of contiguous observations rather than individual ones, so
that the within-block spatial dependence is carried intact into each
resample \citep{kunsch1989jackknife}. The thesis uses this principle in two
ways. First, the permutation null of
Section~\ref{subsec:permutation_theory} resamples groups \emph{within each
region}, preserving each region's spatial footprint and sample size while
breaking only the group identity. Second, the block sampling test perturbs
the configuration one whole region-block at a time --- replacing a single
region's block of cells with the same region's block from a donor group and
recomputing the variance among regional variances --- so that the influence
of each spatial block on the overall statistic can be measured directly.
Aggregating the resulting changes by swapped region yields a
\emph{sensitivity} ranking that identifies which blocks carry the most
leverage over the spatial-variance signal.


% =====================================================================
\section{Validation of probabilistic predictions}
\label{sec:validation_theory}
% =====================================================================

The final diagnostic confronts the bias-corrected occupancy predictions with
independent presence--absence observations. A predicted occupancy
probability $\hat{p} \in [0,1]$ can be wrong in two distinct ways: it may
fail to \emph{discriminate} present from absent sites, and it may be poorly
\emph{calibrated} in magnitude. Different metrics target these different
failures.

\subsection{Discrimination: the ROC curve and AUC}
\label{subsec:auc_theory}

For a binary outcome and a continuous predicted score, a classification rule
is obtained by thresholding the score. As the threshold varies, the
true-positive rate (sensitivity) is traded against the false-positive rate
($1$ minus specificity); the receiver operating characteristic (ROC) curve
plots one against the other over all thresholds. The area under this curve
(AUC) summarises discrimination in a single, threshold-free number
\citep{hanley1982meaning}. The AUC has a direct probabilistic
interpretation: it equals the probability that a randomly chosen present
site is assigned a higher predicted occupancy than a randomly chosen absent
site,
\begin{equation}
    \mathrm{AUC} = \Pr\!\big(\hat{p}_{+} > \hat{p}_{-}\big),
    \label{eq:auc}
\end{equation}
where $\hat{p}_{+}$ and $\hat{p}_{-}$ are predictions at a presence and an
absence respectively. This equals the (normalised) Mann--Whitney $U$
statistic of the two score distributions. A value of $0.5$ indicates no
discrimination beyond chance and $1$ indicates perfect ranking; values above
$0.7$ are conventionally taken to indicate useful discrimination. Because
AUC depends only on the ranking of predictions and not on their absolute
calibration, it isolates discrimination from calibration.

\subsection{Accuracy and calibration: the Brier score}
\label{subsec:brier_theory}

To assess the predictions on their absolute scale, the Brier score
\citep{brier1950verification} averages the squared difference between
predicted probability and observed outcome,
\begin{equation}
    \mathrm{BS} = \frac{1}{n}\sum_{i=1}^{n}\big(\hat{p}_i - y_i\big)^2,
    \qquad y_i \in \{0,1\},
    \label{eq:brier}
\end{equation}
so that lower values indicate better predictions. Unlike AUC, the Brier
score is a \emph{proper} scoring rule: its expectation is minimised by the
true probabilities, so it rewards both correct ranking and correct
magnitude. It admits the decomposition into reliability (calibration),
resolution and uncertainty components \citep{murphy1973new}, which makes
explicit that a low score requires probabilities that are both informative
and calibrated. In the thesis the Brier score, averaged across species at a
plot, serves as the per-plot predictive error in the bias diagnostic below.

\subsection{Rank correlation: Spearman's coefficient}
\label{subsec:spearman_theory}

The bias diagnostic asks whether predictive error grows systematically with
modelled sampling bias --- a question about monotonic association rather
than linear fit, and one that should be insensitive to the (right-skewed)
scales of both quantities. Spearman's rank correlation coefficient
\citep{spearman1904proof} answers it by applying the Pearson correlation to
the \emph{ranks} of the two variables. For $n$ paired observations with no
ties, it reduces to
\begin{equation}
    \rho_s = 1 - \frac{6\sum_{i=1}^{n} d_i^2}{n\,(n^2 - 1)},
    \label{eq:spearman}
\end{equation}
where $d_i$ is the difference between the ranks of the two values in pair
$i$. The coefficient ranges from $-1$ (perfect decreasing monotone
relationship) through $0$ (no monotone association) to $+1$ (perfect
increasing relationship). A value near zero between per-plot bias magnitude
and per-plot Brier score indicates that the correction holds evenly across
the sampling-bias gradient, whereas a strong positive value would signal
that the predictions fail precisely where the model itself flags high bias.

\medskip
\noindent
Having established the theory for both the integrated model and the
diagnostics applied to its output, Chapter~\ref{ch:methods} describes the
practical implementation: the data sources, the construction of the study
regions, and the computational setup used to carry out each test in this
thesis.
