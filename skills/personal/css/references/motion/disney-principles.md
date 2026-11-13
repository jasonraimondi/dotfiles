# Disney Animation Principles

The twelve principles in CSS, for motion that needs character. Reach for these when personality is the goal; `index.md` governs performance, timing, and reduced motion for all of it.

Wrap character motion in `@media (prefers-reduced-motion: no-preference)` — for users with vestibular disorders it is opt-in, not opt-out.

## 1. Squash and stretch

```css
@keyframes squash-stretch {
  0%, 100% { scale: 1 1; }
  50% { scale: 1.2 0.8; }
}

.ball { animation: squash-stretch var(--motion-duration-structural) ease-in-out; }
```

## 2. Anticipation

```css
@keyframes anticipate-jump {
  0% { translate: 0 0; }
  20% { translate: 0 10px; scale: 1 0.9; }
  100% { translate: 0 -100px; }
}
```

The wind-up at 20% is what sells the jump.

## 3. Staging

```css
.hero { z-index: 10; filter: none; }
.background { z-index: 1; filter: blur(2px); opacity: 0.7; }
```

## 4. Pose to pose

```css
@keyframes walk-cycle {
  0% { background-position: 0 0; }
  25% { background-position: -100px 0; }
  50% { background-position: -200px 0; }
  75% { background-position: -300px 0; }
  100% { background-position: -400px 0; }
}
```

## 5. Follow through and overlapping action

```css
.character { animation: move var(--motion-duration-route) ease-out; }
.hair { animation: move var(--motion-duration-route) ease-out 50ms; }
.cape { animation: move var(--motion-duration-route) ease-out 100ms; }
```

## 6. Slow in and slow out

```css
.element {
  transition: translate var(--motion-duration-route) var(--ease-standard);
}
```

## 7. Arc

```css
@keyframes arc-motion {
  0% { translate: 0 0; }
  50% { translate: 100px -80px; }
  100% { translate: 200px 0; }
}

/* True arcs */
.element { offset-path: path("M0,100 Q100,0 200,100"); }
```

## 8. Secondary action

```css
.button:hover { scale: 1.05; }
.button:hover .icon { animation: wiggle var(--motion-duration-structural) ease-in-out; }
```

## 9. Timing

Duration carries weight: light things move fast, heavy things move slow. Scale from the duration tokens in `tokens.css`.

## 10. Exaggeration

```css
@keyframes exaggerated-bounce {
  0%, 100% { translate: 0 0; scale: 1; }
  50% { translate: 0 -150px; scale: 0.8 1.3; }
}
```

## 11. Solid drawing

```css
.scene {
  transform-style: preserve-3d;
  perspective: 1000px;
}

.face { rotate: y 20deg; }
```

## 12. Appeal

```css
.appealing {
  border-radius: 50%;
  box-shadow: 0 4px 20px rgb(0 0 0 / 0.1);
  transition:
    scale var(--motion-duration-structural) var(--ease-standard),
    box-shadow var(--motion-duration-structural) var(--ease-standard);
}

.appealing:hover {
  scale: 1.02;
  box-shadow: 0 8px 30px rgb(0 0 0 / 0.15);
}
```
