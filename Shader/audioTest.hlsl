
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

// Configure builtin uniforms
// These macros are optional, but improve the user experience
#pragma shaderfilter set main__mix__description Main Mix/Track
#pragma shaderfilter set main__channel__description Main Channel
#pragma shaderfilter set main__dampening_factor_attack 0.0
#pragma shaderfilter set main__dampening_factor_release 0.0
uniform texture2d builtin_texture_fft_main;

uniform texture2d builtin_texture_fft_main_previous;

uniform float valueThreshold = 0.5;
uniform float freq = 0.1;

// Define configurable variables
// These macros are optional, but improve the user experience
#pragma shaderfilter set fft_color__description FFT Color
#pragma shaderfilter set fft_color__default 7FFF00FF
uniform float4 fft_color;

float remap(float x, float2 from, float2 to) {
    float normalized = (x - from[0]) / (from[1] - from[0]);
    return normalized * (to[1] - to[0]) + to[0];
}

float4 render(float2 uv) {
    float fft_frequency = freq;
    float threshold = valueThreshold;
    float fft_amplitude = builtin_texture_fft_main.Sample(builtin_texture_sampler, float2(fft_frequency, 0.5)).r;
    float fft_amplitude_previous = builtin_texture_fft_main_previous.Sample(builtin_texture_sampler, float2(fft_frequency, 0.5)).r;

    float fft_db = 20.0 * log(fft_amplitude / 0.5) / log(10.0);
    float fft_db_previous = 20.0 * log(fft_amplitude_previous / 0.5) / log(10.0);

    float fft_db_remapped = remap(fft_db, float2(-50, -0), float2(0, 1));
    float fft_db_remapped_previous = remap(fft_db_previous, float2(-50, -0), float2(0, 1));

    float value = float(1.0 - threshold < fft_db_remapped);
    float value_previous = float(1.0 - threshold < fft_db_remapped_previous);

    float delta = (value - value_previous)/2;
	float uvMult = lerp(1,3,delta*delta);

    float4 color = image.Sample(builtin_texture_sampler, uv * uvMult);

   
    float4 output = color ;
    output.a = 1;
    return output;
}