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

uniform float duration = 10;
uniform float inDuration = 5;
uniform float outDuration = 2;
uniform float4 smokeColor = {1,1,1,1};

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

float3 noise3 (in float3 n){
   float n = noise(n.x,n.y);


   return n;
}


float normnoise(float n) {
    return 0.5*(n+1.0);
}

float clouds(float2 uv) {
    float t = builtin_elapsed_time;
    
    float2 off1 = float2(50.0,33.0);
    float2 off2 = float2(0.0, 0.0);
    float2 off3 = float2(-300.0, 50.0);
    float2 off4 = float2(-100.0, 200.0);
    float2 off5 = float2(400.0, -200.0);
    float2 off6 = float2(100.0, -1000.0);
    float scale1 = 3.0;
    float scale2 = 6.0;
    float scale3 = 12.0;
    float scale4 = 24.0;
    float scale5 = 48.0;
    float scale6 = 96.0;

    //float n = normnoise(noise(float3((uv+off1)*scale1,t*0.5)*0.8));
    
    return normnoise(noise(float3((uv+off1)*scale1,t*0.5))*1.2 + 
                     noise(float3((uv+off2)*scale2,t*0.4))*0.4 +
                     noise(float3((uv+off3)*scale3,t*0.1))*0.2 +
                     noise(float3((uv+off4)*scale4,t*0.7))*0.1 +
                     noise(float3((uv+off5)*scale5,t*0.2))*0.06 +
                     noise(float3((uv+off6)*scale6,t*0.3))*0.025);

    //return n;
}


float4 render(float2 uv) {

    float2 resolution = builtin_uv_size; 
    float screenRatio = float(builtin_uv_size.x) / float(builtin_uv_size.y);


    float4 output = 0;

    float2 screenUV = uv;
    //screenUV.x += screenRatio;
   // screenUV.x *= screenRatio;

   // uv.x -= screenRatio;

   float fadeIn = clamp(builtin_elapsed_time_since_enabled*(1/inDuration),0,1);
   float fadeOut = 1-clamp(-duration+builtin_elapsed_time_since_enabled*(1/outDuration),0,1);

    float2 cuv = uv;
    cuv += float2(builtin_elapsed_time*0.01,builtin_elapsed_time*0.08);
    cuv.y += (sin(builtin_elapsed_time + uv.x*PI*3)+1)*0.5 *0.05;
    cuv.x += sin(uv.y*PI*1 + builtin_elapsed_time*0.30)*0.06;
    cuv.x += sin(uv.x*PI*2.1 + builtin_elapsed_time*1.2)*0.01;
    cuv.x += sin(uv.y*PI*8.9 + builtin_elapsed_time*1.8)*0.005;

    
    float cloud = clamp(clouds(cuv)-(0.5-uv.y)-0.4,0,1);
    
    cloud *= smoothstep(0,3 - fadeIn*fadeOut*3,uv.y);

    float2 imgUV = uv;
    imgUV.x += sin(uv.y * PI * 4 + builtin_elapsed_time)*0.01*fadeIn*fadeOut;

    output+= image.Sample(builtin_texture_sampler,frac(imgUV));
    float4 cloudCol = cloud;
    cloudCol = clamp(cloudCol,0,1);
    cloudCol *= 0.8;
    cloudCol *= smokeColor;
    cloudCol.a = 1;

    output = lerp(output,cloudCol,clamp(cloud,0,1)*0.8);



    output.a = 1;

    return output;
}