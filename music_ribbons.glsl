// Music-Reactive Ribbon Tunnel
// Set iChannel0 to a music/audio input in Shadertoy
//
// Based on a twisting ribbon raymarcher, enhanced with
// audio-reactive parameters driven by FFT frequency bands.

#define PI 3.14159265359
#define MAX_STEPS 100
#define MAX_DEPTH 15.0
#define FOG_FACTOR 9.0

// Audio helpers — iChannel0 is a 512x2 texture:
//   row 0 (y=0.25): FFT frequency spectrum
//   row 1 (y=0.75): waveform
float getFreq(float f) {
    return texture(iChannel0, vec2(f, 0.25)).x;
}

float getWave(float x) {
    return texture(iChannel0, vec2(x, 0.75)).x;
}

// Sample frequency bands
float bass()   { return getFreq(0.05) + getFreq(0.07) + getFreq(0.1); }
float mids()   { return getFreq(0.2) + getFreq(0.3) + getFreq(0.4); }
float treble() { return getFreq(0.6) + getFreq(0.7) + getFreq(0.8); }

float boxSdf(vec3 point, vec3 dimensions) {
    vec3 q = abs(point) - dimensions;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdf(vec3 point, float bassVal, float midsVal) {
    // Ribbon dimensions react to audio
    float ribbonWidth     = 0.1 + bassVal * 0.08;
    float ribbonThickness = 0.025 + bassVal * 0.02;

    // Ribbon length pulses with mids
    float minLen = 0.8;
    float maxLen = 1.0 + midsVal * 0.3;
    float midLen = (minLen + maxLen) * 0.5;
    float rangeLen = maxLen - minLen;

    if (point.z > 0.5) {
        return boxSdf(point, vec3(ribbonWidth, ribbonThickness, 0.5));
    }

    vec3 tp = vec3(fract(point.x), fract(point.y), mod(point.z, 2.0));
    tp -= vec3(0.5, 0.5, 1.0);

    // Rotation speed driven by mids
    float rotSpeed = 1.0 + midsVal * 2.0;
    float angle = atan(1.0) * sin(point.z + iTime * rotSpeed) * 12.0;
    mat2 rot = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    tp.xy *= rot;

    float ribbonLength = sin(iTime) * (rangeLen * 0.5) + midLen;

    return boxSdf(tp, vec3(ribbonWidth, ribbonThickness, ribbonLength));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Sample audio bands
    float bassVal   = bass();
    float midsVal   = mids();
    float trebleVal = treble();

    // Camera — speed pulses with bass
    float camSpeed = 2.0 + bassVal * 1.5;
    vec3 ro = vec3(66.0, 0.0, iTime * camSpeed);

    // Aspect-correct coordinates
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    vec3 rd = normalize(vec3(uv, 1.0));
    float t = 1.0;

    // Raymarching
    for (int i = 0; i < MAX_STEPS; i++) {
        float d = sdf(rd * t - ro, bassVal, midsVal);
        t -= d;
    }

    vec3 col;

    if (t < -MAX_DEPTH) {
        // Background — reacts to treble
        float bg = 0.02 + trebleVal * 0.05;
        col = vec3(bg, bg * 0.5, bg * 0.8);
    } else {
        vec3 point = rd * t;
        float depth = point.z + 22.0;

        // Colors driven by audio bands
        float red   = cos(depth + iTime + bassVal * 2.0) * 0.5 + 0.5;
        float green = sin(depth * 1.5 + iTime + PI + midsVal * 3.0) * 0.5 + 0.5;
        float blue  = sin(depth * 0.8 + iTime * 0.7 + trebleVal * 4.0) * 0.4 + 0.3;

        // Fog — intensity reacts to overall volume
        float volume = (bassVal + midsVal + trebleVal) / 3.0;
        float fogStr = FOG_FACTOR + volume * 6.0;
        float fog = fogStr / (t * t);

        col = vec3(red, green, blue) * fog;

        // Audio-reactive glow on ribbon edges
        col += vec3(0.4, 0.1, 0.6) * bassVal * fog * 0.3;
    }

    // Waveform overlay — thin oscilloscope line across the screen
    float wave = getWave(fragCoord.x / iResolution.x);
    float waveLine = smoothstep(0.015, 0.0, abs(uv.y - (wave - 0.5) * 0.5));
    col += vec3(0.3, 0.8, 1.0) * waveLine * 0.6;

    // Vignette
    vec2 vuv = fragCoord / iResolution.xy;
    col *= 1.0 - 0.4 * dot(vuv - 0.5, vuv - 0.5);

    // Gamma correction
    col = pow(clamp(col, 0.0, 1.0), vec3(1.0 / 2.2));

    fragColor = vec4(col, 1.0);
}
