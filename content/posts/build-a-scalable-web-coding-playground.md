+++
title = "Part 1: Build A Scalable Web Coding Playground Infrastructure"
date = 2025-08-25
taxonomies.tags = [
    "Technology",
]
+++

I remember the first time I used a sophisticated online coding playground like **codedamn**. It wasn't just a single-file snippet editor. It was a full, containerized environment where I could:
- Spin up an entire **React** or **Next.js** app with preview.
- Run a **Java program** or a **Go code**.
- Install dependencies, run builds, and see live output—all in the browser.

The experience was incredibly fast, smooth, and reliable. I was blown away. And immediately, the engineer in me asked: **"How on earth is this built?"**

This blog is the story of my deep dive into that question. It's not a tutorial for a finished product, but a research log of the architectural problems I identified and the potential solutions I explored to build such a system at scale.

<!--more-->
---

## The Core Challenge: Beyond Single-File Snippets

Most basic playgrounds are simple. You paste code into a `<textarea>`, it gets POSTed to an API, run in a sandboxed Lambda function, and the result comes back. But that model breaks down completely when you need:
- A persistent, stateful environment.
- Multiple files and a real filesystem.
- Running servers and processes.
- An interactive terminal.

The fundamental unit shifts from a *function* to a *container* (or a virtual machine). Each user session needs its own isolated, containerized environment. The challenge becomes how to manage thousands of these containers efficiently.

---

## Problem 1: The Shared Filesystem

Each interactive session requires at least two components working in tandem:
1. A **WebSocket Server**: Handles real-time events like file edits, terminal keystrokes, and UI updates.
2. A **Runtime Container**: The language-specific environment (e.g., Node, Python, Go) that executes the code.

**Both need instantaneous access to the exact same files.** When a user edits `index.js`, the runtime container must see that change immediately.

I researched several ways to achieve this shared storage:

- **AWS EFS (Elastic File System)**:  A managed NFS. I chose this because i thought i could save user coding projects in the cloud itself without extra hazzles.It works, but each new mount can take ~10 seconds to initialize. This delay kills the "real-time" feel you expect from a modern IDE.
- **S3 with S3FS**: Tempting because of S3's durability and scale. However, S3 is object storage, not a POSIX filesystem. Operations like `ls` or editing a small file in a large directory become painfully slow.
- **Docker Volumes**: The simplest and fastest option. You create a volume on the host machine, mount it into both containers, and they see the same files instantly. No network latency, no initialization penalty.

**Verdict:** For pure performance and simplicity, a shared volume (or a hostPath) is the winner. This simplicity becomes a key constraint later.

---

## Problem 2: Orchestrating the Chaos

You can't just run `docker run` on a server for every new user. You need a system to orchestrate hundreds of dynamic, short-lived environments.

---

### My Very First Attempt: ECS

Initially, I was using **AWS ECS** to spawn a coding playground per session. It looked promising on paper: I could define tasks, attach storage (EFS), and scale out.  

But the problems I mentioned earlier (slow mounts with EFS, clunky debugging, slow feedback loops) made development extremely worse. Each iteration took too long, and the experience felt nowhere near the "instant" responsiveness of a coding IDE.

Another big factor: I was broke (^-^) and simply couldn’t afford the rising AWS bills for experimentation. Every failed iteration or slow debug cycle felt like I was burning cash faster than my containers were booting.

So yeah… I started looking for something simpler, cheaper, and faster.

---

### My Next Attempt: A Queue + Worker Model

To move away from ECS overhead, I experimented with a **message queue + horizontal scaling approach**:

- A main API server received requests to create a new playground.
- It published a message with a `sessionId` and configuration into a **message queue** (like Redis or RabbitMQ).
- A pool of **worker servers** consumed the queue. Each worker would:
    - Pull a job.
    - Clone a base template repository.
    - Use `docker-compose` to spin up the WebSocket and runtime containers, binding them to the shared volume and mapping ports.

This was horizontally scalable: I could add more worker servers to handle more concurrent playgrounds.

**What I learned:** This worked better than ECS for quick experimentation, but it came with its own problems. I was essentially building a brittle, custom orchestration layer. Managing lifecycle, cleaning up containers, and handling service discovery became messy fast.  

