# Reading List: Microarchitecture Techniques for Building an Out-of-Order RISC-V Core (2026)

No single document catalogs every technique used in modern processors. The closest thing is Smith & Sohi, "The Microarchitecture of Superscalar Processors" (Proc. IEEE, 1995). It is free and short, and it covers the whole fetch → rename → issue → memory → commit framework. Pair it with the free BOOM and NaxRiscv documentation to see how those ideas look in real RISC-V RTL, and with a textbook (Hennessy & Patterson 7th ed. or Shen & Lipasti) for depth.

## TL;DR
- **Read first, in this order:** (1) Smith & Sohi 1995 (free); (2) the BOOM docs and the SonicBOOM paper (free); (3) the NaxRiscv docs (free, and built for Xilinx 7-series FPGAs); (4) a deep textbook, either H&P 7th ed. Ch. 3 plus Appendices B/C or Shen & Lipasti (both paid); (5) the Sorin/Hill/Wood/Nagarajan *Primer on Memory Consistency and Cache Coherence*, 2nd ed. (free, open access). Onur Mutlu's free ETH/CMU lectures make good companion videos.
- **For each block:** branch prediction → Seznec's TAGE papers plus BOOM/XiangShan BPU docs. Rename/ROB/issue → BOOM docs. LSQ/disambiguation → Chrysos & Emer's store sets plus the BOOM LSU docs. Caches/prefetch → H&P Appendix B, Mittal's prefetching survey, Jacob et al. MMU/TLB → Jacob et al. Ch. 31 plus the XiangShan/NaxRiscv MMU docs. Memory ordering → the Primer. Verification → riscv-formal/RVFI, riscv-dv, riscv-arch-test and Spike lockstep co-simulation.
- **Budget reality check:** NaxRiscv is an OoO RV32/64 core that boots Linux. Its README reports its high-performance configuration at "13.3 KLUT on Artix 7-3" (155 MHz). By my calculation from AMD's DS180 data sheet (5,200 slices × 4 LUTs per slice), an XC7A35T has 20,800 LUTs, so that core alone uses about two-thirds of the chip. Plan to start with gshare+BTB+RAS (as NaxRiscv does), and put TAGE, value prediction and SMT on the "later or bigger FPGA" list.

## Key Findings

1. **The best single "catalog" is still Smith & Sohi (1995).** It is a 27-page tutorial in Proc. IEEE vol. 83, no. 12 (Dec. 1995), pp. 1609–1624. It splits superscalar design into five phases: instruction fetch and branch processing; register dependence determination (rename); issue; communication through memory via loads and stores; and in-order commit for precise interrupts. It illustrates them with the MIPS R10000, DEC 21164 and AMD K5. That is almost exactly the list of blocks you plan to build. It's free from the author: https://jes.ece.wisc.edu/papers/superscalar.pdf (mirror: https://ftp.cs.wisc.edu/sohi/papers/1995/ieee-proc.superscalar.pdf).

2. **Open-source core documentation is the most practical "technique catalog" for an RTL designer.** The BOOM docs walk through each structure you named: Fetch Target Queue, backing predictor, rename snapshots, ROB, issue queues with wake-up, LSU and memory-ordering failures. NaxRiscv is the closest analog to your project. Its README describes an OoO, register-renaming RV32/RV64 IMAFDCSU core that is "Superscalar (ex : 2 decode, 3 execution units, 2 retire)" and runs Linux/Buildroot on hardware. It has a BTB+gshare+RAS predictor and a hardware-refilled Sv32/Sv39 MMU, and explicitly uses Xilinx 7-series as its reference target.

3. **TAGE is the state of the art, but not where to start.** Pierre Michaud's ACM TACO paper "An Alternative TAGE-like Conditional Branch Predictor" states that "All four branch prediction championships between 2006 and 2016 were won by André Seznec with a TAGE based predictor." Those were L-TAGE in 2006, ISL-TAGE in 2011, and TAGE-SC-L in 2014 and 2016. Seznec (now at SiFive) published a TAGE-SC for CBP2025 and a "TAGE engineering cookbook" (Nov. 2024). SonicBOOM and XiangShan both implement TAGE variants. On a 35T, gshare is the pragmatic first step.

