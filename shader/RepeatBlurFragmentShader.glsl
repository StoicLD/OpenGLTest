#version 120
// 伸缩加上高斯模糊
//varying vec2 _uv;
uniform sampler2D to;

uniform float scale_w;
uniform float scale_h;
uniform float resolution_w;
uniform float resolution_h;

vec4 backColor = vec4(1., 1., 1., 1.);
//这个shader输入的纹理是window大小的了
vec4 transition()
{
    //vec2 loc = vec2(gl_FragCoord.xy.x * resolution_w, gl_FragCoord.xy.y * resolution_h);       //
    vec2 loc = gl_FragCoord.xy;

    //判断在那个范围内
    vec2 center = vec2(resolution_w / 2.0, resolution_h / 2.0);					//这是一个在0 -> resolution_w范围内的坐标系，因为这时候已经是屏幕坐标系下了
    //vec2 scale_origin = vec2(center.x - scale_w / 2.0, center.y - scale_h / 2.0);
    vec2 resultPoint = loc - center;
    //清晰图像到范围内
    vec2 lookup_uv = loc / vec2(resolution_w, resolution_h);
    if(resultPoint.x >= -scale_w / 2.0 && resultPoint.x <= scale_w / 2.0 && resultPoint.y >= -scale_h / 2.0 && resultPoint.y <= scale_h / 2.0)
    {
        vec4 realColor = texture2D(to, lookup_uv);
        return realColor;
    }
    else
    {
        //模糊图像的范围内
        //做高斯模糊操作
        vec4 blurColor = vec4(0.0, 0.0, 0.0, 1.0);
        vec2 scale_loc_radio = lookup_uv;

        float offset[8] = float[](0, 1.45161, 3.3871, 5.32258, 7.25806, 9.19355, 11.129, 13.0645);
        //offset[0] = 0.0; offset[1] = 1.3846153846; offset[2] = 3.2307692308;

        float weight[8] = float[](0.144464, 0.24697, 0.131429, 0.0413062, 0.00734695, 0.000685715, 2.93041e-05, 4.33065e-07);
        //weight[0] = 0.2270270270; weight[1] = 0.3162162162; weight[2] = 0.0702702703;

        vec4 color = texture2D(to, scale_loc_radio) * weight[0];
        vec4 color2 = color;
        //vec4 color = texture2D(to, scale_loc_radio) * weight[0];
        // 垂直
        for (int i = 1; i < 8; i++) {
            color +=
            texture2D(to, (vec2(scale_loc_radio)+vec2(0.0, offset[i] / resolution_w)))
            * weight[i];
            color +=
            texture2D(to, (vec2(scale_loc_radio)-vec2(0.0, offset[i] / resolution_h)))
            * weight[i];
        }

        // 水平
        for (int i = 1; i < 8; i++) {
            color2 +=
            texture2D(to, (vec2(scale_loc_radio)+vec2(offset[i] / resolution_w, 0.0)))
            * weight[i];
            color2 +=
            texture2D(to, (vec2(scale_loc_radio)-vec2(offset[i] / resolution_h, 0.0)))
            * weight[i];
        }
        blurColor = mix(color, color2, 0.5);
        return blurColor;
    }

    //vec4 resultColor = texture2D(to, _uv);
}


void main(void)
{
    gl_FragColor = transition();
}