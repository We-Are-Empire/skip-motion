// Copyright 2023–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
#if !SKIP_BRIDGE
import Foundation
import OSLog
import SwiftUI
#if !SKIP
import Lottie
#else
import com.airbnb.lottie.__
import com.airbnb.lottie.compose.__
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.Modifier
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.ui.layout.ContentScale
import java.util.zip.ZipInputStream
#endif

let logger: Logger = Logger(subsystem: "SkipMotion", category: "MotionView")

/// Errors that can occur during animation loading.
public enum MotionError: Error, Sendable {
    /// The provided data could not be parsed as a valid animation.
    case invalidData
    /// A DotLottie file was parsed but contained no animations.
    case noAnimationFound
    /// The named resource could not be found in the bundle.
    case resourceNotFound(name: String)
}

/// Defines animation loop behavior.
public enum MotionLoopMode: Hashable, Sendable {
    /// Animation is played once then stops.
    case playOnce
    /// Animation will loop from beginning to end until stopped.
    case loop
    /// Animation will play forward, then backwards and loop until stopped.
    case autoReverse
    /// Animation will loop from beginning to end up to defined amount of times.
    case `repeat`(Int)
    /// Animation will play forward, then backwards a defined amount of times.
    case repeatBackwards(Int)
}

/// Defines how the animation content is scaled within its bounds.
public enum MotionContentMode: Hashable, Sendable {
    /// Scale the animation to fit within the bounds while preserving aspect ratio.
    case fit
    /// Scale the animation to fill the bounds while preserving aspect ratio, cropping if needed.
    case fill
}

/// A dynamic property override for a Lottie animation.
///
/// Use this to change colors in specific animation layers at runtime.
/// The keypath uses dot-separated notation matching Lottie's layer hierarchy
/// (e.g., `"**.Fill 1.Color"` to target all Fill 1 colors).
// SKIP @nobridge
public struct MotionDynamicProperty: Sendable {
    /// The Lottie keypath targeting the property to override (dot-separated, e.g. `"**.Fill 1.Color"`).
    public let keypath: String
    /// The color value to apply at the specified keypath.
    public let color: Color

    public init(keypath: String, color: Color) {
        self.keypath = keypath
        self.color = color
    }
}

/// A MotionView embeds a Lottie animation supporting both JSON and DotLottie (.lottie) formats.
///
/// Load animations by name from a bundle, from raw JSON data, or from DotLottie data:
/// ```swift
/// // Named resource (auto-detects .lottie or .json)
/// MotionView(named: "Landing_V04", bundle: .module, loopMode: .playOnce)
///
/// // Raw JSON data
/// MotionView(jsonData: jsonData, animationSpeed: 1.2)
///
/// // DotLottie (.lottie) data
/// MotionView(dotLottieData: dotLottieData, loopMode: .loop)
/// ```
public struct MotionView : View {
    let lottieContainer: LottieContainer?
    let rawDotLottieData: Data?
    let resourceName: String?
    let resourceBundle: Bundle?
    let animationSpeed: Double
    let loopMode: MotionLoopMode
    let isPlaying: Bool
    let contentMode: MotionContentMode
    let currentProgress: Double?
    let fromProgress: Double?
    let toProgress: Double?
    let fromFrame: CGFloat?
    let toFrame: CGFloat?
    let enableMergePaths: Bool
    let currentFrame: CGFloat?
    let dynamicProperties: [MotionDynamicProperty]
    let onComplete: ((Bool) -> Void)?

