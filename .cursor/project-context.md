# 🪝 Hook Anti-Sandwich para Stable Assets - Project Context

## 📌 Resumen Ejecutivo

**Proyecto:** Hook Anti-Sandwich para Uniswap v4 (Stable Assets)  
**Track:** Track 1 - Stable-Asset Hooks ($10,000 prize pool)  
**Hackathon:** ETHGlobal Buenos Aires (Nov 2025)  
**Organizador:** Uniswap Foundation

### Problema que Resuelve

Los usuarios y LPs en mercados de activos estables sufren por **Sandwich Attacks** (MEV) cuando:
- Bots detectan swaps grandes pendientes
- Ejecutan swaps antes (front-run) y después (back-run) del swap de la víctima
- El usuario paga más y el LP pierde por el arbitraje explotado
- Esto es especialmente problemático en pares estables (USDC/USDT, DAI/USDC, etc.)

### Solución

Hook de Uniswap v4 que:
1. **Detecta patrones de riesgo** típicos de sandwich attacks
2. **Calcula un riskScore** basado en trade size, volatilidad y patrones consecutivos
3. **Ajusta fees dinámicamente** según el riesgo detectado
4. **NO bloquea swaps** - mantiene UX y composabilidad intacta
5. **Protege LPs y usuarios** sin usar oráculos externos

---

## 🎯 Objetivo del MVP

Implementar un hook funcional que demuestre:
- ✅ Detección de patrones de sandwich en `beforeSwap()`
- ✅ Cálculo de riskScore basado en múltiples métricas
- ✅ Fee dinámica que aumenta con el riesgo
- ✅ Actualización de estado en `afterSwap()`
- ✅ Tests completos (>80% coverage)
- ✅ Deployment en testnet con TxIDs
- ✅ README y demo funcional

---

## 🧩 Arquitectura Técnica

### Hooks Utilizados

- `beforeSwap()` - Calcula riskScore y aplica fee dinámica
- `afterSwap()` - Actualiza métricas históricas (lastPrice, avgTradeSize, recentSpikeCount)

**Nota:** Solo necesitamos `beforeSwap()` y `afterSwap()` para el MVP.

### Storage Mínimo

```solidity
struct PoolStorage {
    uint160 lastPrice;         // Último precio del pool (sqrtPriceX96)
    uint256 lastTradeSize;     // Tamaño del swap previo
    uint256 avgTradeSize;      // Promedio dinámico simple de trade sizes
    uint8 recentSpikeCount;     // Contador de trades grandes consecutivos
    uint24 baseFee;            // Fee base en basis points (ej: 5 = 0.05%)
    uint24 lowRiskFee;         // Fee para riesgo bajo (ej: 5 bps)
    uint24 mediumRiskFee;      // Fee para riesgo medio (ej: 20 bps)
    uint24 highRiskFee;        // Fee para riesgo alto (ej: 60 bps)
    uint8 riskThresholdLow;    // Umbral bajo de riesgo (ej: 50)
    uint8 riskThresholdHigh;   // Umbral alto de riesgo (ej: 150)
}
```

### Lógica Core

#### 1. Cálculo de RiskScore

```solidity
// En beforeSwap()
P_current = pool.sqrtPriceX96
tradeSize = amountIn o amountSpecified
deltaPrice = abs(P_current - lastPrice)
relativeSize = tradeSize / avgTradeSize

// Fórmula del riskScore
riskScore = 
    w1 * relativeSize +      // w1 = 50 (peso del tamaño relativo)
    w2 * deltaPrice +        // w2 = 30 (peso del delta de precio)
    w3 * recentSpikeCount;    // w3 = 20 (peso de spikes consecutivos)
```

#### 2. Fee Dinámica Basada en RiskScore

```solidity
if (riskScore < riskThresholdLow) {
    fee = lowRiskFee;        // 5 bps (0.05%) - riesgo bajo
} else if (riskScore < riskThresholdHigh) {
    fee = mediumRiskFee;     // 20 bps (0.20%) - riesgo medio
} else {
    fee = highRiskFee;       // 60 bps (0.60%) - riesgo alto (anti-sandwich)
}
```

#### 3. Actualización de Estado

