# Gating Policy

**Audience:** todo el equipo que escribe Flutter/Dart en este monorepo.
**Source of truth:** `neom_core/lib/utils/app_gates.dart`.
**TL;DR:** no uses `AppConfig.instance.showBetaFeatures` ni `SubscriptionResolver` directos en la UI. Llama a `AppGates.canUseXxx()`.

---

## Las 4 capas del gating

El acceso a cualquier feature es el producto (AND lógico) de hasta 4 capas. Cuando una falla, la feature debe esconderse del usuario.

```
┌──────────────────────────────────────────────────────────────────┐
│ Capa 4 · Admin bypass          → isAdminMode                     │  ← override
├──────────────────────────────────────────────────────────────────┤
│ Capa 3 · Flavour               → AppFlavour.showXxx()            │  ← build
├──────────────────────────────────────────────────────────────────┤
│ Capa 2 · Tier del usuario      → SubscriptionLevel del User      │  ← pago
├──────────────────────────────────────────────────────────────────┤
│ Capa 1 · Flags globales        → AppConfig.instance.*            │  ← kill switch
└──────────────────────────────────────────────────────────────────┘
```

### Capa 1 · Flags globales (`AppConfig`)

| Flag | Valor default | Propósito |
|---|---|---|
| `showBetaFeatures` | `false` | Master switch para features beta. Con `false` ocultamos en producción funciones que aún no tienen pulido de lanzamiento (InterComm, Booking, VST, DAW). |
| `hasEarlyAccess` | `true` | Master switch para early access. Cuando es `true`, las funciones marcadas como early access se muestran a usuarios con tier suficiente. Cuando es `false`, quedan completamente ocultas — **kill switch de emergencia**. |
| `isAdminMode` | `false` | Bypass total. Si es `true`, todas las gates devuelven `true`. |

**Regla:** nadie modifica estos flags en runtime excepto el flujo de login/admin.

### Capa 2 · Tier del usuario (`SubscriptionLevel`)

El enum `SubscriptionLevel` (neom_core) está ordenado por `index`:

```
freemium(0) < freeMonth(1) < basic(2) < plus(3) < family(4)
< creator(5) < ambassador(6) < artist(7) < professional(8)
< corporate(9) < premium(10) < platinum(11) < lifetime(12)
```

- **Baseline beta:** `premium+` (index ≥ 10)
- **Baseline early access:** `platinum+` (index ≥ 11)
- **Lifetime** pasa naturalmente todas las gates de tier.

### Capa 3 · Flavour (`AppFlavour.showXxx()`)

Vive en `neom_commons` y no puede importarse desde `neom_core` (ciclo de dependencias). Por eso `AppGates` **no** lo encapsula. Se evalúa en el call site:

```dart
if (AppFlavour.showVst() && AppGates.canUseHiddenBeta()) { … }
```

### Capa 4 · Admin bypass

`AppGates.isAdmin` (alias de `AppConfig.instance.isAdminMode`). Implícito en todas las gates combinadas — no necesitas evaluarlo a mano.

---

## API de `AppGates` — qué llamar cuándo

### Gates genéricas

| Gate | Fórmula | Cuándo usarla |
|---|---|---|
| `canUseBeta()` | `admin ∨ (showBeta ∧ premium+)` | Features beta "clásicas": ambos candados deben estar abiertos. |
| `canUseHiddenBeta()` | `showBeta ∨ admin ∨ premium+` | **Launch mode.** Features que deben estar ocultas para el público pero accesibles a admins y premium+ para dogfooding. Esta es la gate por default durante el lanzamiento. |
| `canUseEarlyAccess()` | `admin ∨ (hasEarlyAccess ∧ platinum+)` | Features early access que requieren platino+ y que se pueden matar globalmente con el kill switch. |

### Helpers de tier (para casos custom)

```dart
AppGates.isPremiumOrAbove()    // >= premium(10)
AppGates.isPlatinumOrAbove()   // >= platinum(11)
AppGates.currentLevel()        // SubscriptionLevel seguro (fallback freemium)
```

### Aliases semánticos (Saia)

Son wrappers sobre las gates genéricas con nombres que leen como producto. **Úsalos en la UI** para que cuando el tier cambie, solo tengas que editar `app_gates.dart`.

