## SwiftData + iCloud (CloudKit) синхронизация — настройка проекта

Ниже — минимальные шаги, чтобы `ModelConfiguration(... cloudKitDatabase: .private(...))` реально начал синхронизировать данные.

### 1) Включи Capabilities в Xcode

Открой `memory.xcodeproj` → выбери Target `memory` → вкладка **Signing & Capabilities**.

- Нажми **+ Capability**
- Добавь **iCloud**
  - Поставь галочку **CloudKit**
  - В списке контейнеров создай/выбери контейнер:
    - обычно это `iCloud.<BundleID>`
    - у нас Bundle ID сейчас `me.memory`, значит контейнер чаще всего `iCloud.me.memory`

После этого Xcode создаст/обновит `.entitlements` файл у таргета.

### 2) Убедись, что iCloud включён на устройстве/симуляторе

- **На устройстве**: Settings → Apple ID → iCloud → включи iCloud Drive.
- **На симуляторе**: Settings → Sign in to Apple ID (если нужно).

Если iCloud недоступен, приложение не должно падать — оно продолжит работать на локальной базе.

### 3) Где включается синхронизация в коде

Файл: `memory/AppModelContainer.swift`

- `localConfiguration` — локальная база (fallback, всегда).
- `cloudConfiguration` — конфиг с CloudKit:
  - `cloudKitDatabase: .private("iCloud.me.memory")`

Контейнер создаётся так:

- сначала пробуем `[cloudConfiguration, localConfiguration]`
- если CloudKit не завёлся → создаём контейнер только с `localConfiguration`

### 4) Про “огромное количество пользователей”

CloudKit в таком виде — это синк **данных одного пользователя между его устройствами**.
Если нужно “общие данные между разными людьми” (социальное приложение/общая лента/чат),
то потребуется серверная часть (или CloudKit Sharing + отдельная модель доступа).

