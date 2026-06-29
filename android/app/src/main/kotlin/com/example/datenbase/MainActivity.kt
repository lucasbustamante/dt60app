package com.example.datenbase

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.biometrics.BiometricPrompt
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.hardware.camera2.CameraMetadata
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbManager
import android.os.Build
import android.os.Bundle
import android.os.CancellationSignal
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import android.view.KeyEvent
import com.ftpos.apiservice.aidl.led.LedConfig
import com.ftpos.apiservice.aidl.led.LedIndex
import com.ftpos.apiservice.aidl.led.LedMode
import com.ftpos.library.smartpos.datautils.IntTypeValue
import com.ftpos.library.smartpos.icreader.IcReader
import com.ftpos.library.smartpos.icreader.OnIcReaderCallback
import com.ftpos.library.smartpos.led.Led
import com.ftpos.library.smartpos.magreader.MagReader
import com.ftpos.library.smartpos.magreader.OnMagReadCallback
import com.ftpos.library.smartpos.magreader.TrackDataInfo
import com.ftpos.library.smartpos.nfcreader.NfcReader
import com.ftpos.library.smartpos.nfcreader.OnNfcReaderCallback
import com.ftpos.library.smartpos.servicemanager.OnServiceConnectCallback
import com.ftpos.library.smartpos.servicemanager.ServiceManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean

class MainActivity : FlutterActivity() {
    private val cardChannelName = "pinpad_terminal/card_reader"
    private val permissionChannelName = "pinpad_terminal/permissions"
    private val cameraRequestCode = 8831

    private val mainHandler = Handler(Looper.getMainLooper())
    private val hardwareThread = HandlerThread("PinpadHardware").also { it.start() }
    private val hardwareHandler = Handler(hardwareThread.looper)
    private var cardChannel: MethodChannel? = null
    private var permissionResult: MethodChannel.Result? = null
    private var fingerprintCancelSignal: CancellationSignal? = null

    private val serviceReady = AtomicBoolean(false)
    private val detecting = AtomicBoolean(false)
    private val icRunning = AtomicBoolean(false)
    private val magRunning = AtomicBoolean(false)
    private val nfcRunning = AtomicBoolean(false)
    private val fallbackPolling = AtomicBoolean(false)
    private val eventSent = AtomicBoolean(false)
    private val faceLedBlinking = AtomicBoolean(false)
    private val fingerprintDetecting = AtomicBoolean(false)

