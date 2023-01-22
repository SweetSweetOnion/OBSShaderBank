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
#define MAX_STEPS 200
#define MAX_DIST 1000
#define SURF_DIST 0.01

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

float2x2 Rot(float a){
	float s = sin(a);
	float c = cos(a);
	return float2x2(c,-s,s,c);
}

uniform float speed = 10;
uniform float noiseA = 0.2;
uniform float noiseB = 0.5;
uniform float noiseC = 3;
uniform float noiseD = 0.1;
uniform float inDuration = 1;
uniform float duration = 10;
uniform float outDuration = 1;
/*
const float freqA = .15;
const float freqB = .25;
const float ampA = 2.4;
const float ampB = 1.7;
*/
float2 path(in float z){
	return float2(0*sin(z * 0), 0*cos(z * 0)); 
}


float GetDist(float3 p){

	float4 s = float4(0,0,10,4);//spere pos

	float n = noise(float2(p.x,p.y)*3+builtin_elapsed_time_since_enabled*1)*0.1 * (sin(p.x*2+builtin_elapsed_time_since_enabled*10)*0.2+0.1);

	float n2 = noise(float2(p.x+100,p.y+100)*10+builtin_elapsed_time_since_enabled*3)*10 * (cos(builtin_elapsed_time_since_enabled*0.2)+1.1)*0.8;

	float surf = n*n2 * 4;

	float sphereDist = length(p-s.xyz)-s.w+surf;
	float planeDist = p.y;


	float d = min(sphereDist, planeDist);

	float r = cos(p.z * 0.04)*0.5;
	p.xy = mul(p.xy,Rot(r*10));

	float tunneNoise = 1;
	tunneNoise += sin(p.x*3)*noiseA + noise(float2(p.x,p.z)*noiseB);
	tunneNoise += sin(p.z*0.1 + builtin_elapsed_time_since_enabled*2)*noiseC;
	tunneNoise += frac(p.z)*noiseD;

	
	float2 z = float2(2*sin(p.z * 0.1), 2*cos(p.z * 0));
	z.x = (noise(float2(p.z,0)*0.1)-0.5)*4;
	z.y = (noise(float2(p.z+100,0)*0.1)-0.5)*4;
	float2 tunnel = p.xy - z;



	float tunnelDist = 10- length(tunnel) * tunneNoise;


	d = min(sphereDist,tunnelDist);
	return tunnelDist;

}

float RayMarch(float3 ro, float3 rd){
	float t = 0;

	for(int i =0; i< MAX_STEPS;i++ ){
		float3 p = ro + rd*t;
		float ds = GetDist(p);
		t += ds;
		if(t > MAX_DIST || ds< SURF_DIST )break;


	}
	return t;
}

float3 GetNormal(float3 p){
	float d = GetDist(p);
	float2 e = float2(.01, 0);
	float3 n = d - float3(
		GetDist(p -float3(0.01,0,0)),
		GetDist(p - float3(0,0.01,0)),
		GetDist(p - float3(0,0,0.01)));


	return normalize(n);
}

float GetLight(float3 p, float3 lightPos){
	float3 l = normalize(lightPos-p);
	float3 n = GetNormal(p);

	float dif = clamp(dot(n,l),0,1);
	float d = RayMarch(p+n*SURF_DIST*2,l);
	if(d<length(lightPos-p))dif *= 0.1;

	return dif;
}


float4 render(float2 uv) {

	float2 resolution = builtin_uv_size; 
	float screenRatio = float(builtin_uv_size.x) / float(builtin_uv_size.y);
	float2 rmUV = uv;
	rmUV -= 0.5;
	rmUV.x *= screenRatio;
	
	//rmUV.x -= screenRatio;

	float3 ro = float3(0,0,builtin_elapsed_time_since_enabled*speed);
	float3 lightPos = float3(0,0.5,10 + builtin_elapsed_time_since_enabled*speed);

	float3 rd = normalize(float3(rmUV.x,-rmUV.y,1));



	float4 output =0;


	float d = RayMarch(ro,rd);

	float3 p = ro + rd * d;
	float dif = GetLight(p,lightPos);

	float fadeIn = clamp(builtin_elapsed_time_since_enabled*(1/inDuration),0,1);
	float fadeOut = 1-clamp(-duration+builtin_elapsed_time_since_enabled*(1/outDuration),0,1);
	float fade = fadeIn * fadeOut;

	float2 imgUV = lerp(uv,uv+(uv-0.5)*0.5,dif);

	imgUV = lerp(uv,imgUV,fade);


	float4 img = image.Sample(builtin_texture_sampler,imgUV);

	//output.rgb = GetNormal(p);
	

	//d /= 10;

	output = lerp(img,dif,clamp(dif*dif,0,1)*fade);
	//output = img;
	output = dif;

	//output += 1/d *0.2;
	//output += d/10;
	output.a = 1;

	return output;
}