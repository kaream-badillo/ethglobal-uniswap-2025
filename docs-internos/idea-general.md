💡 Idea central (versión conceptual)

El hook calcula un riesgo instantáneo de sandwich basándose en:

Trade size impact
Cuánto moverá el precio este swap.

Desviación del tamaño típico reciente
Si el swap actual es 5×, 10×, 20× más grande que el promedio.

Volatilidad intrabloque
Si varios swaps consecutivos están alterando la curva.

Tamaño de swaps consecutivos
Patrón clásico de sandwich:
grande → pequeño víctima → grande.

Diferencia entre precio “esperado” vs precio “actual”
Si ocurre un salto brusco en stables → casi seguro MEV.

🔥 Acción:

El hook aumenta la fee proporcional al riesgo detectado, NO bloquea swaps.

Esto:

desalienta el sandwich,

compensa el riesgo para LPs,

proteje a usuarios ingenuos,

es 100% compatible con Uniswap v4.

⚙️ Mecánica técnica exacta (simple y ganadora)
✔ 1. Storage mínimo
uint160 lastPrice;         // sqrtPriceX96 anterior
uint256 lastTradeSize;     // size del swap previo
uint256 avgTradeSize;      // promedio dinámico simple
uint8 recentSpikeCount;    // cuantos trades grandes seguidos

✔ 2. En beforeSwap():

Leemos:

P_current

tradeSize (amountIn o amountSpecified)

expectedPriceImpact

deltaPrice = abs(P_current - lastPrice)

relativeSize = tradeSize / avgTradeSize
(si > 5x → riesgo alto)

✔ 3. Cálculo del riskScore

Fórmula simple, ideal para hackathon:

riskScore =
    w1 * relativeSize +
    w2 * deltaPrice +
    w3 * recentSpikeCount;


Donde:

w1 = 50

w2 = 30

w3 = 20

(Puedes ajustar estos pesos en el código como constantes.)

✔ 4. Ajuste de fee dinámico
if (riskScore < 50) {
    fee = 5;    // 0.05%
} else if (riskScore < 150) {
    fee = 20;   // 0.20%
} else {
    fee = 60;   // 0.60% - modo anti-sandwich
}


El modo “extremo” solo se activa cuando hay claros patrones de sandwich.

✔ 5. En afterSwap():

Actualizamos:

lastPrice = P_current;
avgTradeSize = (avgTradeSize * 9 + tradeSize) / 10;

if (relativeSize > 5) {
    recentSpikeCount++;
} else {
    recentSpikeCount = 0;
}


Listo.

🔥 Por qué esta idea ES PERFECTA para el track estable

No usa oráculos → simple.

No rompe UX → swaps siempre se ejecutan.

No censura → cumple filosofía de Uniswap.

No bloquea → composabilidad intacta.

Tiene un “enganche matemático” → jurados aman eso.

Está alineada EXACTAMENTE con
“synthetic lending logic, credit-backed trading y optimized stable AMM logic”
mencionadas en el track.

Es implementable en 1–2 días.

Es elegante y explicable en pitch.

🧠 Resumen en frase para tu pitch

“Nuestro hook detecta patrones de riesgo típicos de sandwich en mercados estables (trade size anómalo, volatilidad intrabloque, saltos consecutivos), calcula un score de riesgo y ajusta la fee dinámicamente. Esto protege LPs y reduce MEV sin bloquear swaps ni romper la UX.”