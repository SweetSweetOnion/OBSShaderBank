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

/*float grid(float2 uv, float battery)
{
    float2 size = float2(uv.y, uv.y * uv.y * 0.5) * 0.001;
    uv += float2(0.0, builtin_elapsed_time * 0.5 * (battery + 0.05));
    uv = abs(frac(uv) - 0.5);
 	float2 lines = smoothstep(size, float2(0.0,0.0), uv);
 	lines += smoothstep(size * 5.0, float2(0.0,0.0), uv) * 0.4 * battery;
    return clamp(lines.x + lines.y, 0.0, 3.0);
}*/

float myGrid(float2 uv, float lineCount,float lineWeight){

	float result = 0;

	float top = frac(uv.y*lineCount-0.01);
	float bottom = frac((1-uv.y)*lineCount-0.01);
	float right = frac(uv.x*lineCount-0.01);
	float left = frac((1-uv.x)*lineCount-0.01);

	top = smoothstep(1-lineWeight,1,top);
	bottom = smoothstep(1-lineWeight,1,bottom);
	right = smoothstep(1-lineWeight,1,right);
	left = smoothstep(1-lineWeight,1,left);
	right = 0;
	left = 0;

	result = saturate(top + bottom + right + left);
	return result;
}

float4 render(float2 uv) {

	float2 resolution = builtin_uv_size; 
	float screenRatio = float(builtin_uv_size.x) / float(builtin_uv_size.y);

	float4 output = 0;
	
	
	float2 gridUV = uv + float2(builtin_elapsed_time * 0,builtin_elapsed_time*1);

	//gridUV.y += gridUV.x * 9;

	float v = myGrid(gridUV,5,0.2);


	output = image.Sample(builtin_texture_sampler,uv);
	output += v;

	return output;
}