```solidity
// En afterSwap()
lastPrice = P_current;
avgTradeSize = (avgTradeSize * 9 + tradeSize) / 10;  // Promedio móvil simple

if (relativeSize > 5) {
    recentSpikeCount++;
} else {
    recentSpikeCount = 0;  // Reset si no hay spike
}
```

---

## 🛠️ Stack de Tecnologías

- **Solidity:** ^0.8.0
- **Foundry:** Para testing y deployment
- **Uniswap v4:** Template oficial de hooks
- **Testnet:** Sepolia o Base Sepolia
- **GitHub:** Repositorio público

---

## 📁 Organización del Proyecto

```
.
├── src/
│   └── AntiSandwichHook.sol      # Hook principal (renombrar de AntiLVRHook)
├── test/
│   ├── AntiSandwichHook.t.sol   # Tests unitarios
│   └── integration/             # Tests de integración
├── script/
│   └── deploy/
│       └── DeployAntiSandwichHook.s.sol
├── .cursor/
│   ├── project-context.md       # Este archivo
│   └── user-rules.md            # Reglas para IA
├── docs-internos/               # Documentación interna
└── README.md                    # Documentación pública
```

---

## 🎯 Casos de Uso Principales

1. **Swap normal en par estable (USDC/USDT)**
   - Trade size normal, precio estable
   - riskScore < 50 → fee = 5 bps
   - Comportamiento normal, sin penalización

2. **Swap grande sospechoso (posible sandwich)**
   - Trade size 10× mayor que promedio
   - Precio salta bruscamente
   - riskScore > 150 → fee = 60 bps
   - Desalienta el sandwich, protege LPs

3. **Patrón de sandwich detectado**
   - Múltiples swaps grandes consecutivos
   - recentSpikeCount aumenta
   - Fee aumenta progresivamente
   - Protege a usuarios y LPs

---

## ✅ Resultados Esperados

### Métricas Clave

- **Reducción de MEV:** 30-50% en pares estables (estimado)
- **Fee dinámica:** 5 bps (normal) → 60 bps (alto riesgo)
- **Gas cost:** <100k gas por swap (objetivo)
- **Detección de patrones:** >80% accuracy en detección de sandwich

### Validaciones

- ✅ Tests unitarios pasando
- ✅ Tests de integración con Uniswap v4
- ✅ Tests de detección de patrones de sandwich
- ✅ Deployment exitoso en testnet
- ✅ TxIDs guardados para hackathon
- ✅ Demo funcional mostrando diferencia

---

## 📋 Requisitos del Hackathon

### Entregables Obligatorios

1. **TxIDs de transacciones** (testnet/mainnet)
2. **Repositorio GitHub** público
3. **README.md** completo
4. **Demo funcional** o instrucciones de instalación
5. **Video demo** (máx. 3 minutos, inglés con subtítulos)

### Criterios de Evaluación (Track 1)

- Funcionalidad del hook
- Innovación y utilidad para stable assets
- Alineación con: lending sintético, trading respaldado por crédito, o lógica AMM optimizada para stables
- Calidad del código
- Documentación
- Demo y presentación

---

## 🔒 Privacidad y Seguridad

- **No hardcodear** claves privadas
- **Usar .env** para variables sensibles
- **Validar parámetros** en funciones de configuración
- **Control de acceso** (onlyOwner) para configuraciones
- **Tests de seguridad** (reentrancy, edge cases, overflow protection)

---

## 🚀 Flujo de Ejecución Básico

1. **Setup:**
   ```bash
   forge install
   forge test
   ```

2. **Deployment:**
   ```bash
   forge script script/deploy/DeployAntiSandwichHook.s.sol \
     --rpc-url $RPC_URL \
     --account $ACCOUNT \
     --broadcast
   ```

3. **Testing:**
   ```bash
   forge test
   forge test --fork-url $RPC_URL  # Tests en fork
   ```

---

## 📚 Referencias Clave

- `docs-internos/idea-general.md` - Lógica detallada del hook (NUEVA IDEA)
- `docs-internos/hackathon-ethglobal-uniswap.md` - Info del hackathon
- `docs-internos/ROADMAP-PASOS.md` - Guía de desarrollo paso a paso
- `docs-internos/README-INTERNO.md` - Info del template Uniswap v4

### Recursos Externos