    /// Creates a MotionView from raw Lottie JSON data with dynamic property support.
    // SKIP @nobridge
    public init(lottie lottieData: Data, animationSpeed: Double = 1.0, loopMode: MotionLoopMode = .loop, isPlaying: Bool = true, contentMode: MotionContentMode = .fit, currentProgress: Double? = nil, fromProgress: Double? = nil, toProgress: Double? = nil, fromFrame: CGFloat? = nil, toFrame: CGFloat? = nil, enableMergePaths: Bool = false, currentFrame: CGFloat? = nil, dynamicProperties: [MotionDynamicProperty] = [], onComplete: ((Bool) -> Void)? = nil) {
        var lottieContainer: LottieContainer? = nil
        do {
            lottieContainer = try LottieContainer(data: lottieData)
        } catch {
            logger.error("Unable to parse Lottie data: \(error)")
        }
        self.lottieContainer = lottieContainer
        self.rawDotLottieData = nil
        self.resourceName = nil
        self.resourceBundle = nil
        self.animationSpeed = animationSpeed
        self.loopMode = loopMode
        self.isPlaying = isPlaying
        self.contentMode = contentMode
        self.currentProgress = currentProgress
        self.fromProgress = fromProgress
        self.toProgress = toProgress
        self.fromFrame = fromFrame
        self.toFrame = toFrame
        self.enableMergePaths = enableMergePaths
        self.currentFrame = currentFrame
        self.dynamicProperties = dynamicProperties
        self.onComplete = onComplete
    }

    /// Creates a MotionView from a pre-parsed LottieContainer with dynamic property support.
    // SKIP @nobridge
    public init(lottie lottieContainer: LottieContainer, animationSpeed: Double = 1.0, loopMode: MotionLoopMode = .loop, isPlaying: Bool = true, contentMode: MotionContentMode = .fit, currentProgress: Double? = nil, fromProgress: Double? = nil, toProgress: Double? = nil, fromFrame: CGFloat? = nil, toFrame: CGFloat? = nil, enableMergePaths: Bool = false, currentFrame: CGFloat? = nil, dynamicProperties: [MotionDynamicProperty] = [], onComplete: ((Bool) -> Void)? = nil) {
        self.lottieContainer = lottieContainer
        self.rawDotLottieData = nil
        self.resourceName = nil
        self.resourceBundle = nil
        self.animationSpeed = animationSpeed
        self.loopMode = loopMode
        self.isPlaying = isPlaying
        self.contentMode = contentMode
        self.currentProgress = currentProgress
        self.fromProgress = fromProgress
        self.toProgress = toProgress
        self.fromFrame = fromFrame
        self.toFrame = toFrame
        self.enableMergePaths = enableMergePaths
        self.currentFrame = currentFrame
        self.dynamicProperties = dynamicProperties
        self.onComplete = onComplete
    }

    /// Creates a MotionView from raw DotLottie (.lottie) data with dynamic property support.
    ///
    /// DotLottie data is parsed asynchronously in the body to avoid blocking the main thread.
    // SKIP @nobridge
    public init(dotLottie dotLottieData: Data, animationSpeed: Double = 1.0, loopMode: MotionLoopMode = .loop, isPlaying: Bool = true, contentMode: MotionContentMode = .fit, currentProgress: Double? = nil, fromProgress: Double? = nil, toProgress: Double? = nil, fromFrame: CGFloat? = nil, toFrame: CGFloat? = nil, enableMergePaths: Bool = false, currentFrame: CGFloat? = nil, dynamicProperties: [MotionDynamicProperty] = [], onComplete: ((Bool) -> Void)? = nil) {
        self.lottieContainer = nil
        self.rawDotLottieData = dotLottieData
        self.resourceName = nil
        self.resourceBundle = nil
        self.animationSpeed = animationSpeed
        self.loopMode = loopMode
        self.isPlaying = isPlaying
        self.contentMode = contentMode
        self.currentProgress = currentProgress
        self.fromProgress = fromProgress
        self.toProgress = toProgress
        self.fromFrame = fromFrame
        self.toFrame = toFrame
        self.enableMergePaths = enableMergePaths
        self.currentFrame = currentFrame
        self.dynamicProperties = dynamicProperties
        self.onComplete = onComplete
    }

