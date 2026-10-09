# Features to add/research

## Return address stack

## OpenSBI

# Superscalar, OoO design

## What to build
1. Fetch with branch predictor + recovery on mispredict
2. Decode and register rename
3. Reorder buffer 
4. Issue queues?
5. Load/store queues
6. Make sure exception, interrupt, and csr handling works. 

## Steps
1. In-order scalar pipeline (extension stage 1)
2. Reorder buffer with in-order issue. 
3. Rename + out-of-order issue (small issue queue)
4. Load/store queue + disambiguation (?) and forwarding
5. Widening the front end and adding pipes. 

## Existing designs
**NaxRiscv (SpinalHDL)** is a parameterizable OoO core that has run Linux on FPGAs, and is probably the closest to what you describe. 
**BOOM (Chisel)** is the best-documented academic one. 
**VexiiRiscv**, from the same author as NaxRiscv, is another to study. 
**Hennessy and Patterson**, and Shen and Lipasti's Modern Processor Design, cover the theory.

## Designing the in-order core so OoO fits later

The idea is to put every OoO building block in the in-order design as a simple version, so later you replace pieces instead of rewiring the whole core. I'm drawing on general architecture practice, not measurements on your device.

### Pass micro-ops, not instruction bits
Decode once into a uop struct and let every later stage use only that struct.
- Fields: operation class, source register indices, destination index, immediate, "uses rs1/rs2" flags, a sequence ID, and a small exception record.
- Nothing after decode should look at raw instruction bits.
- Later, rename edits the register fields of the same struct, and the ROB stores the same struct.
- Define it once as a SystemVerilog typedef struct in a package.

### Give every instruction a sequence ID from the start
Assign a monotonically increasing tag at decode (a small wrapping counter).
- It lets you say "flush everything younger than tag X", which is exactly what a branch mispredict needs, in-order or out-of-order.
- It becomes the ROB index later, and it is how the load/store queue orders accesses.

### Make exceptions precise, taken at one commit point
- Attach exception info to the uop as it moves down the pipe, and act on it only at the last stage.
- Update architectural state only there. That means register writeback, CSR writes, and store release. In an in-order pipe it's "free", but it is the structure a ROB's retire stage later replaces.
- Treat interrupts the same way: pick them up at commit, not mid-pipeline.

### Separate execution units from the pipeline
Give each unit (ALU, branch, load/store, multiply/divide) a uniform interface:

- Issue side: valid/ready, the uop, and the operand values.
- Result side: valid, tag, destination, result value, and exception info.

Don't assume a unit's latency. If everything uses handshakes, a slow multiplier or a cache miss just delays a result, which is the situation an out-of-order core has all the time. A shared result bus with arbitration for the register-file write port is a good rehearsal for the real thing.

### Use valid/ready handshakes between stages, not a global stall
A single global stall signal is hard to keep once things complete out of order. Elastic pipelines (each stage has its own valid/ready) scale naturally to queues, and they make inserting a buffer, such as an issue queue, a local change.

### Hazards through a scoreboard
Track a "busy" bit per register: set when an instruction that writes it issues, cleared at writeback. An instruction waits at issue until its sources are not busy.

- This is the simple precursor to wakeup logic. Later the busy bits turn into ready flags in an issue queue, and register indices turn into tags after rename.
- Put the check behind one module with a clean interface so it can be swapped.

### Keep the register file behind an interface
- Reads and writes take a register index and a port number. The port count should be a parameter.
- On an FPGA, remember that block RAM and LUT RAM have limited ports, so replication or banking will eventually matter. Hiding that behind the interface means you can change it without touching the pipeline.
- Keep register index widths as parameters, so physical register numbers (wider than 5 bits) can go in later.

