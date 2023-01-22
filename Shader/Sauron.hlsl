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
uniform float inDuration = 1;
uniform float duration = 10;
uniform float outDuration = 2;

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

float snoise(float3 uv, float res)
{
	const float3 s = float3(1e0, 1e2, 1e3);
	
	uv *= res;
	
	float3 uv0 = floor(fmod(uv, res))*s;
	float3 uv1 = floor(fmod(uv+float3(1,1,1), res))*s;
	
	float3 f = frac(uv); 
	f = f*f*(3.0-2.0*f);

	float4 v = float4(uv0.x+uv0.y+uv0.z, uv1.x+uv0.y+uv0.z,
		      	  uv0.x+uv1.y+uv0.z, uv1.x+uv1.y+uv0.z);

	float4 r = frac(sin(v*1e-1)*1e3);
	float r0 = lerp(lerp(r.x, r.y, f.x), lerp(r.z, r.w, f.x), f.y);
	
	r = frac(sin((v + uv1.z - uv0.z)*1e-1)*1e3);
	float r1 = lerp(lerp(r.x, r.y, f.x), lerp(r.z, r.w, f.x), f.y);
	
	return lerp(r0, r1, f.z)*2.-1.;
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


	float2 sauronUV = pixelUV*2;
	sauronUV.x *= 2;
	sauronUV.y *= 1;
	
	float color = 3.0 - (3.*length(sauronUV));
	
	float3 coord = float3(atan(pixelUV.x)/6.2832+.5, length(pixelUV)*.4, .5);

	float time = builtin_elapsed_time;
	
	for(float i = 1; i <= 7; i++)
	{
		float power = pow(3.0, float(i));
		color += (1.5 / power) * snoise(coord + float3(0.,-time*.05, time*.01), power*16.);
	}
	

	output += image.Sample(builtin_texture_sampler,uv);
	output *= lerp(1,0.2,fade);
	output += clamp(float4( color, pow(max(color,0.),2.)*0.4, pow(max(color,0.),3.)*0.15 , 1.0),0,1)*fade;


	float pupilWidth = 0.46 + sin(builtin_elapsed_time+abs(sin(builtin_elapsed_time*2)))*0.01;
	pupilWidth += lerp(0.1,0,fade);
	float2 pupilUV = pixelUV;
	pupilUV.x *= 1.1;

	pupilUV.x += sin(builtin_elapsed_time+abs(sin(builtin_elapsed_time)))*0.05;

	float pupil =  step(length(float2(pupilWidth,0)-pupilUV),0.5) * step(length(float2(-pupilWidth,0)-pupilUV),0.5);

	//output *= pupil;
	output = lerp(output,0,pupil);


	output.a = 1;
	return output;

	/*float2 eyePos = 0.5;


	float dx = abs(pixelUV.x)*2 + abs(sin(uv.y*20+builtin_elapsed_time*3)*0.2*uv.y-eyePos.y);

	float dy = abs(pixelUV.y)*1.2;
	float f = smoothstep((dx + dy)*2,0,1);

	float4 eyeColor = float4(1,0.5,0.5,1);

	output = lerp(eyeColor,output,f);

	output.a = 1;



	return output;*/
}


//TO TEST

/*


void mainImage( out vec4 fragColor, in vec2 fragCoord ) 
{
	vec2 p = -.5 + fragCoord.xy / iResolution.xy;
	p.x *= iResolution.x/iResolution.y;
	
	float color = 3.0 - (3.*length(2.*p));
	
	vec3 coord = vec3(atan(p.x,p.y)/6.2832+.5, length(p)*.4, .5);
	
	for(int i = 1; i <= 7; i++)
	{
		float power = pow(2.0, float(i));
		color += (1.5 / power) * snoise(coord + vec3(0.,-iTime*.05, iTime*.01), power*16.);
	}
	fragColor = vec4( color, pow(max(color,0.),2.)*0.4, pow(max(color,0.),3.)*0.15 , 1.0);
}

*/