    /// Creates a MotionView that loads a named animation resource from a bundle.
    ///
    /// Automatically detects `.lottie` (DotLottie) and `.json` formats by checking
    /// for a `.lottie` resource first, then falling back to `.json`.
    ///
    /// - Note: This initializer is only available in transpiled (Skip) contexts. For native
    ///   (Fuse) consumers, use `init(jsonData:)` or `init(dotLottieData:)` instead.
    ///
    /// - Parameters:
    ///   - name: The resource name without extension (e.g., `"Landing_V04"`).
    ///   - bundle: The bundle containing the resource. Defaults to `.main`.
    // SKIP @nobridge
    public init(named name: String, bundle: Bundle = .main, animationSpeed: Double = 1.0, loopMode: MotionLoopMode = .loop, isPlaying: Bool = true, contentMode: MotionContentMode = .fit, currentProgress: Double? = nil, fromProgress: Double? = nil, toProgress: Double? = nil, fromFrame: CGFloat? = nil, toFrame: CGFloat? = nil, enableMergePaths: Bool = false, currentFrame: CGFloat? = nil, dynamicProperties: [MotionDynamicProperty] = [], onComplete: ((Bool) -> Void)? = nil) {
        self.lottieContainer = nil
        self.rawDotLottieData = nil
        self.resourceName = name
        self.resourceBundle = bundle
        self.animationSpeed = animationSpeed
        self.loopMode = loopMode
        self.isPlaying = isPlaying
        self.contentMode = contentMode
        self.currentProgress = currentProgress
        self.fromProgress = fromProgress
        self.toProgress = toProgress
        self.fromFrame = fromFrame
        self.toFrame = toFrame
        self.enableMergePaths = enableMergePaths
        self.currentFrame = currentFrame
        self.dynamicProperties = dynamicProperties
        self.onComplete = onComplete
    }

    // MARK: - Bridge-friendly initializers
    // These initializers omit Bundle and [MotionDynamicProperty] parameters
    // so they can cross the native↔transpiled bridge.

    /// Creates a MotionView from raw Lottie JSON data.
    public init(jsonData: Data, animationSpeed: Double = 1.0, loopMode: MotionLoopMode = .loop, isPlaying: Bool = true, contentMode: MotionContentMode = .fit, currentProgress: Double? = nil, fromProgress: Double? = nil, toProgress: Double? = nil, fromFrame: CGFloat? = nil, toFrame: CGFloat? = nil, enableMergePaths: Bool = false, currentFrame: CGFloat? = nil, onComplete: ((Bool) -> Void)? = nil) {
        var lottieContainer: LottieContainer? = nil
        do {
            lottieContainer = try LottieContainer(data: jsonData)
        } catch {
            logger.error("Unable to parse Lottie data: \(error)")
        }
        self.lottieContainer = lottieContainer
        self.rawDotLottieData = nil
        self.resourceName = nil
        self.resourceBundle = nil
        self.animationSpeed = animationSpeed
        self.loopMode = loopMode
        self.isPlaying = isPlaying
        self.contentMode = contentMode
        self.currentProgress = currentProgress
        self.fromProgress = fromProgress
        self.toProgress = toProgress
        self.fromFrame = fromFrame
        self.toFrame = toFrame
        self.enableMergePaths = enableMergePaths
        self.currentFrame = currentFrame
        self.dynamicProperties = []
        self.onComplete = onComplete
    }

    /// Creates a MotionView from raw DotLottie (.lottie) data.
    ///
    /// DotLottie data is parsed asynchronously in the body to avoid blocking the main thread.
    public init(dotLottieData: Data, animationSpeed: Double = 1.0, loopMode: MotionLoopMode = .loop, isPlaying: Bool = true, contentMode: MotionContentMode = .fit, currentProgress: Double? = nil, fromProgress: Double? = nil, toProgress: Double? = nil, fromFrame: CGFloat? = nil, toFrame: CGFloat? = nil, enableMergePaths: Bool = false, currentFrame: CGFloat? = nil, onComplete: ((Bool) -> Void)? = nil) {
        self.lottieContainer = nil
        self.rawDotLottieData = dotLottieData
        self.resourceName = nil
        self.resourceBundle = nil
        self.animationSpeed = animationSpeed
        self.loopMode = loopMode
        self.isPlaying = isPlaying
        self.contentMode = contentMode
        self.currentProgress = currentProgress
        self.fromProgress = fromProgress
        self.toProgress = toProgress
        self.fromFrame = fromFrame
        self.toFrame = toFrame
        self.enableMergePaths = enableMergePaths
        self.currentFrame = currentFrame
        self.dynamicProperties = []
        self.onComplete = onComplete
    }

