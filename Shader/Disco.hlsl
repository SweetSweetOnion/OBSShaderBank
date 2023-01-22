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
uniform float duration = 5;
uniform float outDuration = 1;
uniform float speed;

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

float2 rotate13( float2  lrf, float guvf) {
	float vf  = cos(guvf); 
    float n   = sin(guvf);
    float2x2  wbxr = float2x2(vf,n,n,-vf);
    
    return mul(lrf,wbxr);
}

float smoothCircle(float2 _uv, float2 _position, float _innerRadius,float _outerRadius){
    float2 dist = _uv-_position;
    _innerRadius = max(0,_innerRadius);
    _outerRadius = max(0,_outerRadius);
	float innerCircle =  1.-smoothstep(_innerRadius-(_innerRadius*0.01),
                         _innerRadius+(_innerRadius*0.01),
                         dot(dist,dist)*4.0);
	float outerCircle = 1.-smoothstep(_outerRadius-(_outerRadius*0.01),
                         _outerRadius+(_outerRadius*0.01),
                         dot(dist,dist)*4.0);

	return outerCircle * (1-innerCircle);
}



float4 render(float2 uv) {

	float2 resolution = builtin_uv_size; 
	float screenRatio = float(builtin_uv_size.x) / float(builtin_uv_size.y);
	float4 output = 0;

	float2 pixelUV = uv;
	pixelUV -= 0.5;
	pixelUV.x *= screenRatio;

	float zoom = 4;
	pixelUV *= zoom;


	float fadeIn = clamp(builtin_elapsed_time_since_enabled*(1/inDuration),0,1);
	float fadeOut = 1-clamp(-duration+builtin_elapsed_time_since_enabled*(1/outDuration),0,1);
	float fade = fadeIn * fadeOut;

	pixelUV.y += lerp(1 * zoom,0.5 * zoom,smoothstep(0,1,fade));

	
	float circle = smoothCircle(pixelUV,float2(0,0),0,zoom);

	float2 sUV = lerp(pixelUV,normalize(pixelUV) * (2 * asin(length(pixelUV))/PI),0.5);
	float3 n = float3(sUV.x,sUV.y,sqrt(1.0-sUV.x*sUV.x-sUV.y*sUV.y));
	sUV = normalize(sUV) * (2.0 * asin(length(sUV))/PI);
	
	if(length(pixelUV)>1){//to fix infinite value ????
		sUV = 0;
	}

	float phase = builtin_elapsed_time*0.25*speed;

	float3 lightvec = float3(1.0,1.0,0.0);
	rotate13(lightvec.xz, phase * 0.5 * 3.1415926);
    sUV.x += phase;

 

    sUV *= 2;


    output += image.Sample(builtin_texture_sampler,uv);


    output *= step(circle,0.5);

    float gridSize = 10;
   
    float rand = 0.5 + random(floor(0.5+sUV.x*gridSize)*2.6113+floor(0.5+sUV.y*gridSize)*1086.3)*0.5;




    float4 proj = image.Sample(builtin_texture_sampler,frac(floor(sUV*5)*0.3));

    float2 cellUV = frac(frac(sUV*5) + pixelUV.x *1);
    proj = image.Sample(builtin_texture_sampler,cellUV);

    float outline = step(abs(frac(sUV.x*5)),0.2) + step(abs(frac(sUV.y*5)),0.2);

    float threshold = step(0.1,proj);

    float4 disco = rand*0.5 +proj*0.5;

    disco = lerp(proj+0.2,0.8,outline);


    float bloom = 2/length(pixelUV);

   // output.rgb += bloom;


    output.rgb += disco *2 * circle + (bloom *0.2)*(1-circle)*fade;
    float angle = atan2(pixelUV.x,pixelUV.y);
    float f = (sin(angle*10 + builtin_elapsed_time*3*speed)+1)*0.5;
    float light = f * (1-circle) * fade ;
    float t = builtin_elapsed_time *0.5;
    float3 lightCol = float3(
    	noise(float2(angle*2+1000 + t,angle*2 +1000)),
    	noise(float2(angle*2+100000+ t,angle*2 +1000000+t)),
    	noise(float2(angle*2+10+ t,angle*2 +100))) + 0.5;
    output.rgb +=  (lightCol+0.5) * smoothstep(0.2,0.8,light)*0.25;

    output.a = 1;
	return output;

}