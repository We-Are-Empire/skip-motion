// Copyright 2023–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
package skip.motion

import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.toArgb
import com.airbnb.lottie.LottieProperty
import com.airbnb.lottie.compose.LottieDynamicProperties
import com.airbnb.lottie.compose.LottieDynamicProperty
import com.airbnb.lottie.compose.rememberLottieDynamicProperties
import com.airbnb.lottie.compose.rememberLottieDynamicProperty

/**
 * Builds [LottieDynamicProperties] from a list of [MotionDynamicProperty] values.
 *
 * Each property's keypath is split on "." to produce the array of path segments
 * that lottie-compose expects (e.g., "**.Fill 1.Color" → ["**", "Fill 1", "Color"]).
 *
 * Returns null if the properties list is empty.
 */
@Composable
fun buildMotionDynamicProperties(
    properties: kotlin.collections.List<MotionDynamicProperty>
): LottieDynamicProperties? {
    if (properties.isEmpty()) return null

    val dynamicProps = mutableListOf<LottieDynamicProperty<*>>()
    for (prop in properties) {
        val keyPathParts = prop.keypath.split(".").toTypedArray()
        val composeColor = (prop.color as skip.ui.Color).asComposeColor()
        val argb = composeColor.toArgb()
        val dynProp = rememberLottieDynamicProperty(
            property = LottieProperty.COLOR,
            value = argb,
            keyPath = *keyPathParts
        )
        dynamicProps.add(dynProp)
    }

    return rememberLottieDynamicProperties(*dynamicProps.toTypedArray())
}