    // MARK: - iOS Implementation

    #if !SKIP
    private var lottieLoopMode: LottieLoopMode {
        switch loopMode {
        case .playOnce:
            return .playOnce
        case .loop:
            return .loop
        case .autoReverse:
            return .autoReverse
        case .repeat(let count):
            return .repeat(Float(count))
        case .repeatBackwards(let count):
            return .repeatBackwards(Float(count))
        }
    }

    private var playbackState: LottiePlaybackMode {
        if isPlaying {
            if let fromF = fromFrame, let toF = toFrame, fromF < toF {
                return .playing(.fromFrame(fromF, toFrame: toF, loopMode: lottieLoopMode))
            } else if let from = fromProgress, let to = toProgress, from < to {
                return .playing(.fromProgress(from, toProgress: to, loopMode: lottieLoopMode))
            } else {
                return .playing(.toProgress(1, loopMode: lottieLoopMode))
            }
        } else if let progress = currentProgress {
            return .paused(at: .progress(progress))
        } else if let frame = currentFrame {
            return .paused(at: .frame(frame))
        } else {
            return .paused
        }
    }

    public var body: some View {
        if let resourceName {
            namedResourceBody(name: resourceName, bundle: resourceBundle ?? .main)
        } else if let rawDotLottieData {
            dotLottieDataBody(data: rawDotLottieData)
        } else if let lottieContainer {
            containerBody(container: lottieContainer)
        }
    }

    @ViewBuilder
    private func namedResourceBody(name: String, bundle: Bundle) -> some View {
        if bundle.url(forResource: name, withExtension: "lottie") != nil {
            // .lottie file — use LottieView's native async DotLottie loading
            LottieView {
                try await DotLottieFile.named(name, bundle: bundle)
            }
            .playbackMode(playbackState)
            .animationSpeed(animationSpeed)
            .animationDidFinishOptional(onComplete)
            .configureOptionalDynamic(dynamicProperties)
            .resizable()
            .scaledToFillOptional(contentMode == .fill)
        } else {
            // .json file — use sync LottieAnimation.named()
            LottieView(animation: .named(name, bundle: bundle))
                .playbackMode(playbackState)
                .animationSpeed(animationSpeed)
                .animationDidFinishOptional(onComplete)
                .configureOptionalDynamic(dynamicProperties)
                .resizable()
                .scaledToFillOptional(contentMode == .fill)
        }
    }

    @ViewBuilder
    private func dotLottieDataBody(data: Data) -> some View {
        // Parse DotLottie data asynchronously off the main thread
        LottieView {
            try await Task.detached {
                try DotLottieFile.SynchronouslyBlockingCurrentThread
                    .loadedFrom(data: data, filename: "animation")
                    .get()
            }.value
        }
        .playbackMode(playbackState)
        .animationSpeed(animationSpeed)
        .animationDidFinishOptional(onComplete)
        .configureOptionalDynamic(dynamicProperties)
        .resizable()
        .scaledToFillOptional(contentMode == .fill)
    }

    @ViewBuilder
    private func containerBody(container: LottieContainer) -> some View {
        LottieView(animation: container.lottieAnimation)
            .playbackMode(playbackState)
            .animationSpeed(animationSpeed)
            .animationDidFinishOptional(onComplete)
            .configureOptionalDynamic(dynamicProperties)
            .resizable()
            .scaledToFillOptional(contentMode == .fill)
    }

