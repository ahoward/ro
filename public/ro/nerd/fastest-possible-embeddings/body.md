### TL;DR;

> today i figured out the fasest possible way to generate embeddings locally with open source tools avaiable today


---
**update 2025-02-24**

@kris (https://github.com/khasinski) helped me with this -> https://gist.github.com/ahoward/2a1d45499ac9e755d802dbcbaf401b71

it.  is fast #af.


---
i tried 4 approaches, based on *extensive* research and lots and lots of testing in my work from the past 8 mos.

i've been busy building 'socially informed AI'.   essentially, a giant,
curated, enahanced, and distilled RAG database of over a million conversations
across a thousand subreddits, domains, etc.  it's a vast database of
a million conversations that can be brought to bear for literally **ANY** task
one might do with **AI**.

i have a beta program now.  ping me directly if you want an **API** key.  it
will be developer-first in the immediate future.  it's a sharp tool i don't
want used for the wrong purposes at this juncture.   a self serve product is
in the works... more on that soon.

anyhow, let's say i need to generate embeddings for all these conversations.
what *is* the fastest way?

i tried 4 methods:

1. ruby wrapper around https://mistral.ai/
2. ruby wrapper on https://ollama.com/
3. rust command line program https://github.com/Anush008/fastembed-rs
4. node command line programm using https://github.com/Anush008/fastembed-js

##### here is the ruby code to generate embeddings with mistral.  very short.  very easy.  i expected this, to be the slowest, although it took me only 5 minutes to write.

```ruby
    #! /usr/bin/env ruby

    require 'mistral-ai'
    require 'json'

    input =
      ARGV.shift

    prompt =
      input == '-' ? STDIN.read : IO.binread(file)

    mistral =
      Mistral.new(
        credentials: { api_key: ENV.fetch('MISTRAL_API_KEY') },
        options: {
          connection: { request: { timeout: 420 } },
        }
      )

    model =
      'mistral-embed'

    result =
      mistral.embeddings(
        { model: model,
          input: inputs,
        }
      )

    embedding =
      result.fetch(:data).fetch(0).fetch(:embedding)

    json =
      JSON.generate(embedding: embedding)

    puts json
```
<br>

##### next, i installed https://ollama.com/ and wrote this silly ruby wrapper to use it.  bout 3 minutes to write.

```ruby
    #! /usr/bin/env ruby
    require 'json'

    input =
      ARGV.shift

    prompt =
      input == '-' ? STDIN.read : IO.binread(file)

    model =
      "mxbai-embed-large"

    data =
      {prompt:, model:,}

    cmd =
      "curl -s 'http://localhost:11434/api/embeddings' -d '#{ data.to_json }'"

    json =
      IO.popen(cmd).read

    puts json
```
<br>

##### finally, i wrote a rust and node/javascript version (see below) which were much longer and took a little time to produce, even **with** ai codebots, vs-code, and a pile of shit to install.

the numbers.  roughly, for a 4 page document, on my linux lappy, which is pretty dang beefy but **not a GPU**

```code
drawohara@drawohara.dev:disco[main] #=> cat /proc/cpuinfo | mistral-ai

The information you provided is the output from a command like `lscpu` or `cat /proc/cpuinfo` on a Linux system, detailing the specifications of each processor core in a multi-core AMD EPYC 7713 64-Core Processor. Here's a breakdown of the key details:

### General Processor Information
- **Vendor ID**: AuthenticAMD
- **Model Name**: AMD EPYC 7713 64-Core Processor
- **CPU Family**: 25
- **Model**: 1
- **Stepping**: 1
- **Microcode**: 0xa0011d1
- **CPU MHz**: 1999.999 MHz (2 GHz base frequency)
- **Cache Size**: 512 KB (L2 cache size per core)
- **Physical ID**: 0 (Indicates it is part of the same physical package)
- **Siblings**: 4 (Indicates the number of logical processors per core, due to hyper-threading)
- **CPU Cores**: 4 (Number of cores reported by this logical processor)

### Core-Specific Information
- **Core ID**: Ranges from 0 to 3 (Indicates the specific core within the physical package)
- **APIC ID**: Ranges from 0 to 3 (Advanced Programmable Interrupt Controller ID)
- **Initial APIC ID**: Ranges from 0 to 3

### CPU Features
- **Flags**:
  - Standard features: `fpu`, `vme`, `de`, `pse`, `tsc`, `msr`, `pae`, `mce`, `cx8`, `apic`, `sep`, `mtrr`, `pge`, `mca`, `cmov`, `pat`, `pse36`, `clflush`, `mmx`, `fxsr`, `sse`, `sse2`, `ss`, `ht`, `syscall`, `nx`, `pdpe1gb`, `rdtscp`, `lm`, `constant_tsc`, `rep_good`, `nopl`, `xtopology`, `nonstop_tsc`, `aperf`, `eagerfpu`, `pni`, `pclmulqdq`, `dtes64`, `monitor`, `ds_cpl`, `vmx`, `est`, `tm2`, `ssse3`, `cx16`, `xtpr`, `pdcm`, `pcid`, `sse4_1`, `sse4_2`, `x2apic`, `movbe`, `popcnt`, `tsc_deadline_timer`, `aes`, `xsave`, `avx`, `f16c`, `rdrand`, `lahf_lm`, `cmp_legacy`, `cr8_legacy`, `abm`, `sse4a`, `misalignsse`, `3dnowprefetch`, `osvw`, `skinit`, `wdt`, `nodeid_msr`, `topoext`, `perfctr_core`, `perfctr_nb`, `bpext`, `ptwrite`, `mwaitx`, `cat_l3`, `cat_l2`, `arat`, `pln`, `mce_am`, `powercnt`, `ssbd`, `ibrs`, `ibpb`, `stibp`, `vmmcall`, `fsgsbase`, `bmi1`, `hle`, `avx2`, `smep`, `bmi2`, `erms`, `invpcid`, `rtm`, `cqm`, `mpx`, `rdseed`, `adx`, `smap`, `clflushopt`, `clwb`, `sha_ni`, `xsaveopt`, `xsavec`, `xgetbv1`, `xsaves`, `avx512f`, `avx512dq`, `avx512pf`, `avx512er`, `avx512cd`, `avx512bw`, `avx512vl`, `prefetchwt1`, `clzero`, `avx512ifma`, `avx512vbmi`, `umip`, `pku`, `ospke`, `waitpkg`, `avx512_vnni`, `avx512bitalg`, `rdpid`, `fsrm`, `vaes`, `vpclmulqdq`, `arch_capabilities`
- **Bugs**: `sysret_ss_attrs`, `null_seg`, `spectre_v1`, `spectre_v2`, `spec_store_bypass`, `srso`

### Performance and Cache Information
- **BogoMIPS**: 3999.99 (A relative measure of processor speed)
- **TLB Size**: 1024 4K pages
- **Clflush Size**: 64 bytes
- **Cache Alignment**: 64 bytes
- **Address Sizes**: 48 bits physical, 48 bits virtual

### Power Management
- The output does not provide specific details on power management features, but modern CPUs like the EPYC 7713 will have various power management capabilities.

### Summary
The AMD EPYC 7713 is a high-performance server processor with 64 cores and advanced features such as SMT (Simultaneous Multi-Threading), large cache sizes, and support for a wide range of instruction sets and security features. The output shows that each physical core has 4 logical processors due to hyper-threading, and all cores are part of the same physical package. The processor operates at a base frequency of 2 GHz and includes numerous features and capabilities suitable for enterprise-level computations.
```
<br>

##### the results really surprised me

1. ruby + remote mistral api call = ~ 1.75 seconds per embedding
2. ruby + local ollama api call = ~ 1.5 seconds per embedding
2. javascript + fastembed-js = ~ 0.7 seconds per embedding
2. rust + fastembed-rs = ~ 0.3 seconds per embedding

so, here is my math:


```ruby

NUMBER_CONVERSATIONS_IN_DISCO =
  1_000_000

SECONDS_PER_CONVERSATION =
  (0.3 .. 1.7).to_a.sample

TOTAL_SECONDS =
  NUMBER_CONVERSATIONS_IN_DISCO * SECONDS_PER_CONVERSATION

TOTAL_MINUTES =
  TOTAL_SECONDS / 60

TOTAL_HOURS =
  TOTAL_MINUTES / 60

TOTAL_DAYS =
  TOTAL_HOURS / 24

```
<br>

basically, with rust + fastembed-js (the fastest): **about 4 days run-time to do all the embeddings**

with ruby + mistral-ai (the slowest): **about 20 days run-time to do all the embeddings**

so, rust is a clear winner yes?  despite a whole tool chain of depenencies needed, compilation steps, integration into ci, etc.?

> ##### NOT SO FAST

remember, what i showed about my machine.  for each of the approaches that run
locally, include ollama, rust, and javascript, i am

**limited by how many cpus i have**

through testing, i have found that running about 4 at a time gives the fastest throughput.  ymmv.

whereas, with mistral, i can run using the `parallel` gem and process **20 at a time with mistral**, due to API limits. and this is *stunningly* easy:

```ruby

  prompts =
    []

  rps =
    20

  embeddings =
    Parallel.map(prompts, in_processes: rps) do |prompt|
      embedding_for(prompt)
    end

```
<br>

yes, i **do actually have a rate_limter** but, since they take > 1 second each that simple code actually never hits the limit ;-)

