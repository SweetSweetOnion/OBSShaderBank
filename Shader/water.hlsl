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

//uniform float waterOffset = 0.5;
uniform float waterStrokeWeight = 0.99;
uniform float duration = 0.5;

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
 	
 	float2 customUV = uv;
 	float time = (builtin_elapsed_time_since_enabled*builtin_elapsed_time_since_enabled)*1/duration;
 	float waterOffset = clamp(1-time,-0.3,1);

 	float fadeOut = clamp(2-time,0,1);

	float waterLine = waterOffset+
		sin((uv.x + builtin_elapsed_time*0.1 )*PI*30 ) *0.01 + 
		sin((uv.x - builtin_elapsed_time*0.2 )*PI*10 ) *0.02 + 
		sin((uv.x + builtin_elapsed_time*5 )*PI*0.5 ) *0.03;
	float water = step(waterLine,uv.y);

	float waterStroke = 1-(uv.y - waterLine);
	waterStroke *= water;
	waterStroke = step(waterStrokeWeight,waterStroke);

	float2 waterUV = uv + (float2(
		noise(uv*10+ builtin_elapsed_time*1.5),
		noise(uv*10+1000+ builtin_elapsed_time*0.5)
		)-0.5)*
	(0.2*(1-uv.y+waterOffset)+0.4*waterStroke)*fadeOut;

	waterUV = abs(waterUV) %1;

	customUV = lerp(uv,waterUV,water*fadeOut);

	float4 img = image.Sample(builtin_texture_sampler,customUV);


	output = lerp(img,float4(img.r*0.5,img.g*0.9,img.b*1.1,1),water*fadeOut);
	output += waterStroke*0.1 * fadeOut;
	output = saturate(output);

	//output = lerp(output,img,fadeOut);
	return output;
}