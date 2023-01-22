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

uniform float duration = 1;
uniform float attackDuration = 1;
uniform float scale  = 1;

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


	float4 output = image.Sample(builtin_texture_sampler,uv);

	float2 rx = float2(random(builtin_elapsed_time_since_enabled+11)-0.5,random(builtin_elapsed_time_since_enabled+100)-0.5);
	float2 ry = float2(random(builtin_elapsed_time_since_enabled+10)-0.5,random(builtin_elapsed_time_since_enabled+300)-0.5);
	float2 rz = float2(random(builtin_elapsed_time_since_enabled+20)-0.5,random(builtin_elapsed_time_since_enabled+400)-0.5);
    
	float time = clamp(duration - builtin_elapsed_time_since_enabled,0,1) * scale;// cos(builtin_elapsed_time_since_enabled*PI*1-PI/4);
	float attack = clamp(lerp(0,1,builtin_elapsed_time_since_enabled/attackDuration),0,1);
	time *= attack;

    output.r = image.Sample(builtin_texture_sampler, uv + rx*0.1 * time).r;
    output.g = image.Sample(builtin_texture_sampler, uv + ry*0.1 * time).g;
    output.b = image.Sample(builtin_texture_sampler, uv + rz*0.1 * time).b;

    // Invert the alpha channel based on the current time
   // output.a = 1.0 - (builtin_elapsed_time_since_enabled % 2.0);


	return output;
}