#version 120
// 伸缩加上高斯模糊
//varying vec2 _uv;
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
vec4 transition()
{
    //vec2 loc = vec2(gl_FragCoord.xy.x * resolution_w, gl_FragCoord.xy.y * resolution_h);       //
    vec2 loc = gl_FragCoord.xy;
    //判断在那个范围内
    //float scaleRadio = cur_w / scale_w;
    vec2 center = vec2(resolution_w / 2.0, resolution_h / 2.0);					//这是一个在0 -> resolution_w范围内的坐标系，因为这时候已经是屏幕坐标系下了
    //vec2 dist = loc - center;
    vec2 scale_origin = vec2(center.x - scale_w / 2.0, center.y - scale_h / 2.0);
    vec2 resultPoint = loc - scale_origin;
    //清晰图像到范围内
    if(resultPoint.x >= 0.0 && resultPoint.x <= scale_w && resultPoint.y >= 0.0 && resultPoint.y <= scale_h)
    {
        vec4 realColor = texture2D(to, vec2(resultPoint.x / scale_w, resultPoint.y / scale_h));
        return realColor;
    }
    else
    {
        //模糊图像的范围内
        //做高斯模糊操作
        vec4 blurColor = vec4(0.0, 0.0, 0.0, 1.0);
        vec2 scale_loc_radio = (loc * crop_w / resolution_w + vec2(overlay_x + crop_x,overlay_y + crop_y) - scale_origin) / vec2(scale_w, scale_h);
        for(int i = 0; i < 10; i++)
        {
            for(int j = 0; j < 10; j++)
            {
                blurColor += texture2D(to, scale_loc_radio) / 100.0;
            }
        }
        return blurColor;
    }

    //vec4 resultColor = texture2D(to, _uv);
}


void main(void)
{
    gl_FragColor = transition();
}