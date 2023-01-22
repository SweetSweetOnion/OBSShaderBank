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

float2 offsetUV(float2 _uv, float2 _center, float _offsetAmount){
	return _uv + (_center-_uv)*_offsetAmount;
}


float4 render(float2 uv) {

	float2 resolution = builtin_uv_size; 
	float screenRatio = float(builtin_uv_size.x) / float(builtin_uv_size.y);


	float4 output = image.Sample(builtin_texture_sampler,uv);

	float2 center = 0.5;
	float size = frac(builtin_elapsed_time_since_enabled * 1)*2;
	float2 nTime = float2(builtin_elapsed_time,builtin_elapsed_time+100);
	float thickness = noise(uv*10+nTime*0)*0.8;
	float circle = smoothCircle(uv,center,size+thickness,size+(thickness+0.5*size));

	output += circle;

	return output;
}