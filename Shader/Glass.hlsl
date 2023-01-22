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


float4 render(float2 uv) {

	float2 resolution = builtin_uv_size; 
	float screenRatio = float(builtin_uv_size.x) / float(builtin_uv_size.y);


	float4 output =0;

	float2 gv = uv * 10;
	gv.x *= screenRatio;

	float2 cv = frac(gv) - 0.5;
	float2 id = floor(gv);
	float2 cid = 0;
	float t = builtin_elapsed_time*0.01;
	float minDist = 100;

	for(float y =-1 ; y <=1 ; y++){
		for(float x =-1 ; x <=1 ; x++){
			float2 offset = float2(x,y);
			float2 n = float2(random(id + offset),random(id + offset+100));
			//n.x = step(id.y%2,0)*0.3;
			//n.y = 0.1;
			//n.x = 0;
			//n.x = step(id.x%2,1);
			//float2 n = float2(step(gv.y%2,1),0);
			//float2 p = offset + sin(n * t) * 0.5;
			float2 p = offset+sin(n*t+t)*0.5;
			float d = length(cv-p);
			if(d<minDist){
				minDist = d;
				cid = id+offset;
			}
		}
	}
	float randID = random(cid);
	float time = 1/(builtin_elapsed_time_since_enabled*10+1);
	float distToCenter = smoothstep(time,1,1-length(0.5- uv));

	float randomDisapear = step(randID %2,2-builtin_elapsed_time_since_enabled);


	float texOff = (float2 (random(cid),random(cid+100))-0.5) * minDist * 0.08 * distToCenter * randomDisapear;


	output = image.Sample(builtin_texture_sampler,frac(uv + texOff));
	//output += randID*0.02;

	//output *= step(randID %2,2-builtin_elapsed_time_since_enabled);

	//output += smoothstep(0.3,0.9,minDist * (1-minDist)*2);
	//output +=  smoothstep(0.4,0.45,minDist);
	//output = step(id.y%2,0);
	//output.r = step(gv.y%2,1);
	//output.r += step(gv.x%2,1);
	//output = distToCenter;
	//output = minDist;
	output.a = 1;


	return output;
}