finally, here is **the main thing**

> 4 days / 4

**==**

> 20 days / 20

because math.

and, actually, with batching i can make the mistral version quite a bit faster, about 10x.

so the moral is this

> the simplest and easiest solution was the best.

and

> premature optimization is the root of all evil.

someone [very clever once said that^^^^^!](https://wiki.c2.com/?PrematureOptimization)

in nearly 30 years doing both big, and i mean [really big](/nerd) data and science with ruby, i have yet to meet a better [VHLL](https://en.wikipedia.org/wiki/Very_high-level_programming_language) to model my abstractions in, and to get shit done **FAST**

for sure, i occasionally will need to drop into rust or c but, those cases, are more rare than you might think and, often, reaching for the 'big guns' too fast just wastes time.

certainly, anything in-between a VHLL and a compiled lang is a waste of time,
money, and effort.  here's looking at you javascript and pythong (ssss 🐍)!  haha ;-)

ps.  because i can hear you thinking

> i can call APIs in pythong (🐍🐍🐍🐍sssss) and js too

and, of course, this is true.   especially if you enjoy worst-in-history
dependency management, security issues, version churn, and really really like
writing 10x the LOC to accomplish the same damn thing that still blow up with
horrible stack traces of parallism in production your dev-ops team (fire them)
still can't figure out no matter how many parameters they tune.

next article is about dependency **hell** in pythong.  the time i worked at a
"really great firm" that was "expert in python" (ssssss 🐍🐍🐍🐍🐍) and showed
them that, depsite 4 months of trying by thier principals, they could not
manage to have fewer than 4 versions of python running in CI and **no one
even knew**.  but i will save that rant, for another day.