4. **Textbook status in 2026.** H&P's *Computer Architecture: A Quantitative Approach* is now in its **7th edition** (Hennessy, Patterson and new co-author Christos Kozyrakis; Elsevier lists it as October 24, 2025, 936 pages). P&H's *Computer Organization and Design RISC-V Edition* is still at the **2nd edition** (December 2020) per Elsevier. Shen & Lipasti is still in print as a 2013 Waveland reissue of the 2005 text. The *Primer on Memory Consistency and Cache Coherence* (2nd ed., 2020) is open access under CC BY 4.0.

## Details: Categorized Reading List

### A. Textbooks

| Title | Authors / Year | What it covers (for you) | Cost | Link |
|---|---|---|---|---|
| Computer Architecture: A Quantitative Approach, 7th ed. | Hennessy, Patterson, Kozyrakis, 2025 | Ch. 3 on ILP, dynamic scheduling, speculation and branch prediction; review appendices on pipelining and memory hierarchy; new GPU/DSA coverage (useful for your later GPU idea) | Paid | https://shop.elsevier.com/books/computer-architecture/hennessy/978-0-443-15406-5 |
| Computer Organization and Design RISC-V Edition, 2nd ed. | Patterson, Hennessy, 2020 | Ch. 4 (RISC-V pipeline) and Ch. 5 (memory hierarchy, VM, TLB). This is the prerequisite level; skim it if you've already built an in-order core | Paid | https://shop.elsevier.com/books/catalog/isbn/9780128203316 |
| Modern Processor Design: Fundamentals of Superscalar Processors | Shen, Lipasti, 2005 (Waveland reissue 2013) | The most implementation-focused superscalar text. Chapters on advanced instruction-flow techniques (branch predictors), advanced register data-flow techniques (value prediction and similar), P6 and PowerPC 620 case studies, and multithreading | Paid (~$115–118 list; e-book via VitalSource) | https://www.waveland.com/browse.php?t=624 |
| Digital Design and Computer Architecture, RISC-V Edition | S. Harris, D. Harris, 2021 | Gates up to single-cycle, multicycle and pipelined RISC-V in SystemVerilog/VHDL. Companion site has slides and labs; free edX MOOCs ENGR85A/B | Paid book, free MOOCs | https://shop.elsevier.com/books/digital-design-and-computer-architecture-risc-v-edition/harris/978-0-12-820064-3 |
| Memory Systems: Cache, DRAM, Disk | Jacob, Ng, Wang, 2008 | 982 pages on caches, DRAM controllers, power, reliability and **virtual memory (Ch. 31)**. Use it as the MMU/DRAM-controller reference | Paid | https://www.sciencedirect.com/book/monograph/9780123797513/memory-systems |
| A Primer on Memory Consistency and Cache Coherence, 2nd ed. | Nagarajan, Sorin, Hill, Wood, 2020 | Sequential consistency, TSO and relaxed models, coherence protocols, and a chapter on specifying and validating consistency and coherence. This is how to think about RVWMO, fences and LSQ ordering | **Free (open access)** | https://library.oapen.org/handle/20.500.12657/61248 |
| A Primer on Hardware Prefetching | Falsafi, Wenisch, 2014 | Classes of instruction and data prefetchers, plus examples from real CPUs | Paid / institutional (Synthesis Lectures) | https://dl.acm.org/doi/10.5555/2643033 |

### B. Survey and classic papers (technique catalogs)

