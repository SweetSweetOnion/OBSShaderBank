/*
uniform texture2d image;                                       // the source texture (the image we are filtering)
uniform int       builtin_frame;                               // the current frame number
uniform float     builtin_framerate;                           // the current output framerate
uniform float     builtin_elapsed_time;                        // the current elapsed time
uniform float     builtin_elapsed_time_previous;               // the elapsed time in the previous frame
uniform float     builtin_elapsed_time_since_shown;            // the time since the source this filter is applied to was shown
uniform float     builtin_elapsed_time_since_shown_previous;   // the time since the source this filter is applied to was shown of the previous frame
uniform float     builtin_elapsed_time_since_enabled;          // the time since the filter itself was shown
uniform float     builtin_elapsed_time_since_enabled_previous; // the time since the filter itself was shown of the previous frame
uniform int2      builtin_uv_size;                             // the source dimensions

sampler_state     builtin_texture_sampler { ... };



uniform texture2d builtin_texture_fft_<NAME>;          // audio output frequency spectrum
uniform texture2d builtin_texture_fft_<NAME>_previous; // output from the previous frame (requires builtin_texture_fft_<NAME> to be defined)
*/

#define PI 3.1415926538

uniform float rainWidth = 0.01;
uniform float rainLength = 0.20;
uniform float rainSpeed = 5;
uniform float rainDisplacement = -0.10;


uniform float4 rainColor = {0.01,0.5,1,1};
uniform float rainColorAlpha = 0.01;


float random (in float2 st) {
    return frac(sin(dot(st.xy,
                         float2(12.9898,78.233)))
                 * 43758.5453123);
}

float noise (in float2 st) {
    float2 i = floor(st);
    float2 f = frac(st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + float2(1.0, 0.0));
    float c = random(i + float2(0.0, 1.0));
    float d = random(i + float2(1.0, 1.0));

    // Smooth Interpolation

    // Cubic Hermine Curve.  Same as SmoothStep()
    float2 u = f*f*(3.0-2.0*f);
    // u = smoothstep(0.,1.,f);

    // Mix 4 coorners percentages
    return lerp(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

float4 render(float2 uv) {

	float2 resolution = builtin_uv_size; 
	float screenRatio = float(builtin_uv_size.x) / float(builtin_uv_size.y);

	float4 output = 0;

	
	float scale = 1/rainWidth;
	float nx = float(int(uv.x * scale)) / scale;
	float r = random(nx);
	float v = sin(r*PI*2 + uv.y*PI*1/rainLength - builtin_elapsed_time*rainSpeed/rainLength)-0.5;
	//uv.y *PI*1 + 
	//v += sin(random(x)*PI * 100);
	v = clamp(v,0,1);
	float rain = v*2;

	
	float2 customUV = lerp(uv,uv+rainDisplacement*(random(nx)*2-1)*0.1,rain);
	output = image.Sample(builtin_texture_sampler,customUV);

	output *= float4(0.8,1,1,1);

	output += rain*rainColor*rainColorAlpha;





	output = saturate(output);
	return output;
}