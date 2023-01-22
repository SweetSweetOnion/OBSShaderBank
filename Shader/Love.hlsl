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
uniform float inDuration = 0.75;
uniform float duration = 4.5;
uniform float outDuration = 0.5;
uniform float bpm = 130;
uniform float pulseIntensity = 2;

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

float love(float2 uv){

	float o = 0;


	float2 cUV = uv;
	cUV.x *= 0.8;

	float a = length(float2(0.1, -0.1)-cUV);
	float b = length(float2(-0.1, -0.1)-cUV);

	float angle = atan2(uv.x,uv.y-0.4);

	angle *= step(0,uv.y);
	float t = 0.775;
	float tri = 1-(step(-PI*t,angle) * step(angle,PI*t));


	o += step(a,0.2);
	o += step(b,0.2);
	o += tri;

	return step(0.5,o);	
}


float4 render(float2 uv) {

	float2 resolution = builtin_uv_size; 
	float screenRatio = float(builtin_uv_size.x) / float(builtin_uv_size.y);
	float2 pixelUV = uv;
	pixelUV -= 0.5;
	pixelUV.x *= screenRatio;


	float fadeIn = clamp(builtin_elapsed_time_since_enabled*(1/inDuration),0,1);
	float fadeOut = 1-clamp(-duration+builtin_elapsed_time_since_enabled*(1/outDuration),0,1);
	float fade = fadeIn * fadeOut;

	float4 output = 0;


	float2 lUV = pixelUV;
	float scale = 1 + abs(sin(builtin_elapsed_time*PI*bpm/60))*0.1*pulseIntensity*fade;

	scale = lerp(0.1,scale,fade);
	lUV *= scale;

	float t = builtin_elapsed_time_since_enabled * 0.1;

	//t *= t;
	//lUV = frac((pixelUV+0.5)*(1+t) - t*0.5 ) -0.5;



	float l = love(lUV);

	float4 img = image.Sample(builtin_texture_sampler,uv);
	float4 pink = img * float4(1,0.2,0.8,1)*2;

	output = lerp(pink,img*(1+2*fade),l);

	//output *=  l ;

	output.a = 1;
	return output;
}