| Paper | Year / venue | Why read it | Free? / Link |
|---|---|---|---|
| Smith & Sohi, "The Microarchitecture of Superscalar Processors" | Proc. IEEE 1995 | The canonical end-to-end catalog | Free: https://jes.ece.wisc.edu/papers/superscalar.pdf |
| Seznec & Michaud, "A Case for (Partially) TAgged GEometric History Length Branch Prediction" | JILP 2006 | The original TAGE paper | Free on Seznec's page (link not individually verified): https://team.inria.fr/pacap/members/andre-seznec/ |
| Seznec, "A New Case for the TAGE Branch Predictor" | MICRO-44, 2011, pp. 117–127 | Cheaper hardware implementation of TAGE, plus statistical-corrector ideas | Paid at ACM (DOI 10.1145/2155620.2155635); author copies usually on the page above |
| Seznec, "TAGE-SC for CBP2025" | CBP 2025 | Current "realistic" TAGE-SC with 7 tagged tables; points to the 2024 TAGE engineering cookbook | Free: https://ericrotenberg.wordpress.ncsu.edu/files/2025/06/cbp2025-final37-Seznec.pdf |
| Chrysos & Emer, "Memory Dependence Prediction using Store Sets" | ISCA 1998 | *The* memory-disambiguation predictor (SSIT + LFST tables). gem5's O3 CPU still uses it: its MemDepUnit names `StoreSet depPred` as "The memory dependence predictor", citing Chrysos & Emer | Free: https://people.csail.mit.edu/emer/media/papers/1998.06.isca.storesets.pdf |
| Mittal, "A Survey of Recent Prefetching Techniques for Processor Caches" | ACM CSUR 49(2), 2016 | Taxonomy of HW/SW prefetchers | Paid at ACM (DOI 10.1145/2907071); preprint copies circulate |
| Zhao, Korpan, Gonzalez, Asanović, "SonicBOOM: The 3rd Generation Berkeley Out-of-Order Machine" | CARRV 2020 | Real-RTL lessons: TAGE in hardware, superscalar LSU with multiple loads per cycle, short-forward-branch recoding, next-line prefetcher; 6.2 CoreMark/MHz | Free: https://carrv.github.io/2020/papers/CARRV2020_paper_15_Zhao.pdf (slides: https://carrv.github.io/2020/slides/CARRV2020_slides_15_Zhao.pdf) |
| Mutlu et al., Runahead Execution | HPCA 2003 (HPCA Test of Time Award 2021) | Memory-latency tolerance; optional advanced reading | Via Mutlu's publication page: https://people.inf.ethz.ch/omutlu/projects.htm |

**Other items you mentioned.** I did not verify these individually in this research pass. They are well known, but check the links yourself: Mittal's other CSUR surveys (cache locking, DRAM power management, embedded energy efficiency); Hill & Marty, "Amdahl's Law in the Multicore Era"; Esmaeilzadeh et al., "Dark Silicon"; a value-prediction survey; the SIGARCH "Computer Architecture Today" blog; IEEE Micro Top Picks; ISCA/MICRO Test-of-Time lists. Of these, only Mittal's DRAM-power and cache-locking surveys connect directly to your build. The rest are background.

### C. Real-core microarchitecture write-ups

- **Agner Fog, "The microarchitecture of Intel, AMD and VIA CPUs"**: free, last updated 2026-05-23. It's the best free description of how commercial x86 front ends, renamers, schedulers and LSUs actually behave: https://www.agner.org/optimize/microarchitecture.pdf. The companion instruction tables were updated 2025-09-20.
- **Vendor disclosures:** AMD's Hot Chips 2024 Zen 5 deck (free PDF) shows what "modern" means today: 2 predicted-taken branches per cycle, dual fetch/decode and op-cache pipes, 8-wide dispatch, 6 ALUs, 48 KB 12-way L1D and 4 load pipes: https://hc2024.hotchips.org/assets/program/conference/day2/24_HC2024.AMD.Cohen.Subramony.final.pdf
- **Dan Luu, "Branch prediction"** (2017): the best gentle on-ramp from 1-bit counters through two-level, gshare and agree predictors to reading modern papers: https://danluu.com/branch-prediction/
- **Chips and Cheese, WikiChip, AnandTech archives, and Intel/AMD/Arm optimization manuals** are excellent for real-core numbers. I did not verify specific URLs in this pass. Note that AnandTech stopped publishing in 2024, so treat its articles as an archive.

### D. Open-source core documentation (most practical)

