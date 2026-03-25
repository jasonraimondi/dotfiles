---
name: iot-homeassistant-best-practices
description: >
  Home Assistant automation, helper, script, and device control best practices.
  Enforces native HA constructs over Jinja2 templates and safe refactoring workflows.

  TRIGGER WHEN:
  - Creating or editing HA automations, scripts, or scenes
  - Choosing between template sensors and built-in helpers
  - Writing triggers, conditions, waits, or selecting automation modes
  - Setting up Zigbee button/remote automations (ZHA or Zigbee2MQTT)
  - Renaming entities or migrating device_id to entity_id
  - Agent uses Jinja2 templates where native constructs exist
  - Agent uses device_id instead of entity_id
  - Agent picks wrong automation mode (e.g., single for motion lights)
metadata:
  version: "1.1.0"
---

# Home Assistant Best Practices

**Core principle:** Use native Home Assistant constructs wherever possible. Templates bypass validation, fail silently at runtime, and make debugging opaque.

## Decision Workflow

Follow this sequence for every automation task.

### 1. Modifying existing config? → Safe refactoring first

If your change affects entity IDs, cross-component references, or restructures existing automations — read `references/safe-refactoring.md` first and complete its workflow before proceeding.

Steps 2-6 apply to new config or pattern evaluation.

### 2. Prefer native conditions and triggers

Before writing any template, check `references/automation-patterns.md` for native alternatives.

| Template | Native replacement |
|---|---|
| `{{ states('x') \| float > 25 }}` | `numeric_state` with `above: 25` |
| `{{ is_state('x', 'on') and is_state('y', 'on') }}` | `condition: and` with state conditions |
| `{{ now().hour >= 9 }}` | `condition: time` with `after: "09:00:00"` |
| `wait_template: "{{ is_state(...) }}"` | `wait_for_trigger` with state trigger |

> **Caveat:** `wait_for_trigger` waits for a *change*, unlike `wait_template` which resolves immediately if already true. See `references/safe-refactoring.md#trigger-restructuring`.

### 3. Prefer built-in helpers over template sensors

Before creating a template sensor, check `references/helper-selection.md`.

| Need | Helper |
|---|---|
| Sum/average sensors | `min_max` integration |
| Binary any-on/all-on | `group` helper |
| Rate of change | `derivative` integration |
| Cross threshold | `threshold` integration |
| Consumption tracking | `utility_meter` helper |

### 4. Select correct automation mode

Default `single` is often wrong. See `references/automation-patterns.md#automation-modes`.

| Scenario | Mode |
|---|---|
| Motion light with timeout | `restart` |
| Sequential processing (door locks) | `queued` |
| Independent per-entity actions | `parallel` |
| One-shot notifications | `single` |

### 5. Use entity_id over device_id

`device_id` breaks when devices are re-added. See `references/device-control.md`.

**Exception:** Zigbee2MQTT autodiscovered device triggers are acceptable.

### 6. Zigbee buttons/remotes

- **ZHA:** `event` trigger with `device_ieee` (persistent)
- **Z2M:** `device` trigger (autodiscovered) or `mqtt` trigger

See `references/device-control.md#zigbee-buttonremote-patterns`.

---

## Anti-Patterns Quick Reference

| Anti-pattern | Fix | Reference |
|---|---|---|
| `condition: template` for numeric comparison | `condition: numeric_state` | `references/automation-patterns.md#native-conditions` |
| `wait_template` | `wait_for_trigger` | `references/automation-patterns.md#wait-actions` |
| `device_id` in triggers | `entity_id` or `device_ieee` (ZHA) | `references/device-control.md#entity-id-vs-device-id` |
| `mode: single` for motion lights | `mode: restart` | `references/automation-patterns.md#automation-modes` |
| Template sensor for sum/mean | `min_max` helper | `references/helper-selection.md#numeric-aggregation` |
| Template binary sensor with threshold | `threshold` helper | `references/helper-selection.md#threshold` |
| Renaming entity IDs without impact analysis | `references/safe-refactoring.md` workflow | `references/safe-refactoring.md#entity-renames` |

---

## Reference Files

| File | When to read |
|---|---|
| `references/safe-refactoring.md` | Renaming entities, replacing helpers, restructuring automations |
| `references/automation-patterns.md` | Triggers, conditions, waits, automation modes, choose vs if/then |
| `references/helper-selection.md` | Built-in helper vs template sensor decisions |
| `references/template-guidelines.md` | Confirming templates ARE appropriate for a use case |
| `references/device-control.md` | Service calls, Zigbee buttons, target syntax |
| `references/examples.yaml` | Compound examples combining multiple best practices |
