# SWE-gen-C++ (work in progress) 

<p align="center">
  <a href="https://github.com/abundant-ai/SWE-gen-JS">
    <img src="assets/swegen-cpp-banner.jpg" style="height: 20em" alt="SWE-gen C++ banner" />
  </a>
</p>

> X C++ tasks generated from Y open-source GitHub repos using [SWE-gen](https://github.com/abundant-ai/SWE-gen).

## Each task
- is a merged GitHub PR with 1-10 source files edited
- has Fail-to-Pass unit tests
- passes NOP (baseline fails) and Oracle (fix succeeds) validation

## Getting Started

Install [**Harbor**](https://github.com/laude-institute/harbor):

```shell
uv tool install harbor
```

Run with Codex:

```shell
export OPENAI_API_KEY=<YOUR-KEY> 
harbor run --dataset swe-gen-cpp \
   --agent codex \
   --model openai/gpt-5.2-codex \
   --n-concurrent 4
```

This command automatically downloads the tasks.

<p align="center">
  <img src="assets/pie_chart.png" style="height: 20em" alt="SWE-gen C++ pie chart" />
</p>

