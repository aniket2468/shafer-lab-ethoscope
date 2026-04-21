# Research Report: Optomotor Sleep Deprivation and Rethomics

**Date:** January 20, 2026  
**Compiled by:** Research Assistant

---

## Table of Contents
1. [Optomotor Sleep Deprivation](#optomotor-sleep-deprivation)
2. [Rethomics Framework](#rethomics-framework)
3. [Ethoscope Platform](#ethoscope-platform)
4. [Integration: Ethoscope + Rethomics](#integration-ethoscope--rethomics)
5. [All Sources](#all-sources)

---

## Optomotor Sleep Deprivation

### Overview
Optomotor sleep deprivation is a method used in *Drosophila melanogaster* (fruit fly) research to induce sleep loss through targeted mechanical stimulation. The term "optomotor" in this context refers to the rotational mechanical module used to disrupt sleep, rather than manipulating the fly's visual optomotor response.

### Methodology

#### Mechanical Sleep Deprivation Devices
- **Sleep Nullifying Apparatus (SNAP)** and similar systems physically disturb flies when they become inactive
- Devices place vials or tubes containing flies on a shaker or motor that periodically agitates them
- The "optomotor module" is programmed to rapidly turn a motor and spin the tube housing the fly when immobility is detected

#### Specific Parameters
- **Rotation speed:** Approximately 400 rpm for 3 seconds or 150 rpm
- **Trigger threshold:** Typically 30 or 220 seconds of inactivity
- **Goal:** Study sleep homeostasis and consequences of sleep deprivation by disrupting sleep only when detected

### Advantages Over Traditional Methods
- **Targeted approach:** Delivers stimuli only to inactive flies, unlike orbital shakers that stimulate all flies indiscriminately
- **Reduced stress:** Minimizes non-sleep-related stress responses in experimental subjects
- **Behavioral feedback:** Uses real-time monitoring to trigger stimulation only when needed

### Research Findings

#### Effects on Visual Behavior
- Simple optomotor responses (tendency to orient toward moving visual stimuli) are largely **unaffected** by sleep deprivation
- Sleep deprivation **can impair** visual attention in tasks involving competing stimuli
- Basic optomotor responses remain intact even after sleep loss

#### Visual Experience and Sleep Need
- *optomotor-blind (omb)* mutants with undeveloped motion-processing cells exhibit reduced and less consolidated sleep
- Optogenetic activation of motion-processing neurons in wild-type flies can increase sleep
- Visual experience and processing contribute to sleep need

### Methodological Considerations
- **Yoked controls:** Used to distinguish effects directly caused by sleep loss from those caused by mechanical stimulation
- **Stress minimization:** Critical for avoiding confounding variables
- **Continuous monitoring:** EEG/EMG can confirm effectiveness of sleep deprivation

---

## Rethomics Framework

### Overview
**Rethomics** is an open-source R framework designed for high-throughput behavioral data analysis. It unifies the analysis of behavioral datasets in an efficient and flexible manner, bridging the gap between behavioral biology and data sciences.

### Core Architecture

#### Modular Design
Rethomics is implemented as a collection of interconnected R packages, similar to the `tidyverse` framework. This modular architecture provides:
- Increased testability
- Enhanced maintainability
- Greater adaptability

### Key Components

#### 1. `behavr` Tables
- **Purpose:** Central data structure for handling very large behavioral datasets
- **Features:** Links metadata and data within the same object
- **Base:** Built on `data.table` for efficiency
- **Flexibility:** Universal structure that works with data from various recording platforms

#### 2. Data Import Packages

**`damr` (Drosophila Activity Monitor Reader)**
- Loads data from Drosophila Activity Monitor Systems (DAMS)
- Imports behavioral data into `behavr` tables
- Handles metadata linking and zeitgeber references

**`scopr` (Ethoscope Reader)**
- Reads and handles data from the Ethoscope platform
- Imports real-time tracking data into `behavr` tables
- Processes Cartesian coordinates and behavioral parameters

#### 3. `ggetho` (Visualization)
- Extends `ggplot2` for behavioral data visualization
- Produces high-quality, publication-ready figures
- Features for long experiments:
  - Double-plotted actograms
  - Periodograms
  - Light/dark phase annotations

#### 4. `zeitgebr` (Circadian Analysis)
- Suite of methods for analyzing circadian rhythms
- Computational tools:
  - Autocorrelograms
  - Chi-squared (χ²) periodograms
  - Lomb-Scargle periodograms
  - Automatic peak detection

#### 5. `sleepr` (Sleep Analysis)
- Analyzes sleep patterns from movement data
- Particularly designed for *Drosophila*
- Integrates with other rethomics packages

### Workflow

1. **Experimental Design:** Plan experiments and define variables
2. **Recording/Tracking:** Collect behavioral data using automated systems
3. **Metadata Creation:** Create metadata files describing experimental conditions
4. **Data Loading:** Import data into `behavr` tables using `damr` or `scopr`
5. **Transformation:** Process and manipulate data using R tools
6. **Analysis:** Apply statistical methods and circadian/sleep analyses
7. **Visualization:** Create publication-quality figures with `ggetho`

### Availability
- **License:** Free academic software
- **Documentation:** Extensive tutorials available at https://rethomics.github.io
- **Repository:** GitHub (open-source)
- **Tutorials:** Both practical and theoretical guides available

---

## Ethoscope Platform

### Overview
The **Ethoscope** is an open-source platform for high-throughput behavioral tracking and analysis, particularly designed for *Drosophila melanogaster* and other small animals. It offers a cost-effective and scalable solution for ethomics (the study of animal behavior).

### Hardware Components

#### Core System
- **Microcomputer:** Raspberry Pi
- **Camera:** High-definition camera for video tracking
- **Physical Structure:** 
  - 3D-printed components
  - LEGO bricks
  - Folded cardboard (highly accessible options)

### Software Capabilities

#### Real-Time Tracking
- Records individual fly Cartesian coordinates
- Tracks multiple parameters simultaneously
- Performs real-time behavioral profiling

#### Machine Learning Integration
- Supervised machine learning algorithms for behavior classification
- Automatic annotation of activities:
  - Walking
  - Micro-movements
  - Inactivity/sleep

### Key Features

#### 1. High-Throughput Scalability
- Monitors numerous flies simultaneously
- Extended period tracking (days to weeks)
- Addresses limitations of manual scoring methods

#### 2. Behaviorally-Triggered Stimuli
- **Unique capability:** Delivers stimuli in feedback-loop mode
- Stimuli triggered by specific behaviors
- Applications:
  - Sleep deprivation (gentle waking when no movement detected)
  - Reward delivery upon task completion
  - Conditional environmental manipulation

#### 3. Customization
- Open-source software and hardware specifications
- Freely available construction plans
- Templates for different arenas (e.g., 20-tube, 30-tube configurations)
- Adaptable for various research needs

### Applications in Neuroscience

#### Why *Drosophila*?
- Simple genetics
- Short lifespan
- Well-characterized neural circuits
- Powerful genetic tools

#### Research Areas
- Sleep and circadian rhythms
- Learning and memory
- Decision-making
- Environmental responses
- Pharmaceutical effects
- Genetic and neuronal underpinnings of behavior

### Advantages
- **Objective:** Removes human bias from behavioral scoring
- **Reproducible:** Standardized protocols and open-source code
- **Cost-effective:** Affordable hardware components
- **Accessible:** Easy to construct and modify

---

## Integration: Ethoscope + Rethomics

### Workflow Integration

#### Data Collection (Ethoscope)
1. Ethoscope performs real-time tracking of individual flies
2. Records behavioral data (position, activity, movement patterns)
3. Can deliver behaviorally-triggered stimuli (e.g., for sleep deprivation)
4. Generates raw data files with timestamps and coordinates

#### Data Analysis (Rethomics)
1. **Import:** Use `scopr` package to load Ethoscope data into `behavr` tables
2. **Quality Control:** Assess data quality and identify outliers
3. **Visualization:** Create actograms and behavioral plots with `ggetho`
4. **Circadian Analysis:** Apply `zeitgebr` tools for rhythm analysis
5. **Sleep Analysis:** Use `sleepr` for sleep pattern quantification
6. **Statistical Analysis:** Leverage R's statistical capabilities

### Example Research Pipeline

#### Optomotor Sleep Deprivation Study
1. **Setup:** Configure Ethoscope with optomotor module for mechanical stimulation
2. **Baseline:** Record normal sleep/activity patterns
3. **Intervention:** Trigger rotation when flies are inactive (sleep deprivation)
4. **Recording:** Continuous tracking throughout experiment
5. **Data Export:** Export Ethoscope data
6. **Import to R:** Load data using `scopr` into `behavr` tables
7. **Analysis:** 
   - Quantify sleep loss with `sleepr`
   - Analyze circadian rhythm disruption with `zeitgebr`
   - Compare experimental vs. control groups
8. **Visualization:** Create publication-quality figures with `ggetho`

### Benefits of Integration
- **Seamless workflow:** From data collection to publication
- **Standardized analysis:** Consistent methods across experiments
- **Reproducibility:** Open-source tools ensure transparency
- **Flexibility:** Adaptable to various experimental designs
- **Efficiency:** Automated analysis of high-throughput data

---

## All Sources

### Optomotor Sleep Deprivation Sources

1. **NIH (National Institutes of Health)**
   - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGTi7J5mMU1QUJmvuHHPzT0z7kuafHrGXMz3upro36JnjxpA-YH3mPJfXs8OySBRLNsCm2M9ubo-FU4fyr6vReJNK8qA9YRNxYgpBV44PBXiwQXL0hEX4XF_jnVTJirB-C8mkfyDXvoJAf1srg=
   - Visual attention and optomotor responses after sleep deprivation

2. **eLife Sciences**
   - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG6ihFslfRtyqGr2DeHQlHRhHjn960xCgqMh_xpZOuLrMEWDsYjonbdVnySpnFA6zxfsFIaE-tne3Q5DsvLUQyV7uiQDrKM_Ul9-JgAi8vfKRszSoRy56Y6OkLKWy93aR2fcDt7dtZgGNIb9IFg
   - Mechanical sleep deprivation methods and ethoscope integration

3. **NIH - Optomotor Module Study**
   - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEI01IAlEAA_n8_2-SzrTVjh506IAMy-vAheRiyTLMxj7cAfeZM5drTk3r0uGmgHQtoa2LnP3gYpq2U_6vvIoTOSGTgGUdUW3y7Qyh8GigPf_5uSHSL5coN_GW2UPe2xfRRvrTgnQ7t9YDhrjML
   - Optomotor module for mechanical stimulation

4. **MDPI**
   - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF06rhkqJZzx4lAcBi9nXM22QYr9Yc3eJl3FR-ynyxJRTR5L3OCAkjjyCl4UOvHDHBwnzWGOIOj1eYrFFxyhopeZh_FWjimEekNz93nrJLbnsg1EHe9zToUNHDGyp94Ss8=
   - Sleep deprivation apparatus and methods

5. **University of San Diego**
   - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFaeatThokLITxgFndKSnaRU1SpfLWgbcnp6m3iJLaUymssuJ1zsfFX2ARG4kNhXhuBbVrwWZsgQ8-RC9mA1IU1t3wNvFNdK2fZbVRwqJ-QvDD1o0iZ5nP42COt-chszksZwf0X33e2oI6ImjTZF_7wyUPaRz4_K93JyCIps0GRmEjGa25OW8XIVFXKhAykQDjExLo6Cx_q4vLe9XxcdyKJtXzpRhhabg==
   - Sleep deprivation protocols

6. **PLOS (Public Library of Science)**
   - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGkxfN0eXNn_iLQFXUwMeXsOb6tjzfYiRztjZeABrUkIMvgTlRqwq76Jgf5GWUQwHT75-NQtA9M-xwmquVwerCNIBjqLPnSDO3AX2dn39uEkLcNN4zdcxiFRWNDFlIaNjO24QO_bH17ZuY0bSeH4i62GB1LnopRSIlcKK4kfQw1eKKrFtgDkorxguE7NPu261YcUGlv1m0dXw==
   - Behavioral analysis methods

7. **NIH - Visual Processing**
   - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHIlmMwg_sf_VFKfn6m3pKf6M1mopJThDccoezskLra9PgO8xsCZNCLKea56deyDREc3PHMT6WNiBcCE4so_uK_lYdC8_skrRqsbCC4uP14Wkv5yhtd6coNuls6r98838i7s-Rg8WsCbNB9ups=
   - Sleep deprivation effects on visual processing

8. **Oxford University Press**
   - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFr4-xeb9ctVVXHofrI0s4Zmja8lVVI5AZ4uJ3PCJ-yG8rseLYjR2-nLPQrIW5cq0gHeRRD1c47XjAezGeWBPQdwE_VSSv1ZiLpzwwcIsg1_cBdMYHChC-HQW9GaAEB0t1wxXcBDjJ9Mf_tlN5HGLIPSKY5vTU=
   - Visual experience and sleep need

### Optomotor Response Protocol Sources

9. **NIH - OMR Testing**
   - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEQ_h3u1-z7_a82a9-oRbBDBsMekIT0B4N54mJcuBqH5yzDrJ_u7mMAs5WbFCoewHMag8L2e8ndtAaVFXua_3FXCjvBKY4RDUtzPOG0JK3hiNqIAvlzAr9XHoTDdonNzozqo6QDdpPwm3RdPA==
   - Optomotor response testing protocols

10. **YouTube - OMR Demonstration**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGaCBzcZBM2gdSk6yaDrGEvZa4m_mS_axsRdSZ7rMRC0si7ZQRwff1wPZSPEfxFEjpVAW5UJjg6RuqO9-MRZT_AGWyOF3PsNK3Jh8tEcgVo1eUeQIP20Kb8lWBSoaRPWYCNZuF8Fg==
    - Visual demonstration of OMR apparatus

11. **Frontiers in Neuroscience**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE70McokD2mgbm4NY7j7VKxLUZmnYOEBEhZznLssZO1hm_QxbUwJ2AilGsD7F8FUMO60c_0G2evrEaVQpxz1i9JHjaLjJsNk7BWY9bOWj01Y4t2bf3Kh1fi_UAZ-v3PNIh7QPdSpCWTYhr5hX67GnDl4PYUmWtIrd-8tuqP8_xG5HQPE95eOwX8Igylyko9GB6nbqTZGXKliCIp
    - Sleep deprivation methods review

12. **NIH - Sleep Deprivation Chambers**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFwe2n5x57a8hBQXOFvnJwKQNvWc-P_j7lZNjZQWYmGgE1UE1WWyTmtNkioH84aSzNT0WEbkCXL8ZCdphGzOvF8Ip5HIaihHhDwjXn6N5wgpLuDCZ1D514uaPZ2wfnegScctKrEYpNROFMDow==
    - Automated sleep deprivation systems

13. **Conduct Science**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF7VdHDqBXsu44gTtPbE1YK3Y-2BbNvwcRyT9IcUz7ppiSdhQqibGCP2lo99fVd9tOqQgngzkO3EnPTqwIkAFNkuptXxr5OAGiG82gP9CmEN77uOM0lHruzL29tSNbfwkN4Js3ihzQ6DMgH8c8_lFRBXBBOuNtmQK0pecUi4N-WbgIiPSs=
    - Sleep deprivation behavioral testing

### Rethomics Framework Sources

14. **PLOS ONE - Rethomics Paper**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH2toA7K26U-XXg4R0l2Tvm5XDRZ5xI7kxScV4fQ10K8vDo7WKn2O9RXj4fOy5Gqp1GlaYtdwG2wkr6xyYGV3u7oeoImM3b6JJQngpAJsneld-pMQDy23xS-f2ohX8EgpDwvrdqkE9A6GEUMcDjZ-FJFMyG_3Lk4RXkAxL7GtItFAkbNvQ=
    - Primary publication on rethomics framework

15. **NIH - Rethomics Overview**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFLgKhWtjLSNAKfIrOS_d0zFPJT4evZEhIaidyHgRY8g2TMAndScbEzKtl_nh6h037glovZHzZ6shgFPyYEffGkQZgLcezzPvKiG7Sqm7Q1G5lJb9WhkFIdaixVGegMf3zKSEnLa0KkE6B26jc=
    - Behavioral data analysis framework

16. **bioRxiv - Rethomics Preprint**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH8ZkdPdYtB46xy8I_4_VfRpLw1JY7Za7ZoAWEiuIgz3QV31TmNhvz9gjFeyYV8AxYjc-FHTmuWFXryqL1vPTbDZRVyAYXo79kR3BcD1418fvickH8NkNbGXeMrjU4VjQyzHBKsI5E46s_4eQ==
    - Early version of rethomics publication

17. **Rethomics GitHub Pages - Main Documentation**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEQfnyVZ29c52ou28PVayMN_-gn6wH2k9BXnf0CpW0OrgwHREjlEmSC3I_RyoahuQVUUgnm_q83oHD1jmlBTomi_vB_9HhH3tZvFOAGPy1qJeAJ4w-2x1s=
    - Official documentation website

18. **Rethomics GitHub Pages - Workflow**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEOOSmxUs1Y-yllrq9zs4psRsLtS6yGEVDgRm1lucSwwnMBBfTJh4b9YZet7PbvxQsb3SRdPP9im8kniFv4Qpl6ITBaTaZpv15DLUXFoNaqWGBf3IfmyUXeApmqH25j3VrToR0X
    - Detailed workflow documentation

19. **NIH - Circadian Analysis**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHnsS5q2AbIsqRLMqGAq5XoNUbuKnaD5tUtauUzrVBYQUK60iWedaZijFw8iSZh1oa8rI0ti2XUooEHNigVa3K74DsfwyDzqpdd-8Wi9fqve3B2aYcFSZPEEcJWOXktVXFmP5--lVp1OWE_yQ==
    - Rethomics for circadian rhythm analysis

20. **PLOS ONE - Rethomics Application**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHwl9jCuLt6HB4e6M0Veddqpe75LCbJ5BESyN12kMbn0cIYYqoVcOURVip299edjhvsR5vRLPatELwJp7obgltlHXcrTGEewjthPFIqSwcw_4nSs33IjE5J0ge6j4nLJlC2OOZ4FfO-mB4QstPQxSfNAdElvZvz9OH4Eqk-G86AIAcXFQ==
    - Application examples

21. **ResearchGate - Rethomics**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG43skJNvf1e__OhyEOWGyDujCMNEuddMm0YDOo6AYm4WXWm4oZdGeLFtWz8ll8CoQkZozPkjJUxHX3VW02L2xA1yoe9s8v0ycGjm8BcnZhGFZI1Si1nyM56EL-ShUxdBRvQO84kCV9Bt-3YUtw1JjMTzWDx5p6oQbh3Hwe9B69aQKe3IqIdgCqv94vhzfXfGGnqq-Gpo9Tagoat_MeOyfluXs0uil_J65KDBJ5yszPl2Q=
    - Research publication

22. **Rethomics GitHub Pages - Package Overview**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFDnJE_26-0SYF9i9EQIMn4wUcvyyzjE2Q9Tdi9n-px3gEYx7T4qbw6LTjdq8xFSj5uRP3gD8D7D-aRlMbOzAKJ2_WyU1mBc2zSqHjEWKKh82gDZbs8148yukwyrEk6gAs=
    - Package documentation

23. **Rethomics GitHub Pages - Tutorial**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGWFyRpa4i3IgXh5wkfBO4EaG5FUtM1XySwuXFFzyLgvj6KPctixgmHA1zjdlisF4IBYfYMb80VXerwA6i--cF7GFfM8AFdvKR1LcWkYlM383oXZ4Ua-w==
    - Comprehensive tutorials

24. **GitHub - damr Repository**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGoTK0tiz2297cUUP6Ta4kCg71YBn8SR3wwiMBxf2qoUNatadI_eVH1PWTQo1c0BbLtHl_TYnUX6NImqO0275adlVN0GN-L_HgsFeXWiCj3DMHgy4OBknMUkl7PEQ==
    - DAMS data import package

25. **GitHub - scopr Repository**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF9ywK6SDrWAig7yHME5GuR8lZZR5KccRToEoQDdQ_4HtwROAhwM7ma9zpOg9hHGFDg3-dLu1-xVKs2pt2kcxxyMQ-Y8UEFmPeyzErCwERrtDqAtMIL_qSWqO57
    - Ethoscope data import package

26. **bioRxiv - zeitgebr**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHusWEuNm1pT4qBfuzhSze14r_icZvlJ9mbInh3AvSUaVErlC584awAGUU6gUoP1OxlD3EQ6CVh9XV1t6ZvMDpwOaKYIxTAbBKvaYRRNbJOo_mofgCDrw9FfZ-jOeoBNgiaBzeO9OkVHu8YxVUO_biyud2h
    - Circadian analysis package

27. **GitHub - sleepr Repository**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHFU-cAvOZjsfHQ4rNQVrUF9fJd0mYEvCUyIq6B7k9SNWXKk6f8n1deFEnT7ilNgFUcUThBeqIojunoSjSEGw89ydY9vufzbiHZ3z4fqZ9A8T9F3Of3yDl__cfYZNw=
    - Sleep analysis package

28. **Rethomics GitHub Pages - sleepr Documentation**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFDMfIFV9onGDUQB7XWYoYi074tD4HGUghlx_CgrtWOaXEoSX59vxh-FqbX4EalzD5nryF2_6xvrZHfIhRU5GFxtIIwml2uf_4bp7I_vWjza9B2VUE_9Dt0cR7ptI036eo=
    - Sleep analysis documentation

### Ethoscope Platform Sources

29. **bioRxiv - Ethoscope Platform**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEg97NUz2KPAF9UbFulKYbXvuvTDlt8OA7E9-CQL9JazQRIrnevZmvFA2IwKwLu3WvI1G3fGs7JkcIlVQ6Nf2fDP4E2tmfJzZrzwDBCd6CXyrMgynB2GZGWrCDMh-gUU_sOiazIT8Z0RrJBNMeVqXXMwynfuQ==
    - Original ethoscope publication

30. **Gilestro Lab**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEDas_bfAuY1PLXrCSp74chud4Ly4yV3b6YEpKkfIc-gB57udJTOC7qhxmDzmbJDaw8bwGbxRDDFlYSIDkWPrMAg_wIcJFSdhyEViblCUDb_jJ6fqQKGBlldG7Sibv3ROMNEj-uScwyEZSnIlwBBnxaIZczgjWWK1Y1BAvcbGWrQgkUEbrfyNq2DX6cmBy-zcw=
    - Ethoscope development and documentation

31. **NIH - Ethoscope Behavioral Tracking**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQENHkIrY9WPUhUigLEuns5IH6HEMccsDs2fgenWljLxzectBb5iiYSWua6K-uT1hEtT2twkYVhp4SCMRixaa8wnCLgFZRUUcsAIez9Wi4YYFsITw75PeManxnfhnMlVEorChxBD
    - Behavioral tracking applications

32. **PLOS ONE - Ethoscope**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHz53KiPR6paPEC4qiyDBauNNz72BTd9wzO2cKEy12eljtZZ_vXiYJf1kvro0JXEbTMgmTKa0gnnuyN35RfkZWzZSiTscTUDK22xcUjHjYOb9S0Wc4rAVGejt5W5gIfScko-4JEWDVq0muIzugQwOgQkyOpc_xvaJ7LjmnBReXDhlT53VzmXc7i
    - Ethoscope methodology

33. **NIH - High-Throughput Behavioral Analysis**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFbvka4wN83vbnOd39UPER0Nk30jmU_6i1Ml8eSLypj_b22wXcso1wbCwI8_sobvel4WUF068XV7G9E-t-6mjlzPuuAqJyFkPeehDEUAtTymi-NE-VkeZJzsBSXf-rBHTdDgWGKLA0-iAmCoU4=
    - High-throughput applications

34. **Open Electronics**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGOzTM9oa4HxaP4aVXV1sfBn3eVnCia4HxUPKqi1T4dPDRumt1fib-LYj3MQrXQW946TVuYDhck_g-eRCTJkqHJ4pEQbf8fau-3ftIpY3uDpJizzUYeHQurDyFft-TaEKsU7IlkzGZXhxL-gSOPEhpLzdiaSlFWkJiDTrXNX_0DjJC92Mgnec-RRALaE3WBrS7yFT3QVg-W6axzEphzxssY0ZLDMKtSPe9J46ktaV9I1pw=
    - Hardware construction guide

35. **ResearchGate - Ethoscope**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFTxXyf4EMXxJMqum2lbRnNIGwoX0w9Glf3kc_VhaUowc3ORGi76vu4WFRONiUQXIHEHSQ7bZ3D8xeeu-LYmlgkKMfug051TV0CkQdPZS_WKS6bkaW_SvX3yNYCPKAdbvFwK4yfM2ichUuS4rcZ8WEnoGa2qAole03iBMHodzIwL34oCGYlnj95rh0bLLb4mvUPkMY9m0RXky4AiIanAnuU9lgi5DQn1g==
    - Research applications

36. **Jamasb.io - Ethoscope Tutorial**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFrr9vVZr4qE0cYhuNSNTh2P9V8O9fww6NxNCE1hTxqYGAyxdXqRvmeWatHTBU6aDH9GX8RPtuWtEmk3Fhnrzr2geIM_Bpr-7Xc_0SanTWQj3HYwmsGCXkXYCQX
    - Practical tutorial

37. **EurekAlert!**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGx9Y7mGXzoChvHl22uFc96LndBRhsduclwKlxl6TIYW8mnLwwr5uMPGRTe0ratR2E566rCzYIX5mlc0U47jsiHlhNX0Lh5uGKG5XJu5uN-XCpPM-KPlz3jU1gkpVzu3A2o5mxohHckPuZq
    - Press release and overview

38. **GitHub - Ethoscope Repository**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFL2ETDT2kpAlY17sRp5lZ-_7Z345afjbF06pPpemDSDJ1u-uR_Eym8ITgvhkMhtO_E_Zgu262VJ8Y80HA2YcsYg0qiTORha9FKdF9KLjdt3U2KEVR6xbMckXmtMSGm_1K2PA=
    - Source code and templates

39. **University of Kentucky**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF3quy6nO--Hu99hptT54jOaOs8DVQfjND6qLuwoZFSQRWsvK4KJ8sXPQFoBFIzHq4AFI-lu8Cg0Ron_yjWX_BGOv8rqPCYFghvyfHBJUzFfvJ8wfVGV-hoOsKWGBSS-7EpMUrltvshLZQVZ5wQy_kHrxHevooPwl3k58pOx0GBZhExG8rnMjZJgkbay1VZEfZ83y3P7KbZ_tFJq5IhBymQ14X7pCW9TfNqAMxiFAMpM3BrrovRoQ==
    - Neuroscience applications

40. **American University**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF5mLEjh83zbw9n3PLYTu-_K6FwHhnK92cOeshR8L5P0ZfBxn7iA2OOeVStS5hMN5m82mnHMzhnTMknR0cVfoCUxyTB2pMqLBDniqo58UHuUr0KVgGHW93MQGJQJ9xe75_l-7LiwCT-nr768lWOn69lQ5Fv81FthrI=
    - Educational resources

41. **Tulane University**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGTuGypD3LUKGcfwMpxhDG8zFZnnReKHveD6tv1kg9OWHmC9xUs-v4tno_aZzHuMCCC0zxuGTlFjIZy03Pim9K1CYCeY-epcx2rp6uFpXYjdDplHKAhFL_yQ02D2BlP6EO-b3Ywl7inBR4hHRtACabmxVcWcqjNKtetkrDuMP9F-HWNrNzl7_TpixcwXYba-ikl8qzFU7wEwXe2ApnGE1S4SnSrpXtypeS7qwYq93Bykfoqcg==
    - Research implementation

### Ethoscope + Sleep Deprivation Integration Sources

42. **eLife Sciences - Mechanical Sleep Deprivation**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFEpNh_BvKBfbezaWMJPKT_amDfCuXwv70FeF5x-cru-fif9KiB5Azea5OTa_z_nAifI1zEUUsWEKd_AxgwR-d_-NpdmKEe2LV5CqJ72Oa1sMrro-JwVhJw_-KL39hQ-SvqUc4=
    - Ethoscope-based sleep deprivation

43. **bioRxiv - Optomotor Sleep Deprivation**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGweINQmfau_eL2Nw0wA8hxvaDG4TI81EMQU9O1Czta61PO6tBulj6BNIXjpWHXnHz_STl5g-c33N8BOmh5Hz1gOnLhot8czvrdotWVz5POrvZG6PQqu6vRhd9qR6muQ3GRRIxYbIlTAzatgNy_IAxmGxaCxQ==
    - Behavioral feedback sleep deprivation

44. **NIH - Targeted Sleep Deprivation**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEy8TKnjhvAoboQ6l_KLvbCjYVTWS6erUsXknSfh2plgT1Nt5w1IkNfZ-sEfYc2Dc5Tyqgwdt0IEuHD3ch5LcQvinCOVUjZht-OBSa-vqaXaqhp4iuAJFX4t6maB3qntFQ33fd_3I2vLmmBzEw=
    - Targeted mechanical stimulation

45. **NIH - Sleep Homeostasis**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHUMg6hLoLLWXX1tgB9nmS3zrLGTXjtaRdKzuZAwUvmyimgFu-Ny3LiJjNGVJ4BhaJHA_3bEvdk8mQCrpdNtGe71v8NFNC158Rm-0o0DzHKCK70dpQCbwfrTjlKTJ5a6GKyWMODXMH11OQpfDCP
    - Sleep homeostasis studies

46. **NIH - Yoked Controls**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHMqeAQcivlaU0f6CICUildu-E2QZFU6p3UA4ME0-3BJDFVHMz_0oQggxqaYK40LgDli8ombE35RovIJ-30tfoOATOfB0l3x9tP80x55p2S9pjZ6Tw4W4yGKct6AysPbGN7fSGAGZvH2LoMZNtY
    - Experimental controls for sleep deprivation

### Rethomics Tutorial and Package Sources

47. **PLOS ONE - Rethomics Tutorial**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFRQKvooX63ZGRHI5eMyNjgJ0S3AMw-mipshyHdQ1tGxjUGy19VKnv7QdTvbzpVL1DdnY5tCWvnH-z_zNAuvXKucJ9j1V9cpY30cMnRJLLj9e_t10W0f55l2j1Xxw2C1j1JAiFgyLV0zfs3oozya1PYkN5SUG0K3UOTfwxOQcH06EuoVMs=
    - Comprehensive tutorial

48. **NIH - Rethomics Framework**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFp2ulbO6Ow1YXUpHXWPrVV_QjoApIL3s9nhEYX2khNwo1REHmYq_icUHiP22grt_rA0iSamh887S5zFg1Mzli6dqtRZuPW6a-RByLnqm7uBdfnlRrbIM_l-Xb5vxeh6KoOZXcKf56MMH6HSw=
    - Framework documentation

49. **GitHub - Rethomics**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGmFKbogoIYOpmaTDRcdqBy7qvvR4f1yYzGIE4-nrGluv6_XdPmfhh0BFLvU5khXDGj9vINDCJD4ccOYmTz8EwB3yJ4i6ZMWJnDXDKkVsR4nCA7k2cajF0=
    - Source repository

50. **bioRxiv - Rethomics Methods**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGv1lDO10tEwoGHdNPzzP5NQWoKvfc70840OMibhvrwHgmMTOvaKjOqVAjRc_S3__pH3xh_I3dwhHBnH0Zsu9W9nX0fZNkgiNPXE2uuka7wZrN2tNsgV9HnOVZnA7qGndnmyIuqY7i-5zTu4YClrWUvMLXHA==
    - Methods paper

51. **Rethomics GitHub Pages - Main Site**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFcn5YqzGAFl0mBHtQafSvcONVQB3cNB_piy1WmX2CQUucef-Lbk6twNfRapmF3r4fSPgjra5pQnaApNEGiJW7AgAQHmagEz2-u5FVugIQLuVZUFea-fjk=
    - Official website

52. **Rethomics GitHub Pages - Getting Started**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEZClx80pRl9LCmLUJ8n5L55vAd-mg9gHo810QQZzWr9qS5rdCDEUXW2gJycopPQFuK1tMyWOQGlBUdcKemtMV7-DyxrWSSFT1QTkM6AseOLyJ59j2wjxJFUOSuhhjz1moB
    - Getting started guide

53. **R-Project - damr Package**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG963wDYX5fSGITowOXux0YnpvznjoKGbdsqzfVKlOJQTL1WIKnAF1VhkfRzXnZRgqoBm5wkaYK-1H-TGV5e7A5rJel52K2oCSEXHQPzSqb44vyrLhxZr4mJpTL6mCNF5kK7_R-qajtPJKXNzdNI7in
    - CRAN package page

54. **R-Project - damr Documentation**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEjL-3m6Kcx6VBjKLH2oCLav0p7kgYali0-vubE_PTUQzIQaPIbskJBxBLTbaUpeSqt5qmvMMCDwHc62NN41VgzMw6S8_-Un0CA4E2Z4O5s-WpVnbKD5jUc8JrssnN-LTDPFA==
    - Package documentation

55. **RDocumentation - scopr**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFa4SzWiv8TAz7dEtuP80377_qB3fAwKUywwQ0-I629bQ79xyBHwEehlVPEbiRTaZ5ASoUeFLzdEJPBV1xXglSEv4CuCGJttUpzlNAV7f7hiVta3OWtRe5dMUNmPbPwjQHCjcyflHth5vZaPOBArcr3-vqKgHQDUQ==
    - scopr documentation

56. **R-Project - scopr Package**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHbfzYqkJQRtCFSYH9pjcZelTGUYSWrdWyflU7FTRIA0Y7jlbkrbho0AaL_Mo4z9kCcL8Afs0G1dGAa6ICmjO1tBT9O79Dh8resOw7HwhvQIb95nijMONzwBSjkbuu2jpXo2VMJZ2k4TuOLuVRWS-yttcLuaEPMqFkLeA==
    - CRAN package page

57. **R-Project - scopr Functions**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE4hVrkf0BciNWM2Mu63d_wmCT9LeYuYgR5kIz1NIVvMsShwFRZLtYCRM0nLGtk4fMm-0bOFtY-yqgFr7lQ_8ypSkN9irmnE7MRNW5_L78v-Or40FPXUG5-56c_eqL31K5L91I6YPFQWNicNx4OrafdZUc=
    - Function reference

58. **Rethomics GitHub Pages - zeitgebr**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGlA9sD0O7DsLa8FkGkkVk8yOehPF3yTt6_OJRSast__zN0AhAYC-B5DBGT28jMXgHu_V_ywGkOmSOZEsK2VTIQIml_U0lbMq-j5ePA-6ppHL71nIxOXAyQH7d5qNOukjW9pQ==
    - Circadian analysis tools

59. **Rethomics GitHub Pages - sleepr**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGOknEhj-y12F8KpNSmYqmTbg7UVtYHVJgbirDgBfqxjx1QYKhbeuTqmf5q8-gQ888cJ92XcLa6_qYFZvKM3MN1R4PLu7URd5CDA-kVIqTMAtwUzBE4wNEEovqL_mFm-hMrzncV
    - Sleep analysis tools

60. **RDocumentation - damr Tutorial**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFYmZbDaa_jI5PcqJ5JMSmpQuJbd2GGcBV2-cwswI08MAApoDOyOlGM4jezMSdOz2dSfRbr7yXSB5dhTEMnNQ7pGCiz5co8pn7msgqihhZ4MPNPlX-Uj6lS-tSLr1dR3WVcIJNI0JH0cv_kkd53_LSaLPb3Lbc1
    - damr tutorial

61. **Rethomics GitHub Pages - damr Tutorial**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG9he3fTeXfCZDpd2VpGb59YpO-pc6QhF-Asb2Y10bnhiE1jVAcbXhpm_G-6tdhpdV0XZY16ueKRdNfrxkgtfeNl8e2cl-swD-jJxszGFnkNqmB3udSLgKFX-Yflo2ycEM=
    - Comprehensive damr tutorial

62. **GitHub - damr Examples**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEv9_pFfKb0cQHWR0J1l7Y7V5kRs4PTjsyVlPOerC6YHR5F4HSV8E7QSqHS3_bJ-EdmUVM8FhuTGOFw-8cM4gIyhUHCW7MrvpX3Au0jzqS1qjK_4E0KXrbxMCo_Ew==
    - Example code

63. **Rethomics GitHub Pages - scopr Tutorial**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFTeT3h0cQl7m_DxPzmFx7wflgT9qK6M2FUcMSaZtvLrjBTdmrsJuCiZcMmw9b3OwuNuwS36_OzE0AFxNW_2aFDrf0-2kN7f4oyMIoRlk6X7zeALq2xdhp2uFjEHddhy0V2
    - scopr tutorial

### Additional Resources

64. **Zantiks - Rethomics Integration**
    - https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGMgFTRvaqYh_Q9S1I46p_Lp3-iaABZG1N4X8_MLrL3Baf0K0ZfjIspaDDXZErBR3ROb1shx0G23nYxHypmJngVehUKfskwJItF-rT7WRWQmy7S2FFc75hQPHYSm5QypWv_rUf8k-6eRgjeebyJmWf7qwm8vyVQdv21HwsyaURE3-3HK56ufQ==
    - Commercial integration

---

## Summary

This research report provides comprehensive information on:

1. **Optomotor Sleep Deprivation:** A targeted method for inducing sleep loss in *Drosophila* using mechanical stimulation triggered by behavioral inactivity, particularly useful for studying sleep homeostasis while minimizing stress.

2. **Rethomics Framework:** An open-source R-based toolkit for analyzing high-throughput behavioral data, featuring modular packages for data import (`damr`, `scopr`), visualization (`ggetho`), circadian analysis (`zeitgebr`), and sleep analysis (`sleepr`).

3. **Ethoscope Platform:** An affordable, open-source behavioral tracking system using Raspberry Pi and machine learning for real-time monitoring and behaviorally-triggered stimulation in *Drosophila* research.

4. **Integration:** The combination of Ethoscope for data collection and Rethomics for analysis creates a complete, reproducible workflow from experimental design to publication-quality results.

All sources are provided above with direct links to the original publications and documentation.
