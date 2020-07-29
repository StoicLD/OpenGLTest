#version 120
// 伸缩加上高斯模糊
varying vec2 _uv;
uniform sampler2D to;

uniform float cur_w;
uniform float cur_h;
uniform float scale_w;
uniform float scale_h;
uniform float resolution_w;
uniform float resolution_h;
uniform float crop_x;
uniform float crop_y;
uniform float crop_w;
uniform float crop_h;
uniform float overlay_x;
uniform float overlay_y;

vec4 backColor = vec4(1., 1., 1., 1.);
vec4 transition(vec2 uv)
{
	//vec2 loc = vec2(gl_FragCoord.xy.x * resolution_w, gl_FragCoord.xy.y * resolution_h);       //
	vec2 loc = gl_FragCoord.xy;
	//判断在那个范围内
	float scaleRadio = cur_w / scale_w;
	vec2 center = vec2(resolution_w / 2.0, resolution_h / 2.0);
	//vec2 dist = loc - center;
	vec2 scale_origin = vec2(center.x - scale_w / 2.0, center.y - scale_h / 2.0);
	vec2 resultPoint = loc - scale_origin;
	//清晰图像到范围内
	if(resultPoint.x >= 0.0 && resultPoint.x <= scale_w && resultPoint.y >= 0.0 && resultPoint.y <= scale_h)
	{
		//相对于real image左下角的坐标
		//vec2 relativePoint = (dist * scaleRadio) + center;
		vec4 realColor = texture2D(to, vec2(resultPoint.x / scale_w, resultPoint.y / scale_h));
		return realColor;
	}
	else
	{
		//模糊图像的范围内
		//做高斯模糊操作
		vec4 blurColor = vec4(0.0, 0.0, 0.0, 1.0);
		vec2 scale_loc_radio = (loc * crop_w / resolution_w + vec2(overlay_x + crop_x,overlay_y + crop_y) - scale_origin) / vec2(scale_w, scale_h);
		vec2 texelOffset = vec2(1.0) / vec2(scale_w, scale_h);
		//return texture2D(to, scale_loc_radio);


		const int coreSize = 3;
		float kernel[9];
		kernel[0] = .0947416; kernel[1] = .118318; kernel[2] = .0947416;
		kernel[3] = .118318; kernel[4] = .147761; kernel[5] = .118318;
		kernel[6] = .0947416; kernel[7] = .118318; kernel[8] = .0947416;
		int index = 0;
		for(int y=0; y < coreSize; y++)
		{
			for(int x = 0; x < coreSize; x++)
			{
				vec2 curr_loc_radio = scale_loc_radio + vec2(float(-1 + x) * texelOffset.x, float(-1 + y) * texelOffset.y);
				if(curr_loc_radio.x < 0 || curr_loc_radio.x > 1 || curr_loc_radio.y < 0 || curr_loc_radio.y > 1)
				{
					index++;
					continue;
				}
				vec4 currentColor = texture2D(to, curr_loc_radio);
				blurColor += currentColor * kernel[index];
				index++;
			}
		}

		return blurColor;
	}

	//vec4 resultColor = texture2D(to, _uv);
}


void main(void)
{
	gl_FragColor = transition(_uv);
}