At this point, I realized I was reinventing wheels Kubernetes already solved.

<iframe src="https://drive.google.com/file/d/1q3h8tw690-OI_OYb_WgetwUgyXJDmFMd/preview" width="640" height="480" allow="autoplay"></iframe>

---

## Problem 2.1: The Networking Nightmare

Every playground might need to expose a web server (e.g., a Next.js app on port 3000). How do you route user traffic to the correct container?

- **Static Port Mapping**: Assign a unique external port to each session (e.g., user A gets `:4001`, user B gets `:4002`). This is a nightmare to manage and scale. You quickly run out of ports, and configuring the reverse proxy dynamically is messy.
- **Dynamic Reverse Proxy**: I tried **Traefik** and **Caddy** with their Docker provider plugins. They can automatically discover containers and configure routes. This was closer. You could route `user1.yourdomain.com` to the correct container.

But making this rock-solid with wildcard DNS and TLS, especially in development, felt complex. I was spending more time on plumbing than on the product.

---

## The "Aha!" Moment: Embracing Kubernetes

I realized I was painstakingly reassembling pieces that **Kubernetes** provides out of the box. Instead of fighting it, I designed a new architecture around it.

Here’s how a scalable playground system can work on Kubernetes:

1.  **Session as a Job**: Each coding environment is defined as a **Kubernetes Job**. This Job is responsible for creating the Pod that contains both the WebSocket server and runtime containers, sharing a volume for the code.

2.  **Internal Service**: Each Job gets its own headless **Kubernetes Service**. This provides a stable internal DNS name (e.g., `session-abc123.default.svc.cluster.local`) for the Pod, allowing other components in the cluster to talk to it easily.

3.  **Ingress for External Traffic**: A single **Ingress Controller** (like Traefik or Nginx) handles all incoming HTTP/S traffic.
    - A wildcard DNS record (`*.playground.yourdomain.com`) points to the Ingress.
    - The Ingress uses a simple path or hostname-based rule: a request to `s1.playground.yourdomain.com` is routed to the Service for session `s1`.

4.  **Local Development**: For testing, you can use `minikube` or `kind`. Adding a line to your `/etc/hosts` file (`127.0.0.1 s1.playground.yourdomain.com`) and configuring the Ingress lets you test the entire flow seamlessly on your local machine.

Kubernetes solves the hard problems elegantly:
- **Orchestration**: It manages the lifecycle of the Pods (containers).
- **Networking**: Services and Ingress handle discovery and routing.
- **Storage**: Persistent Volume Claims (PVCs) abstract the shared storage perfectly.
- **Scaling**: The entire system can scale horizontally across a cluster of nodes.

---

## Key Takeaways from My Research

1.  **Start Simple, Then Scale**: A simple Docker-based worker model is a great starting point to validate the idea. Don't jump to Kubernetes on day one.
2.  **Volumes Over Networked FS**: For the low-latency filesystem needs of an IDE, local volumes are superior to networked filesystems like EFS or S3FS at the beginning.
3.  **You Aren't Google (Yet)**: Avoid building custom orchestration. Kubernetes is a complex tool, but it's a solved complex tool. Leveraging it lets you focus on your application logic instead of infrastructure plumbing.
4.  **Ingress is Key**: A wildcard DNS record paired with a modern Ingress Controller is the cleanest way to handle routing to dynamic, multi-tenant services.

---

## Closing Thoughts

The magic of platforms like codedamn isn't just in the UI—it's in the incredibly sophisticated cloud-native infrastructure that powers it. My journey to understand it was a deep dive into containers, orchestration, and distributed systems design.

While I set out to *build* a playground, what I really built was a blueprint. The final, production-grade system would need more: resource limits, security policies, permission management in pods, session timeouts, and snapshotting. But the foundation is clear: **Kubernetes provides the primitives to make this not just possible, but elegant and scalable.**

This post just scratches the surface.  

In the next part, I’ll either:
- Dig deeper into solving some inefficiencies in the current infra design,  
- Or break down the **Kubernetes Job model** and the **application layer** that ties it all together.  

And maybe after that… yes, the **Language Server Protocol (LSP)** integration story awaits. 🚀

