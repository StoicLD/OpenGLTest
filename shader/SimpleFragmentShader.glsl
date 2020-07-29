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

vec4 backColor = vec4(1., 0.5, 1., 1.);
vec4 transition(vec2 uv)
{
	//vec2 loc = vec2(gl_FragCoord.xy.x * resolution_w, gl_FragCoord.xy.y * resolution_h);       //
	vec2 loc = gl_FragCoord.xy;
	//判断在那个范围内
	float scaleRadio = cur_w / scale_w;
	vec2 center = vec2(resolution_w / 2.0, resolution_h / 2.0);
	//vec2 dist = loc - center;
	vec2 resultPoint = loc - vec2(center.x - scale_w / 2.0, center.y - scale_h / 2.0);
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
		return backColor;
	}

	//vec4 resultColor = texture2D(to, _uv);
}


void main(void)
{
	gl_FragColor = transition(_uv);
}