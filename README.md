# Save Aiyaman in 20s
This is just a simple game project to try out the [DragonRuby Game Toolkit](https://dragonruby.itch.io/dragonruby-gtk)
engine that was given out free for [20s Game Jam](https://itch.io/jam/20-second-game-jam) joiners. You have 20 seconds
to interact with the objects and save Aiyaman from death.


## Licensing and Credits
This project in its entirety is under the [CC0 public domain license](https://creativecommons.org/publicdomain/zero/1.0/).
This includes the following third-party assets that were used for this game:

| Asset | Original | Modified | Author | License |
| --- | --- | --- | --- | --- |
| [Gunshots](https://opengameart.org/content/gunshots) | Unkown.wav | sounds/gunshot.wav | kurt | CC0 |
| [Ambient Bird Sounds](https://opengameart.org/content/ambient-bird-sounds) | birds-isaiah658.ogg  | sounds/birdstand-[0-2].wav | isaiah658 | CC0 |
| [Atmospheric Interaction Sound Pack](https://opengameart.org/content/atmospheric-interaction-sound-pack) | space/link.wav | sounds/resume.wav | legoluft | CC0 |
| [Reversing Time](https://opengameart.org/content/reversing-time-stuck-in-time) | Reverse-Time-Loop-isaiah658.ogg | sounds/reverse-time.ogg | isaiah658 | CC0 |
| [Time Slow](https://opengameart.org/content/time-slow) | time_stop.mp3 | sounds/time-stop.ogg | MidFag | CC0 |


### Thoughts on DragonRuby GTK
I joined this game jam as an opportunity to try out something new for game development, and I must say that I am highly
impressed by the elegance of DragonRuby. It provides excellent control over what you want to output to the player,
with plenty of built-in functions that are actually much more lean and specific compared to any other game engine I've
come across so far. It is extremely tiny, extremely efficient, builds to various platforms, provides an in-game
console and hot-swapping code instantaneously right out of the box. This sentence alone is enough to impress any
programmer.

It is very powerful in the hands of a computer scientist and a software engineer, though not so
much an artist or game developers in general. Programming with DragonRuby requires a more functional and mathematical
approach compared to the more intuitive GUI workflows of other game engines like Unity. This is not a bad thing; it
fills an engineering niche in game development methodology, and is very refreshing to see. You have a lot of
control just by code alone - all this power at your fingertips with zero bloat.

It is unfortunate that it is behind a paywall which makes it difficult for it to be popular compared to more rounded,
open-source, free and feature-packed game engines like Godot. Luckily, they are giving out free copies once in a while
but there needs to be a better way to entice users to at least try it out. Not only that, its documentation is poor.
As of 29th November 2022, methods like `Numeric#randomize` and `args.audio.delete` were used and dumped in various code
snippets, but not actually explained. While I don't mind reading through code, they need to belong in the
right sections in the table of contents for users to be able to look it up.

Overall, I find DragonRuby robust and fun to use. I think the asking price for the Standard License (lifetime, USD$32)
is more than justified, though I am highly against any form of subscription-based plans in principle. If certain
features require this to happen, it would be best to forego them to support a more libre approach - then perhaps a
lifetime license could be offered for the Pro version. Lastly, while I believe the Standard License pricing is more
than fair, I don't think their stance on open source and copyright is commendable. The creators of DragonRuby want to
make money to continue doing what they love, simple as that - they shouldn't be twisting words in their documentation
about open source being unsustainable or needing to be more "ethical" because nothing about open source and copyleft
forbids commercialization or monetization. A simple "we made this engine to be sold as a product; we run a business
and believe this will allow us to make more money" would be far more appealing than trying to rationalize away
from FOSS. If the developers don't know how to garner support even at this basic level, I worry that such an
outstanding game engine may never see enough adoption.