    private var icReader: IcReader? = null
    private var magReader: MagReader? = null
    private var nfcReader: NfcReader? = null
    private var led: Led? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        bindSdkService()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        cardChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, cardChannelName)
        cardChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startCardDetection", "startIcCardDetection", "startMagCardDetection", "startNfcDetection" -> {
                    startCardDetection()
                    result.success(true)
                }
                "stopCardDetection", "stopIcCardDetection", "stopMagCardDetection", "stopNfcDetection" -> {
                    stopCardDetection()
                    result.success(true)
                }
                "startFingerprintDetection" -> {
                    startFingerprintDetection()
                    result.success(true)
                }
                "stopFingerprintDetection" -> {
                    stopFingerprintDetection()
                    result.success(true)
                }
                "setStatusLed" -> {
                    val color = call.argument<String>("color") ?: "off"
                    result.success(setStatusLed(color))
                }
                "testLed" -> {
                    val target = call.argument<String>("target") ?: "all"
                    val color = call.argument<String>("color") ?: "off"
                    val effect = call.argument<String>("effect") ?: "solid"
                    val code = call.argument<Int>("code")
                    val index = call.argument<Int>("index")
                    val red = call.argument<Int>("red")
                    val green = call.argument<Int>("green")
                    val blue = call.argument<Int>("blue")
                    result.success(testLed(target, color, effect, code, index, red, green, blue))
                }
                "playFixedLedLoading" -> {
                    playFixedLedLoading()
                    result.success(true)
                }
                "startFaceLedBlink" -> {
                    startFaceLedBlink()
                    result.success(true)
                }
                "stopFaceLedBlink" -> {
                    stopFaceLedBlink()
                    result.success(true)
                }
                "ledOff" -> result.success(setStatusLed("off"))
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, permissionChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestCameraPermission" -> requestCameraPermission(result)
                    "hasCameraPermission" -> result.success(hasCameraPermission())
                    "getCameraDiagnostics" -> result.success(getCameraDiagnostics())
                    else -> result.notImplemented()
                }
            }
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        val method = when (event.keyCode) {
            KeyEvent.KEYCODE_ENTER,
            KeyEvent.KEYCODE_NUMPAD_ENTER,
            KeyEvent.KEYCODE_DPAD_CENTER -> "onPinpadEnter"
            KeyEvent.KEYCODE_BACK,
            KeyEvent.KEYCODE_ESCAPE -> "onPinpadCancel"
            KeyEvent.KEYCODE_DEL,
            KeyEvent.KEYCODE_FORWARD_DEL,
            KeyEvent.KEYCODE_CLEAR -> "onPinpadClear"
            else -> null
        }

        if (method != null) {
            if (event.action == KeyEvent.ACTION_UP) {
                sendCardEvent(
                    method,
                    mapOf(
                        "source" to "hardware_key",
                        "keyCode" to event.keyCode
                    )
                )
            }
            return true
        }

        return super.dispatchKeyEvent(event)
    }

    private fun bindSdkService() {
        try {
            ServiceManager.bindPosServer(this, object : OnServiceConnectCallback {
                override fun onSuccess() {
                    serviceReady.set(true)
                    icReader = IcReader.getInstance(this@MainActivity)
                    magReader = MagReader.getInstance(this@MainActivity)
                    nfcReader = NfcReader.getInstance(this@MainActivity)
                    led = Led.getInstance(this@MainActivity)
                    if (detecting.get()) hardwareHandler.post { startReadersLoop() }
                }

                override fun onFail(error: Int) {
                    serviceReady.set(false)
                    sendCardEvent("onCardReaderError", mapOf("source" to "service", "code" to error))
                    retryBindService()
                }
            })
        } catch (error: Throwable) {
            serviceReady.set(false)
            sendCardEvent("onCardReaderError", mapOf("source" to "service", "message" to (error.message ?: error.toString())))
            retryBindService()
        }
    }

    private fun retryBindService() {
        mainHandler.postDelayed({ if (!serviceReady.get()) bindSdkService() }, 1200L)
    }

    private fun startCardDetection() {
        // Reabre os leitores sempre do zero. Em alguns firmwares FT/F310, deixar uma busca antiga
        // aberta faz o leitor só destravar depois do botão ANULA. Por isso cancelamos/fechamos antes
        // de iniciar uma nova rodada curta de leitura.
        eventSent.set(false)
        detecting.set(true)
        hardwareHandler.post {
            stopCardHardwareOnly()
            if (!serviceReady.get()) {
                mainHandler.post { bindSdkService() }
                return@post
            }
            hardwareHandler.postDelayed({ startReadersLoop() }, 180L)
        }
    }

    private fun startReadersLoop() {
        if (!detecting.get() || !serviceReady.get()) return
        startFallbackPollingLoop()
        startIcLoop()
        startMagLoop()
        startNfcLoop()
    }

    private fun stopCardDetection() {
        detecting.set(false)
        fallbackPolling.set(false)
        eventSent.set(false)
        hardwareHandler.post { stopCardHardwareOnly() }
    }

    private fun stopCardHardwareOnly() {
        icRunning.set(false)
        magRunning.set(false)
        nfcRunning.set(false)
        try { icReader?.cancel() } catch (_: Throwable) {}
        try { magReader?.cancel() } catch (_: Throwable) {}
        try { nfcReader?.cancel() } catch (_: Throwable) {}
        try { nfcReader?.close() } catch (_: Throwable) {}
    }

    private fun startIcLoop() {
        if (!detecting.get() || !serviceReady.get() || icRunning.getAndSet(true)) return
        try {
            val reader = icReader ?: IcReader.getInstance(this).also { icReader = it }
            reader.openCard(2, object : OnIcReaderCallback {
                override fun onCardATR(atr: ByteArray?) {
                    icRunning.set(false)
                    emitOnce("onIcCardDetected", mapOf("reader" to "ic", "atrLength" to (atr?.size ?: 0)))
                    if (detecting.get()) hardwareHandler.postDelayed({ startIcLoop() }, 220L)
                }

                override fun onError(error: Int) {
                    icRunning.set(false)
                    if (detecting.get()) hardwareHandler.postDelayed({ startIcLoop() }, 360L)
                }
            })
        } catch (error: Throwable) {
            icRunning.set(false)
            sendCardEvent("onCardReaderError", mapOf("source" to "ic", "message" to (error.message ?: error.toString())))
            if (detecting.get()) hardwareHandler.postDelayed({ startIcLoop() }, 700L)
        }
    }

    private fun startMagLoop() {
        if (!detecting.get() || !serviceReady.get() || magRunning.getAndSet(true)) return
        try {
            val reader = magReader ?: MagReader.getInstance(this).also { magReader = it }
            reader.readMagCard(2, 0, object : OnMagReadCallback {
                override fun onTrackData(trackData: TrackDataInfo?) {
                    magRunning.set(false)
                    val t1 = trackData?.getmTrack1Data()?.size ?: 0
                    val t2 = trackData?.getmTrack2Data()?.size ?: 0
                    val t3 = trackData?.getmTrack3Data()?.size ?: 0
                    emitOnce("onMagCardSwiped", mapOf("reader" to "mag", "track1Length" to t1, "track2Length" to t2, "track3Length" to t3))
                    if (detecting.get()) hardwareHandler.postDelayed({ startMagLoop() }, 220L)
                }

                override fun onError(error: Int) {
                    magRunning.set(false)
                    if (detecting.get()) hardwareHandler.postDelayed({ startMagLoop() }, 360L)
                }
            })
        } catch (error: Throwable) {
            magRunning.set(false)
            sendCardEvent("onCardReaderError", mapOf("source" to "mag", "message" to (error.message ?: error.toString())))
            if (detecting.get()) hardwareHandler.postDelayed({ startMagLoop() }, 700L)
        }
    }

    private fun startNfcLoop() {
        if (!detecting.get() || !serviceReady.get() || nfcRunning.getAndSet(true)) return
        try {
            val reader = nfcReader ?: NfcReader.getInstance(this).also { nfcReader = it }
            reader.openCard(2, object : OnNfcReaderCallback {
                override fun onCardATR(atr: ByteArray?) {
                    nfcRunning.set(false)
                    emitOnce("onNfcCardDetected", mapOf("reader" to "nfc", "atrLength" to (atr?.size ?: 0)))
                    if (detecting.get()) hardwareHandler.postDelayed({ startNfcLoop() }, 220L)
                }

                override fun onError(error: Int) {
                    nfcRunning.set(false)
                    if (detecting.get()) hardwareHandler.postDelayed({ startNfcLoop() }, 360L)
                }
            })
        } catch (error: Throwable) {
            nfcRunning.set(false)
            sendCardEvent("onCardReaderError", mapOf("source" to "nfc", "message" to (error.message ?: error.toString())))
            if (detecting.get()) hardwareHandler.postDelayed({ startNfcLoop() }, 700L)
        }
    }

    private fun startFingerprintDetection() {
        // Não usamos fallback por tempo. Antes o app avançava sozinho após ~1s; agora só emite
        // onFingerprintDetected quando o Android/firmware confirmar toque/autenticação no sensor.
        stopCardDetection()
        stopFingerprintDetection()
        fingerprintDetecting.set(true)
        sendCardEvent("onFingerprintWaiting", mapOf("source" to "finger_presence_wait"))

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
            sendCardEvent("onFingerprintError", mapOf("source" to "finger", "message" to "BiometricPrompt indisponível neste Android"))
            return
        }

        try {
            val cancelSignal = CancellationSignal()
            fingerprintCancelSignal = cancelSignal
            val prompt = BiometricPrompt.Builder(this)
                .setTitle("Toque no sensor")
                .setSubtitle("Coloque o dedo no sensor biométrico")
                .setDescription("A tela só avança quando o sensor confirmar a presença do dedo.")
                .setNegativeButton("Cancelar", mainExecutor) { _, _ ->
                    fingerprintDetecting.set(false)
                    sendCardEvent("onFingerprintCancelled", mapOf("source" to "finger"))
                }
                .build()

            prompt.authenticate(
                cancelSignal,
                mainExecutor,
                object : BiometricPrompt.AuthenticationCallback() {
                    override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult?) {
                        if (!fingerprintDetecting.compareAndSet(true, false)) return
                        sendCardEvent("onFingerprintDetected", mapOf("source" to "biometric_prompt"))
                    }

                    override fun onAuthenticationError(errorCode: Int, errString: CharSequence?) {
                        if (!fingerprintDetecting.get()) return
                        fingerprintDetecting.set(false)
                        sendCardEvent("onFingerprintError", mapOf("source" to "finger", "code" to errorCode, "message" to (errString?.toString() ?: "Erro biométrico")))
                    }

                    override fun onAuthenticationFailed() {
                        sendCardEvent("onFingerprintFailed", mapOf("source" to "finger"))
                    }
                }
            )
        } catch (error: Throwable) {
            fingerprintDetecting.set(false)
            sendCardEvent("onFingerprintError", mapOf("source" to "finger", "message" to (error.message ?: error.toString())))
        }
    }

    private fun stopFingerprintDetection() {
        fingerprintDetecting.set(false)
        try { fingerprintCancelSignal?.cancel() } catch (_: Throwable) {}
        fingerprintCancelSignal = null
    }

    private fun setStatusLed(color: String): Boolean {
        return try {
            val normalized = color.lowercase()
            when (normalized) {
                "red", "vermelho", "erro", "error" -> testLed("all", "red", "solid", null)
                "green", "verde", "sucesso", "success" -> testLed("all", "green", "solid", null)
                "blue", "azul" -> testLed("all", "blue", "solid", null)
                "yellow", "amarelo" -> testLed("all", "yellow", "solid", null)
                "purple", "roxo" -> testLed("all", "purple", "solid", null)
                "white", "branco" -> testLed("all", "white", "solid", null)
                else -> testLed("all", "off", "solid", null)
            }
        } catch (error: Throwable) {
            sendCardEvent("onLedError", mapOf("message" to (error.message ?: error.toString())))
            false
        }
    }

    private fun testLed(
        target: String,
        color: String,
        effect: String,
        code: Int?,
        index: Int? = null,
        red: Int? = null,
        green: Int? = null,
        blue: Int? = null
    ): Boolean {
        return try {
            val deviceLed = led ?: Led.getInstance(this).also { led = it }
            val normalizedTarget = target.lowercase()
            val normalizedColor = color.lowercase()
            val normalizedEffect = effect.lowercase()
            val normalizedIndex = index?.coerceIn(0, 12)
            val customConfig = rgbConfig(normalizedColor, red, green, blue)

            when (normalizedTarget) {
                "all" -> {
                    clearAllLeds(deviceLed)
                    if (normalizedColor != "off") {
                        applyFixedLed(deviceLed, normalizedColor)
                        applyTopRgbLed(deviceLed, normalizedColor, normalizedEffect)
                        applyFingerRgbLed(deviceLed, normalizedColor, normalizedEffect, customConfig, normalizedIndex)
                    }
                }
                "fixed", "fixo", "reader", "leitor", "status" -> {
                    clearFixedLeds(deviceLed)
                    if (normalizedColor != "off") applyFixedLed(deviceLed, normalizedColor)
                }
                "top_rgb", "top", "superior", "tela", "screen" -> {
                    if (normalizedColor == "off") try { deviceLed.ledControlLightStrip(0) } catch (_: Throwable) {}
                    else applyTopRgbLed(deviceLed, normalizedColor, normalizedEffect, code)
                }
                "top_rgb_config", "top_config", "superior_rgb_livre" -> {
                    if (normalizedColor == "off") aggressiveLedOff(deviceLed)
                    else {
                        applyTopRgbLed(deviceLed, normalizedColor, normalizedEffect, code)
                        applyTapeLamp(deviceLed, customConfig, normalizedIndex ?: 0)
                    }
                }
                "finger_rgb", "finger", "fingerprint", "digital", "anel" -> {
                    applyFingerRgbLed(deviceLed, normalizedColor, normalizedEffect, customConfig, normalizedIndex)
                }
                "finger_index", "tape_index", "tape_lamp", "tape" -> {
                    if (normalizedColor == "off") applyTapeLamp(deviceLed, LedConfig(0, 0, 0), normalizedIndex ?: 0)
                    else applyTapeLamp(deviceLed, customConfig, normalizedIndex ?: 0)
                }
                "finger_all", "finger_all_indices", "tape_all" -> {
                    if (normalizedColor == "off") aggressiveLedOff(deviceLed)
                    else applyTapeLampAllIndices(deviceLed, customConfig)
                }
                "breath_rgb", "breath", "respirar_rgb" -> {
                    if (normalizedColor == "off") aggressiveLedOff(deviceLed)
                    else try { deviceLed.breathOn(listOf(customConfig), 0, 255, 850, 0L) } catch (_: Throwable) {}
                }
                "marquee_rgb", "marquee", "girar_rgb" -> {
                    if (normalizedColor == "off") aggressiveLedOff(deviceLed)
                    else try { deviceLed.marqueeOn(listOf(customConfig), 12, 90, 0L) } catch (_: Throwable) {}
                }
                "rgb_probe", "probe", "all_rgb_methods" -> {
                    clearAllLeds(deviceLed)
                    if (normalizedColor != "off") {
                        applyTopRgbLed(deviceLed, normalizedColor, normalizedEffect, code)
                        applyTapeLamp(deviceLed, customConfig, normalizedIndex ?: 0)
                        try { deviceLed.breathOn(listOf(customConfig), 0, 255, 850, 0L) } catch (_: Throwable) {}
                        try { deviceLed.marqueeOn(listOf(customConfig), 12, 90, 0L) } catch (_: Throwable) {}
                    }
                }
                "strip_code", "strip", "light_strip", "codigo", "código" -> {
                    try { deviceLed.ledControlLightStrip(code ?: 0) } catch (_: Throwable) {}
                }
                "default", "sdk_default" -> {
                    try { deviceLed.ledDefault() } catch (_: Throwable) {}
                }
                "tape_off", "finger_off", "aggressive_off", "off_all" -> {
                    aggressiveLedOff(deviceLed)
                }
                else -> clearAllLeds(deviceLed)
            }
            true
        } catch (error: Throwable) {
            sendCardEvent("onLedError", mapOf("message" to (error.message ?: error.toString())))
            false
        }
    }

    private fun clearAllLeds(deviceLed: Led) {
        clearFixedLeds(deviceLed)
        aggressiveLedOff(deviceLed)
    }

    private fun clearFixedLeds(deviceLed: Led) {
        try { deviceLed.ledStatus(false, false, false, false) } catch (_: Throwable) {}
        try { deviceLed.ledPartsStatus(false, false, false, false) } catch (_: Throwable) {}
        try { deviceLed.readerLedStatus(LedIndex.LED_RED, false, false, false) } catch (_: Throwable) {}
        try { deviceLed.readerLedStatus(LedIndex.LED_YELLOW, false, false, false) } catch (_: Throwable) {}
        try { deviceLed.readerLedStatus(LedIndex.LED_GREEN, false, false, false) } catch (_: Throwable) {}
        try { deviceLed.readerLedStatus(LedIndex.LED_BLUE, false, false, false) } catch (_: Throwable) {}
    }

    private fun applyFixedLed(deviceLed: Led, color: String) {
        when (color) {
            "red", "vermelho", "erro", "error" -> {
                try { deviceLed.ledStatus(true, false, false, false) } catch (_: Throwable) {}
                try { deviceLed.ledPartsStatus(true, false, false, false) } catch (_: Throwable) {}
                try { deviceLed.readerLedStatus(LedIndex.LED_RED, true, true, true) } catch (_: Throwable) {}
                try { deviceLed.ledCardIndicator(LedIndex.LED_RED, 1, LedMode.LED_MODE_ASYNC, 0) } catch (_: Throwable) {}
            }
            "yellow", "amarelo" -> {
                try { deviceLed.ledStatus(false, true, false, false) } catch (_: Throwable) {}
                try { deviceLed.ledPartsStatus(false, true, false, false) } catch (_: Throwable) {}
                try { deviceLed.readerLedStatus(LedIndex.LED_YELLOW, true, true, true) } catch (_: Throwable) {}
                try { deviceLed.ledCardIndicator(LedIndex.LED_YELLOW, 1, LedMode.LED_MODE_ASYNC, 0) } catch (_: Throwable) {}
            }
            "green", "verde", "sucesso", "success" -> {
                try { deviceLed.ledStatus(false, false, true, false) } catch (_: Throwable) {}
                try { deviceLed.ledPartsStatus(false, false, true, false) } catch (_: Throwable) {}
                try { deviceLed.readerLedStatus(LedIndex.LED_GREEN, true, true, true) } catch (_: Throwable) {}
                try { deviceLed.ledCardIndicator(LedIndex.LED_GREEN, 1, LedMode.LED_MODE_ASYNC, 0) } catch (_: Throwable) {}
            }
            "blue", "azul" -> {
                try { deviceLed.ledStatus(false, false, false, true) } catch (_: Throwable) {}
                try { deviceLed.ledPartsStatus(false, false, false, true) } catch (_: Throwable) {}
                try { deviceLed.readerLedStatus(LedIndex.LED_BLUE, true, true, true) } catch (_: Throwable) {}
                try { deviceLed.ledCardIndicator(LedIndex.LED_BLUE, 1, LedMode.LED_MODE_ASYNC, 0) } catch (_: Throwable) {}
            }
        }
    }

    private fun applyTopRgbLed(deviceLed: Led, color: String, effect: String, explicitCode: Int? = null) {
        val code = explicitCode ?: topRgbCode(color, effect)
        try { deviceLed.ledControlLightStrip(code) } catch (_: Throwable) {}
    }

    private fun applyTapeLamp(deviceLed: Led, ledConfig: LedConfig, index: Int) {
        try { deviceLed.tapeLampOn(ledConfig, index.coerceIn(0, 12)) } catch (_: Throwable) {}
    }

    private fun applyTapeLampAllIndices(deviceLed: Led, ledConfig: LedConfig) {
        for (index in 0..12) {
            applyTapeLamp(deviceLed, ledConfig, index)
        }
    }

    private fun aggressiveLedOff(deviceLed: Led) {
        val black = LedConfig(0, 0, 0)
        try { deviceLed.ledDefault() } catch (_: Throwable) {}
        try { deviceLed.tapeLampOff() } catch (_: Throwable) {}
        try { deviceLed.ledControlLightStrip(0) } catch (_: Throwable) {}
        try { deviceLed.breathOn(listOf(black), 0, 0, 1, 0L) } catch (_: Throwable) {}
        try { deviceLed.marqueeOn(listOf(black), 0, 1, 0L) } catch (_: Throwable) {}
        for (index in 0..12) {
            try { deviceLed.tapeLampOn(black, index) } catch (_: Throwable) {}
        }
        val fixed = listOf(LedIndex.LED_RED, LedIndex.LED_YELLOW, LedIndex.LED_GREEN, LedIndex.LED_BLUE)
        for (ledIndex in fixed) {
            try { deviceLed.readerLedStatus(ledIndex, false, false, false) } catch (_: Throwable) {}
            try { deviceLed.ledCardIndicator(ledIndex, 0, LedMode.LED_MODE_ASYNC, 0) } catch (_: Throwable) {}
        }
    }

    private fun applyFingerRgbLed(
        deviceLed: Led,
        color: String,
        effect: String,
        ledConfig: LedConfig = rgbConfig(color),
        index: Int? = null
    ) {
        if (color == "off") {
            aggressiveLedOff(deviceLed)
            return
        }

        when (effect) {
            "breath", "respirar", "pulso", "piscar" -> {
                try { deviceLed.breathOn(listOf(ledConfig), 0, 255, 850, 0L) } catch (_: Throwable) {
                    applyTapeLamp(deviceLed, ledConfig, index ?: 1)
                }
            }
            "marquee", "girar", "circulo", "círculo" -> {
                try { deviceLed.marqueeOn(listOf(ledConfig), 12, 90, 0L) } catch (_: Throwable) {
                    applyTapeLamp(deviceLed, ledConfig, index ?: 1)
                }
            }
            else -> {
                if (index == null) {
                    applyTapeLampAllIndices(deviceLed, ledConfig)
                } else {
                    applyTapeLamp(deviceLed, ledConfig, index)
                }
            }
        }
    }

    private fun topRgbCode(color: String, effect: String): Int {
        if (color == "off") return 0
        return when (color) {
            "purple", "roxo", "violet", "violeta" -> if (effect == "breath" || effect == "piscar") 4 else 3
            "blue", "azul" -> 1
            "green", "verde", "sucesso", "success" -> 2
            "red", "vermelho", "erro", "error" -> 5
            "white", "branco" -> 6
            "yellow", "amarelo" -> 7
            else -> 3
        }
    }

    private fun playFixedLedLoading() {
        val deviceLed = led ?: try { Led.getInstance(this).also { led = it } } catch (_: Throwable) { null }
        if (deviceLed == null) return
        val colors = listOf("blue", "yellow", "green", "red")
        var delay = 0L
        repeat(2) {
            for (color in colors) {
                mainHandler.postDelayed({
                    try {
                        clearFixedLeds(deviceLed)
                        applyFixedLed(deviceLed, color)
                    } catch (_: Throwable) {}
                }, delay)
                delay += 170L
            }
        }
        mainHandler.postDelayed({ try { clearFixedLeds(deviceLed) } catch (_: Throwable) {} }, delay + 80L)
    }

    private fun startFaceLedBlink() {
        if (!faceLedBlinking.compareAndSet(false, true)) return
        val deviceLed = led ?: try { Led.getInstance(this).also { led = it } } catch (_: Throwable) { null }
        if (deviceLed == null) {
            faceLedBlinking.set(false)
            return
        }
        hardwareHandler.post(object : Runnable {
            var white = false
            override fun run() {
                if (!faceLedBlinking.get()) {
                    try { clearAllLeds(deviceLed) } catch (_: Throwable) {}
                    return
                }
                try {
                    clearAllLeds(deviceLed)
                    val color = if (white) "white" else "purple"
                    val effect = if (white) "solid" else "breath"
                    applyTopRgbLed(deviceLed, color, effect)
                    applyFingerRgbLed(deviceLed, color, "solid")
                    white = !white
                } catch (_: Throwable) {}
                hardwareHandler.postDelayed(this, 700L)
            }
        })
    }

    private fun stopFaceLedBlink() {
        faceLedBlinking.set(false)
        try { led?.let { clearAllLeds(it) } } catch (_: Throwable) {}
    }

    private fun rgbConfig(color: String, red: Int? = null, green: Int? = null, blue: Int? = null): LedConfig {
        if (red != null || green != null || blue != null) {
            return LedConfig(
                (red ?: 0).coerceIn(0, 255),
                (green ?: 0).coerceIn(0, 255),
                (blue ?: 0).coerceIn(0, 255)
            )
        }

        return when (color) {
            "red", "vermelho", "erro", "error" -> LedConfig(255, 0, 0)
            "green", "verde", "sucesso", "success" -> LedConfig(0, 255, 0)
            "blue", "azul" -> LedConfig(0, 0, 255)
            "purple", "roxo", "violet", "violeta" -> LedConfig(160, 0, 255)
            "white", "branco" -> LedConfig(255, 255, 255)
            "yellow", "amarelo" -> LedConfig(255, 180, 0)
            "cyan", "ciano" -> LedConfig(0, 180, 255)
            else -> LedConfig(0, 0, 0)
        }
    }

    private fun startFallbackPollingLoop() {
        if (!fallbackPolling.compareAndSet(false, true)) return
        hardwareHandler.post(object : Runnable {
            override fun run() {
                if (!detecting.get() || !serviceReady.get()) {
                    fallbackPolling.set(false)
                    return
                }

                try {
                    val ic = icReader ?: IcReader.getInstance(this@MainActivity).also { icReader = it }
                    val status = IntTypeValue()
                    val rc = ic.getCardStatus(status)
                    if (rc == 0 && status.getData() != 0) {
                        emitOnce("onIcCardDetected", mapOf("reader" to "ic_poll", "status" to status.getData()))
                    }
                } catch (_: Throwable) {}

                try {
                    val nfc = nfcReader ?: NfcReader.getInstance(this@MainActivity).also { nfcReader = it }
                    if (nfc.isExist()) {
                        emitOnce("onNfcCardDetected", mapOf("reader" to "nfc_poll"))
                    }
                } catch (_: Throwable) {}

                if (detecting.get()) hardwareHandler.postDelayed(this, 520L) else fallbackPolling.set(false)
            }
        })
    }

    private fun emitOnce(method: String, args: Map<String, Any?>) {
        if (!detecting.get()) return
        if (!eventSent.compareAndSet(false, true)) return
        sendCardEvent(method, args)
        detecting.set(false)
        fallbackPolling.set(false)
        try { icReader?.cancel() } catch (_: Throwable) {}
        try { magReader?.cancel() } catch (_: Throwable) {}
        try { nfcReader?.cancel() } catch (_: Throwable) {}
    }

    private fun sendCardEvent(method: String, args: Map<String, Any?>) {
        mainHandler.post { cardChannel?.invokeMethod(method, args) }
    }

    private fun getCameraDiagnostics(): Map<String, Any?> {
        val cameras = mutableListOf<Map<String, Any?>>()
        var bestCameraId: String? = null
        var error: String? = null

        try {
            val cameraManager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
            for (cameraId in cameraManager.cameraIdList) {
                val characteristics = cameraManager.getCameraCharacteristics(cameraId)
                val lensFacing = characteristics.get(CameraCharacteristics.LENS_FACING)
                val hardwareLevel = characteristics.get(CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL)
                val capabilities = characteristics.get(CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES)
                    ?.map { cameraCapabilityName(it) }
                    ?: emptyList()
                val lensName = cameraLensName(lensFacing)
                val hardwareName = cameraHardwareLevelName(hardwareLevel)
                val item = mapOf(
                    "id" to cameraId,
                    "lensFacing" to lensName,
                    "hardwareLevel" to hardwareName,
                    "capabilities" to capabilities
                )
                cameras.add(item)
                if (bestCameraId == null && (lensFacing == CameraMetadata.LENS_FACING_EXTERNAL || hardwareLevel == CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL_EXTERNAL)) {
                    bestCameraId = cameraId
                }
            }
            if (bestCameraId == null && cameras.isNotEmpty()) {
                bestCameraId = cameras.maxByOrNull { cameraHardwareRank(it["hardwareLevel"]?.toString()) }?.get("id")?.toString()
            }
        } catch (cameraError: Throwable) {
            error = cameraError.message ?: cameraError.toString()
        }

        val usbDevices = mutableListOf<Map<String, Any?>>()
        try {
            val usbManager = getSystemService(Context.USB_SERVICE) as UsbManager
            for (device in usbManager.deviceList.values) {
                val interfaces = mutableListOf<Map<String, Any?>>()
                var hasVideoInterface = false
                for (index in 0 until device.interfaceCount) {
                    val item = device.getInterface(index)
                    if (item.interfaceClass == UsbConstants.USB_CLASS_VIDEO) {
                        hasVideoInterface = true
                    }
                    interfaces.add(
                        mapOf(
                            "id" to item.id,
                            "class" to item.interfaceClass,
                            "subclass" to item.interfaceSubclass,
                            "protocol" to item.interfaceProtocol
                        )
                    )
                }
                usbDevices.add(
                    mapOf(
                        "name" to device.deviceName,
                        "vendorId" to device.vendorId,
                        "productId" to device.productId,
                        "deviceClass" to device.deviceClass,
                        "hasVideoInterface" to hasVideoInterface,
                        "interfaces" to interfaces
                    )
                )
            }
        } catch (_: Throwable) {}

        return mapOf(
            "hasCameraExternalFeature" to packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_EXTERNAL),
            "bestCameraId" to bestCameraId,
            "cameras" to cameras,
            "usbDevices" to usbDevices,
            "error" to error
        )
    }

    private fun cameraLensName(lensFacing: Int?): String {
        return when (lensFacing) {
            CameraMetadata.LENS_FACING_FRONT -> "front"
            CameraMetadata.LENS_FACING_BACK -> "back"
            CameraMetadata.LENS_FACING_EXTERNAL -> "external"
            else -> "unknown"
        }
    }

    private fun cameraHardwareLevelName(level: Int?): String {
        return when (level) {
            CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL_LEGACY -> "legacy"
            CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL_LIMITED -> "limited"
            CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL_FULL -> "full"
            CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL_3 -> "level_3"
            CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL_EXTERNAL -> "external"
            else -> "unknown"
        }
    }

    private fun cameraHardwareRank(level: String?): Int {
        return when (level) {
            "external" -> 5
            "level_3" -> 4
            "full" -> 3
            "limited" -> 2
            "legacy" -> 1
            else -> 0
        }
    }

    private fun cameraCapabilityName(capability: Int): String {
        return when (capability) {
            CameraMetadata.REQUEST_AVAILABLE_CAPABILITIES_BACKWARD_COMPATIBLE -> "backward_compatible"
            CameraMetadata.REQUEST_AVAILABLE_CAPABILITIES_MANUAL_SENSOR -> "manual_sensor"
            CameraMetadata.REQUEST_AVAILABLE_CAPABILITIES_MANUAL_POST_PROCESSING -> "manual_post_processing"
            CameraMetadata.REQUEST_AVAILABLE_CAPABILITIES_RAW -> "raw"
            CameraMetadata.REQUEST_AVAILABLE_CAPABILITIES_PRIVATE_REPROCESSING -> "private_reprocessing"
            CameraMetadata.REQUEST_AVAILABLE_CAPABILITIES_READ_SENSOR_SETTINGS -> "read_sensor_settings"
            CameraMetadata.REQUEST_AVAILABLE_CAPABILITIES_BURST_CAPTURE -> "burst_capture"
            CameraMetadata.REQUEST_AVAILABLE_CAPABILITIES_YUV_REPROCESSING -> "yuv_reprocessing"
            CameraMetadata.REQUEST_AVAILABLE_CAPABILITIES_DEPTH_OUTPUT -> "depth_output"
            else -> "capability_$capability"
        }
    }

    private fun hasCameraPermission(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
            checkSelfPermission(Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestCameraPermission(result: MethodChannel.Result) {
        if (hasCameraPermission()) {
            result.success(true)
            return
        }
        permissionResult = result
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            requestPermissions(arrayOf(Manifest.permission.CAMERA), cameraRequestCode)
        } else {
            result.success(true)
            permissionResult = null
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == cameraRequestCode) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            permissionResult?.success(granted)
            permissionResult = null
        }
    }

    override fun onDestroy() {
        stopFingerprintDetection()
        stopCardDetection()
        setStatusLed("off")
        try { ServiceManager.unbindPosServer() } catch (_: Throwable) {}
        try { hardwareThread.quitSafely() } catch (_: Throwable) {}
        super.onDestroy()
    }
}
