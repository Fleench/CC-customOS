# CustomOS Architecture & Implementation Plan

This document outlines the architectural roadmap and planned features for the next iteration of **customOS**. The OS is evolving from a monolithic kernel script into a modular, capability-secure operating system with a rich graphical ecosystem.

---

## 1. Modular Kernel Architecture & Load Order
The bootloader will iterate through the `/sys/modules/` directory, loading kernel modules alphabetically. Modules run in a privileged state and can call each other's global functions directly, whereas userland applications must use syscalls. 

The planned load order is:
1. **`00_config.lua`**: System-wide configuration registry (loads base settings).
2. **`01_perms.lua`**: Capability token minting and validation engine.
3. **`02_vfs.lua`**: Virtual Filesystem. Secures the filesystem immediately by intercepting the `fs` API.
4. **`03_process.lua`**: Process manager and scheduler. Handles environment isolation and injects the `syscall()` function into userland apps.
5. **`04_users.lua`**: Single-user authentication and password storage.
6. **`05_sudo.lua`**: Privilege elevation module. Prompts for the admin password and injects all capability tokens for temporary elevation.
7. **`06_net.lua`**: Network sandbox. Intercepts `rednet` and requires a `net` capability token.
8. **`07_hw.lua`**: Hardware sandbox. Intercepts `peripheral.wrap` and `peripheral.find`, requiring specific tokens (e.g., `hw:disk`, `hw:modem`) for dangerous hardware.

## 2. Capability-Based Security & Syscalls
The OS replaces standard security models with a capability token system.

* **The Syscall Interface:** Userland applications communicate with the kernel strictly through a single globally injected `syscall("action", ...)` function, drastically reducing the attack surface.
* **Dynamic Request System:** When an application is launched via the `process` module, it requests capabilities. If unapproved, the kernel pauses and prompts the single admin user for approval.
* **Persistent Approvals:** Granted capabilities are recorded by the kernel.
* **`sudo` Elevation:** For administrative tasks, `sudo` pauses execution, verifies the user's password, and temporarily grants the target app a master token.

## 3. System Shell & Package Manager
The shell will natively understand the capability model, making background processes and app installations safe.

* **Capability-Aware Shell:** The shell tracks permission contexts for background jobs, processes, and pipelines, ensuring a rogue background task cannot escalate privileges.
* **Built-in Package Manager:** A new utility to download, update, and manage third-party applications.
* **App Manifests (`manifest.lua`):** Apps downloaded via the package manager will include a `manifest.lua` file. This file returns a native Lua table detailing the app's metadata and required capability tokens (e.g., `{ capabilities = { "net", "hw:disk" } }`). The system reads this to prompt the user *before* execution.

## 4. Graphical User Interface & "CANVAS"
The operating system will rely on the **Basalt** UI framework for graphical elements.

* **Multishell Base:** The OS utilizes ComputerCraft's built-in `multishell` feature at its core, providing native top-bar tabs for multitasking.
* **The CANVAS App:** 
  * A flagship graphical application built on Basalt running inside a multishell tab.
  * Acts as a lightweight Window Manager (providing overlapping windows within its own tab).
  * Serves as the primary App Launcher and Settings Menu (GUI-based).
  * Can launch new programs into its own windowing system or out to fresh multishell tabs.

---

### Implementation Next Steps:
1. **Build the Bootloader:** Create the `/sys/modules/` directory and the script that loops through and executes them.
2. **Draft the Modules:** Begin stubbing out `00_config` through `07_hw` to establish the global kernel APIs.
3. **Implement Syscalls & VFS:** Finalize the `process` module's isolated `_G` injection and test it against `02_vfs`.
4. **Draft the Manifest System:** Create a standard `manifest.lua` structure and the Package Manager.
5. **Integrate Basalt & CANVAS:** Load Basalt into the environment and begin drafting the CANVAS app launcher.
