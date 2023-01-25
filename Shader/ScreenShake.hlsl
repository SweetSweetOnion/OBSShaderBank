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

uniform float shakeAmount = 0.03;
uniform float inDuration = 0.2;
uniform float duration = 0;
uniform float outDuration = 1;

float random (in float2 st) {
    return frac(sin(dot(st.xy,
                         float2(12.9898,78.233)))
                 * 43758.5453123);
}


float circle(float2 _uv, float2 _position, float _innerScale, float _outerScale){
	float innerCircle = step(distance(_uv,_position),_innerScale);
	float outCircle = step(distance(_uv,_position),_outerScale); 
    float outputCircle = outCircle * (1-innerCircle);
    return outputCircle;
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
    // sample the source texture and return its color to be displayed
    float4 output = float4(0,0,0,1);

    float fadeIn = clamp(builtin_elapsed_time_since_enabled*(1/inDuration),0,1);
    float fadeOut = 1-clamp(-duration+builtin_elapsed_time_since_enabled*(1/outDuration),0,1);
    float fade = fadeIn * fadeOut;



	float screenShakeAmout = shakeAmount * fade;
	
    float2 customUV = uv;
    customUV.x += (random(builtin_elapsed_time)-0.5)*2*screenShakeAmout;
	customUV.y += (random(builtin_elapsed_time+100)-0.5)*2*screenShakeAmout;

	float4 img = image.Sample(builtin_texture_sampler,frac(customUV));




    output =  img;
    output.a = 1;

    //output.x += wave * wave * wave;
   // output += img;
    return output;
   // return image.Sample(builtin_texture_sampler, uv);
}