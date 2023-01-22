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
uniform float speed = 0.4;
uniform float delay = 0.1;
uniform float rocketCount = 10;
uniform float particleCount = 60;

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

float2 hash21(float seed){
	float a = random(seed+1*100.25)*PI*2;
	float d = random(seed+a+1000)*0.5+0.5;

	return float2(cos(a)*d,sin(a)*d);
}

float particle(float2 pos, float2 uv, float particleCount, float seed, float time, float size, float b){

	float t = time;
	float col = 0;

	for(int i = 0; i< particleCount; i++){
		float s = lerp(t,1-(t-1)*(t-1),0.6);
		float2 dir = hash21((1+i)*1000+seed)*s*size;
		
		float d = length(uv + pos + dir);
		float brightness = b/((t+1)*(t+1));
		col += lerp(brightness/d , brightness/d * brightness/d,0.5) * step(0,time);
	}
	return col;
}

float trail(float2 pos,float2 target, float2 uv, float count, float size, float b){
	float col = 0;
	float2 dir = normalize(target-pos)*size/count;
	for(int i = 0; i< count; i++){
		float d = length(uv + pos - dir*i);
		float s = lerp(i/count,1-(i/count-1)*(i/count-1),1.5);
		float brightness = lerp(b,b/10,s);
		col += lerp(brightness/d , brightness/d * brightness/d,0.5);
	}
	return col;
}

float easeOut(float t, float a){
	return lerp(t,1-(t-1)*(t-1),a);
}

float4 render(float2 uv) {

	float2 resolution = builtin_uv_size; 
	float screenRatio = float(builtin_uv_size.x) / float(builtin_uv_size.y);
	float2 pixelUV = uv;
	pixelUV -= 0.5;
	pixelUV.x *= screenRatio;

	float3 output = 0;


	for(float i = 0; i< rocketCount; i++){
		float offset = random((i+10)*35.3)*4.2;
		offset = i * delay;
		float time = frac((builtin_elapsed_time_since_enabled+offset)*speed)*2;
		//float t = frac(time);
		float seed = floor((builtin_elapsed_time_since_enabled+offset)*speed)+10*100;
		float seed2 = (i+1)*100 + random(seed+i);

		float tIn = clamp(time,0,1) * step(time,1);
		float tOut = clamp(time,1,2)-1;


		float2 startPos = float2((random(seed2)-0.5)*0.1,-0.5);
		float2 endPos = float2((
			(random(seed + seed2+14616.3)-0.5)*0.5),
			random(seed + seed2+56516.3)*0.2);
		float2 dir = (endPos - startPos);

		float2 pos = startPos + dir*easeOut(tIn,0.5);
		//pos.x += sin(tIn*PI*10)*0.01;
		float rocketBrightness = (1-tIn)*0.003 * abs(sin(tIn * PI * 10));
		float rocket = trail(pos, endPos, pixelUV,5*ceil(tIn),0.1,rocketBrightness);

		float fw = particle(endPos,pixelUV,particleCount,seed2 +25.35,tOut,1,0.002 * ceil(tOut)* (1-tOut));

		float sum = rocket + fw;
		//sum *= step(0.03,sum);
		float3 col = sum;
		col.r *= random(seed2*96.3)+0.1;
		col.g *= random(seed2*143.2)+0.1;
		col.b *= random(seed2*53.1)+0.1;
		output += col;
	}

	float4 final = 0;
	float grey = (output.r+output.g+output.b)/3;
	float distortAmount = step(0.2,grey) * step(grey,0.9) * (grey-0.2)*0;
	float2 imgUV = uv * (1 + distortAmount*0.2);
	//output +=distortAmount; 
	final.rgb += output;
	final += image.Sample(builtin_texture_sampler,imgUV);

	
	final.a = 1;


	return final;



	//return tIn * step(0.5,uv.x) + tOut * step(uv.x,0.5);


	//float3 fw = 0;
	//float particleCount = 1;

	//float rocket = 0;


	/*for(int i = 0; i< particleCount; i++){
	
		float2 partInit = hash21(id*1000+i*1000)*0.9;
		partInit.y = 0;

		float2 partPos = hash21(id*100+i*100)*0.9;

		partInit = float2(0,0);
		partPos = float2(0.1,0.1);

		partInit += normalize(partPos - partInit)*0.2*frac(builtin_elapsed_time_since_enabled);

		//partInit = float2(0,0);
		

		rocket += trail(partInit, partPos, pixelUV,10,0.1);

		float seed = random(id*50+i*100);
		float fwTime = frac(time-i*0.15);

		float part = particle(partPos,pixelUV,100,seed,fwTime,0.3 + random(id)*0.5);

		float3 col = float3(random(id+(i+1)*3) *part,random(id*13.2+(i+1)*5) *part,random(id*96.2+(i+1)*50) *part);

		fw += col;
	}*/

	//output.rgb += fw;
	/*output.rgb += rocket;

	
	
	float grey = (fw.r+fw.g+fw.b)/3;
	float distortAmount = step(0.2,grey) * step(grey,0.9) * (grey-0.2)*0;
	float2 imgUV = uv * (1 + distortAmount*0.2);
	//output +=distortAmount; 
	output += image.Sample(builtin_texture_sampler,imgUV);
	//output = distortAmount;
	output.a = 1;


	return output;*/
}