| Alias | Baseline | Notas |
|---|---|---|
| `canUseSaiaMemory()` | platino+ (early access) | Dreaming scorer, consolidación, contexto personal. |
| `canUseSaiaMultiProvider()` | platino+ (early access) | Routing multi-provider (Claude + GPT + Gemini + Mistral). |
| `canUseSaiaAdvancedTools()` | platino+ (early access) | Subagents, MCP, code execution, RAG. |
| `canUseSaiaOffline()` | **universal** | Ollama local. Intencional: sin gate por tier. Solo global kill switch + admin. |
| `isSaiaLaunchActive()` | global + admin | Master check del entrypoint en drawer/sidebar. |
| `canUseSaiaBench()` | **admin-only** (temporal) | Bench runner (`neom_ia_bench`). Dogfooding interno antes de abrirlo a platino+ → premium+ → público. |

---

## Cheat sheet · ¿qué gate uso?

```
┌─────────────────────────────────────────────────┬─────────────────────────┐
│ Situación                                       │ Gate                    │
├─────────────────────────────────────────────────┼─────────────────────────┤
│ Feature a medio hacer, oculta en launch,        │ canUseHiddenBeta()      │
│ pero dogfooding interno con admins + premium+   │                         │
├─────────────────────────────────────────────────┼─────────────────────────┤
│ Feature beta clásica (solo si showBeta=true)    │ canUseBeta()            │
├─────────────────────────────────────────────────┼─────────────────────────┤
│ Feature early access (platino+ con kill switch) │ canUseEarlyAccess()     │
├─────────────────────────────────────────────────┼─────────────────────────┤
│ Feature Saia específica                         │ canUseSaiaXxx()         │
├─────────────────────────────────────────────────┼─────────────────────────┤
│ Ollama / offline                                │ canUseSaiaOffline()     │
├─────────────────────────────────────────────────┼─────────────────────────┤
│ Entry point del drawer                          │ isSaiaLaunchActive()    │
└─────────────────────────────────────────────────┴─────────────────────────┘
```

---

## Reglas

1. **No leas `AppConfig.instance.showBetaFeatures` ni `hasEarlyAccess` directamente en UI.** Llama a una gate de `AppGates`.
2. **No importes `SubscriptionResolver` desde `neom_core`.** Vive en `neom_commerce` y crearía ciclo. `AppGates` ya reimplementa los checks con `SubscriptionLevel.index`.
3. **No importes `AppFlavour` dentro de `AppGates`.** Vive en `neom_commons` y crearía ciclo. Capa 3 siempre se evalúa en el call site:
   ```dart
   if (AppFlavour.showVst() && AppGates.canUseHiddenBeta()) { … }
   ```
4. **Si una feature cambia de tier**, edita una sola línea de `app_gates.dart`. Nunca grep-and-replace por la codebase.
5. **Tests y splash son seguros.** `AppGates.currentLevel()` devuelve `freemium` si `UserController` no está registrado.
6. **Admin bypass es global.** Si eres admin, todas las gates combinadas devuelven `true`. Úsalo con responsabilidad.

---

## Estado actual (launch Itzli)

| Flag | Valor |
|---|---|
| `showBetaFeatures` | `false` |
| `hasEarlyAccess` | `true` |
| Baseline beta | `premium+` |
| Baseline early access | `platinum+` |

**Features gated por `canUseHiddenBeta()` en `left_sidebar.dart`:**
- InterComm (además requiere `_isSupportOrAbove`)
- Booking
- VST
- DAW

**Features Saia (todas detrás de `canUseEarlyAccess()` vía alias, excepto offline):**
- Memoria persistente — platino+
- Multi-provider routing — platino+
- Advanced tools (subagents, MCP, RAG) — platino+
- Offline / Ollama — **universal** (solo global + admin)

---

## Ejemplos

### UI condicional en un sidebar

```dart
// ❌ Mal
if (AppConfig.instance.showBetaFeatures) { … }

// ✅ Bien
if (AppFlavour.showVst() && AppGates.canUseHiddenBeta()) { … }
```

### Mostrar un banner de "upgrade a platino"

```dart
if (!AppGates.canUseSaiaMemory() && AppGates.earlyAccessEnabled) {
  return UpgradeBanner(targetTier: SubscriptionLevel.platinum);
}
```

### Kill switch en caliente

Si algo explota en producción después del lanzamiento, cambia `hasEarlyAccess` a `false` en remote config → todas las features Saia desaparecen instantáneamente para usuarios no-admin. No hay que desplegar.

---

## Cambios / historial

- **2026-04-08** — Creación inicial. Launch mode Itzli: `showBetaFeatures=false`, `hasEarlyAccess=true`. Introducción de `canUseHiddenBeta()` y aliases `canUseSaiaXxx()`.
- **2026-04-08** — Agregada `canUseSaiaBench()` como gate admin-only temporal para dogfooding de `neom_ia_bench` antes de abrirlo a tiers pagados.