- **BOOM / SonicBOOM docs**: https://docs.boom-core.org/en/latest/ (PDF: https://docs.boom-core.org/_/downloads/en/stable/pdf/). Sections cover the 10-stage conceptual pipeline (Fetch, Decode, Rename, Dispatch, Issue, RegRead, Execute, Memory, Writeback, Commit), the Fetch Target Queue, backing predictor and GHR repair, rename snapshots, the ROB (banked circular buffer, PNR), the issue unit (age-ordered and unordered queues, wake-up, speculative issue), and the memory model and ordering failures. Caveat: users on the BOOM mailing list have asked when BOOM v4 documentation will appear, so the docs may lag the current RTL. Use them for concepts, not exact signal names.
- **NaxRiscv** (SpinalHDL): https://spinalhdl.github.io/NaxRiscv-Rtd/main/NaxRiscv/introduction/index.html and https://github.com/SpinalHDL/NaxRiscv. The repository README reports "2.93 DMIPS/MHz, 5.02 Coremark/MHz … @ 155 MHz + 13.3 KLUT on Artix 7-3". The frontend page explains FPGA-friendly rename (free list in distributed RAM, speculative and committed maps) and a 2-D unified issue queue. There is also a third-party CEA-Leti doc with "OoO basics" notes: https://github.com/SpinalHDL/naxriscv_doc. For your board, read this before anything else in this section.
- **XiangShan** (Kunminghu V2R2 design doc, CC BY 4.0): https://docs.xiangshan.cc/projects/design/en/latest. The BPU chapter is a near-complete modern catalog: uBTB, ahead-BTB, micro-TAGE, main BTB, TAGE, statistical corrector, ITTAGE, RAS and history management. The LSU chapters cover load/store/atomics units. Caveat: the older general microarchitecture docs are outdated for Kunminghu.
- **CVA6, VexiiRiscv, Chipyard**: all relevant. CVA6 is an in-order Linux-capable core with a clean MMU/PTW; VexiiRiscv is NaxRiscv's in-order sibling. I did not re-verify their documentation URLs in this pass.

### E. Courses and lecture series (free unless noted)

- **Onur Mutlu, ETH Zürich Computer Architecture** (taught every fall; the Fall 2025 materials are online): https://safari.ethz.ch/architecture/fall2025/. Videos: https://www.youtube.com/onurmutlulectures. CMU 18-447/18-740 archive: https://www.youtube.com/@CMUCompArch. His slides cover OoO, precise exceptions, branch prediction, runahead, prefetching and memory controllers.
- **Princeton ELE 475 (Wentzlaff)** as the Coursera course "Computer Architecture": https://www.coursera.org/learn/comparch. Free to audit; covers pipelining, superscalar/OoO, VLIW, branch prediction, caches, vectors and multiprocessors.
- **Berkeley CS152/252A**: Spring 2026 site (past semester) at https://inst.eecs.berkeley.edu/~cs152/sp26/. Slides and homework are public; recordings may need a Berkeley login. The resources page links Sodor, Rocket, BOOM and Chipyard.
- **MIT 6.823 → 6.5900**: OCW Fall 2005 lecture notes at https://ocw.mit.edu/courses/6-823-computer-system-architecture-fall-2005/. Current public lecture PDFs at https://csg.csail.mit.edu/6.5900/.
- **Georgia Tech HPCA (Prvulovic, Udacity ud007)**: covers Tomasulo, ROB and LSQ very clearly, and the CEA NaxRiscv notes are based on it. Class Central now lists it as "No Longer Offered", so treat the Udacity link as unreliable. Individual lesson videos remain on YouTube.
- **Not verified in this pass:** UW-Madison CS 752, Cornell ECE 4750, Stanford EE282.

## Recommendations: map documents to the pieces you'll build

| Block you're building | Read (in order) |
|---|---|
| Overall framework | Smith & Sohi 1995 → H&P Ch. 3 (or Shen & Lipasti Chs. 4–5) |
| Front end: BTB, RAS, gshare → TAGE | Dan Luu post → BOOM "Branch Prediction" and FTQ sections → NaxRiscv frontend → Seznec 2006/2011 → XiangShan BPU doc → TAGE-SC CBP2025 |
| Rename / ROB / issue queues | BOOM rename, ROB and issue-unit pages → NaxRiscv frontend (FPGA-friendly rename and issue) → Shen & Lipasti "advanced register data flow" |
| LSQ and memory disambiguation | BOOM LSU and memory-model pages → Chrysos & Emer store sets → SonicBOOM paper (multi-load LSU) |
| Caches and prefetching | H&P memory-hierarchy appendix/chapter → SonicBOOM (non-blocking cache, next-line prefetcher) → Mittal survey / Falsafi & Wenisch primer → Jacob et al. for DRAM |
| TLB / MMU / Linux | P&H RISC-V Ch. 5 (VM basics) → Jacob et al. Ch. 31 → NaxRiscv (hardware-refilled Sv32/Sv39 MMU) and XiangShan MMU chapters → the RISC-V privileged spec (Sv32/Sv39; spec link not checked in this pass) |
| Memory ordering / fences / atomics | Sorin/Hill/Wood/Nagarajan Primer (free) → BOOM memory model page → the RVWMO chapter of the RISC-V unprivileged spec |
| Verification | See below |

