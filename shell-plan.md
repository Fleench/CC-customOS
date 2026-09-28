# CC-customOS Shell & GUI Architecture Plan

This document outlines the architectural roadmap for the user space, shell, and graphical environment of CC-customOS. 

## 1. The Core Stack
The GUI ecosystem is divided into four distinct layers, separating the rendering engine, developer toolkit, window manager, and user interface.

### Layer 1: Basalt (Rendering Engine)
* **Role:** The raw graphics and event handling framework.
* **Function:** Draws pixels, renders basic UI elements (buttons, text), and captures mouse/keyboard events.

### Layer 2: WIMP (Window Interface & Menu Protocol)
* **Role:** The CC-customOS Developer API / Desktop Environment Wrapper.
* **Function:** Sits on top of Basalt to provide OS-specific components.
  * **System Prompts:** Standardized security dialogs (e.g., capability token requests like "App X wants to access hw:disk").
  * **Window Decorators:** Wraps app UI frames in standardized borders (Title bars, Close/Minimize buttons).
  * **Layouts:** Provides pre-built grid components for launchers.
  * **Theming:** Stores global color palettes that instantly sync across all WIMP-compliant apps.

### Layer 3: CANVAS (The Window Manager)
* **Role:** The blank slate desktop workspace.
* **Function:** A dedicated application that acts as the Window Manager.
  * Holds the desktop background.
  * Manages the drawing order and focus state of overlapping WIMP-wrapped windows.
  * Can be run inside its own tab.

### Layer 4: ATMIN (All The Menus I Need)
* **Role:** The persistent App Launcher and System Menu.
* **Function:** 
  * Acts like an Android-style home screen or a persistent OpusOS launcher.
  * Relies on WIMP for its grid layout and UI elements.
  * Parses installed app manifests (via the Package Manager) to display icons and software.
  * When a user taps an app in ATMIN, it commands CANVAS to spawn a new window for that application.

## 2. Advanced Multishell / Tab Management
Currently, the OS leverages CC:Tweaked's native `multishell`. However, future iterations may include a custom multishell implementation to better integrate with the security model.
* **Custom Multishell:** Would allow deeper hooks into background process pausing, security context switching, and a more seamless integration with CANVAS and ATMIN.

## 3. Integration with Kernel Security
The entire GUI stack respects the kernel-level sandboxing and capability token system.
* **App Manifests:** ATMIN will read `manifest.lua` for apps to display required tokens before launch.
* **WIMP Security Dialogs:** If an app dynamically requests a capability, the kernel pauses the app and WIMP draws the system-level approval prompt on top of CANVAS.