    // MARK: - Android Implementation

    #else
    private var iterations: Int {
        switch loopMode {
        case .playOnce:
            return 1
        case .loop, .autoReverse:
            return LottieConstants.IterateForever
        case .repeat(let count):
            return count
        case .repeatBackwards(let count):
            return count
        }
    }

    private var reverseOnRepeat: Bool {
        switch loopMode {
        case .autoReverse:
            return true
        case .repeatBackwards:
            return true
        default:
            return false
        }
    }

    private var composeContentScale: ContentScale {
        switch contentMode {
        case .fit:
            return ContentScale.Fit
        case .fill:
            return ContentScale.Crop
        }
    }

    private var progressClipSpec: LottieClipSpec? {
        if let from = fromProgress, let to = toProgress, from < to {
            return LottieClipSpec.Progress(min: from.toFloat(), max: to.toFloat())
        }
        return nil
    }

    // SKIP @nobridge
    @Composable override func ComposeContent(context: ComposeContext) {
        // Resolve the composition from either named resource or pre-loaded container
        var composition: LottieComposition? = nil

        if let resourceName {
            // Named resource — async loading via LaunchedEffect
            let loadedComposition = remember { mutableStateOf<LottieComposition?>(nil) }
            let bundle = resourceBundle ?? Bundle.main

            LaunchedEffect(resourceName) {
                // Try .lottie (DotLottie ZIP) first, then .json
                if let url = bundle.url(forResource: resourceName, withExtension: "lottie") {
                    do {
                        let data = try Data(contentsOf: url)
                        let zipStream = ZipInputStream(data.platformData.inputStream())
                        let result = LottieCompositionFactory.fromZipStreamSync(zipStream, resourceName)
                        loadedComposition.value = result.getValue()
                    } catch {
                        logger.error("Failed to load .lottie resource '\(resourceName)': \(error)")
                    }
                } else if let url = bundle.url(forResource: resourceName, withExtension: "json") {
                    do {
                        let data = try Data(contentsOf: url)
                        let result = LottieCompositionFactory.fromJsonInputStreamSync(data.platformData.inputStream(), resourceName)
                        loadedComposition.value = result.getValue()
                    } catch {
                        logger.error("Failed to load .json resource '\(resourceName)': \(error)")
                    }
                } else {
                    logger.error("Animation resource '\(resourceName)' not found in bundle")
                }
            }

            composition = loadedComposition.value
        } else if let rawDotLottieData {
            // DotLottie raw data — async loading via LaunchedEffect
            let loadedComposition = remember { mutableStateOf<LottieComposition?>(nil) }

            LaunchedEffect(Unit) {
                do {
                    let zipStream = ZipInputStream(rawDotLottieData.platformData.inputStream())
                    let result = LottieCompositionFactory.fromZipStreamSync(zipStream, nil)
                    loadedComposition.value = result.getValue()
                } catch {
                    logger.error("Failed to load DotLottie data: \(error)")
                }
            }

            composition = loadedComposition.value
        } else if let lottieContainer {
            composition = lottieContainer.lottieComposition
        }

        guard let composition else {
            return
        }

        // Calculate effective clip spec (frame-based takes priority over progress-based)
        var effectiveClipSpec = progressClipSpec
        if effectiveClipSpec == nil, let fromF = fromFrame, let toF = toFrame, fromF < toF {
            let fromP = composition.getProgressForFrame(fromF.toFloat())
            let toP = composition.getProgressForFrame(toF.toFloat())
            effectiveClipSpec = LottieClipSpec.Progress(min: fromP, max: toP)
        }

        // Build dynamic properties for Android via Kotlin helper
        // SKIP INSERT: val lottieDynProps = buildMotionDynamicProperties(dynamicProperties.toList())

        let contentContext = context.content()
        ComposeContainer(modifier: context.modifier) { modifier in
            if !isPlaying, let progress = currentProgress {
                // Paused at specific progress
                // SKIP REPLACE: LottieAnimation(composition, progress = { progress.toFloat() }, modifier = modifier.fillMaxSize(), contentScale = composeContentScale, dynamicProperties = lottieDynProps, enableMergePaths = enableMergePaths)
                LottieAnimation(composition,
                                progress: { progress.toFloat() },
                                modifier: modifier.fillMaxSize(),
                                contentScale: composeContentScale,
                                enableMergePaths: enableMergePaths)
            } else if !isPlaying, let frame = currentFrame {
                // Paused at specific frame
                let frameProgress = composition.getProgressForFrame(frame.toFloat())
                // SKIP REPLACE: LottieAnimation(composition, progress = { frameProgress }, modifier = modifier.fillMaxSize(), contentScale = composeContentScale, dynamicProperties = lottieDynProps, enableMergePaths = enableMergePaths)
                LottieAnimation(composition,
                                progress: { frameProgress },
                                modifier: modifier.fillMaxSize(),
                                contentScale: composeContentScale,
                                enableMergePaths: enableMergePaths)
            } else if let onComplete = onComplete {
                // Animated playback with completion tracking
                let animationState = animateLottieCompositionAsState(
                    composition: composition,
                    isPlaying: isPlaying,
                    iterations: iterations,
                    speed: animationSpeed.toFloat(),
                    reverseOnRepeat: reverseOnRepeat,
                    clipSpec: effectiveClipSpec
                )

                let wasPlaying = remember { mutableStateOf(false) }
                LaunchedEffect(animationState.isPlaying, animationState.isAtEnd) {
                    if wasPlaying.value && !animationState.isPlaying {
                        onComplete(animationState.isAtEnd)
                    }
                    wasPlaying.value = animationState.isPlaying
                }

                // SKIP REPLACE: LottieAnimation(composition, progress = { animationState.progress }, modifier = modifier.fillMaxSize(), contentScale = composeContentScale, dynamicProperties = lottieDynProps, enableMergePaths = enableMergePaths)
                LottieAnimation(composition,
                                progress: { animationState.progress },
                                modifier: modifier.fillMaxSize(),
                                contentScale: composeContentScale,
                                enableMergePaths: enableMergePaths)
            } else {
                // Normal animated playback
                // SKIP REPLACE: LottieAnimation(composition, modifier = modifier.fillMaxSize(), isPlaying = isPlaying, iterations = iterations, speed = animationSpeed.toFloat(), reverseOnRepeat = reverseOnRepeat, clipSpec = effectiveClipSpec, contentScale = composeContentScale, dynamicProperties = lottieDynProps, enableMergePaths = enableMergePaths)
                LottieAnimation(composition,
                                modifier: modifier.fillMaxSize(),
                                isPlaying: isPlaying,
                                iterations: iterations,
                                speed: animationSpeed.toFloat(),
                                reverseOnRepeat: reverseOnRepeat,
                                clipSpec: effectiveClipSpec,
                                contentScale: composeContentScale,
                                enableMergePaths: enableMergePaths)
            }
        }
    }
    #endif
}

