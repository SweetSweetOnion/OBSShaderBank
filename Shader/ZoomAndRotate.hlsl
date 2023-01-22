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

uniform float startZoomAmount = 1;
uniform float endZoomAmount = 100;
uniform float startAngle = 0;
uniform float endAngle = 145;
uniform float effectDuration = 1;
uniform float zoomPositionX = 0.5;
uniform float zoomPositionY = 0.5;


float random (in float2 st) {
    return frac(sin(dot(st.xy,
                         float2(12.9898,78.233)))
                 * 43758.5453123);
}

float2x2 rotate(float angle){
	angle *= PI / 180.0;
    float s=sin(angle), c=cos(angle);
    return float2x2( c, -s, s, c );
}

float4 render(float2 uv) {

	float2 resolution = builtin_uv_size; 
	float screenRatio = float(builtin_uv_size.x) / float(builtin_uv_size.y);

	float time = saturate(builtin_elapsed_time_since_enabled/effectDuration);

	float zoomAmount = lerp(startZoomAmount,endZoomAmount, time*time)/screenRatio;
	float angle = lerp(startAngle,endAngle,time*time);

	float2 customUV = uv;

	
	
	customUV = ((uv-float2(zoomPositionX,zoomPositionY))*resolution)/resolution.y;
	customUV = mul(rotate(angle)*zoomAmount,customUV);

	customUV.y *= screenRatio;
	customUV+= float2(zoomPositionX,zoomPositionY);
	//return float4(customUV.x*1000,customUV.y*1000,0,1);
	float4 output = image.Sample(builtin_texture_sampler,frac(customUV));


	return output;
}