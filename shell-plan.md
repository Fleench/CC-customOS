# CC-customOS Shell & GUI Architecture Plan

This document outlines the architectural roadmap for the user space, shell, and graphical environment of CC-customOS. 

## 1. The Core Stack
The GUI ecosystem is divided into four distinct components, separating the rendering engine, the custom shell, the persistent menu, and the window manager app.

### Layer 1: Basalt (Rendering Engine)
* **Role:** The raw graphics and event handling framework.
* **Function:** Draws pixels, renders basic UI elements (buttons, text), and captures mouse/keyboard events.

### Layer 2: WIMP (Window Interface & Multishell Protocol)
* **Role:** The Custom Shell and Compositor.
* **Function:** WIMP replaces the native CC:Tweaked shell and `multishell`. Built using Basalt, it acts as the underlying compositor that handles:
  * **Tab Management:** Exposes functions to request a new tab to be opened and manages switching between them.
  * **Panel Drawing:** Exposes functions for drawing global panels/overlays (like a top bar or dock).
  * **Security Integration:** Hooks deeply into the kernel capability system to pause background processes and securely draw system-level approval prompts over the active tab.

### Layer 3: ATMIN (All The Menus I Need)
* **Role:** The Persistent System Menu.
* **Function:** 
  * Acts as the main app launcher and system menu.
  * ATMIN draws *on top* of WIMP (utilizing WIMP's panel/overlay drawing functions).
  * Parses installed app manifests (via the Package Manager) to display icons and required capability tokens.
  * Uses WIMP's functions to request a new tab whenever the user launches an application.

### Layer 4: CANVAS (The Window Manager App)
* **Role:** The desktop workspace app.
* **Function:** A dedicated Window Manager application that runs as a tab inside WIMP.
  * Holds the desktop background.
  * Allows users to spawn multiple overlapping, windowed applications *within* its specific WIMP tab.
  * Ideal for multi-tasking several smaller apps on a single screen rather than using full-screen WIMP tabs.

## 2. Integration with Kernel Security
The entire GUI stack respects the kernel-level sandboxing and capability token system.
* **App Manifests:** ATMIN reads `manifest.lua` for apps to display required tokens before launch, keeping the user informed.
* **WIMP Security Dialogs:** If an app dynamically requests a capability, the kernel pauses the app and WIMP securely draws the system-level approval prompt over the active tab, ensuring malware cannot fake approval screens.
