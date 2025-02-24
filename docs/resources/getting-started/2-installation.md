---
prev:
    text: Why
    link: ./1-why/
next:
    text: Installation
    link: ./3-setting-up/
---

<script setup>
import { VPButton } from "vitepress/theme"
</script>

# Getting Started

This goes over how to start setting up conch.

## Installation

:::tabs
==Wally
In your `wally.toml`, add the following lines to your dependencies.

```toml
conch = "alicesaidhi/conch@0.2.0-rc.6"
conch_ui = "alicesaidhi/conch-ui@0.2.0-rc.6"
```

==pesde
In your terminal, run the following commands.

```sh
pesde add alicesaidhi/conch
pesde add alicesaidhi/conch_ui
```

==rbxm
You can download the latest rbxm from [GitHub Releases](https://github.com/alicesaidhi/conch/releases/latest/) or by pressing the button below. All packages expect to be within the same folder.

<VPButton href="https://github.com/alicesaidhi/conch/releases/latest/download/standalone.rbxm" text="Download latest rbxm"></VPButton>
<VPButton href="https://github.com/centau/vide/releases/latest" text="Vide"></VPButton>

You can drag the rbxm into Studio. You should place your packages somewhere where both the client and server can access it, ideally ReplicatedStorage.
==git clone

soon:tm:

:::
