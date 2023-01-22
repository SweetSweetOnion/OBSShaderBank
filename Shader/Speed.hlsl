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

uniform float lineWidth = 0.02;
uniform float minAperture = 120;
uniform float maxAperture = 140;
uniform float speedLineAmount = 0.01;
uniform float minSpeedLineLength = 0.50;
uniform float maxSpeedLineLength = 0.01;
uniform float strengthFisheye = -1.10;
uniform float zoomAmount = 0.70;


float random (in float2 st) {
	return frac(sin(dot(st.xy,
		float2(12.9898,78.233)))
		* 43758.5453123);
}

float distsq(float2 v){
	return v.x*v.x+v.y*v.y;
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

float2 fishEyeSample(float2 uvCoord)
{
    float aperture = minAperture + random(builtin_elapsed_time_since_enabled) * (maxAperture - minAperture);
    float apertureHalf = 0.5 * aperture * (PI / 180.0);
    float maxFactor = sin(apertureHalf);

    float2 uv;
    float2 xy = 2.0 * uvCoord.xy - 1.0;
    float d = length(xy);
    if (d < (2.0 - maxFactor))
    {
        d = length(xy * maxFactor);
        float z = sqrt(1.0 - d * d);
        float r = atan2(d, z) / PI;
        float phi = atan2(xy.y, xy.x);

        uv.x = r * cos(phi) + 0.5;
        uv.y = r * sin(phi) + 0.5;
    }
    else
    {
        uv = uvCoord.xy;
    }
    return uv;
}


float4 render(float2 uv) {

	float2 resolution = float2(float(builtin_uv_size.x), float(builtin_uv_size.y));
	float screenRatio = float(builtin_uv_size.x) / float(builtin_uv_size.y);
	float2 center = float2(0.5,0.5); 

	float4 output = 0;


	float polarAngle = atan2(0.5-uv.y,0.5-uv.x);
	polarAngle = float(int(polarAngle*1/lineWidth))/1/lineWidth;
	float distToCenter = distsq(center - uv);
	float value = step(minSpeedLineLength+random(polarAngle+builtin_elapsed_time+100)* (maxSpeedLineLength - minSpeedLineLength),distsq(distToCenter));
	value *= step(random(polarAngle*builtin_elapsed_time*10),speedLineAmount);

	float2 customUV = fishEyeSample(uv);

	float2 texCoordCentered = uv - 0.5;
    float dist = length(texCoordCentered);

    // Calculate the strength of the fisheye distortion
    float strength = 1.0 + (dist * dist) * strengthFisheye;

    // Apply the distortion to the texture coordinate
    texCoordCentered *= strength;
    customUV = texCoordCentered + 0.5;

    customUV = ((customUV-float2(0.5,0.5))*resolution)/resolution.y;
    customUV *= zoomAmount;
    customUV.y *= screenRatio;
	customUV+= float2(0.5,0.5);
	//customUV = mul(rotate(angle)*zoomAmount,customUV);

	

	output += image.Sample(builtin_texture_sampler,customUV);
	output.a = 1;
	output += value*0.5;
	//output +=  value*0.5;

	return output;
}