// MARK: - LottieContainer

/// A container for Lottie animation data supporting both JSON and DotLottie formats.
///
/// This is the serialized model from which the animation will be created. It is designed
/// to be stateless, cacheable, and shareable.
///
/// In Swift, this wraps a `Lottie.LottieAnimation` and on Android it wraps a
/// `com.airbnb.lottie.LottieComposition`.
public struct LottieContainer : Sendable {
    #if !SKIP
    let lottieAnimation: LottieAnimation
    #else
    let lottieComposition: LottieComposition
    #endif

    /// Creates a LottieContainer from Lottie JSON data.
    public init(data lottieData: Data) throws {
        #if !SKIP
        self.lottieAnimation = try LottieAnimation.from(data: lottieData)
        #else
        let compositionResult = try LottieCompositionFactory.fromJsonInputStreamSync(lottieData.platformData.inputStream(), nil)

        guard let composition = compositionResult.getValue() else {
            throw compositionResult.getException() ?? IllegalArgumentException("Unable to load composition from data")
        }
        self.lottieComposition = composition
        #endif
    }

    /// Creates a LottieContainer from DotLottie (.lottie) data.
    ///
    /// The DotLottie format is a ZIP archive containing animation JSON and optional assets.
    public init(dotLottieData: Data) throws {
        #if !SKIP
        let result = DotLottieFile.SynchronouslyBlockingCurrentThread.loadedFrom(data: dotLottieData, filename: "animation")
        let dotLottieFile = try result.get()
        guard let firstAnimation = dotLottieFile.animations.first else {
            throw MotionError.noAnimationFound
        }
        self.lottieAnimation = firstAnimation.animation
        #else
        let zipStream = ZipInputStream(dotLottieData.platformData.inputStream())
        let compositionResult = LottieCompositionFactory.fromZipStreamSync(zipStream, nil)

        guard let composition = compositionResult.getValue() else {
            throw compositionResult.getException() ?? IllegalArgumentException("Unable to load dotlottie composition from data")
        }
        self.lottieComposition = composition
        #endif
    }

