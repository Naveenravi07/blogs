+++
title = "Part 2: Optimizing the Playground Infrastructure"
date = 2025-11-06

taxonomies.tags = [
    "Technology",
    "Infrastructure",
]
+++

After building the first version of the web coding playground, I started noticing places where the system could be faster, lighter, and more efficient.  
The first challenge I wanted to tackle was **boot time** — how long it took for a containerized environment to become fully operational after being scheduled on Kubernetes. <!-- more -->

<!--more-->
<br>

## **The Boot-Time Problem**

Initially, each playground’s Docker image (Next.js, Svelte, etc.) included its own `node_modules` folder.  
This made every image **large and heavy**, even though most dependencies didn’t need to be pre-packaged.

While Kubernetes only pulls an image if it doesn’t exist on a node or the tag changes, image size still matters in a scalable system.  

To fix this, I redesigned the Docker setup.  
Each image now focuses purely on:

- Creating a **dedicated user** for the playground  
- Pulling the **base runtime image** (Node, Go, etc.)  
- Exposing the **required port** for the service  

## **Dockerfile Example**

Here’s an example of how the simplified Dockerfile for a playground container looks after optimization:

```dockerfile
FROM node:22-alpine AS development
RUN addgroup -S coder && adduser -S coder -G coder -h /home/coder
RUN mkdir -p /home/coder/workspace && chown -R coder:coder /home/coder
WORKDIR /home/coder/workspace
COPY --chown=coder:coder package.json ./
USER coder
COPY --chown=coder:coder . .
EXPOSE 3000
CMD ["tail", "-f", "/dev/null"]
```


No more pre-bundled dependencies inside the container.

Instead, I introduced a configuration file called **`.cdmrc`** (short for *codedamn config*, inspired by where the idea started).  
Each playground template now ships with a `.cdmrc` file that lists the commands required to install and run the project.

```bash
# .cdmrc for a Next.js playground
npm install
npm run dev
```

The frontend was updated to parse this file on startup, automatically open a terminal, and execute the commands dynamically.  
This made the environments **lighter, faster, and more flexible**, and it decoupled build logic from the container itself.

I wouldn’t say this is the best approach though, since it **tightly couples the creation of a playground with the client**.  
I actually tried another interesting design where the **WebSocket container** inside the playground parsed the `.cdmrc` file located in the **user-service container** and executed the commands by itself.  
This approach worked well in theory and removed client dependency — but it introduced a new issue.  
The WebSocket container was only **streaming the command outputs as text** to the frontend, meaning the terminal wasn’t truly interactive.  
You couldn’t press keys like `Ctrl + C` or run additional commands mid-session — it behaved more like a log viewer than a live terminal.  
That broke the whole “interactive coding” feel I was aiming for, so I shelved this version for now.

<br>

## **To-Do (If I Ever Continue)**

After optimizing the performance side, I had a few more ideas that I wanted to explore if I decided to continue this project later.

### **1. Add Proper LSP Support**

One of the most interesting next steps would have been to **add real Language Server Protocol (LSP) support**, not just some fake workers that mimic code completions.  
Since all the source code already exists on a shared volume, we could spin up a **new container inside each playground pod** to run a language-specific LSP server.  

The **WebSocket container** could then proxy requests to that LSP container — upgrading the connection to a WebSocket and relaying all LSP operations back to the frontend.  
That way, the browser would receive real diagnostics, completions, and symbol lookups from the actual LSP server.

*(I might be slightly off on the implementation details — this idea came toward the end of the project and I didn’t dive deep into it yet.)*

Alternatively, for simplicity, the LSP could run **inside the WebSocket container itself**, but that would make the image insanely heavy and harder to maintain.  
It would also require custom logic to detect the project’s language and start the right LSP.  

Personally, I’d go with **approach #1** — a separate, lightweight LSP container per playground.

<br>

### **2. Add Collaborative Editing & Video Calling**

Another idea was to add **collaborative editing** and **peer-to-peer video calls** so multiple users could share the same playground session.  
This would make it perfect for **mock interviews, pair programming, or teaching setups**.  

I’ve already built systems with **WebRTC** and **Mediasoup**, so technically it’s feasible.  
But implementing real-time sync and state consistency for multiple terminals would require a lot of effort — and honestly, after finishing the core infra, I didn’t have the same drive to push this part through.  
Still, it’s a direction that would make the playground feel alive.

<br>

### **3. Migrate From Node to Bun**

Another idea on my list was to **migrate from Node.js to Bun**.  
It’s simpler, faster, and has built-in tooling that could make both container builds and dependency installs quicker.  
This would help reduce startup time even further and simplify the dev experience across all playgrounds.

<br>

## **Wrapping Up**

This project started as an attempt to understand how **modern coding environments scale**, and along the way, it became a crash course in **containers, orchestration, and distributed systems design**.  

I’ve learned more than I expected — from optimizing Docker images to building real-time infrastructure that actually feels responsive.  
And while I’m not continuing this project further, it served its purpose perfectly: helping me understand the systems behind scalable cloud developer platforms.  

Sometimes, stopping is part of the process.  
Not every project has to become a product — some just need to teach you what you wanted to learn.