- [Uniswap v4 Docs](https://docs.uniswap.org/contracts/v4/overview)
- [v4-template](https://github.com/uniswapfoundation/v4-template)
- [OpenZeppelin Hooks Library](https://docs.openzeppelin.com/uniswap-hooks)

---

## 🎨 Estructura de Código Esperada

### Convenciones

- **Nombres descriptivos:** `calculateRiskScore()` no `calcRisk()`
- **Comentarios NatSpec:** Todas las funciones públicas
- **Events:** Para cambios importantes de estado
- **Modifiers:** Para validaciones reutilizables
- **Libraries:** Para cálculos complejos

### Ejemplo de Estructura

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BaseHook} from "uniswap-v4/...";

contract AntiSandwichHook is BaseHook {
    // Storage
    struct PoolStorage {
        uint160 lastPrice;
        uint256 lastTradeSize;
        uint256 avgTradeSize;
        uint8 recentSpikeCount;
        // ...
    }
    
    // Hooks
    function beforeSwap(...) external override returns (bytes4, BeforeSwapDelta, uint24) {
        // Calcular riskScore
        // Aplicar fee dinámica
    }
    
    function afterSwap(...) external override returns (bytes4, int128) {
        // Actualizar métricas históricas
    }
    
    // Helpers internos
    function _calculateRiskScore(...) internal view returns (uint8) {
        // ...
    }
    
    function _calculateDynamicFee(...) internal view returns (uint24) {
        // ...
    }
    
    // Configuración
    function setPoolConfig(...) external onlyOwner {
        // ...
    }
}
```

---

## 🔧 Configurabilidad

### Parámetros Ajustables

- `baseFee` / `lowRiskFee`: Fee base (default: 5 bps)
- `mediumRiskFee`: Fee para riesgo medio (default: 20 bps)
- `highRiskFee`: Fee para riesgo alto (default: 60 bps)
- `riskThresholdLow`: Umbral bajo (default: 50)
- `riskThresholdHigh`: Umbral alto (default: 150)
- Pesos del riskScore: `w1 = 50`, `w2 = 30`, `w3 = 20` (constantes ajustables)

### Control de Acceso

- **Owner:** Puede cambiar parámetros
- **Futuro:** Governance o timelock (opcional)

---

## 📈 Notas para Escalabilidad Futura

### Mejoras Opcionales (Post-MVP)

1. **Métricas más sofisticadas:**
   - EWMA para avgTradeSize
   - Detección de patrones más complejos
   - Machine learning on-chain (futuro)

2. **Governance:**
   - Timelock para cambios de parámetros
   - Multi-sig para configuración

3. **Analytics:**
   - Events más detallados
   - Funciones view para consultar métricas
   - Dashboard off-chain

4. **Gas Optimization:**
   - Pack structs (uint8, uint160, etc.)
   - Caching de variables
   - Optimización de cálculos

---

## 🎯 Guía para el Asistente Técnico

### Prioridades

1. **MVP funcional** - Hook básico con detección de riesgo y fee dinámica
2. **Tests completos** - >80% coverage, incluyendo tests de patrones de sandwich
3. **Deployment** - Testnet con TxIDs
4. **Documentación** - README claro y demo

### Enfoque

- **Simplicidad:** MVP primero, mejoras después
- **Testing:** Validar cada función antes de continuar
- **Documentación:** Comentarios claros y README completo
- **Seguridad:** Validar inputs y edge cases (overflow, underflow)

### Comandos Frecuentes

Ver `user-rules.md` para comandos específicos del proyecto.

---

## 🔥 Por qué esta idea es perfecta para Track 1

1. **No usa oráculos** → Simple y eficiente
2. **No rompe UX** → Swaps siempre se ejecutan
3. **No censura** → Cumple filosofía de Uniswap
4. **No bloquea** → Composabilidad intacta
5. **Tiene "enganche matemático"** → Jurados aman eso
6. **Alineada con Track 1** → "lending sintético, trading respaldado por crédito, lógica AMM optimizada para stables"
7. **Implementable en 1-2 días** → Perfecto para hackathon
8. **Elegante y explicable** → Fácil de presentar en pitch

---

📅 **Última actualización:** 2025-11-22  
👤 **Creado por:** kaream  
🎯 **Versión:** 2.0 (Track 1 - Stable Assets)
