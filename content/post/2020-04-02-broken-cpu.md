---
title: "Fixing a broken CPU"
date: 2020-04-03T00:44:06-04:00
subtitle: "Why my computer wouldn't start"
tags: ["hardware"]
---

About a year ago, my home server wouldn't start back up, with no power going to any component. I had come to the conclusion that the power supply was the culprit after testing it directly. So I purchased a new power supply and after replacing the old one, there was only an incremental improvement. I'd initially see the fans power on, but within 10 seconds, everything would shut off. I double and tripled checked the cable connections, but still no luck. Discouraged, I pretty much gave up for almost a year.

## Second Attempt
A year later, I was determined to revive my computer. After reading through numerous forums, I came to the conclusion that the motherboard had to be the cultprit. The computer was fairly old as it was built around 2011. I still liked the case, so I decided to replace the memory, motherboard (`Gigabyte GA-Z77X-D3H`) and CPU.

After re-assembling the computer, to my disappointment, there was only an incremental improvement. The power and the fans stayed on, but still no POST. I repeatedly checked the various cables and connections and replacing the memory, but the results were the same. Eventually through process of elimination, I was able to determine that there was likely an issue with the CPU. It turns out that the issue wasn't with the CPU itself, but the CPU socket!

### The Culprit
{{< gallery caption-effect="fade" >}}
  {{< figure thumb="-thumb" link="/images/cpu-bent-pin.jpg" caption="Bent CPU Pin" >}}
{{< /gallery >}}

## The Fix
Upon closer examination (it was pretty hard to see), I noticed that one of the pins was bent. Each pin has a separate function or it could be unused. This means you will deal with different issues based on the pin that was bent. It's probably why I really wasn't able to directly match the issue I was facing with anything I researched online. To fix the issue, I gently pushed the pin back with a pick tool. I was overcome with a wave of relief when I was finally able to see the BIOS configuration screen again!

## How Did This Happen?
I believe this was caused from being careless with the way I placed the CPU onto the socket. I probably dropped the CPU chip from too high of a distance and that caused enough impact to bend that 1 pin. Crazy how 1 pin can effectively shut down a computer!