    public var duration: TimeInterval {
        #if !SKIP
        lottieAnimation.duration
        #else
        lottieComposition.duration.toDouble() / 1000.0 // kotlin.Float milliseconds
        #endif
    }

    public var startFrame: CGFloat {
        #if !SKIP
        lottieAnimation.startFrame
        #else
        lottieComposition.startFrame.toDouble()
        #endif
    }

    public var endFrame: CGFloat {
        #if !SKIP
        lottieAnimation.endFrame
        #else
        lottieComposition.endFrame.toDouble()
        #endif
    }

    public var framerate: Double {
        #if !SKIP
        lottieAnimation.framerate
        #else
        lottieComposition.getFrameRate().toDouble()
        #endif
    }

    public var width: Double {
        bounds.width
    }

    public var height: Double {
        bounds.height
    }

    // SKIP @nobridge
    public var bounds: CGRect {
        #if !SKIP
        lottieAnimation.bounds
        #else
        let rect: android.graphics.Rect = lottieComposition.bounds
        let x: Int = rect.left
        let y: Int = rect.top
        let width: Int = rect.right - x
        let height: Int = rect.bottom - y
        return CGRect(x: x, y: y, width: width, height: height)
        #endif
    }
}

// MARK: - iOS Helper Extensions

#if !SKIP
private extension LottieView {
    func animationDidFinishOptional(_ handler: ((Bool) -> Void)?) -> Self {
        if let handler {
            return self.animationDidFinish { finished in handler(finished) }
        } else {
            return self
        }
    }

    func configureOptionalDynamic(_ properties: [MotionDynamicProperty]) -> Self {
        if properties.isEmpty {
            return self
        }
        return self.configure { lottieView in
            for prop in properties {
                let lottieColor = prop.color.resolvedLottieColor
                let provider = ColorValueProvider(lottieColor)
                lottieView.setValueProvider(provider, keypath: AnimationKeypath(keypath: prop.keypath))
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func scaledToFillOptional(_ condition: Bool) -> some View {
        if condition {
            self.scaledToFill()
        } else {
            self
        }
    }
}

extension Color {
    /// Converts a SwiftUI Color to a Lottie LottieColor for use with dynamic properties.
    var resolvedLottieColor: LottieColor {
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return LottieColor(r: r, g: g, b: b, a: a)
        #elseif canImport(AppKit)
        let nsColor = NSColor(self)
        if let rgb = nsColor.usingColorSpace(.sRGB) {
            return LottieColor(r: rgb.redComponent, g: rgb.greenComponent, b: rgb.blueComponent, a: rgb.alphaComponent)
        }
        return LottieColor(r: 0, g: 0, b: 0, a: 1)
        #endif
    }
}
#endif
#endif
