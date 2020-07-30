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

		//（0）原版，效率最低的版本
//		const int coreSize = 3;
//		float kernel[9];
//		kernel[0] = .0947416; kernel[1] = .118318; kernel[2] = .0947416;
//		kernel[3] = .118318; kernel[4] = .147761; kernel[5] = .118318;
//		kernel[6] = .0947416; kernel[7] = .118318; kernel[8] = .0947416;
//		int index = 0;
//		for(int y=0; y < coreSize; y++)
//		{
//			for(int x = 0; x < coreSize; x++)
//			{
//				vec2 curr_loc_radio = scale_loc_radio + vec2(float(-1 + x) * texelOffset.x, float(-1 + y) * texelOffset.y);
//				if(curr_loc_radio.x < 0 || curr_loc_radio.x > 1 || curr_loc_radio.y < 0 || curr_loc_radio.y > 1)
//				{
//					index++;
//					continue;
//				}
//				vec4 currentColor = texture2D(to, curr_loc_radio);
//				blurColor += currentColor * kernel[index];
//				index++;
//			}
//		}

		//（1）优化一，尝试使用两次一维的高斯函数优化性能
		//目前的问题是亮度比较大，估计是核函数的数值有问题。
		//int kernel_width = 2;
		//float kernel[5];
//		kernel[0] = 0.054; kernel[1] = 0.244;
//		kernel[2] = 0.403; kernel[3] = 0.244; kernel[4] = 0.054;
//		kernel[0] = 0.0171; kernel[1] = 0.07766;
//		kernel[2] = 0.1282; kernel[3] = 0.07766; kernel[4] = 0.0171;
//
//		for(int i = 0; i < 5; i++)
//		{
//			vec2 curr_loc_radio = scale_loc_radio + vec2(float(-kernel_width + i) * texelOffset.x, 0.);
//			if(curr_loc_radio.x < 0 || curr_loc_radio.x > 1 || curr_loc_radio.y < 0 || curr_loc_radio.y > 1)
//			{
//				continue;
//			}
//			vec4 currentColor = texture2D(to, curr_loc_radio);
//			blurColor += currentColor * kernel[i];
//		}
//
//		for(int i = 0; i < 5; i++)
//		{
//			vec2 curr_loc_radio = scale_loc_radio + vec2(0., float(-kernel_width + i) * texelOffset.y);
//			if(curr_loc_radio.x < 0 || curr_loc_radio.x > 1 || curr_loc_radio.y < 0 || curr_loc_radio.y > 1)
//			{
//				continue;
//			}
//			vec4 currentColor = texture2D(to, curr_loc_radio);
//			blurColor += currentColor * kernel[i];
//		}

		//(2) 优化二
		vec2 iResolution = vec2(scale_w, scale_h);

		float offset[3];
		offset[0] = 0.0; offset[1] = 1.3846153846; offset[2] = 3.2307692308;

		float weight[3];
		weight[0] = 0.2270270270; weight[1] = 0.3162162162; weight[2] = 0.0702702703;

		vec4 color = texture2D(to, scale_loc_radio) * weight[0];

		// 垂直
		for (int i=1; i < 3; i++) {
			color +=
			texture2D(to, (vec2(scale_loc_radio)+vec2(0.0, offset[i] / scale_h)))
			* weight[i];
			color +=
			texture2D(to, (vec2(scale_loc_radio)-vec2(0.0, offset[i] / scale_h)))
			* weight[i];
		}

		vec4 color2 = texture2D(to, vec2(scale_loc_radio)) * weight[0];

		// 水平
		for (int i = 1; i < 3; i++) {
			color2 +=
			texture2D(to, (vec2(scale_loc_radio)+vec2(offset[i] / scale_w, 0.0)))
			* weight[i];
			color2 +=
			texture2D(to, (vec2(scale_loc_radio)-vec2(offset[i] / scale_w, 0.0)))
			* weight[i];
		}
		blurColor = mix(color, color2, 0.5);
		if(blurColor.x == 1.0)
			return vec4(0., 0., 1., 1.);

		return blurColor;
	}

	//vec4 resultColor = texture2D(to, _uv);
}


void main(void)
{
	gl_FragColor = transition(_uv);
}