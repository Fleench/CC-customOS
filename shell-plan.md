# CC-customOS Shell & GUI Architecture Plan

This document outlines the architectural roadmap for the user space, shell, and graphical environment of CC-customOS. 

## 1. The Core Stack
The GUI ecosystem is divided into four distinct components, separating the rendering engine, the custom shell, the persistent menu, and the window manager app.

### Layer 1: Basalt (Rendering Engine)
* **Role:** The raw graphics and event handling framework.
* **Function:** Draws pixels, renders basic UI elements (buttons, text), and captures mouse/keyboard events.

### Layer 2: WIMP (Window Interface & Multishell Protocol)
* **Role:** The Custom Shell and Tab Manager.
* **Function:** WIMP replaces the native CC:Tweaked shell and `multishell`. It is the full custom shell environment that handles:
  * **Tab Management:** Spawning and switching between different environment tabs.
  * **Security Integration:** Hooks deeply into the kernel capability system to pause background processes or switch security contexts.
  * **System Prompts:** Standardized security dialogs (e.g., capability token requests like "App X wants to access hw:disk") drawn securely above the tabs.

### Layer 3: ATMIN (All The Menus I Need)
* **Role:** The persistent App Launcher and System Menu.
* **Function:** 
  * Acts as an always-there, persistent menu (similar to an Android home screen or OpusOS launcher).
  * Tied deeply into WIMP, serving as the primary way users launch new tabs or access system settings.
  * Parses installed app manifests (via the Package Manager) to display icons and required capability tokens.

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
