# Telco MicroVM Lab

Firecracker microVMs for telco and infrastructure readers. This repository holds the kernel, the lab scripts, and the AI agent that deploys the lab, from the telco tech series.

- The whole series: [https://afaf-arfaoui.github.io/telco-tech-series/](https://afaf-arfaoui.github.io/telco-tech-series/)

## Episodes

| Episode | Title | Link |
|---|---|---|
| 01 | MicroVM's theory | [Read](https://afaf-arfaoui.github.io/telco-tech-series/episode-01-what-is-a-microvm.html) |
| 02 | MicroVM in practice | [Read](https://afaf-arfaoui.github.io/telco-tech-series/episode-02-microvms-in-practice.html) |
| 03 | Deployment with an AI agent | [Read](https://afaf-arfaoui.github.io/telco-tech-series/episode-03-deployment-with-an-ai-agent.html) |
| 04 | What is a UPF? | Coming soon |
| 05 | Basic eBPF | Coming soon |
| 06 | Inside the eUPF | Coming soon |
| 07 | Make the microVM useful | Coming soon |
| 08 | Deploying the AI agent | Coming soon |
| 09 | Monitoring the deployment | Coming soon |

## What is in this repository

- `kernel`: the Linux 6.18.63 kernel with BPF and BTF enabled, attached to a release (see Download below).
- `scripts/`: the lab scripts from the series, described below.

## Scripts

The scripts are written for Ubuntu and run with `bash`. They work in the lab folder `~/Desktop/microVMs`.

### check-prereqs.sh

Checks that your laptop is ready for the lab. It only reads information. It never installs, downloads, or changes anything.

It checks six things: the processor type, access to `/dev/kvm`, the programs the lab needs, free disk space, the Internet route, and whether Firecracker is installed.

```bash
bash check-prereqs.sh
```

Each line starts with `PASS`, `FAIL`, or `NOTE`. A `FAIL` line is followed by the fix. The script exits with code 0 when everything passes and with code 1 when a check fails.

### fetch-artifacts.sh (coming soon)

Downloads the Firecracker release, the Firecracker CI kernel, and the Ubuntu root filesystem into the lab folder. It asks before each download and skips files that already exist.

```bash
bash fetch-artifacts.sh --dry-run
```

The `--dry-run` option shows what would be downloaded, without downloading anything.

## Download the kernel

Get the latest release:

[https://github.com/afaf-arfaoui/telco-microvm-lab/releases/tag/kernel-6.18-btf](https://github.com/afaf-arfaoui/telco-microvm-lab/releases/tag/kernel-6.18-btf)

Download these two files:

- `vmlinux-6.18-btf.gz`, the compressed kernel
- `vmlinux-6.18-btf.gz.sha256`, the checksum

### Verify and unpack

Put both files in the same folder, then run:

```bash
sha256sum -c vmlinux-6.18-btf.gz.sha256
gunzip -k vmlinux-6.18-btf.gz
```

The first command should print `vmlinux-6.18-btf.gz: OK`. The second creates `vmlinux-6.18-btf`, which goes into your `kernel_rootfs` folder.

### How the kernel was built

- Source: Linux 6.18.63 from kernel.org
- Configuration: the running configuration of the Firecracker CI 6.18.56 guest kernel, with these options enabled: `BPF`, `BPF_SYSCALL`, `BPF_JIT`, `BPF_EVENTS`, `KPROBES`, `KPROBE_EVENTS`, `FTRACE`, `TRACING`, `PERF_EVENTS`, `XDP_SOCKETS`, `CGROUP_BPF`, `DEBUG_INFO`, `DEBUG_INFO_DWARF5`, and `DEBUG_INFO_BTF`
- The steps are explained in episode 02.

## Requirements

- Firecracker with the Firecracker CI guest image
- Linux 5.15 or newer inside the microVM, which this kernel meets

## License

- The kernel is licensed under GPL-2.0, as is all Linux kernel source.
- The scripts and the documentation: to be chosen (see the note below).