**Verification stack for a hobbyist OoO core** (from the follow-up research; all links live as of October 2026 unless noted):
- **riscv-formal + RVFI** (https://github.com/YosysHQ/riscv-formal; docs at https://yosyshq.readthedocs.io/projects/riscv-formal/en/latest/quickstart.html). A SymbiYosys formal framework that supports multi-retire cores (`RISCV_FORMAL_NRET`). Expose an RVFI retirement port from your ROB commit stage on day one. Note the open issue about RVFI support for multiple register writebacks.
- **Spike lockstep co-simulation.** Spike (https://github.com/riscv-software-src/riscv-isa-sim) compiled as a shared library and stepped alongside a Verilator DUT, as NaxRiscv does (https://spinalhdl.github.io/NaxRiscv-Rtd/main/NaxRiscv/simulation/index.html). Ibex's documented cosim API (https://ibex-core.readthedocs.io/en/latest/03_reference/cosim.html) is the cleanest reference design. Chipyard/BOOM do the same through testchipip's SpikeCosim, and FireSim offers "Cospike" for single-core BOOM.
- **riscv-dv** (https://github.com/chipsalliance/riscv-dv) for random instruction streams, including page-table/MMU stress and interrupts. The main generator needs a commercial SV/UVM simulator; use its Python generator (pygen) or the eUVM port instead.
- **riscv-arch-test / ACT** (https://github.com/riscv/riscv-arch-test, now under the `riscv` GitHub org) for self-checking compliance tests with Sail-derived expected results.

**My recommended order for you:** Smith & Sohi (one evening) → NaxRiscv docs (because they target your FPGA family) → BOOM docs section by section as you build each block → H&P 7th ed. or Shen & Lipasti as the reference → the Primer once you start the LSQ and fences. Watch Mutlu's lectures alongside. Also, get a scalar in-order RV32 core with an MMU booting Linux on the 35T, with RVFI and Spike cosim in place, *before* adding rename and a ROB. Debugging an OoO core without a lockstep reference model is the most common way projects like this stall.

## Caveats
- **Not verified in this pass:** H&P 7th-edition online appendices being free (earlier editions hosted extra appendices online; check the Elsevier companion site); the claim on a free-book aggregator site that P&H RISC-V has a "free online edition" (treat as unreliable); Chips and Cheese, WikiChip and CPU-world URLs; Mittal's non-prefetching surveys; Dark Silicon, Amdahl's Law in the Multicore Era and the value-prediction survey; CVA6, VexiiRiscv and Chipyard doc URLs; Fabien Sanglard articles; the "latency numbers" list.
- **Conflicting publication dates:** Elsevier lists H&P 7th ed. as October 24, 2025, while Google Books shows December 2, 2025. Shen & Lipasti's list price appears as both $114.95 and $117.95 on Waveland pages.
- **Docs may lag the code:** BOOM v4 documentation, and XiangShan's general microarchitecture docs for Kunminghu.
- **FPGA sizing:** the XC7A35T's 20,800 LUTs is my own calculation from AMD's DS180 data sheet (v2.6.1), not a figure AMD states directly. DS180 lists 5,200 slices for the part and says "Each 7 series FPGA slice contains four LUTs and eight flip-flops". NaxRiscv's 13.3k-LUT figure is for a specific "high perf" configuration and excludes caches and peripherals.
- **Recent commercial-core claims** (e.g., Zen 5's two-ahead branch prediction, cited secondhand via Wikipedia) are vendor or press descriptions, not independent measurements.