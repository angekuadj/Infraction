package net.circulation.ci.circulation

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import java.io.File
import java.nio.ByteBuffer

/**
 * Découpe une vidéo sans ré-encodage en copiant les pistes audio/vidéo
 * comprises entre startMs et endMs dans un nouveau conteneur MP4.
 */
object VideoTrimmer {

    fun trim(
        inputPath: String,
        outputPath: String,
        startMs: Long,
        endMs: Long,
    ): Boolean {
        if (startMs < 0 || endMs <= startMs) return false
        val input = File(inputPath)
        if (!input.exists()) return false

        val output = File(outputPath)
        output.parentFile?.mkdirs()
        if (output.exists()) output.delete()

        val extractor = MediaExtractor()
        var muxer: MediaMuxer? = null
        var wroteSample = false
        try {
            extractor.setDataSource(inputPath)

            muxer = MediaMuxer(
                outputPath,
                MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4,
            )

            val trackMap = HashMap<Int, Int>()
            for (index in 0 until extractor.trackCount) {
                val format = extractor.getTrackFormat(index)
                val mime = format.getString(MediaFormat.KEY_MIME) ?: continue
                if (!mime.startsWith("video/") && !mime.startsWith("audio/")) {
                    continue
                }
                extractor.selectTrack(index)
                trackMap[index] = muxer.addTrack(format)
            }
            if (trackMap.isEmpty()) return false

            muxer.start()

            extractor.seekTo(startMs * 1000, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)

            val buffer = ByteBuffer.allocateDirect(2 * 1024 * 1024)
            val info = MediaCodec.BufferInfo()
            val startUs = startMs * 1000
            val endUs = endMs * 1000
            var baseUs = -1L

            while (true) {
                val sampleTime = extractor.sampleTime
                if (sampleTime < 0 || sampleTime > endUs) break

                val size = extractor.readSampleData(buffer, 0)
                if (size < 0) break

                val muxerTrack = trackMap[extractor.sampleTrackIndex]
                if (muxerTrack != null && sampleTime >= startUs) {
                    if (baseUs < 0) baseUs = sampleTime
                    info.offset = 0
                    info.size = size
                    info.presentationTimeUs = sampleTime - baseUs
                    info.flags = extractor.sampleFlags
                    muxer.writeSampleData(muxerTrack, buffer, info)
                    wroteSample = true
                }
                if (!extractor.advance()) break
            }

            return wroteSample
        } catch (_: Exception) {
            return false
        } finally {
            try {
                muxer?.stop()
            } catch (_: Exception) {
            }
            try {
                muxer?.release()
            } catch (_: Exception) {
            }
            try {
                extractor.release()
            } catch (_: Exception) {
            }
            if (!wroteSample && output.exists()) {
                output.delete()
            }
        }
    }
}
