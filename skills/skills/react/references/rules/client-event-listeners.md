---
title: Deduplicate Global Event Listeners
impact: MEDIUM-HIGH
impactDescription: single listener for N components
tags: client, event-listeners, subscription
---

## Deduplicate Global Event Listeners

Share one global event listener across component instances by registering callbacks in a module-level map.

**Incorrect (N instances = N listeners):**

```tsx
function useKeyboardShortcut(key: string, callback: () => void) {
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (e.metaKey && e.key === key) {
        callback();
      }
    };
    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, [key, callback]);
}
```

When using the `useKeyboardShortcut` hook multiple times, each instance will register a new listener.

**Correct (N instances = 1 listener):**

```tsx
const keyCallbacks = new Map<string, Set<() => void>>();

function handleKeydown(e: KeyboardEvent) {
  if (e.metaKey) {
    keyCallbacks.get(e.key)?.forEach((cb) => cb());
  }
}

function subscribe(key: string, callback: () => void) {
  if (keyCallbacks.size === 0) {
    window.addEventListener("keydown", handleKeydown);
  }
  const callbacks = keyCallbacks.get(key) ?? new Set();
  keyCallbacks.set(key, callbacks.add(callback));

  return () => {
    callbacks.delete(callback);
    if (callbacks.size === 0) {
      keyCallbacks.delete(key);
    }
    if (keyCallbacks.size === 0) {
      window.removeEventListener("keydown", handleKeydown);
    }
  };
}

function useKeyboardShortcut(key: string, callback: () => void) {
  useEffect(() => subscribe(key, callback), [key, callback]);
}

function Profile() {
  // Multiple shortcuts share the same listener
  useKeyboardShortcut("p", () => {
    /* ... */
  });
  useKeyboardShortcut("k", () => {
    /* ... */
  });
  // ...
}
```