### Decouple the load/store unit and treat it like it's already speculative
- Buffer stores in a store buffer, and send them to memory only when they commit. This is the in-order version of a store queue.
- Loads should check the store buffer first (store-to-load forwarding). It's simple in order and the base for the load/store queue.
- Mark peripheral and uncached accesses as non-speculative, so they happen only at commit (or when they're the oldest instruction).
- Give the memory interface a request/response handshake with a tag, supporting several outstanding requests, as described for the cache.

### Make the front end its own block
- Fetch should output packets with a valid mask and a predicted next PC, even if it's always one instruction wide now.
- Redirects (branch mispredict, exception, fence.i) come in through a single "redirect" input carrying the sequence ID.
- Put the branch predictor behind a predict/update interface. Start with "predict not taken" or a simple BTB, and improve it later without touching the rest.

### Serialize the awkward instructions
- CSR accesses, fence, fence.i, wfi, ecall, atomics and cache operations are easiest if they execute only when they are the oldest instruction. Give them a "wait until oldest, drain the pipe" path now. Out-of-order cores do the same thing, so the logic carries over unchanged.

### Parameterize widths and sizes
- Define XLEN, fetch width, issue width, queue depths, and the number of functional units as parameters or package constants. Use generate loops for replicated units. Writing a 1-wide pipe in a form that doesn't assume 1 costs little now and saves a lot later.

### Build the verification harness first
- Output an RVFI trace (RISC-V Formal Interface) from the commit stage: one record per retired instruction, with PC, instruction, register writes, and memory accesses.
- Run it in lockstep against Spike or a Sail model in simulation, and with riscv-formal for formal checks.
- Because the retire interface is fixed, the same testbench works for the in-order and the OoO core. That is the best insurance you can buy against reworks.

# Extensions
## Stage 1: the minimum that works
### Extensions
**RV32I**: The base ISA. Everything else is built on it.
**Zicsr**: CSR instructions, which traps and counters need.
**Zifencei**: fence.i, needed when code is written to memory (bootloaders, debuggers).
**Machine mode**: mstatus, mtvec, mepc, mcause, mtval, mret, plus a timer interrupt.

This is enough for bare-metal C and an RTOS like FreeRTOS. The GCC flag is -march=rv32i_zicsr_zifencei.

## Stage 2: what almost every real program wants
### Extensions
**M**: Hardware multiply and divide. Software emulation is slow. The multiplier maps well onto the Artix-7's DSP blocks, and a divider can be a small multi-cycle unit.
**C**: 16-bit compressed instructions. Code gets about 25-30% smaller, which matters when program memory is BRAM. The cost is that fetch must handle 2-byte-aligned instructions that can straddle words.
**Zicntr**: cycle, time and instret counters. Cheap and useful for benchmarking and for the OS tick.
**Zba, Zbb, Zbs**: Basic bit manipulation (shift-and-add, bit counting, rotates, single-bit ops). Small to implement, and compilers use them when allowed.

Target string: rv32imc_zicsr_zifencei_zicntr_zba_zbb_zbs. I'd stop here for an RTOS system.

## Stage 3: systems features
### Extensions
**A**: Atomics (lr/sc and amo*). Linux requires it, and multi-master buses and RTOS locks use it. You'll need a reservation mechanism and a way to hold the bus.
**Zicbom** (and optionally Zicboz): Cache clean, flush and invalidate by address, which makes DMA with a cache practical, as discussed. **Zicboz**: adds cbo.zero for fast buffer clears.
**PMP (Smpmp)**: Physical memory protection, so lower privilege levels can be restricted to regions of memory.
**User**: M plus U modes give you basic protection even without an MMU.
**Zihintpause, Zicond**: Optional. pause helps spin loops, and czero.eqz/czero.nez give cheap conditional moves.

## Stage 4: running Linux
### Extensions
**Supervisor mode (S)**: Linux runs in S-mode, with its own CSRs and trap delegation.
**Sv32 MMU**: Page tables, a TLB and page-fault exceptions. This is the largest single piece of work, as I said earlier.
**Sstc**: A supervisor timer comparison register, so Linux doesn't call firmware for every timer tick.
**Svade or Svadu**: How hardware handles page accessed and dirty bits. Check what your Linux version expects.
**Svinval**: Finer-grained TLB invalidation. Optional.
**Platform pieces:** A CLINT (or ACLINT) for the timer and software interrupts, and a PLIC for external interrupts. These aren't ISA extensions but Linux needs them.

Linux on RV32 is less common than RV64, so check the current state of kernel and C library support before committing to it. One alternative is an MMU-less (nommu) build of Linux, which skips S-mode and Sv32 and needs only stages 1-3.

# Tests

riscv-tests, rv32mi, riscv-arch-test, random instruction streams (riscv-dv), formal checks (riscv-formal, YosysHQ)